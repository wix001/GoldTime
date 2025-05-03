//
//  GoldTimeActivityAttributes.swift
//  GoldTime
//
//  Created on 03/05/2025.
//

import Foundation
import ActivityKit

// 定义LiveActivity的属性和内容状态
struct GoldTimeActivityAttributes: ActivityAttributes {
    // 固定属性 - 活动一旦创建就不会改变的属性
    public struct ContentState: Codable, Hashable {
        // 动态状态属性 - 这些属性会随着活动的更新而改变
        var hourlyRate: Double
        var startTime: Date
        var pausedTotalTime: TimeInterval
        var isWorking: Bool
        var currency: String
        var decimalPlaces: Int = 4 // 默认显示4位小数
        
        // 计算已工作的总时间
        func calculateWorkedTime(currentTime: Date = Date()) -> TimeInterval {
            guard isWorking else {
                return pausedTotalTime
            }
            
            return pausedTotalTime + currentTime.timeIntervalSince(startTime)
        }
        
        // 计算已赚取的金额
        func calculateEarnedMoney(currentTime: Date = Date()) -> Double {
            let workedHours = calculateWorkedTime(currentTime: currentTime) / 3600
            return hourlyRate * workedHours
        }
        
        // 格式化工资显示
        func formattedEarnings(currentTime: Date = Date()) -> String {
            let format = "%.\(decimalPlaces)f"
            return "\(currency)\(String(format: format, calculateEarnedMoney(currentTime: currentTime)))"
        }
        
        // 格式化工作时间
        func formattedWorkTime(currentTime: Date = Date()) -> String {
            let totalSeconds = Int(calculateWorkedTime(currentTime: currentTime))
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    // 显示名称 - 活动的标题
    var name: String
}
