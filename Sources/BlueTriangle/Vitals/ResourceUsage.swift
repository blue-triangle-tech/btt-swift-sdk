//
//  ResourceUsage.swift
//
//  Created by Mathew Gacy on 1/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct ResourceUsage: ResourceUsageMeasuring {

    static func cpu() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadList: thread_act_array_t = UnsafeMutablePointer(mutating: [thread_act_t]())
        var threadCount: mach_msg_type_number_t = 0

        let threadResult = withUnsafeMutablePointer(to: &threadList) {
            $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadCount)
            }
        }

        if threadResult == KERN_SUCCESS {
            for index in 0..<threadCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                guard infoResult == KERN_SUCCESS else {
                    break
                }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }

        vm_deallocate(mach_task_self_,
                      vm_address_t(UInt(bitPattern: threadList)),
                      vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride))

        return totalUsageOfCPU
    }

    // https://stackoverflow.com/a/50968168/4472195
    static func memory() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        let used: UInt64 = result == KERN_SUCCESS ? UInt64(taskInfo.phys_footprint) : 0
        return used
    }
}
