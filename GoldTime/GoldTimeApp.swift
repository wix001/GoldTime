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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 当应用进入后台时，检查是否需要启动LiveActivity
                    if timeManager.settings.isWorking {
                        LiveActivityManager.shared.startActivity(with: timeManager.settings)
                        
                        // 延长后台运行时间
                        BackgroundManager.shared.beginBackgroundTask()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // 当应用返回前台时，根据情况更新或关闭LiveActivity
                    if timeManager.settings.isWorking {
                        LiveActivityManager.shared.updateActivity(with: timeManager.settings)
                    } else if !timeManager.settings.isWorking && LiveActivityManager.shared.hasActiveActivity {
                        LiveActivityManager.shared.endActivity()
                    }
                    
                    // 结束后台任务
                    BackgroundManager.shared.endBackgroundTask()
                }
        }
    }
}
