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
                    
                    // 收入金额（金色金属风格）
                    GoldMetalText(text: context.state.formattedEarnings(), fontSize: 24)
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
                GoldMetalText(text: context.state.formattedEarnings(), fontSize: 12)
            } minimal: {
                // 动态岛最小化视图
                Image(systemName: context.state.isWorking ? "dollarsign.circle.fill" : "dollarsign.circle")
                    .foregroundColor(context.state.isWorking ? .green : Color(hex: 0xFFD700)) // 使用金色
            }
            .widgetURL(URL(string: "goldtime://open"))
            .keylineTint(context.state.isWorking ? .green : Color(hex: 0xFFD700))
        }
    }
}

// 锁屏界面视图
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    
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
                    
                    // 收入金额 - 金色金属风格，左对齐，无背景
                    GoldMetalText(text: context.state.formattedEarnings(), fontSize: 28)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // 右侧信息
                VStack(alignment: .trailing) {
                    Text("工作时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(context.state.formattedWorkTime())
                        .font(.callout)
                        .bold()
                }
            }
            
            // 进度条 - 改为绿色
            ZStack(alignment: .leading) {
                // 背景条
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                // 进度指示 - 使用绿色
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: min(CGFloat(context.state.calculateWorkedTime() / 3600) * 100, UIScreen.main.bounds.width - 32), height: 8)
                    .cornerRadius(4)
                    .animation(.linear, value: context.state.calculateWorkedTime())
            }
            
            // 底部信息
            HStack {
                Circle()
                    .fill(context.state.isWorking ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                // 状态文本
                Text(context.state.isWorking ? "正在赚钱💰" : "休息一下😴")
                    .font(.caption)
                    .foregroundColor(context.state.isWorking ? .green : .orange)
                
                Spacer()
                
                // 时薪信息
                Text("时薪: \(context.state.currency)\(String(format: "%.2f", context.state.hourlyRate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

// 金色金属文字组件 - 增强版
struct GoldMetalText: View {
    let text: String
    let fontSize: CGFloat
    @State private var phase: CGFloat = 0
    @State private var glintPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 主要金色文字层
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                          Color(hex: 0xFFE1A3), // 暖金色过渡
                          Color(hex: 0xFFD700), // 亮金色（标准金）
                          Color(hex: 0xFFE1A3), // 回到暖金色
                        ]),
                        startPoint: UnitPoint(x: phase, y: 0),
                        endPoint: UnitPoint(x: phase + 0.8, y: 1)
                    )
                )
                .shadow(color: .yellow.opacity(0.4), radius: 1, x: 0, y: 0)
                
            // 镜面金属效果 - 更宽的闪光
            Text(text)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0),
                            .white.opacity(0.95),
                            .white.opacity(0)
                        ]),
                        startPoint: UnitPoint(x: phase, y: 0),
                        endPoint: UnitPoint(x: phase + 0.2, y: 1)
                    )
                )
        }
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
            decimalPlaces: 4
        )
     }
     
    fileprivate static var paused: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            hourlyRate: 100.0,
            startTime: Date(),
            pausedTotalTime: 1800, // 半小时的暂停时间
            isWorking: false,
            currency: "¥",
            decimalPlaces: 4
        )
     }
}

#Preview("活动通知", as: .content, using: GoldTimeActivityAttributes.preview) {
   WidgetLiveActivity()
} contentStates: {
    GoldTimeActivityAttributes.ContentState.working
    GoldTimeActivityAttributes.ContentState.paused
}
