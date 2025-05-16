//
//  LiveActivityManager.swift (Adjusted for Minimal Live Activity & TimelineView)
//  GoldTime
//
//  Created on 03/05/2025.
//

import Foundation
import ActivityKit
import SwiftUI // 仍然需要，因为 UserSettings 可能来自 SwiftUI 环境
import WidgetKit


// LiveActivity管理器，负责创建、更新和结束LiveActivity
class LiveActivityManager {
    // 更简洁的单例模式
    static let shared = LiveActivityManager()
    
    private var activity: Activity<GoldTimeActivityAttributes>?
    // 移除了 updateTimer，因为更新由 TimelineView 在 Widget 内部处理
    
    private init() {} // 保持私有构造函数
    
    // 检查是否支持LiveActivity
    var isSupported: Bool {
        // 可以在这里添加更详细的 iOS 版本检查，如果需要的话
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
    
    // 检查是否已有活动的LiveActivity
    var hasActiveActivity: Bool {
        guard let currentActivity = activity else { return false }
        return currentActivity.activityState == .active || currentActivity.activityState == .stale
    }
    
    // 开始一个新的LiveActivity
    func startActivity(with settings: UserSettings, forceStart: Bool = false) {
        guard isSupported else {
            print("Live Activities not supported or not enabled.")
            return
        }
        
        // 如果已经有一个活动的LiveActivity
        if let currentActivity = activity, currentActivity.activityState == .active || currentActivity.activityState == .stale {
            if forceStart {
                print("Forcing start: Ending existing activity first.")
                // 如果强制启动，先结束现有的活动
                Task { // 将结束操作放入 Task 中
                    await endActivityInternal(activityToEnd: currentActivity, andClearShared: true)
                    // 等待一小段时间确保LiveActivity被完全清除 (这个延迟可能需要也可能不需要，取决于系统行为)
                    // 通常情况下，直接创建新的应该没问题，因为 Activity.request 是异步的。
                    // 但为了安全，保留一个非常短的延迟。
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.createNewActivity(with: settings)
                    }
                }
                return
            } else {
                // 否则只更新现有活动的状态
                print("Updating existing activity.")
                updateActivityContent(with: settings) // 确保这个方法只更新必要的状态
                return
            }
        }
        
        // 没有活动的LiveActivity，或者之前的已结束，直接创建新的
        print("Creating new activity.")
        createNewActivity(with: settings)
    }
    
    // 创建新的LiveActivity
    private func createNewActivity(with settings: UserSettings) {
        // 如果没有在工作状态，则不启动LiveActivity (或者根据你的逻辑，可能启动一个“已暂停”状态的)
        // 对于最小化测试，我们假设只有 isWorking 为 true 时才启动计时器
        guard settings.isWorking else {
            print("Not creating activity: settings.isWorking is false.")
            // 如果需要，可以在这里结束任何可能残留的活动
            endAllActivities() // 确保之前的都清除了
            return
        }
        
        // 使用最小化 Attributes 的 activityName
        let attributes = GoldTimeActivityAttributes(activityName: "GoldTime Timer")
        
        // 使用最小化 ContentState
        // startTime 必须在 isWorking 为 true 时有意义
        let effectiveStartTime = settings.startTime ?? Date() // 如果 settings.startTime 为 nil，则从现在开始

        let state = GoldTimeActivityAttributes.ContentState(
            lastUpdateTime: Date(), // 记录本次状态生成时间
            isWorking: settings.isWorking,
            startTime: effectiveStartTime,
            pausedTotalTime: settings.pausedTotalTime
        )
        
        // 创建LiveActivity
        do {
            let newActivity: Activity<GoldTimeActivityAttributes>
            if #available(iOS 16.2, *) {
                newActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil), // staleDate: nil 或 .distantFuture
                    pushType: nil
                )
            } else {
                // iOS 16.1
                newActivity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
            self.activity = newActivity // 存储新创建的 activity
            print("LiveActivity created successfully: \(newActivity.id)")
            
        } catch {
            print("Error creating LiveActivity: \(error.localizedDescription)")
            self.activity = nil // 创建失败则清空
        }
    }
    
    // 内部使用的结束单个 Activity 的方法
    private func endActivityInternal(activityToEnd: Activity<GoldTimeActivityAttributes>, andClearShared: Bool) async {
        guard activityToEnd.activityState == .active || activityToEnd.activityState == .stale else { return }
        
        await activityToEnd.end(nil, dismissalPolicy: .immediate)
        print("Ended activity: \(activityToEnd.id)")
        if andClearShared && self.activity?.id == activityToEnd.id {
            self.activity = nil
        }
    }

    // 结束当前管理的LiveActivity
    func endActivity() {
        guard let currentActivity = self.activity else {
            // 如果 self.activity 为空，也尝试清理一下所有活动的
            endAllActivities()
            return
        }
        
        Task {
            await endActivityInternal(activityToEnd: currentActivity, andClearShared: true)
        }
    }
    
    // 结束所有此 App 的 LiveActivity
    func endAllActivities() {
        Task {
            // 首先尝试结束当前跟踪的 activity
            if let currentActivity = self.activity {
                await endActivityInternal(activityToEnd: currentActivity, andClearShared: true)
            }
            
            // 然后遍历并结束所有该类型的活动
            // (确保 GoldTimeActivityAttributes 定义在 Widget Target 和 App Target 都能访问到)
            for activityInstance in Activity<GoldTimeActivityAttributes>.activities {
                await endActivityInternal(activityToEnd: activityInstance, andClearShared: false) // 不在这里清除 self.activity，因为可能不是当前跟踪的
            }
            print("Ended all activities of type GoldTimeActivityAttributes.")
        }
    }
    
    // 更新LiveActivity (当核心状态改变时，如暂停/继续，时薪改变等)
    func updateActivity(with settings: UserSettings) {
        guard isSupported else { return }
        
        // 如果 activity 为 nil 或已结束，但 settings.isWorking 为 true，则尝试重新启动
        if (activity == nil || (activity?.activityState != .active && activity?.activityState != .stale)) {
            if settings.isWorking {
                print("No active activity, and settings indicate working. Starting new one.")
                startActivity(with: settings, forceStart: true) // 可能需要强制启动以覆盖旧状态
            } else {
                print("No active activity, and settings indicate not working. Doing nothing.")
                // 如果不是工作状态，且没有活动，通常不需要做什么，除非你想显示一个“已结束”的Live Activity
            }
            return
        }
        
        print("Updating activity content.")
        updateActivityContent(with: settings)
    }
    
    // 从后台更新LiveActivity (这个方法名可能有点误导，它实际只是更新状态)
    // 确保你的 UserSettings 能正确反映后台可能发生的变化
    func updateActivityFromBackground(with settings: UserSettings) {
        // 确保我们在主队列上与 ActivityKit 交互 (通常是安全的，但最好明确)
        // ActivityKit 的 API 通常是主线程安全的
        DispatchQueue.main.async {
            self.updateActivityContent(with: settings)
            
            // 通常不需要手动 reloadAllTimelines() 来更新 Live Activity，
            // 因为 Activity.update() 会自动触发 Widget 的刷新。
            // WidgetCenter.shared.reloadAllTimelines() // 除非你有独立的 Widget 也需要同步
        }
    }
    
    // 更新LiveActivity内容 (仅当状态真正改变时调用)
    private func updateActivityContent(with settings: UserSettings) {
        guard let currentActivity = activity, (currentActivity.activityState == .active || currentActivity.activityState == .stale) else {
            print("Cannot update: No active or stale activity.")
            return
        }
        
        // startTime 对于正在运行的计时器，不应该轻易改变，除非是“继续”操作
        // 如果是暂停->继续，startTime 应该更新为继续的时间点，pausedTotalTime 也应包含之前的累计工作时长
        let effectiveStartTime: Date
        if settings.isWorking {
            // 如果是从暂停变为工作，startTime 应该是当前时间，pausedTotalTime 保持不变
            // 如果本来就在工作，startTime 应该保持原始的开始时间
            if currentActivity.content.state.isWorking { // 正在工作，保持原来的startTime
                effectiveStartTime = currentActivity.content.state.startTime
            } else { // 从暂停到工作，startTime是现在
                effectiveStartTime = Date()
            }
        } else { // 如果是暂停，startTime 也是当前时间，pausedTotalTime 会包含到此刻的工作时长
            effectiveStartTime = Date() // 或者保持 settings.startTime (如果它代表了暂停的时刻)
        }


        // 更新LiveActivity状态
        let updatedState = GoldTimeActivityAttributes.ContentState(
            lastUpdateTime: Date(),
            isWorking: settings.isWorking,
            startTime: effectiveStartTime, // 使用计算出的 effectiveStartTime
            pausedTotalTime: settings.pausedTotalTime // UserSettings 应该正确管理这个值
        )
        
        Task {
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await currentActivity.update(content)
            print("Activity updated with new state. isWorking: \(updatedState.isWorking)")
        }
    }
    
    // 移除了 startUpdateTimer, stopUpdateTimer, updateCurrentActivity 方法
}
