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
        var hourlyRate: Double
        var startTime: Date
        var pausedTotalTime: TimeInterval
        var isWorking: Bool
        var currency: String
        var decimalPlaces: Int = 4 // 保持4位小数
        
        // 目标相关属性
        var timeGoal: Double = 8.0
        var incomeGoal: Double = 1000.0
        var activeGoalType: GoalType = .time
        
        // 这些计算方法已经不需要了，因为View会自己计算
        // 但保留它们以保持向后兼容性
        
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
        
        // 计算目标完成度
        func calculateGoalProgress(currentTime: Date = Date()) -> Double {
            switch activeGoalType {
            case .time:
                let workedHours = calculateWorkedTime(currentTime: currentTime) / 3600
                return min(workedHours / timeGoal, 1.0)
            case .income:
                let earned = calculateEarnedMoney(currentTime: currentTime)
                return min(earned / incomeGoal, 1.0)
            }
        }
        
        // 获取目标说明文本
        func getGoalDescription() -> String {
            switch activeGoalType {
            case .time:
                let hours = Int(timeGoal)
                let minutes = Int((timeGoal - Double(hours)) * 60)
                return String(format: "目标: %d时%02d分", hours, minutes)
            case .income:
                return String(format: "目标: %@%.2f", currency, incomeGoal)
            }
        }
        
        // 获取目标进度百分比文本
        func getGoalProgressText(currentTime: Date = Date()) -> String {
            return String(format: "%.0f%%", calculateGoalProgress(currentTime: currentTime) * 100)
        }
    }
    
    // 显示名称 - 活动的标题
    var name: String
}
