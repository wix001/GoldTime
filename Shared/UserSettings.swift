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
    var currency: String = "¥" // 默认使用人民币符号，可以根据需要修改
    
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
}