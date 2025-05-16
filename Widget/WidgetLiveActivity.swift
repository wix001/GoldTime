//
//  WidgetLiveActivity.swift (Minimal Version)
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
            // 锁屏界面 UI (最小化)
            MinimalLockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(UIColor.systemGray6)) // 可以保留背景色
                .activitySystemActionForegroundColor(Color.black) // 可以保留前景操作色

        } dynamicIsland: { context in
            // Dynamic Island 也可以简化或暂时移除以专注于锁屏
            DynamicIsland {
                // 展开状态
                DynamicIslandExpandedRegion(.center) {
                    TimelineView(.periodic(from: .now, by: 1.0)) { timelineContext in
                        // 或者使用 context.state.formattedElapsedTime(currentTime: timelineContext.date)
                        Text(timelineContext.date, style: .timer)
                            .font(.title)
                            .monospacedDigit() // 使数字等宽，防止跳动
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                TimelineView(.periodic(from: .now, by: 1.0)) { timelineContext in
                     // 显示秒数，方便观察更新
                    Text("\(Calendar.current.component(.second, from: timelineContext.date))s")
                        .font(.caption)
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: "timer")
            }
            .keylineTint(.cyan) // 简单颜色
        }
        .contentMarginsDisabled() // 如果你的视图很简单，可能不需要禁用边距
    }
}

// 最小化锁屏界面视图
struct MinimalLockScreenLiveActivityView: View {
    let context: ActivityViewContext<GoldTimeActivityAttributes>
    
    var body: some View {
        VStack {
            Text("Live Timer Test")
                .font(.headline)
                .padding(.bottom, 5)

            TimelineView(.periodic(from: .now, by: 1.0)) { timelineContext in
                VStack {
                    // 方式一：使用 SwiftUI 内置的 .timer 样式 (推荐用于纯时间显示)
                    // 这个样式本身就会自动处理秒级更新
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit() // 使数字等宽，看起来更稳定
                        .foregroundColor(.blue)
                    
                    // 方式二：手动格式化 (如果需要更复杂的基于时间的计算，但这里我们用它显示秒数来观察)
                    // Text("Elapsed: \(context.state.formattedElapsedTime(currentTime: timelineContext.date))")
                    //    .font(.title2)
                    
                    // 显示当前秒数，用于精确观察更新频率
                    Text("Current Second: \(Calendar.current.component(.second, from: timelineContext.date))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}


// 预览组 (也需要更新以匹配最小化的 Attributes 和 ContentState)
extension GoldTimeActivityAttributes {
    fileprivate static var preview: GoldTimeActivityAttributes {
        GoldTimeActivityAttributes(activityName: "Preview Timer")
    }
}

extension GoldTimeActivityAttributes.ContentState {
    fileprivate static var running: GoldTimeActivityAttributes.ContentState {
        GoldTimeActivityAttributes.ContentState(
            lastUpdateTime: Date(),
            isWorking: true,
            startTime: Date().addingTimeInterval(-60), // 1分钟前开始
            pausedTotalTime: 0
        )
     }
     
    fileprivate static var paused_minimal: GoldTimeActivityAttributes.ContentState { // 重命名以避免与之前的冲突
        GoldTimeActivityAttributes.ContentState(
            lastUpdateTime: Date(),
            isWorking: false,
            startTime: Date().addingTimeInterval(-120), // 2分钟前开始
            pausedTotalTime: 30 // 暂停了30秒
        )
     }
}

// 确保你的主App也使用这个最小化的 Attributes 和 ContentState 来启动 Activity
// #Preview 注释掉，因为在Widget Target中直接使用可能不方便，或者确保它使用新的ContentState
/*
#Preview("活动通知", as: .content, using: GoldTimeActivityAttributes.preview) {
   WidgetLiveActivity()
} contentStates: {
    GoldTimeActivityAttributes.ContentState.running
    GoldTimeActivityAttributes.ContentState.paused_minimal
}
*/
