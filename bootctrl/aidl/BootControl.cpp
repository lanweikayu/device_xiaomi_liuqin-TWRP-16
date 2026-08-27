/*
 * Copyright (C) 2022 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "BootControl.h"

#include <android-base/logging.h>
#include <cerrno>
#include <cstring>
#include <string>

using HIDLMergeStatus = ::android::hardware::boot::V1_1::MergeStatus;
using ndk::ScopedAStatus;

namespace aidl::android::hardware::boot {

namespace {

static MergeStatus ToAidlMergeStatus(HIDLMergeStatus status) {
    return static_cast<MergeStatus>(status);
}

static HIDLMergeStatus ToHidlMergeStatus(MergeStatus status) {
    return static_cast<HIDLMergeStatus>(status);
}

static ScopedAStatus CommandFailed() {
    return ScopedAStatus::fromServiceSpecificErrorWithMessage(IBootControl::COMMAND_FAILED,
                                                              "Operation failed");
}

static ScopedAStatus InvalidSlot(int32_t slot) {
    return ScopedAStatus::fromServiceSpecificErrorWithMessage(
            IBootControl::INVALID_SLOT,
            (std::string("Invalid slot ") + std::to_string(slot)).c_str());
}

}  // namespace

BootControl::BootControl() {
    if (!bootcontrol_init()) {
        LOG(WARNING) << "QTI bootcontrol_init failed; GPT slot ops may still work";
    }
}

ScopedAStatus BootControl::getActiveBootSlot(int32_t* _aidl_return) {
    int32_t ret = get_active_boot_slot();
    *_aidl_return = ret < 0 ? 0 : ret;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getCurrentSlot(int32_t* _aidl_return) {
    *_aidl_return = static_cast<int32_t>(get_current_slot());
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getNumberSlots(int32_t* _aidl_return) {
    *_aidl_return = static_cast<int32_t>(get_number_slots());
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getSnapshotMergeStatus(MergeStatus* _aidl_return) {
    *_aidl_return = ToAidlMergeStatus(get_snapshot_merge_status());
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getSuffix(int32_t in_slot, std::string* _aidl_return) {
    const char* suffix = get_suffix(static_cast<unsigned>(in_slot));
    if (!suffix) {
        _aidl_return->clear();
    } else {
        *_aidl_return = suffix;
    }
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotBootable(int32_t in_slot, bool* _aidl_return) {
    int32_t ret = is_slot_bootable(static_cast<unsigned>(in_slot));
    if (ret < 0) {
        return InvalidSlot(in_slot);
    }
    *_aidl_return = ret != 0;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotMarkedSuccessful(int32_t in_slot, bool* _aidl_return) {
    int32_t ret = is_slot_marked_successful(static_cast<unsigned>(in_slot));
    if (ret < 0) {
        return InvalidSlot(in_slot);
    }
    *_aidl_return = ret != 0;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::markBootSuccessful() {
    if (mark_boot_successful() != 0) {
        return CommandFailed();
    }
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setActiveBootSlot(int32_t in_slot) {
    if (in_slot < 0) {
        return InvalidSlot(in_slot);
    }
    if (set_active_boot_slot(static_cast<unsigned>(in_slot)) != 0) {
        LOG(ERROR) << "set_active_boot_slot(" << in_slot << ") failed: " << strerror(errno);
        return CommandFailed();
    }
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setSlotAsUnbootable(int32_t in_slot) {
    if (in_slot < 0) {
        return InvalidSlot(in_slot);
    }
    if (set_slot_as_unbootable(static_cast<unsigned>(in_slot)) != 0) {
        return CommandFailed();
    }
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::setSnapshotMergeStatus(MergeStatus in_status) {
    if (!set_snapshot_merge_status(ToHidlMergeStatus(in_status))) {
        return CommandFailed();
    }
    return ScopedAStatus::ok();
}

}  // namespace aidl::android::hardware::boot
