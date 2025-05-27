//
//  ScreenStateMonitor.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

import Foundation
import UIKit
import WidgetKit

/// 监听屏幕状态变化以智能更新Live Activity
public class ScreenStateMonitor {
    public static let shared = ScreenStateMonitor()
    
    private var isObserving = false
    private var userDefaultsManager = UserDefaultsManager.shared
    private var lastUpdateTime: Date = Date()
    private let minimumUpdateInterval: TimeInterval = 5.0 // 最小更新间隔
    
    private init() {}
    
    /// 开始监听屏幕状态变化
    public func startMonitoring() {
        guard !isObserving else { return }
        
        // 注册屏幕亮度变化通知（用户解锁时会触发）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenBrightnessChanged),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
        
        // 注册应用激活通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 注册应用进入后台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 注册应用即将进入前台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 注册设备锁定/解锁通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceLockStateChanged),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceLockStateChanged),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil
        )
        
        isObserving = true
        print("屏幕状态监控已启动")
    }
    
    /// 停止监听
    public func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
        isObserving = false
        print("屏幕状态监控已停止")
    }
    
    /// 屏幕亮度变化时调用
    @objc private func screenBrightnessChanged(_ notification: Notification) {
        // 屏幕亮度从0变化通常意味着用户解锁了设备
        if UIScreen.main.brightness > 0 {
            throttledUpdate(reason: "屏幕亮度变化")
        }
    }
    
    /// 应用激活时调用
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        print("应用已激活")
        throttledUpdate(reason: "应用激活", forceUpdate: true)
    }
    
    /// 应用进入后台时调用
    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        print("应用进入后台")
        // 进入后台时进行一次更新，确保状态同步
        let settings = userDefaultsManager.loadUserSettings()
        if settings.isWorking {
            updateLiveActivity(with: settings, reason: "进入后台")
        }
    }
    
    /// 应用即将进入前台时调用
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        print("应用即将进入前台")
        throttledUpdate(reason: "即将进入前台", forceUpdate: true)
    }
    
    /// 设备锁定状态变化
    @objc private func deviceLockStateChanged(_ notification: Notification) {
        if notification.name == UIApplication.protectedDataDidBecomeAvailableNotification {
            print("设备已解锁")
            throttledUpdate(reason: "设备解锁", forceUpdate: true)
        } else {
            print("设备已锁定")
        }
    }
    
    /// 节流更新（避免过于频繁的更新）
    private func throttledUpdate(reason: String, forceUpdate: Bool = false) {
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        
        // 如果距离上次更新时间太短且不是强制更新，则跳过
        if !forceUpdate && timeSinceLastUpdate < minimumUpdateInterval {
            print("跳过更新 - 距离上次更新仅 \(Int(timeSinceLastUpdate)) 秒")
            return
        }
        
        print("执行更新 - 原因: \(reason)")
        lastUpdateTime = now
        
        // 获取当前用户设置
        let settings = userDefaultsManager.loadUserSettings()
        
        // 如果正在工作，则更新活动
        if settings.isWorking {
            updateLiveActivity(with: settings, reason: reason)
        }
    }
    
    /// 智能更新LiveActivity
    private func updateLiveActivity(with settings: UserSettings, reason: String) {
        print("更新LiveActivity - 原因: \(reason)")
        
        // 使用主线程更新
        DispatchQueue.main.async {
            // 方法1: 通过LiveActivityManager更新
            if let liveActivityManager = NSClassFromString("LiveActivityManager") as? NSObject.Type,
               let sharedInstance = liveActivityManager.value(forKey: "shared") as? NSObject,
               sharedInstance.responds(to: NSSelectorFromString("smartRefresh")) {
                sharedInstance.perform(NSSelectorFromString("smartRefresh"))
            }
            
            // 方法2: 通过UserDefaults触发更新
            UserDefaultsManager.shared.saveUserSettings(settings)
            
            // 方法3: 刷新小组件时间线
            WidgetCenter.shared.reloadAllTimelines()
            
            // 方法4: 发送自定义通知
            NotificationCenter.default.post(
                name: Notification.Name("com.wix.GoldTime.updateLiveActivity"),
                object: nil,
                userInfo: ["reason": reason]
            )
        }
    }
}
