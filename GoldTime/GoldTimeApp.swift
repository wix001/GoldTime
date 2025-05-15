//
//  GoldTimeApp.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import SwiftUI
import WidgetKit


@main
struct GoldTimeApp: App {
    // 创建一个时间管理器的实例，作为环境对象在整个应用中共享
    @StateObject private var timeManager = TimeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timeManager)
                .onAppear {
                    // 启动屏幕状态监视器
                    ScreenStateMonitor.shared.startMonitoring()
                    
                    // 设置通知监听器
                    timeManager.setupNotificationObserver()
                    
                    // 如果正在工作，确保LiveActivity正常运行
                    if timeManager.settings.isWorking {
                        timeManager.updateLiveActivityIfNeeded()
                    }
                }
                .onDisappear {
                    // 停止监视器
                    ScreenStateMonitor.shared.stopMonitoring()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 当应用进入后台时，检查是否需要启动LiveActivity
                    if timeManager.settings.isWorking {
                        // 这里尝试使用现有的更新方法
                        timeManager.updateLiveActivityIfNeeded()
                        
                        // 延长后台运行时间
                        BackgroundManager.shared.beginBackgroundTask()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // 当应用返回前台时，根据情况更新或关闭LiveActivity
                    // 关键是确保LiveActivity状态与App状态同步
                    timeManager.updateLiveActivityIfNeeded()
                    
                    // 结束后台任务
                    BackgroundManager.shared.endBackgroundTask()
                }
        }
    }
}
