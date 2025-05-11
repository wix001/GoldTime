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
            // 锁屏界面 UI - 使用TimelineView实现实时计算
            LockScreenLiveActivityView(context: context)
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
                    // 使用实时计算的工作时间
                    LiveWorkTimeView(context: context)
                        .font(.caption)
                        .bold()
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("工资计算器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 使用实时计算的收入金额
                    LiveEarningsView(context: context)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(context.state.isWorking ? Color(hex: 0xFFD700) : Color.secondary)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("时薪: \(context.state.currency)\(String(format: "%.2f", context.state.hourlyRate))", systemImage: "dollarsign.circle")
                            .font(.caption)
                        
                        Spacer()
                        
                        // 显示工作状态和最后更新时间
                        if context.state.isWorking {
                            VStack(alignment: .trailing, spacing: 1) {
                                Label("工作中", systemImage: "play.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                LastUpdateTimeView(updateTime: context.state.lastUpdateTime)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
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
                // 动态岛右侧紧凑视图 - 使用实时计算的收入
                LiveEarningsView(context: context, fontSize: 12)
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

// 实时计算工资的视图组件
struct LiveEarningsView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    var fontSize: CGFloat? = nil
    
    var body: some View {
        // 使用TimelineView进行实时更新
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            // 仅在工作状态下进行实时计算
            if context.state.isWorking {
                Text(calculateEarnings(currentTime: timeline.date))
                    .font(fontSize != nil ? .system(size: fontSize!) : nil)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: 0xFFD700))
                    .shadow(color: .yellow.opacity(0.3), radius: 1, x: 0, y: 0)
            } else {
                // 非工作状态下显示固定值
                Text(formatEarnings(context.state.calculatedEarnings))
                    .font(fontSize != nil ? .system(size: fontSize!) : nil)
                    .fontWeight(.bold)
                    .foregroundColor(Color.secondary)
            }
        }
    }
    
    // 实时计算收入
    private func calculateEarnings(currentTime: Date) -> String {
        // 计算已工作的时间
        let workedTime = context.state.pausedTotalTime +
                         currentTime.timeIntervalSince(context.state.startTime)
        
        // 计算小时数和收入
        let workedHours = workedTime / 3600
        let earnings = context.state.hourlyRate * workedHours
        
        return formatEarnings(earnings)
    }
    
    // 格式化收入显示
    private func formatEarnings(_ earnings: Double) -> String {
        let format = "%.\(context.state.decimalPlaces)f"
        return "\(context.state.currency)\(String(format: format, earnings))"
    }
}

// 实时计算工作时间的视图组件
struct LiveWorkTimeView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            if context.state.isWorking {
                Text(formatWorkTime(currentTime: timeline.date))
            } else {
                Text(formatWorkTime(currentTime: nil))
            }
        }
    }
    
    // 格式化工作时间
    private func formatWorkTime(currentTime: Date?) -> String {
        let totalSeconds: Int
        
        if let current = currentTime, context.state.isWorking {
            // 计算实时工作时间
            let workedTime = context.state.pausedTotalTime +
                             current.timeIntervalSince(context.state.startTime)
            totalSeconds = Int(workedTime)
        } else {
            // 使用固定时间（暂停状态）
            totalSeconds = Int(context.state.pausedTotalTime)
        }
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// 显示最后更新时间的视图组件
struct LastUpdateTimeView: View {
    let updateTime: Date
    
    var body: some View {
        Text("更新: \(formattedTime(updateTime))")
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// 锁屏界面视图 - 使用TimelineView更新
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // 使用TimelineView自动更新UI
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        // 标题
//                        HStack {
//                            // 显示上次更新时间，提供反馈
//                            if context.state.isWorking {
//                                Text("上次更新时间: \(formattedTime(context.state.lastUpdateTime))")
//                                    .font(.caption2)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
                        
                        // 动态计算收入金额
                        Text(getEarnings(currentTime: timeline.date))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(context.state.isWorking ?
                                             (colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B)) :
                                             Color.secondary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer()
                    
                    // 右侧信息
                    VStack(alignment: .trailing) {
                        Text("工作时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 动态计算工作时间
                        Text(getWorkTime(currentTime: timeline.date))
                            .font(.callout)
                            .bold()
                    }
                }
                
                // 动态计算进度条
                ProgressView(value: getGoalProgress(currentTime: timeline.date))
                    .progressViewStyle(LinearProgressViewStyle(tint: context.state.activeGoalType == .time ? .green : Color(hex: 0xFFD700)))
                    .padding(.vertical, 4)

                // 底部信息部分
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(context.state.isWorking ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        // 状态文本
                        Text(context.state.isWorking ? "工作中" : "已暂停")
                            .font(.caption)
                            .foregroundColor(context.state.isWorking ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    // 目标信息
                    Text("\(context.state.getGoalDescription()) (\(getGoalProgressText(currentTime: timeline.date)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
    }
    
    // 获取格式化时间
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // 实时计算工作时间
    private func getWorkTime(currentTime: Date) -> String {
        let totalSeconds: Int
        
        if context.state.isWorking {
            // 实时计算
            let workedTime = context.state.pausedTotalTime +
                             currentTime.timeIntervalSince(context.state.startTime)
            totalSeconds = Int(workedTime)
        } else {
            // 固定时间（暂停状态）
            totalSeconds = Int(context.state.pausedTotalTime)
        }
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // 实时计算收入
    private func getEarnings(currentTime: Date) -> String {
        if context.state.isWorking {
            // 计算已工作的时间
            let workedTime = context.state.pausedTotalTime +
                             currentTime.timeIntervalSince(context.state.startTime)
            
            // 计算收入
            let workedHours = workedTime / 3600
            let earnings = context.state.hourlyRate * workedHours
            
            // 格式化显示
            let format = "%.\(context.state.decimalPlaces)f"
            return "\(context.state.currency)\(String(format: format, earnings))"
        } else {
            // 非工作状态显示固定收入
            let format = "%.\(context.state.decimalPlaces)f"
            return "\(context.state.currency)\(String(format: format, context.state.calculatedEarnings))"
        }
    }
    
    // 实时计算目标进度
    private func getGoalProgress(currentTime: Date) -> Double {
        if context.state.isWorking {
            switch context.state.activeGoalType {
            case .time:
                // 计算工作时间进度
                let workedTime = context.state.pausedTotalTime +
                                 currentTime.timeIntervalSince(context.state.startTime)
                let workedHours = workedTime / 3600
                return min(workedHours / context.state.timeGoal, 1.0)
                
            case .income:
                // 计算收入进度
                let workedTime = context.state.pausedTotalTime +
                                 currentTime.timeIntervalSince(context.state.startTime)
                let workedHours = workedTime / 3600
                let earnings = context.state.hourlyRate * workedHours
                return min(earnings / context.state.incomeGoal, 1.0)
            }
        } else {
            // 暂停状态使用固定进度
            return context.state.calculatedProgress
        }
    }
    
    // 实时计算目标进度文本
    private func getGoalProgressText(currentTime: Date) -> String {
        let progress = getGoalProgress(currentTime: currentTime)
        return String(format: "%.0f%%", progress * 100)
    }
}

// 颜色扩展，支持十六进制颜色
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// 预览组
extension GoldTimeActivityAttributes {
    fileprivate static var preview: GoldTimeActivityAttributes {
        GoldTimeActivityAttributes(name: "工资计算器")
    }
}

extension GoldTimeActivityAttributes.ContentState {
    fileprivate static var working: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date().addingTimeInterval(-3600), // 一小时前开始
            pausedTotalTime: 0,
            calculatedEarnings: 100.0,
            calculatedProgress: 0.5,
            isWorking: true,
            currency: "¥",
            decimalPlaces: 2,
            lastUpdateTime: Date()
        )
     }
     
    fileprivate static var paused: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date(),
            pausedTotalTime: 1800, // 半小时的暂停时间
            calculatedEarnings: 50.0,
            calculatedProgress: 0.25,
            isWorking: false,
            currency: "¥",
            decimalPlaces: 2,
            lastUpdateTime: Date()
        )
     }
}

#Preview("活动通知", as: .content, using: GoldTimeActivityAttributes.preview) {
   WidgetLiveActivity()
} contentStates: {
    GoldTimeActivityAttributes.ContentState.working
    GoldTimeActivityAttributes.ContentState.paused
}
