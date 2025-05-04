//
//  WorkRecord.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//
//
//  WorkRecord.swift
//  GoldTime
//
//  Created on 04/05/2025.
//

import Foundation

// 打工记录模型
public struct WorkRecord: Identifiable, Codable {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date
    public var duration: TimeInterval
    public var hourlyRate: Double
    public var currency: String
    public var earnings: Double
    public var note: String?
    
    // 便利初始化方法
    public init(id: UUID = UUID(), startDate: Date, endDate: Date, hourlyRate: Double, currency: String, note: String? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = endDate.timeIntervalSince(startDate)
        self.hourlyRate = hourlyRate
        self.currency = currency
        self.earnings = (self.duration / 3600) * hourlyRate
        self.note = note
    }
    
    // 格式化开始日期
    public var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    // 格式化结束日期
    public var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
    
    // 格式化持续时间
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d时%02d分", hours, minutes)
    }
    
    // 格式化收入
    public var formattedEarnings: String {
        return "\(currency)\(String(format: "%.2f", earnings))"
    }
}
