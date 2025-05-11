//
//  ScreenStateMonitor.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

import Foundation
import UIKit
import WidgetKit

/// 监听屏幕状态变化以更新Live Activity
public class ScreenStateMonitor {
    public static let shared = ScreenStateMonitor()
    
    private var isObserving = false
    private var userDefaultsManager = UserDefaultsManager.shared
    
    // 上次检测时间和最小检测间隔
    private var lastScreenWakeTime: Date = Date()
    private let minimumWakeInterval: TimeInterval = 15 // 15秒
    
    private init() {}
    
    /// 开始监听屏幕状态变化
    public func startMonitoring() {
        guard !isObserving else { return }
        
        // 注册屏幕唤醒通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidWake),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
        
        // 注册屏幕解锁通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidWake),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        isObserving = true
    }
    
    /// 停止监听
    public func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
        isObserving = false
    }
    
    /// 屏幕唤醒时调用 - 添加节流控制
    @objc private func screenDidWake(_ notification: Notification) {
        // 检查是否满足最小间隔要求
        let now = Date()
        if now.timeIntervalSince(lastScreenWakeTime) < minimumWakeInterval {
            print("不满足最小间隔，跳过更新")
            return // 不满足最小间隔，跳过更新
        }
        
        // 更新最后检测时间
        lastScreenWakeTime = now
        
        print("用户唤醒屏幕")
        // 获取当前用户设置
        let settings = userDefaultsManager.loadUserSettings()
        
        // 如果正在工作，则更新活动
        if settings.isWorking {
            // 更新最后更新时间
            var updatedSettings = settings
            updatedSettings.updateLastUpdateTime()
            userDefaultsManager.saveUserSettings(updatedSettings)
            
            // 使用备用方法更新活动
            updateLiveActivity(with: updatedSettings)
            
            // 刷新小组件时间线
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// 备用方法来更新LiveActivity，避免直接调用可能无法编译的方法
    private func updateLiveActivity(with settings: UserSettings) {
        // 方法1: 通过用户默认值触发更新
        UserDefaultsManager.shared.saveUserSettings(settings)
        
        // 方法2: 如果可行，尝试直接更新通知
        #if canImport(ActivityKit)
        if let activityClass = NSClassFromString("Activity") as? NSObject.Type,
           let activitiesValue = activityClass.value(forKey: "activities"),
           let activities = activitiesValue as? [Any] {
            // 有活动存在，通知应用需要更新
            NotificationCenter.default.post(
                name: Notification.Name("com.wix.GoldTime.updateLiveActivity"),
                object: nil,
                userInfo: nil
            )
        }
        #endif
    }
}
