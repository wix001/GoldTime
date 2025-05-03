////
//  UserDefaultsManager.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//


import Foundation

// 用于在UserDefaults中存储和检索UserSettings的管理器
public class UserDefaultsManager {
    public static let shared = UserDefaultsManager()
    
    private let userSettingsKey = "userSettings"
    
    // 确保app group标识符正确设置，并使用nil检查前的强制解包
    private let userDefaults = UserDefaults(suiteName: "group.com.wix.GoldTime")!
    
    private init() {}
    
    public func saveUserSettings(_ settings: UserSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: userSettingsKey)
            userDefaults.synchronize()
        }
    }
    
    public func loadUserSettings() -> UserSettings {
        if let data = userDefaults.data(forKey: userSettingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return decoded
        }
        return UserSettings()
    }
}
