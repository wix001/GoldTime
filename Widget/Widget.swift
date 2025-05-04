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
            decimalPlaces: 4,
            timeGoal: 8.0,
            incomeGoal: 1000.0,
            activeGoalType: .time
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
            decimalPlaces: 4,
            timeGoal: settings.timeGoal,
            incomeGoal: settings.incomeGoal,
            activeGoalType: settings.activeGoalType
        )

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // 创建一个时间线，定期更新小组件
        var entries: [SimpleEntry] = []
        let settings = UserDefaultsManager.shared.loadUserSettings()
        
        // 创建未来的条目
        let currentDate = Date()
        let updateInterval: TimeInterval = settings.isWorking ? 1 : 60 // 工作时每秒更新，否则每分钟更新
        
        for secondOffset in stride(from: 0, to: 180, by: updateInterval) {
            let entryDate = Calendar.current.date(byAdding: .second, value: Int(secondOffset), to: currentDate)!
            
            // 计算预计收入
            let earnedMoney = settings.calculateEarnedMoney(currentTime: entryDate)
            
            // 计算工作时间
            let totalSeconds = Int(settings.calculateWorkedTime(currentTime: entryDate))
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            let formattedWorkTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            
            let entry = SimpleEntry(
                date: entryDate,
                earnedMoney: earnedMoney,
                workedTime: formattedWorkTime,
                isWorking: settings.isWorking,
                currency: settings.currency,
                decimalPlaces: 4,
                timeGoal: settings.timeGoal,
                incomeGoal: settings.incomeGoal,
                activeGoalType: settings.activeGoalType
            )
            entries.append(entry)
        }

        // 创建更快的刷新策略，以保持实时更新
        // 根据工作状态决定刷新时间
        let refreshDate = settings.isWorking
            ? Calendar.current.date(byAdding: .second, value: 1, to: currentDate)!  // 每1秒刷新
            : Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!  // 每1分钟刷新
            
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
    
    // 新增目标相关属性
    let timeGoal: Double
    let incomeGoal: Double
    let activeGoalType: GoalType
    
    // 格式化工资显示为四位小数
    func formattedEarnings() -> String {
        let format = "%.\(decimalPlaces)f"
        return "\(currency)\(String(format: format, earnedMoney))"
    }
    
    // 计算目标进度
    func calculateGoalProgress() -> Double {
        switch activeGoalType {
        case .time:
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
        case .income:
            return min(earnedMoney / incomeGoal, 1.0)
        }
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
}
