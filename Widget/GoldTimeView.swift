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
    @State private var phase: CGFloat = 0
    
    // 创建一个计时器来更新视图
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        // 根据不同的小组件尺寸显示不同的视图
        Group {
            switch widgetFamily {
            case .systemSmall:
                smallWidgetContent
                    .containerBackground(.fill.tertiary, for: .widget)
            case .accessoryRectangular:
                lockScreenWidgetContent
                    .containerBackground(.clear, for: .widget) // 锁屏小组件通常使用透明背景
            default:
                smallWidgetContent
                    .containerBackground(.fill.tertiary, for: .widget)
            }
        }
        .onReceive(timer) { _ in
            // 每秒更新当前时间，触发视图刷新
            withAnimation(.linear) {
                phase += 0.02
                if phase > 1.0 {
                    phase = 0.0
                }
            }
        }
    }
    
    // 主屏幕上的小组件内容 - 优化布局版本
    var smallWidgetContent: some View {
        VStack(spacing: 4) {
            // 标题和状态在同一行，节省空间
            HStack {
                Circle()
                    .fill(entry.isWorking ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(entry.isWorking ? "正在赚钱💰" : "休息一下😴")
                    .font(.caption2)
                    .foregroundColor(entry.isWorking ? .green : .orange)
            }
            
            // 给工资显示分配更多空间
            Spacer()
            
            // 已赚取的金额 - 增加自适应机制
            WidgetGoldText(text: entry.formattedEarnings(), fontSize: 28, phase: phase)
                .frame(maxWidth: .infinity)
                .frame(height: 40) // 固定高度确保有足够空间
                .padding(.vertical, 4) // 增加一点垂直间距
            
            Spacer()
            
            // 添加目标进度条
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
                    .frame(width: max(min(CGFloat(entry.calculateGoalProgress()) * 130, 130), 6), height: 6)
                    .cornerRadius(3)
            }
            .padding(.horizontal, 5)
            
            // 工作时间显示在底部
            HStack {
                Text(entry.workedTime)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1) // 确保单行显示
                
                Spacer()
                
                // 显示目标类型小图标
                Image(systemName: entry.activeGoalType == .time ? "clock" : "dollarsign.circle")
                    .font(.caption2)
                    .foregroundColor(entry.activeGoalType == .time ? .green : Color(hex: 0xFFD700))
            }
        }
        .padding(10) // 减小边距以获得更多内部空间
    }

    // 修改锁屏小组件内容，添加目标进度显示
    var lockScreenWidgetContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 工作状态
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.isWorking ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(entry.isWorking ? "工作中" : "已暂停")
                        .font(.system(size: 10)) // 更小的字体
                        .fontWeight(.medium)
                }
                
                // 已赚取的金额 - 金色效果（增强自适应性）
                Text(entry.formattedEarnings())
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)  // 允许文本在必要时缩小到50%
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: 0xFFD700).opacity(0.7), radius: 1, x: 0, y: 0)
                
                // 添加小型进度条
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    // 进度
                    Rectangle()
                        .fill(entry.activeGoalType == .time ? Color.green : Color(hex: 0xFFD700))
                        .frame(width: max(min(CGFloat(entry.calculateGoalProgress()) * 60, 60), 3), height: 3)
                        .cornerRadius(1.5)
                }
            }
            
            Spacer()
            
            // 工作时间
            Text(entry.workedTime)
                .font(.caption2) // 减小字体
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
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
                .minimumScaleFactor(0.6) // 允许文本缩小到原始大小的60%
                .lineLimit(1) // 确保只有一行
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
                .minimumScaleFactor(0.6) // 这里也要添加相同的缩放因子
                .lineLimit(1) // 这里也确保单行
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

