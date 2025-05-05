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
            // 锁屏界面 UI
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
                    Text(context.state.formattedWorkTime())
                        .font(.caption)
                        .bold()
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("工资计算器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 收入金额
                    Text(context.state.formattedEarnings())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(context.state.isWorking ? Color(hex: 0xFFD700) : Color.secondary)
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
                // 动态岛右侧紧凑视图
                Text(context.state.formattedEarnings())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(context.state.isWorking ? Color(hex: 0xFFD700) : Color.secondary)
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

// 锁屏界面视图
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    @State private var currentTime = Date()
    @Environment(\.colorScheme) var colorScheme
    
    // 使用计时器来更新当前时间
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    // 标题
                    HStack {
                        Text("黄金时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 收入金额
                    Text(getRealTimeEarnings())
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
                    
                    Text(getRealTimeWorkTime())
                        .font(.callout)
                        .bold()
                }
            }
            
            // 进度条 - 根据目标类型显示进度
            ProgressView(value: context.state.calculateGoalProgress())
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
                Text("\(context.state.getGoalDescription()) (\(context.state.getGoalProgressText()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // 实时计算当前工作时间（考虑当前时间）
    private func calculateRealTimeWorkedTime() -> TimeInterval {
        guard context.state.isWorking else {
            return context.state.pausedTotalTime
        }
        
        return context.state.pausedTotalTime + currentTime.timeIntervalSince(context.state.startTime)
    }
    
    // 实时获取工作时间
    private func getRealTimeWorkTime() -> String {
        let totalSeconds = Int(calculateRealTimeWorkedTime())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // 实时计算收入
    private func getRealTimeEarnings() -> String {
        let workedHours = calculateRealTimeWorkedTime() / 3600
        let earnings = context.state.hourlyRate * workedHours
        
        let format = "%.\(context.state.decimalPlaces)f"
        return "\(context.state.currency)\(String(format: format, earnings))"
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
            isWorking: true,
            currency: "¥",
            decimalPlaces: 2
        )
     }
     
    fileprivate static var paused: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date(),
            pausedTotalTime: 1800, // 半小时的暂停时间
            isWorking: false,
            currency: "¥",
            decimalPlaces: 2
        )
     }
}

#Preview("活动通知", as: .content, using: GoldTimeActivityAttributes.preview) {
   WidgetLiveActivity()
} contentStates: {
    GoldTimeActivityAttributes.ContentState.working
    GoldTimeActivityAttributes.ContentState.paused
}
