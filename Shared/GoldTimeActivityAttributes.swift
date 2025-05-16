//
//  GoldTimeActivityAttributes.swift (Minimal Version)
//  GoldTime
//
//  Created on 03/05/2025.
//

import Foundation
import ActivityKit

// 定义LiveActivity的属性和内容状态 (最小化版本)
struct GoldTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 最小化状态，只需要一个可以区分不同 Activity 实例的值（如果需要）
        // 或者只是一个简单的占位符，因为这个最小化视图不直接使用它。
        var lastUpdateTime: Date // 记录主App最后一次更新状态的时间 (可选，但有时有用)
        var isWorking: Bool      // 仍然需要知道是否应该计时
        var startTime: Date      // 计时开始时间
        var pausedTotalTime: TimeInterval // 累计暂停时间

        // 我们可以保留一个简单的格式化时间函数，如果需要在锁屏上显示它
        func formattedElapsedTime(currentTime: Date) -> String {
            guard isWorking else {
                // 如果暂停了，可以显示总的暂停时间，或者一个固定的"Paused"文本
                let totalPausedSeconds = Int(round(pausedTotalTime))
                let p_hours = totalPausedSeconds / 3600
                let p_minutes = (totalPausedSeconds % 3600) / 60
                let p_seconds = totalPausedSeconds % 60
                return String(format: "Paused: %02d:%02d:%02d", p_hours, p_minutes, p_seconds)
            }
            
            let currentElapsed = pausedTotalTime + currentTime.timeIntervalSince(startTime)
            let totalSeconds = Int(round(currentElapsed))
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    // 固定属性
    var activityName: String = "Minimal Timer" // 一个简单的名称

    // 关键：告诉系统这是一个计时器
    static var showsLiveActivityTimer: Bool {
        return true
    }
}
