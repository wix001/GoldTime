//
//  ColorExtension.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

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
}
