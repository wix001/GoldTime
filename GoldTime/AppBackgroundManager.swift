//
//  AppBackgroundManager.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

//
//  AppBackgroundManager.swift
//  GoldTime
//
//  Created on 2025/05/04
//

import Foundation
import UIKit

// 仅在主应用中使用的后台任务管理类
public class AppBackgroundManager {
    public static let shared = AppBackgroundManager()
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 应用进入后台
    @objc private func appDidEnterBackground() {
        let userSettings = UserDefaultsManager.shared.loadUserSettings()
        if userSettings.isWorking {
            startBackgroundTask()
            
            // 安排后台刷新
            scheduleBackgroundRefresh()
        }
    }
    
    // 应用即将进入前台
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }
    
    // 开始后台任务
    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    // 结束后台任务
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // 安排后台刷新任务
    private func scheduleBackgroundRefresh() {
        // 如果支持后台刷新框架，可以在这里添加代码
        if #available(iOS 13.0, *) {
            if let scheduler = NSClassFromString("BGTaskScheduler") {
                // 后台任务逻辑，但这里不直接实现，避免编译问题
                print("可以使用后台任务调度器")
            }
        }
    }
    
    // 公共方法，可从LiveActivityManager调用
    public func processBackgroundWork(settings: UserSettings) {
        if settings.isWorking {
            // 更新LiveActivity
            LiveActivityManager.shared.updateActivity(with: settings)
            // 重新加载小组件时间线
            reloadWidgetTimelines()
        }
    }
    
    // 重新加载小组件时间线
    private func reloadWidgetTimelines() {
        // 导入WidgetKit并调用刷新方法
        if let widgetCenter = NSClassFromString("WidgetCenter") as? NSObject.Type,
           let shared = widgetCenter.value(forKey: "shared") as? NSObject,
           shared.responds(to: NSSelectorFromString("reloadAllTimelines")) {
            shared.perform(NSSelectorFromString("reloadAllTimelines"))
        }
    }
}
