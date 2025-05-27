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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timeManager)
                .onAppear {
                    // 启动屏幕状态监视器
                    ScreenStateMonitor.shared.startMonitoring()
                    
                    // 确保LiveActivity状态与应用状态同步
                    syncLiveActivityState()
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("应用进入活跃状态")
            // 应用活跃时，确保更新机制正常工作
            if timeManager.settings.isWorking {
                timeManager.startUpdatingIfNeeded()
                timeManager.updateLiveActivityIfNeeded()
            }
            
        case .inactive:
            print("应用进入非活跃状态")
            // 应用即将进入后台时，进行一次更新
            if timeManager.settings.isWorking {
                timeManager.updateLiveActivityIfNeeded()
            }
            
        case .background:
            print("应用进入后台状态")
            // 在后台时，确保LiveActivity继续工作
            if timeManager.settings.isWorking {
                // 最后一次更新确保状态同步
                timeManager.updateLiveActivityIfNeeded()
                
                // 延长后台运行时间
                BackgroundManager.shared.beginBackgroundTask()
            }
            
        @unknown default:
            break
        }
    }
    
    private func syncLiveActivityState() {
        // 检查是否有活跃的LiveActivity
        if LiveActivityManager.shared.hasActiveActivity {
            // 如果有LiveActivity但应用状态显示未工作，可能需要同步
            if !timeManager.settings.isWorking {
                print("检测到LiveActivity与应用状态不同步")
                // 可以选择结束LiveActivity或恢复工作状态
                // 这里选择结束LiveActivity
                LiveActivityManager.shared.endActivity()
            } else {
                // 如果正在工作，更新LiveActivity
                timeManager.updateLiveActivityIfNeeded()
            }
        } else if timeManager.settings.isWorking {
            // 如果应用显示正在工作但没有LiveActivity，创建一个
            print("正在工作但没有LiveActivity，创建新的")
            LiveActivityManager.shared.startActivity(with: timeManager.settings)
        }
    }
}
