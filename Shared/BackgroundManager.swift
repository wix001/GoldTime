//
//  BackgroundManager.swift
//  GoldTime
//
//  Created on 2025/05/04
//

import Foundation
import UIKit

// 专门处理后台任务的单例类
class BackgroundManager {
    static let shared = BackgroundManager()
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    // 开始后台任务以延长运行时间
    func beginBackgroundTask() {
        // 先结束已有任务
        endBackgroundTask()
        
        // 开始新的后台任务
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    // 结束后台任务
    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
