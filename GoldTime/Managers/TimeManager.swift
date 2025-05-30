//
//  TimeManager.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import Foundation
import SwiftUI
import WidgetKit

// 时间管理器类，负责跟踪工作时间和计算工资
public class TimeManager: ObservableObject {
    @Published var settings: UserSettings {
        didSet {
            UserDefaultsManager.shared.saveUserSettings(settings)
            WidgetCenter.shared.reloadAllTimelines() // 更新小组件
            
            // 智能更新LiveActivity
            updateLiveActivityIfNeeded()
        }
    }
    
    @Published var currentEarnings: Double = 0.0
    @Published var formattedWorkTime: String = "00:00:00"
    @Published var workRecords: [WorkRecord] = []
    
    private var timer: Timer?
    private var isInBackground = false
    
    init() {
        // 从UserDefaults加载设置
        self.settings = UserDefaultsManager.shared.loadUserSettings()
        self.workRecords = UserDefaultsManager.shared.loadWorkRecords()
        self.startUpdatingIfNeeded()
        
        // 设置通知观察者
        setupNotificationObserver()
    }
    
    // 设置时薪
    func setHourlyRate(_ rate: Double) {
        settings.hourlyRate = rate
    }
    
    // 设置货币符号
    func setCurrency(_ currency: String) {
        settings.currency = currency
    }
    
    // 手动重启LiveActivity功能
    func restartLiveActivity() {
        // 使用修改后的endAllActivities方法确保所有LiveActivity都被关闭
        LiveActivityManager.shared.endAllActivities()
        
        // 延迟确保先前的活动已完全关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 如果处于工作状态，立即强制创建一个新的LiveActivity
            if self.settings.isWorking {
                LiveActivityManager.shared.startActivity(with: self.settings, forceStart: true)
            } else {
                // 如果不是工作状态，临时设置为工作状态，创建LiveActivity，然后恢复状态
                let originalState = self.settings.isWorking
                let originalStartTime = self.settings.startTime
                
                // 临时修改状态
                self.settings.isWorking = true
                self.settings.startTime = Date()
                
                // 创建LiveActivity
                LiveActivityManager.shared.startActivity(with: self.settings, forceStart: true)
                
                // 恢复原始状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.settings.isWorking = originalState
                    self.settings.startTime = originalStartTime
                    // 更新LiveActivity状态以反映正确的工作状态
                    LiveActivityManager.shared.updateActivity(with: self.settings)
                }
            }
        }
    }
    
    // 开始计时
    func startWorking() {
        if !settings.isWorking {
            settings.isWorking = true
            settings.startTime = Date()
            startUpdatingIfNeeded()
            
            // 启动LiveActivity
            LiveActivityManager.shared.startActivity(with: settings)
        }
    }
    
    // 暂停计时，并自动添加工作记录
    func pauseWorking() {
        if settings.isWorking {
            settings.isWorking = false
            
            // 计算已工作时间并添加到总暂停时间
            if let startTime = settings.startTime {
                let endTime = Date()
                settings.pausedTotalTime += endTime.timeIntervalSince(startTime)
                
                // 添加工作记录
                let record = WorkRecord(
                    startDate: startTime,
                    endDate: endTime,
                    hourlyRate: settings.hourlyRate,
                    currency: settings.currency
                )
                
                UserDefaultsManager.shared.addWorkRecord(record)
                workRecords = UserDefaultsManager.shared.loadWorkRecords()
                
                settings.startTime = nil
            }
            
            stopUpdating()
            
            // 更新LiveActivity状态（保持显示但停止计时）
            LiveActivityManager.shared.updateActivity(with: settings)
        }
    }
    
    // 重置计时
    func resetWorking() {
        settings.isWorking = false
        settings.startTime = nil
        settings.pausedTotalTime = 0
        updateCurrentStatus()
        stopUpdating()
        
        // 结束LiveActivity
        LiveActivityManager.shared.endActivity()
    }
    
    // 开始定时更新（如果正在工作）
    func startUpdatingIfNeeded() {
        if settings.isWorking && !isInBackground {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateCurrentStatus()
            }
            RunLoop.current.add(timer!, forMode: .common)
        }
    }
    
    // 停止定时更新
    func stopUpdating() {
        timer?.invalidate()
        timer = nil
        updateCurrentStatus()
    }
    
    // 更新LiveActivity（智能更新）
    func updateLiveActivityIfNeeded() {
        // 使用LiveActivityManager的智能刷新方法
        LiveActivityManager.shared.smartRefresh()
    }
    
    // 更新当前状态（工作时间和收入）
    func updateCurrentStatus() {
        let totalSeconds = Int(settings.calculateWorkedTime())
        
        // 格式化工作时间
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        formattedWorkTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        // 计算收入
        currentEarnings = settings.calculateEarnedMoney()
        
        // 智能更新小组件（降低频率）
        if totalSeconds % 10 == 0 { // 每10秒更新一次
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // 添加此方法以监听通知更新
    func setupNotificationObserver() {
        // 监听由ScreenStateMonitor发送的更新通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLiveActivityUpdateRequest),
            name: Notification.Name("com.wix.GoldTime.updateLiveActivity"),
            object: nil
        )
        
        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        isInBackground = true
        // 进入后台时停止高频更新
        stopUpdating()
    }
    
    @objc private func appWillEnterForeground() {
        isInBackground = false
        // 返回前台时恢复更新
        startUpdatingIfNeeded()
        // 立即更新一次LiveActivity
        updateLiveActivityIfNeeded()
    }
    
    // 处理更新请求
    @objc private func handleLiveActivityUpdateRequest(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let reason = userInfo["reason"] as? String {
            print("收到LiveActivity更新请求 - 原因: \(reason)")
        }
        updateLiveActivityIfNeeded()
    }
    
    // 格式化货币显示（四位小数）
    func formattedEarnings() -> String {
        return "\(settings.currency)\(String(format: "%.4f", currentEarnings))"
    }

    // 设置时间目标
    func setTimeGoal(_ hours: Double) {
        settings.timeGoal = hours
        UserDefaultsManager.shared.saveUserSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
        updateLiveActivityIfNeeded()
    }

    // 设置收入目标
    func setIncomeGoal(_ amount: Double) {
        settings.incomeGoal = amount
        UserDefaultsManager.shared.saveUserSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
        updateLiveActivityIfNeeded()
    }

    // 切换活跃的目标类型
    func toggleGoalType() {
        if settings.activeGoalType == .time {
            settings.activeGoalType = .income
        } else {
            settings.activeGoalType = .time
        }
        UserDefaultsManager.shared.saveUserSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
        updateLiveActivityIfNeeded()
    }

    // 获取当前目标进度
    func getCurrentGoalProgress() -> Double {
        return settings.calculateGoalProgress()
    }

    // 获取当前目标描述
    func getCurrentGoalDescription() -> String {
        return settings.getGoalDescription()
    }
    
    // 添加新的工作记录
    func addWorkRecord(_ record: WorkRecord) {
        UserDefaultsManager.shared.addWorkRecord(record)
        workRecords = UserDefaultsManager.shared.loadWorkRecords()
    }
    
    // 删除工作记录
    func deleteWorkRecord(withID id: UUID) {
        UserDefaultsManager.shared.deleteWorkRecord(withID: id)
        workRecords = UserDefaultsManager.shared.loadWorkRecords()
    }
    
    // 更新工作记录
    func updateWorkRecord(_ record: WorkRecord) {
        UserDefaultsManager.shared.updateWorkRecord(record)
        workRecords = UserDefaultsManager.shared.loadWorkRecords()
    }
    
    // 刷新工作记录列表
    func refreshWorkRecords() {
        workRecords = UserDefaultsManager.shared.loadWorkRecords()
    }
    
    // 计算不同货币的总收入
    func calculateTotalEarningsByCurrency() -> [String: Double] {
        var totalsByCurrency: [String: Double] = [:]
        
        for record in workRecords {
            if let current = totalsByCurrency[record.currency] {
                totalsByCurrency[record.currency] = current + record.earnings
            } else {
                totalsByCurrency[record.currency] = record.earnings
            }
        }
        
        return totalsByCurrency
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
