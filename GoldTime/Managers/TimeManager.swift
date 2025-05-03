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
class TimeManager: ObservableObject {
    @Published var settings: UserSettings {
        didSet {
            UserDefaultsManager.shared.saveUserSettings(settings)
            WidgetCenter.shared.reloadAllTimelines() // 更新小组件
            
            // 更新LiveActivity状态
            updateLiveActivityIfNeeded()
        }
    }
    
    @Published var currentEarnings: Double = 0.0
    @Published var formattedWorkTime: String = "00:00:00"
    
    private var timer: Timer?
    
    init() {
        // 从UserDefaults加载设置
        self.settings = UserDefaultsManager.shared.loadUserSettings()
        self.startUpdatingIfNeeded()
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
        
        // 然后强制创建一个新的LiveActivity
        // 添加短暂延迟确保之前的活动完全结束
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            LiveActivityManager.shared.startActivity(with: self.settings, forceStart: true)
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
    
    // 暂停计时
    func pauseWorking() {
        if settings.isWorking {
            settings.isWorking = false
            
            // 计算已工作时间并添加到总暂停时间
            if let startTime = settings.startTime {
                settings.pausedTotalTime += Date().timeIntervalSince(startTime)
                settings.startTime = nil
            }
            
            stopUpdating()
            
            // 更新或结束LiveActivity
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
    private func startUpdatingIfNeeded() {
        if settings.isWorking {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateCurrentStatus()
            }
        }
    }
    
    // 停止定时更新
    private func stopUpdating() {
        timer?.invalidate()
        timer = nil
        updateCurrentStatus()
    }
    
    // 更新当前状态（工作时间和收入）
    private func updateCurrentStatus() {
        let totalSeconds = Int(settings.calculateWorkedTime())
        
        // 格式化工作时间
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        formattedWorkTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        // 计算收入
        currentEarnings = settings.calculateEarnedMoney()
        
        // 更新小组件
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // 更新LiveActivity（如果需要）
    private func updateLiveActivityIfNeeded() {
        LiveActivityManager.shared.updateActivity(with: settings)
    }
    
    // 格式化货币显示（四位小数）
    func formattedEarnings() -> String {
        return "\(settings.currency)\(String(format: "%.4f", currentEarnings))"
    }
}
