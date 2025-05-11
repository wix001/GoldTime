//
//  UserSettings.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import Foundation

// 用户设置模型，包含工资率和工作状态信息
public struct UserSettings: Codable {
    var hourlyRate: Double = 0.0
    var isWorking: Bool = false
    var startTime: Date?
    var pausedTotalTime: TimeInterval = 0.0
    var currency: String = "¥" // 默认使用人民币符号
    
    // 新增的目标设置
    var timeGoal: Double = 8.0 // 默认目标工作时间为8小时
    var incomeGoal: Double = 1000.0 // 默认目标收入1000元
    var activeGoalType: GoalType = .time // 默认使用时间目标
    
    // 记录上次更新时间，用于监控更新频率
    var lastUpdateTime: Date = Date()
    
    // 计算已工作的总时间
    func calculateWorkedTime(currentTime: Date = Date()) -> TimeInterval {
        guard let start = startTime, isWorking else {
            return pausedTotalTime
        }
        
        return pausedTotalTime + currentTime.timeIntervalSince(start)
    }
    
    // 计算已赚取的金额
    func calculateEarnedMoney(currentTime: Date = Date()) -> Double {
        let workedHours = calculateWorkedTime(currentTime: currentTime) / 3600
        return hourlyRate * workedHours
    }
    
    // 计算目标完成度（时间或收入）
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
    
    // 更新最后更新时间
    mutating func updateLastUpdateTime() {
        lastUpdateTime = Date()
    }
}

// 目标类型枚举
public enum GoalType: String, Codable {
    case time = "time"
    case income = "income"
}
