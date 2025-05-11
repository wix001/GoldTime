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
    private var lastUpdateTime: Date = Date()
    
    // 更新间隔时间（秒）
    private let normalUpdateInterval: TimeInterval = 3.0 // 普通更新间隔为3秒秒
    private let lowPowerUpdateInterval: TimeInterval = 30.0 // 低电量模式下更新间隔为30秒
    private let forceUpdateInterval: TimeInterval = 60.0 // 强制更新间隔为1分钟
    
    private init() {
        // 监听电池状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        // 启用电池监控
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    // 检查是否支持LiveActivity
    var isSupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // 检查是否已有活动的LiveActivity
    var hasActiveActivity: Bool {
        return activity != nil && activity?.activityState != .ended
    }
    
    // 电池状态变化处理
    @objc private func batteryStateDidChange(_ notification: Notification) {
        adjustUpdateInterval()
    }
    
    // 根据电池状态调整更新间隔
    private func adjustUpdateInterval() {
        guard hasActiveActivity else { return }
        
        stopUpdateTimer()
        startUpdateTimer()
    }
    
    // 获取当前应该使用的更新间隔
    private func getCurrentUpdateInterval() -> TimeInterval {
        if UIDevice.current.batteryState == .unplugged && UIDevice.current.batteryLevel < 0.2 {
            // 电池低于20%使用较长的更新间隔
            return lowPowerUpdateInterval
        } else {
            return normalUpdateInterval
        }
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
//        if !settings.isWorking {
//            return
//        }
        
        let attributes = GoldTimeActivityAttributes(name: "工资计算器")
        
        // 预先计算当前的收入和进度值
        let currentEarnings = settings.calculateEarnedMoney()
        let currentProgress = settings.calculateGoalProgress()
        
        let state = GoldTimeActivityAttributes.ContentState(
            hourlyRate: settings.hourlyRate,
            startTime: startTime,
            pausedTotalTime: settings.pausedTotalTime,
            calculatedEarnings: currentEarnings,
            calculatedProgress: currentProgress,
            isWorking: settings.isWorking,
            currency: settings.currency,
            decimalPlaces: 4,
            lastUpdateTime: Date(),
            timeGoal: settings.timeGoal,
            incomeGoal: settings.incomeGoal,
            activeGoalType: settings.activeGoalType
        )
        
        // 创建LiveActivity
        do {
            // 设置8小时的staleDate
            let staleDate = Calendar.current.date(
                byAdding: .hour,
                value: 8,
                to: Date()
            ) ?? Date().addingTimeInterval(8 * 3600)
            
            // 兼容不同iOS版本的Activity请求
            if #available(iOS 16.2, *) {
                // iOS 16.2及更高版本 - 使用staleDate和relevanceScore
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(
                        state: state,
                        staleDate: staleDate,
                        relevanceScore: 1 // 设置较高的优先级
                    ),
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
            
            // 保存最后更新时间
            lastUpdateTime = Date()
            
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
        
        // 预先计算当前的收入和进度值
        let currentEarnings = settings.calculateEarnedMoney()
        let currentProgress = settings.calculateGoalProgress()
        
        // 更新LiveActivity状态 - 无论是工作中还是已暂停
        let updatedState = GoldTimeActivityAttributes.ContentState(
            hourlyRate: settings.hourlyRate,
            startTime: startTime,
            pausedTotalTime: settings.pausedTotalTime,
            calculatedEarnings: currentEarnings,
            calculatedProgress: currentProgress,
            isWorking: settings.isWorking,
            currency: settings.currency,
            decimalPlaces: 4,
            lastUpdateTime: Date(),
            timeGoal: settings.timeGoal,
            incomeGoal: settings.incomeGoal,
            activeGoalType: settings.activeGoalType
        )
        
        // 兼容不同iOS版本的更新方式
        Task {
            if #available(iOS 16.2, *) {
                // iOS 16.2及更高版本 - 更新时也设置staleDate
                let staleDate = Calendar.current.date(
                    byAdding: .hour,
                    value: 8,
                    to: Date()
                ) ?? Date().addingTimeInterval(8 * 3600)
                
                await activity.update(.init(
                    state: updatedState,
                    staleDate: staleDate,
                    relevanceScore: 1 // 保持较高的优先级
                ))
            } else {
                // iOS 16.1
                await activity.update(using: updatedState)
            }
            
            // 更新最后更新时间
            self.lastUpdateTime = Date()
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
    
    // 启动更新定时器 - 使用根据电量状态自适应的间隔
    private func startUpdateTimer() {
        // 停止当前的定时器（如果有）
        stopUpdateTimer()
        
        // 获取当前应该使用的更新间隔
        let interval = getCurrentUpdateInterval()
        
        // 创建新的定时器，间隔时间根据电池状态动态调整
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.checkAndUpdateActivity()
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
    
    // 检查是否需要更新，并执行更新
        private func checkAndUpdateActivity() {
            // 检查距离上次更新是否超过强制更新间隔
            let timeIntervalSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
            
            // 如果超过强制更新间隔或需要周期性更新，则执行更新
            if timeIntervalSinceLastUpdate >= forceUpdateInterval {
                forceActivityUpdate()
            } else {
                // 执行常规更新
                updateCurrentActivity()
            }
        }
        
        // 强制更新活动 - 当检测到长时间未更新
        private func forceActivityUpdate() {
            print("执行强制更新，距离上次更新: \(Date().timeIntervalSince(lastUpdateTime)) 秒")
            
            // 从UserDefaults获取最新设置
            let settings = UserDefaultsManager.shared.loadUserSettings()
            
            // 更新活动内容
            updateActivityContent(with: settings)
            
            // 如果活动即将过期（超过5小时），考虑重建活动
            if let activity = activity {
                let activityAge = Date().timeIntervalSince(lastUpdateTime)
                if activityAge > 5 * 3600 { //5小时
                    // 结束当前活动并创建新的
                    Task {
                        await activity.end(nil, dismissalPolicy: .immediate)
                        self.activity = nil
                        
                        // 如果还在工作，创建新的活动
                        if settings.isWorking {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.createNewActivity(with: settings)
                            }
                        }
                    }
                }
            }
        }
        
        // 更新当前活动（定时器触发）
        private func updateCurrentActivity() {
            guard let activity = activity, activity.activityState != .ended else { return }
            
            // 获取当前用户设置
            let settings = UserDefaultsManager.shared.loadUserSettings()
            
            // 只有在工作状态下才进行更新
            if settings.isWorking {
                // 预先计算当前的收入和进度值
                let currentEarnings = settings.calculateEarnedMoney()
                let currentProgress = settings.calculateGoalProgress()
                
                // 创建更新状态
                let updatedState = GoldTimeActivityAttributes.ContentState(
                    hourlyRate: settings.hourlyRate,
                    startTime: settings.startTime ?? Date(),
                    pausedTotalTime: settings.pausedTotalTime,
                    calculatedEarnings: currentEarnings,
                    calculatedProgress: currentProgress,
                    isWorking: settings.isWorking,
                    currency: settings.currency,
                    decimalPlaces: 4,
                    lastUpdateTime: Date(),
                    timeGoal: settings.timeGoal,
                    incomeGoal: settings.incomeGoal,
                    activeGoalType: settings.activeGoalType
                )
                
                // 执行更新
                Task {
                    if #available(iOS 16.2, *) {
                        // 计算新的staleDate - 8小时有效期
                        let staleDate = Calendar.current.date(
                            byAdding: .hour,
                            value: 8,
                            to: Date()
                        ) ?? Date().addingTimeInterval(8 * 3600)
                        
                        await activity.update(.init(
                            state: updatedState,
                            staleDate: staleDate,
                            relevanceScore: 1
                        ))
                    } else {
                        await activity.update(using: updatedState)
                    }
                    
                    // 更新最后更新时间
                    self.lastUpdateTime = Date()
                }
            }
        }
    }
