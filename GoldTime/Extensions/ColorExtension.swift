//
//  ColorExtension.swift
//  GoldTime
//
//  Created on 04/05/2025.
//

import SwiftUI

// 颜色扩展，支持十六进制颜色
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
    
    // 定义应用中使用的颜色主题
    static let primaryGold = Color(hex: 0xD4AF37)
    static let darkBlueGray = Color(hex: 0x445566)
    static let lightBackground = Color(hex: 0xF8F9FA)
    static let fieldBackground = Color(hex: 0xF5F5F5)
    static let successGreen = Color(hex: 0x2E8B57)
    static let warningAmber = Color(hex: 0xFFBF00)
    static let errorRed = Color(hex: 0x9B2226)
}
