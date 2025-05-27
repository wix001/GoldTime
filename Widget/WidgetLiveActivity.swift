//
//  WidgetLiveActivity.swift
//  Widget
//
//  Created by 徐蔚起 on 03/05/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoldTimeActivityAttributes.self) { context in
            // 锁屏界面 UI - 使用自更新版本
            SelfUpdatingLockScreenView(context: context)
                .activityBackgroundTint(Color(UIColor.systemGray6))
                .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // 展开状态的动态岛 UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                        Text("工作时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    SelfUpdatingWorkTimeView(context: context, style: .compact)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("工资计算器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 自更新收入金额
                    SelfUpdatingEarningsView(context: context, style: .large)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("时薪: \(context.state.currency)\(String(format: "%.2f", context.state.hourlyRate))", systemImage: "dollarsign.circle")
                            .font(.caption)
                        
                        Spacer()
                        
                        // 显示工作状态
                        if context.state.isWorking {
                            Label("工作中", systemImage: "play.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("已暂停", systemImage: "pause.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // 动态岛左侧紧凑视图
                HStack(spacing: 2) {
                    Circle()
                        .fill(context.state.isWorking ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text("工资")
                        .font(.caption2)
                }
            } compactTrailing: {
                // 动态岛右侧紧凑视图 - 使用自更新版本
                SelfUpdatingEarningsView(context: context, style: .minimal)
            } minimal: {
                // 动态岛最小化视图
                Image(systemName: context.state.isWorking ? "dollarsign.circle.fill" : "dollarsign.circle")
                    .foregroundColor(context.state.isWorking ? .green : Color(hex: 0xFFD700))
            }
            .widgetURL(URL(string: "goldtime://open"))
            .keylineTint(context.state.isWorking ? .green : Color(hex: 0xFFD700))
        }
        .contentMarginsDisabled()
    }
}

// 自更新的锁屏视图
struct SelfUpdatingLockScreenView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    @State private var currentTime = Date()
    @Environment(\.colorScheme) var colorScheme
    
    // 创建本地计时器，不依赖主应用
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // 标题和状态
                    HStack(spacing: 4) {
                        Text("黄金时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(context.state.isWorking ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        
                        Text(context.state.isWorking ? "工作中" : "已暂停")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(context.state.isWorking ? .green : .orange)
                    }
                    
                    // 实时计算的收入金额
                    Text(calculateRealTimeEarnings())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(context.state.isWorking ?
                                         (colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B)) :
                                         Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // 右侧信息
                VStack(alignment: .trailing, spacing: 8) {
                    // 工作时间
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("工作时间")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(calculateRealTimeWorkTime())
                            .font(.system(size: 16, weight: .semibold))
                            .monospacedDigit()
                    }
                    
                    // 时薪信息
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("时薪")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(context.state.currency)\(String(format: "%.2f", context.state.hourlyRate))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // 目标进度条
            VStack(spacing: 4) {
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        // 进度
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        context.state.activeGoalType == .time ? Color.green.opacity(0.8) : Color(hex: 0xFFD700).opacity(0.8),
                                        context.state.activeGoalType == .time ? Color.green : Color(hex: 0xFFD700)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(CGFloat(calculateRealTimeGoalProgress()) * geometry.size.width, geometry.size.width), height: 6)
                            .cornerRadius(3)
                            .animation(.linear(duration: 0.3), value: calculateRealTimeGoalProgress())
                    }
                }
                .frame(height: 6)
                
                // 目标信息
                HStack {
                    // 目标描述
                    HStack(spacing: 4) {
                        Image(systemName: context.state.activeGoalType == .time ? "clock" : "dollarsign.circle")
                            .font(.caption2)
                            .foregroundColor(context.state.activeGoalType == .time ? .green : Color(hex: 0xFFD700))
                        
                        Text(context.state.getGoalDescription())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 进度百分比
                    Text(String(format: "%.0f%%", calculateRealTimeGoalProgress() * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(context.state.activeGoalType == .time ? .green : Color(hex: 0xFFD700))
                }
            }
        }
        .padding(16)
        .onReceive(timer) { _ in
            // 每秒更新一次当前时间，触发UI重新计算
            currentTime = Date()
        }
    }
    
    // 实时计算工作时间
    private func calculateRealTimeWorkTime() -> String {
        let totalSeconds: Int
        
        if context.state.isWorking {
            // 工作中：计算从开始时间到现在的时间 + 已暂停的时间
            let workingTime = currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = Int(context.state.pausedTotalTime + workingTime)
        } else {
            // 已暂停：只显示已暂停的总时间
            totalSeconds = Int(context.state.pausedTotalTime)
        }
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // 实时计算收入
    private func calculateRealTimeEarnings() -> String {
        let totalSeconds: TimeInterval
        
        if context.state.isWorking {
            let workingTime = currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = context.state.pausedTotalTime + workingTime
        } else {
            totalSeconds = context.state.pausedTotalTime
        }
        
        let hours = totalSeconds / 3600
        let earnings = context.state.hourlyRate * hours
        
        let format = "%.\(context.state.decimalPlaces)f"
        return "\(context.state.currency)\(String(format: format, earnings))"
    }
    
    // 实时计算目标进度
    private func calculateRealTimeGoalProgress() -> Double {
        let totalSeconds: TimeInterval
        
        if context.state.isWorking {
            let workingTime = currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = context.state.pausedTotalTime + workingTime
        } else {
            totalSeconds = context.state.pausedTotalTime
        }
        
        switch context.state.activeGoalType {
        case .time:
            let workedHours = totalSeconds / 3600
            return min(workedHours / context.state.timeGoal, 1.0)
        case .income:
            let hours = totalSeconds / 3600
            let earned = context.state.hourlyRate * hours
            return min(earned / context.state.incomeGoal, 1.0)
        }
    }
}

// 自更新的收入显示组件
struct SelfUpdatingEarningsView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    let style: EarningsStyle
    @State private var currentTime = Date()
    
    enum EarningsStyle {
        case minimal
        case compact
        case large
    }
    
    // 本地计时器
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(calculateEarnings())
            .font(fontSize)
            .fontWeight(.bold)
            .foregroundColor(context.state.isWorking ? Color(hex: 0xFFD700) : Color.secondary)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }
    
    private var fontSize: Font {
        switch style {
        case .minimal:
            return .system(size: 12)
        case .compact:
            return .system(size: 14)
        case .large:
            return .system(size: 24)
        }
    }
    
    private func calculateEarnings() -> String {
        let totalSeconds: TimeInterval
        
        if context.state.isWorking {
            let workingTime = currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = context.state.pausedTotalTime + workingTime
        } else {
            totalSeconds = context.state.pausedTotalTime
        }
        
        let hours = totalSeconds / 3600
        let earnings = context.state.hourlyRate * hours
        
        // 根据样式调整小数位数
        let decimalPlaces = style == .minimal ? 2 : context.state.decimalPlaces
        let format = "%.\(decimalPlaces)f"
        return "\(context.state.currency)\(String(format: format, earnings))"
    }
}

// 自更新的工作时间显示组件
struct SelfUpdatingWorkTimeView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    let style: TimeStyle
    @State private var currentTime = Date()
    
    enum TimeStyle {
        case compact
        case full
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(calculateWorkTime())
            .font(style == .compact ? .caption : .callout)
            .fontWeight(.medium)
            .monospacedDigit()
            .onReceive(timer) { _ in
                currentTime = Date()
            }
    }
    
    private func calculateWorkTime() -> String {
        let totalSeconds: Int
        
        if context.state.isWorking {
            let workingTime = currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = Int(context.state.pausedTotalTime + workingTime)
        } else {
            totalSeconds = Int(context.state.pausedTotalTime)
        }
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if style == .compact {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

// 预览
extension GoldTimeActivityAttributes {
    fileprivate static var preview: GoldTimeActivityAttributes {
        GoldTimeActivityAttributes(name: "工资计算器")
    }
}

extension GoldTimeActivityAttributes.ContentState {
    fileprivate static var working: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date().addingTimeInterval(-3600),
            pausedTotalTime: 0,
            isWorking: true,
            currency: "¥",
            decimalPlaces: 4,
            timeGoal: 8.0,
            incomeGoal: 1000.0,
            activeGoalType: .time
        )
    }
    
    fileprivate static var paused: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date(),
            pausedTotalTime: 1800,
            isWorking: false,
            currency: "¥",
            decimalPlaces: 4,
            timeGoal: 8.0,
            incomeGoal: 1000.0,
            activeGoalType: .income
        )
    }
}

#Preview("活动通知", as: .content, using: GoldTimeActivityAttributes.preview) {
    WidgetLiveActivity()
} contentStates: {
    GoldTimeActivityAttributes.ContentState.working
    GoldTimeActivityAttributes.ContentState.paused
}
