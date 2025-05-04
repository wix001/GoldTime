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
    private let workRecordsKey = "workRecords"
    
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
    
    // 保存工作记录列表
    public func saveWorkRecords(_ records: [WorkRecord]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(records) {
            userDefaults.set(encoded, forKey: workRecordsKey)
            userDefaults.synchronize()
        }
    }
    
    // 加载工作记录列表
    public func loadWorkRecords() -> [WorkRecord] {
        if let data = userDefaults.data(forKey: workRecordsKey),
           let decoded = try? JSONDecoder().decode([WorkRecord].self, from: data) {
            return decoded
        }
        return []
    }
    
    // 添加一条工作记录
    public func addWorkRecord(_ record: WorkRecord) {
        var records = loadWorkRecords()
        records.append(record)
        saveWorkRecords(records)
    }
    
    // 删除一条工作记录
    public func deleteWorkRecord(withID id: UUID) {
        var records = loadWorkRecords()
        records.removeAll { $0.id == id }
        saveWorkRecords(records)
    }
    
    // 更新一条工作记录
    public func updateWorkRecord(_ record: WorkRecord) {
        var records = loadWorkRecords()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveWorkRecords(records)
        }
    }
}
