//
//  LiveActivityManager.swift
//  GoldTime
//
//  Created on 03/05/2025.
//

import Foundation
import ActivityKit
import SwiftUI
import WidgetKit

// LiveActivity管理器，负责创建、更新和结束LiveActivity
class LiveActivityManager {
    // 使用静态属性而不是shared单例模式
    private static var _shared: LiveActivityManager?
    static var shared: LiveActivityManager {
        if _shared == nil {
            _shared = LiveActivityManager()
        }
        return _shared!
    }
    
    private var activity: Activity<GoldTimeActivityAttributes>?
    private var updateTimer: Timer?
    
    private init() {}
    
    // 检查是否支持LiveActivity
    var isSupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // 检查是否已有活动的LiveActivity
    var hasActiveActivity: Bool {
        return activity != nil && activity?.activityState != .ended
    }
    
    // 开始一个新的LiveActivity
    func startActivity(with settings: UserSettings, forceStart: Bool = false) {
        // 确保系统支持LiveActivity
        guard isSupported else { return }
        
        // 如果已经有一个活动的LiveActivity，则根据forceStart决定是否更新或重新创建
        if hasActiveActivity {
            if forceStart {
                // 如果强制启动，先结束现有的活动
                endAllActivities()
                // 等待一小段时间确保LiveActivity被完全清除
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.createNewActivity(with: settings)
                }
                return
            } else {
                // 否则只更新现有活动
                updateActivity(with: settings)
                return
            }
        }
        
        // 没有活动的LiveActivity，直接创建
        createNewActivity(with: settings)
    }
    
    // 创建新的LiveActivity
    private func createNewActivity(with settings: UserSettings) {
        // 获取起始时间，如果没有则使用当前时间
        let startTime = settings.startTime ?? Date()
        
        // 如果没有在工作状态，则不启动LiveActivity
        if !settings.isWorking {
            return
        }
        
        let attributes = GoldTimeActivityAttributes(name: "工资计算器")
        let state = GoldTimeActivityAttributes.ContentState(
            hourlyRate: settings.hourlyRate,
            startTime: startTime,
            pausedTotalTime: settings.pausedTotalTime,
            isWorking: settings.isWorking,  // 使用settings中的工作状态
            currency: settings.currency,
            decimalPlaces: 4  // 使用4位小数
        )
        
        // 创建LiveActivity
        do {
            // 兼容不同iOS版本的Activity请求
            if #available(iOS 16.2, *) {
                // iOS 16.2及更高版本
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: .distantFuture),
                    pushType: nil
                )
            } else {
                // iOS 16.1
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
            
            print("LiveActivity创建成功: \(self.activity?.id ?? "未知")")
            
            // 如果当前是工作状态，启动定时器
            if settings.isWorking {
                startUpdateTimer()
            }
        } catch {
            print("创建LiveActivity出错: \(error.localizedDescription)")
        }
    }
    
    // 结束所有活动的LiveActivity
    func endAllActivities() {
        // 首先结束当前跟踪的活动
        if let activity = activity, activity.activityState != .ended {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
                self.activity = nil
            }
        }
        
        // 然后检查并结束所有其他可能存在的活动
        Task {
            for activity in Activity<GoldTimeActivityAttributes>.activities {
                if activity.activityState != .ended {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        
        // 停止更新定时器
        stopUpdateTimer()
    }
    
    // 更新LiveActivity
    func updateActivity(with settings: UserSettings) {
        guard isSupported else { return }
        
        if activity == nil || activity?.activityState == .ended {
            // 如果没有活动的LiveActivity且正在工作，创建新的
            if settings.isWorking {
                startActivity(with: settings)
            }
            return
        }
        
        updateActivityContent(with: settings)
    }
    
    // 从后台更新LiveActivity
    func updateActivityFromBackground(with settings: UserSettings) {
        // 确保我们在后台线程上
        DispatchQueue.global(qos: .background).async {
            // 更新Activity内容
            self.updateActivityContent(with: settings)
            
            // 强制更新小组件
            DispatchQueue.main.async {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    // 更新LiveActivity内容
    private func updateActivityContent(with settings: UserSettings) {
        guard let activity = activity, activity.activityState != .ended else { return }
        
        // 获取合适的起始时间
        let startTime = settings.startTime ?? Date()
        
        // 更新LiveActivity状态 - 无论是工作中还是已暂停
        let updatedState = GoldTimeActivityAttributes.ContentState(
            hourlyRate: settings.hourlyRate,
            startTime: startTime,
            pausedTotalTime: settings.pausedTotalTime,
            isWorking: settings.isWorking,
            currency: settings.currency,
            decimalPlaces: 4
        )
        
        // 兼容不同iOS版本的更新方式
        Task {
            if #available(iOS 16.2, *) {
                // iOS 16.2及更高版本
                await activity.update(.init(state: updatedState, staleDate: .distantFuture))
            } else {
                // iOS 16.1
                await activity.update(using: updatedState)
            }
        }
        
        // 根据工作状态管理定时器
        if settings.isWorking && updateTimer == nil {
            // 如果正在工作且定时器未启动，启动定时器
            startUpdateTimer()
        } else if !settings.isWorking {
            // 如果暂停工作，停止更新定时器，但保持LiveActivity存在
            stopUpdateTimer()
        }
    }
    
    // 结束LiveActivity
    func endActivity() {
        endAllActivities()
    }
    
    // 启动更新定时器
    private func startUpdateTimer() {
        // 停止当前的定时器（如果有）
        stopUpdateTimer()
        
        // 创建新的每秒更新定时器，确保在主线程中
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateCurrentActivity()
            }
            
            // 确保定时器在后台也能运行
            RunLoop.current.add(self.updateTimer!, forMode: .common)
        }
    }
    
    // 停止更新定时器
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // 更新当前活动的LiveActivity（不改变基本参数，仅触发UI刷新）
    private func updateCurrentActivity() {
        guard let activity = activity, activity.activityState != .ended else { return }
        
        // 获取当前状态
        let currentState = activity.content.state
        
        // 创建一个新的状态对象，内容与当前状态相同
        // 这将触发UI更新，显示最新的计算结果
        let updatedState = GoldTimeActivityAttributes.ContentState(
            hourlyRate: currentState.hourlyRate,
            startTime: currentState.startTime,
            pausedTotalTime: currentState.pausedTotalTime,
            isWorking: currentState.isWorking,
            currency: currentState.currency,
            decimalPlaces: currentState.decimalPlaces
        )
        
        // 兼容不同iOS版本的更新方式
        Task {
            if #available(iOS 16.2, *) {
                // iOS 16.2及更高版本
                await activity.update(.init(state: updatedState, staleDate: .distantFuture))
            } else {
                // iOS 16.1
                await activity.update(using: updatedState)
            }
        }
    }
}
