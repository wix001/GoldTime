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
        
        // 添加预先计算的值，减少实时计算需要
        var calculatedEarnings: Double
        var calculatedProgress: Double
        
        var isWorking: Bool
        var currency: String
        var decimalPlaces: Int = 4 // 默认显示4位小数
        
        // 添加最后更新时间，用于显示和监控
        var lastUpdateTime: Date = Date()
        
        // 目标相关属性
        var timeGoal: Double = 8.0
        var incomeGoal: Double = 1000.0
        var activeGoalType: GoalType = .time
        
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
        
        // 格式化工资显示
        func formattedEarnings() -> String {
            let format = "%.\(decimalPlaces)f"
            return "\(currency)\(String(format: format, calculatedEarnings))"
        }
    }
    
    // 显示名称 - 活动的标题
    var name: String
}
