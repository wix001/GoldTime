//
//  WidgetView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import SwiftUI
import WidgetKit

struct HourlyWageWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        // 根据不同的小组件尺寸显示不同的视图
        Group {
            switch widgetFamily {
            case .systemSmall:
                // 使用TimelineView包装小组件内容，实现实时更新
                TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                    smallWidgetContent(currentTime: timeline.date)
                        .containerBackground(.fill.tertiary, for: .widget)
                }
            case .accessoryRectangular:
                // 对于锁屏小组件也使用TimelineView
                TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                    lockScreenWidgetContent(currentTime: timeline.date)
                        .containerBackground(.clear, for: .widget)
                }
            default:
                // 使用TimelineView包装小组件内容，实现实时更新
                TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                    smallWidgetContent(currentTime: timeline.date)
                        .containerBackground(.fill.tertiary, for: .widget)
                }
            }
        }
    }
    
    // 主屏幕上的小组件内容 - 优化布局版本 - 支持实时计算
    func smallWidgetContent(currentTime: Date) -> some View {
        VStack(spacing: 4) {
            // 标题和状态在同一行，节省空间
            HStack {
                Circle()
                    .fill(entry.isWorking ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(entry.isWorking ? "正在赚钱💰" : "休息一下😴")
                    .font(.caption2)
                    .foregroundColor(entry.isWorking ? .green : .orange)
                
                Spacer()
                
                // 添加最后更新时间指示
                if entry.isWorking {
                    Text("更新: \(entry.formattedUpdateTime())")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            
            // 给工资显示分配更多空间
            Spacer()
            
            // 已赚取的金额 - 实时计算
            if entry.isWorking {
                            WidgetGoldText(
                                text: entry.formattedRealTimeEarnings(currentTime: currentTime),
                                fontSize: 28,
                                phase: calculatePhase(currentTime: currentTime)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .padding(.vertical, 4)
                        } else {
                            WidgetGoldText(
                                text: entry.formattedEarnings(),
                                fontSize: 28,
                                phase: 0
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .padding(.vertical, 4)
                        }
                        
                        Spacer()
                        
                        // 添加目标进度条 - 实时计算进度
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
                                            entry.activeGoalType == .time ? Color.green.opacity(0.7) : Color(hex: 0xFFD700).opacity(0.7),
                                            entry.activeGoalType == .time ? Color.green : Color(hex: 0xFFD700)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(min(CGFloat(entry.calculateGoalProgress(currentTime: currentTime)) * 130, 130), 6), height: 6)
                                .cornerRadius(3)
                        }
                        .padding(.horizontal, 5)
                        
                        // 工作时间显示在底部 - 实时计算时间
                        HStack {
                            if entry.isWorking {
                                Text(entry.calculateWorkTime(currentTime: currentTime))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            } else {
                                Text(entry.workedTime)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // 显示目标类型小图标
                            Image(systemName: entry.activeGoalType == .time ? "clock" : "dollarsign.circle")
                                .font(.caption2)
                                .foregroundColor(entry.activeGoalType == .time ? .green : Color(hex: 0xFFD700))
                        }
                    }
                    .padding(10)
                }

                // 修改锁屏小组件内容，添加目标进度显示 - 支持实时计算
                func lockScreenWidgetContent(currentTime: Date) -> some View {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            // 工作状态
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(entry.isWorking ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                                
                                Text(entry.isWorking ? "工作中" : "已暂停")
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                            }
                            
                            // 已赚取的金额 - 实时计算
                            if entry.isWorking {
                                Text(entry.formattedRealTimeEarnings(currentTime: currentTime))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(.white)
                                    .shadow(color: Color(hex: 0xFFD700).opacity(0.7), radius: 1, x: 0, y: 0)
                            } else {
                                Text(entry.formattedEarnings())
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(.white)
                                    .shadow(color: Color(hex: 0xFFD700).opacity(0.7), radius: 1, x: 0, y: 0)
                            }
                            
                            // 添加小型进度条 - 实时计算进度
                            ZStack(alignment: .leading) {
                                // 背景
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 3)
                                    .cornerRadius(1.5)
                                
                                // 进度
                                Rectangle()
                                    .fill(entry.activeGoalType == .time ? Color.green : Color(hex: 0xFFD700))
                                    .frame(width: max(min(CGFloat(entry.calculateGoalProgress(currentTime: currentTime)) * 60, 60), 3), height: 3)
                                    .cornerRadius(1.5)
                            }
                        }
                        
                        Spacer()
                        
                        // 工作时间 - 实时计算
                        if entry.isWorking {
                            Text(entry.calculateWorkTime(currentTime: currentTime))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        } else {
                            Text(entry.workedTime)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                
                // 计算闪光效果的相位
                private func calculatePhase(currentTime: Date) -> CGFloat {
                    // 基于当前时间的秒数创建波动效果
                    let seconds = Calendar.current.component(.second, from: currentTime)
                    let milliseconds = Calendar.current.component(.nanosecond, from: currentTime) / 1_000_000
                    
                    let totalMilliseconds = Double(seconds * 1000 + milliseconds)
                    let cycleTime = 3000.0 // 3秒完成一个循环
                    
                    let normalizedPhase = (totalMilliseconds.truncatingRemainder(dividingBy: cycleTime)) / cycleTime
                    return CGFloat(normalizedPhase)
                }
            }

            // 小组件专用的金色文字（增强版，自动调整大小以显示完整内容）
            struct WidgetGoldText: View {
                let text: String
                let fontSize: CGFloat
                let phase: CGFloat
                
                var body: some View {
                    ZStack {
                        // 主要金色文字层
                        Text(text)
                            .font(.system(size: fontSize, weight: .heavy))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                      Color(hex: 0xFFE1A3),
                                      Color(hex: 0xFFD700),
                                      Color(hex: 0xFFE1A3),
                                    ]),
                                    startPoint: UnitPoint(x: phase, y: 0),
                                    endPoint: UnitPoint(x: phase + 0.8, y: 1)
                                )
                            )
                            .shadow(color: .yellow.opacity(0.4), radius: 1, x: 0, y: 0)
                            
                        // 镜面金属效果 - 更宽的闪光
                        Text(text)
                            .font(.system(size: fontSize, weight: .heavy))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
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
