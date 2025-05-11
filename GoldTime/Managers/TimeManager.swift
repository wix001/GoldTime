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
            
            // 更新LiveActivity状态 - 针对状态变化立即更新
            if settings.isWorking != oldValue.isWorking ||
               settings.hourlyRate != oldValue.hourlyRate ||
               settings.currency != oldValue.currency ||
               settings.activeGoalType != oldValue.activeGoalType {
                updateLiveActivityIfNeeded()
            }
        }
    }
    
    @Published var currentEarnings: Double = 0.0
    @Published var formattedWorkTime: String = "00:00:00"
    @Published var workRecords: [WorkRecord] = []
    
    private var timer: Timer?
    
    // 追踪上次LiveActivity更新时间
    private var lastLiveActivityUpdate: Date = Date()
    private let liveActivityUpdateInterval: TimeInterval = 60 // 60秒
    
    init() {
        // 从UserDefaults加载设置
        self.settings = UserDefaultsManager.shared.loadUserSettings()
        self.workRecords = UserDefaultsManager.shared.loadWorkRecords()
        self.startUpdatingIfNeeded()
        
        // 设置电量监测
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
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
            
            // 记录更新时间
            lastLiveActivityUpdate = Date()
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
            
            // 更新收入值，确保暂停后显示正确
            updateCurrentStatus()
            
            // 更新或结束LiveActivity - 状态改变时立即更新
            LiveActivityManager.shared.updateActivity(with: settings)
            
            // 记录更新时间
            lastLiveActivityUpdate = Date()
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
        if settings.isWorking {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateCurrentStatus()
                self?.checkAndUpdateLiveActivity()
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
    
    // 检查是否需要更新LiveActivity
    private func checkAndUpdateLiveActivity() {
        // 仅在工作状态且已经过去liveActivityUpdateInterval时间后更新
        if settings.isWorking &&
           Date().timeIntervalSince(lastLiveActivityUpdate) >= liveActivityUpdateInterval {
            updateLiveActivityIfNeeded()
            lastLiveActivityUpdate = Date()
        }
    }
    
    // 更新LiveActivity（如果需要）
    func updateLiveActivityIfNeeded() {
        // 尝试调用常规的更新方法
        LiveActivityManager.shared.updateActivity(with: settings)
        
        // 保存最新设置，这将触发数据更新
        UserDefaultsManager.shared.saveUserSettings(settings)
        
        // 刷新小组件时间线
        WidgetCenter.shared.reloadAllTimelines()
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
        
        // 更新小组件 - 但不需要每秒都更新
        if totalSeconds % 5 == 0 { // 每5秒更新一次
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
        
        // 监听电池状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }
    
    // 处理电池状态变化
    @objc private func batteryStateDidChange(_ notification: Notification) {
        // 根据电池状态调整更新频率
        if UIDevice.current.batteryState == .unplugged &&
           UIDevice.current.batteryLevel < 0.2 {
            // 低电量模式，减少更新频率
            if let timer = timer {
                timer.invalidate()
                self.timer = Timer.scheduledTimer(
                    withTimeInterval: 5.0, // 降低到5秒一次
                    repeats: true
                ) { [weak self] _ in
                    self?.updateCurrentStatus()
                    self?.checkAndUpdateLiveActivity()
                }
                RunLoop.current.add(self.timer!, forMode: .common)
            }
        } else {
            // 正常电量模式，恢复正常频率
            if settings.isWorking {
                stopUpdating()
                startUpdatingIfNeeded()
            }
        }
    }
    
    // 处理更新请求
    @objc private func handleLiveActivityUpdateRequest(_ notification: Notification) {
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
}
