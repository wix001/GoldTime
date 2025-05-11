//
//  Widget.swift
//  Widget
//
//  Created by 徐蔚起 on 03/05/2025.
//

import WidgetKit
import SwiftUI
import Foundation

// 小组件的主入口点
struct HourlyWageWidget: Widget {
    // 小组件的唯一标识符
    let kind: String = "HourlyWageWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HourlyWageWidgetView(entry: entry)
        }
        .configurationDisplayName("工资计算器") // 小组件显示名称
        .description("实时显示您的工作收入") // 小组件描述
        .supportedFamilies([.systemSmall, .accessoryRectangular]) // 支持的尺寸，包括锁屏小组件
        .contentMarginsDisabled() // 禁用内容边距以获得更好的显示效果
    }
}

// 小组件的时间线提供者
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // 提供占位符数据
        SimpleEntry(
            date: Date(),
            earnedMoney: 0.0,
            workedTime: "00:00:00",
            isWorking: false,
            currency: "¥",
            decimalPlaces: 2,
            timeGoal: 8.0,
            incomeGoal: 1000.0,
            activeGoalType: .time,
            startTime: Date(),
            pausedTotalTime: 0,
            hourlyRate: 100.0,
            lastUpdateTime: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // 获取当前状态的快照
        let settings = UserDefaultsManager.shared.loadUserSettings()
        let earnedMoney = settings.calculateEarnedMoney()
        
        // 计算工作时间
        let totalSeconds = Int(settings.calculateWorkedTime())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let formattedWorkTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        let entry = SimpleEntry(
            date: Date(),
            earnedMoney: earnedMoney,
            workedTime: formattedWorkTime,
            isWorking: settings.isWorking,
            currency: settings.currency,
            decimalPlaces: 2,
            timeGoal: settings.timeGoal,
            incomeGoal: settings.incomeGoal,
            activeGoalType: settings.activeGoalType,
            startTime: settings.startTime ?? Date(),
            pausedTotalTime: settings.pausedTotalTime,
            hourlyRate: settings.hourlyRate,
            lastUpdateTime: Date()
        )

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // 创建一个时间线，定期更新小组件
        var entries: [SimpleEntry] = []
        let settings = UserDefaultsManager.shared.loadUserSettings()
        
        // 创建未来的条目 - 减少条目数量，提高效率
        let currentDate = Date()
        
        // 根据工作状态确定更新间隔和条目数量
        let updateInterval: TimeInterval = settings.isWorking ? 1 : 10 // 工作时每1秒更新，否则每分钟更新
        let numberOfEntries = settings.isWorking ? 12 : 5 // 工作时生成更多条目
        
        for secondOffset in stride(from: 0, to: Int(updateInterval * Double(numberOfEntries)), by: Int(updateInterval)) {
            let entryDate = Calendar.current.date(byAdding: .second, value: secondOffset, to: currentDate)!
            
            // 预先计算收入 - 用于非工作状态显示
            let earnedMoney = settings.calculateEarnedMoney(currentTime: entryDate)
            
            // 预先计算工作时间 - 用于非工作状态显示
            let totalSeconds = Int(settings.calculateWorkedTime(currentTime: entryDate))
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            let formattedWorkTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            
            // 创建条目，但保留开始时间和时薪，以便在视图层进行实时计算
            let entry = SimpleEntry(
                date: entryDate,
                earnedMoney: earnedMoney,
                workedTime: formattedWorkTime,
                isWorking: settings.isWorking,
                currency: settings.currency,
                decimalPlaces: 2,
                timeGoal: settings.timeGoal,
                incomeGoal: settings.incomeGoal,
                activeGoalType: settings.activeGoalType,
                startTime: settings.startTime ?? currentDate,
                pausedTotalTime: settings.pausedTotalTime,
                hourlyRate: settings.hourlyRate,
                lastUpdateTime: currentDate
            )
            entries.append(entry)
        }

        // 创建更智能的刷新策略
        let refreshDate: Date
        
        if settings.isWorking {
            // 工作状态下5-10秒刷新一次
            refreshDate = Calendar.current.date(
                byAdding: .second,
                value: UIDevice.current.batteryState == .charging ? 1 : 5,
                to: currentDate
            )!
        } else {
            // 非工作状态下1分钟刷新一次
            refreshDate = Calendar.current.date(
                byAdding: .minute,
                value: 1,
                to: currentDate
            )!
        }
            
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// 小组件的数据条目
struct SimpleEntry: TimelineEntry {
    let date: Date
    let earnedMoney: Double
    let workedTime: String
    let isWorking: Bool
    let currency: String
    let decimalPlaces: Int
    
    // 目标相关属性
    let timeGoal: Double
    let incomeGoal: Double
    let activeGoalType: GoalType
    
    // 添加用于实时计算的属性
    let startTime: Date
    let pausedTotalTime: TimeInterval
    let hourlyRate: Double
    let lastUpdateTime: Date
    
    // 格式化工资显示为指定小数位数
    func formattedEarnings() -> String {
        let format = "%.\(decimalPlaces)f"
        return "\(currency)\(String(format: format, earnedMoney))"
    }
    
    // 实时计算收入 - 用于视图层
    func calculateEarnings(currentTime: Date) -> Double {
        if isWorking {
            let workedTime = pausedTotalTime + currentTime.timeIntervalSince(startTime)
            let workedHours = workedTime / 3600
            return hourlyRate * workedHours
        } else {
            return earnedMoney
        }
    }
    
    // 实时格式化收入 - 用于视图层
    func formattedRealTimeEarnings(currentTime: Date) -> String {
        let earnings = calculateEarnings(currentTime: currentTime)
        let format = "%.\(decimalPlaces)f"
        return "\(currency)\(String(format: format, earnings))"
    }
    
    // 实时计算工作时间 - 用于视图层
    func calculateWorkTime(currentTime: Date) -> String {
        if isWorking {
            let workedTime = pausedTotalTime + currentTime.timeIntervalSince(startTime)
            let totalSeconds = Int(workedTime)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return workedTime
        }
    }
    
    // 计算目标进度
    func calculateGoalProgress(currentTime: Date? = nil) -> Double {
        let current = currentTime ?? date
        
        switch activeGoalType {
        case .time:
            if isWorking {
                // 实时计算时间进度
                let workedTime = pausedTotalTime + current.timeIntervalSince(startTime)
                let workedHours = workedTime / 3600
                return min(workedHours / timeGoal, 1.0)
            } else {
                // 解析workedTime字符串获取小时数
                let components = workedTime.split(separator: ":")
                if components.count == 3,
                   let hours = Double(components[0]),
                   let minutes = Double(components[1]),
                   let seconds = Double(components[2]) {
                    let totalHours = hours + minutes/60 + seconds/3600
                    return min(totalHours / timeGoal, 1.0)
                }
                return 0.0
            }
        case .income:
            if isWorking {
                // 实时计算收入进度
                let earnings = calculateEarnings(currentTime: current)
                return min(earnings / incomeGoal, 1.0)
            } else {
                return min(earnedMoney / incomeGoal, 1.0)
            }
        }
    }
    
    // 获取目标进度文本
    func getGoalProgressText(currentTime: Date? = nil) -> String {
        let progress = calculateGoalProgress(currentTime: currentTime)
        return String(format: "%.0f%%", progress * 100)
    }
    
    // 获取目标描述
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
    
    // 获取格式化的更新时间
    func formattedUpdateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: lastUpdateTime)
    }
}
