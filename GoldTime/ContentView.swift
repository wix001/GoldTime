//
//  ContentView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timeManager: TimeManager
    @State private var hourlyRateText: String = ""
    @State private var showInfo: Bool = false
    @State private var showGoalSettings: Bool = false
    
    // 获取当前赚取的工资
    private var earningsText: String {
        return timeManager.formattedEarnings()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("工时工资计算器")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: 0xB8860B)) // 暗金色
                    .padding(.top)
                
                // 信息卡片
                VStack(spacing: 15) {
                    HStack {
                        Text("已工作时间:")
                            .font(.headline)
                        Spacer()
                        Text(timeManager.formattedWorkTime)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    // 工资显示（金色金属风格）
                    VStack {
                        Text("已赚取:")
                            .font(.headline)
                        
                        GoldMetalText(text: earningsText, fontSize: 36)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black.opacity(0.05), Color.black.opacity(0.2)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .padding(.vertical, 10)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.3), radius: 5)
                )
                .padding(.horizontal)
                
                // 货币选择器
                CurrencySelector()
                    .padding(.vertical, 5)
                
                // 时薪设置
                VStack(alignment: .leading) {
                    Text("设置时薪")
                        .font(.headline)
                        .padding(.leading)
                    
                    HStack {
                        Text(timeManager.settings.currency)
                            .font(.title3)
                        
                        TextField("输入每小时工资", text: $hourlyRateText)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                            .onAppear {
                                hourlyRateText = String(format: "%.2f", timeManager.settings.hourlyRate)
                            }
                        
                        Button(action: {
                            if let rate = Double(hourlyRateText) {
                                timeManager.setHourlyRate(rate)
                                hideKeyboard()
                            }
                        }) {
                            Text("保存")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(hex: 0xDAA520)) // 使用金色
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                // 添加目标设置按钮
                Button(action: {
                    showGoalSettings.toggle()
                }) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(Color(hex: 0xFFD700))
                        Text("设置工作目标")
                            .foregroundColor(Color(hex: 0xB8860B))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        // 显示当前目标类型和进度
                        Text(timeManager.getCurrentGoalDescription())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xDAA520), lineWidth: 2)
                            .background(Color(hex: 0xFFF8E1).cornerRadius(10))
                    )
                }
                .padding(.horizontal)

                // 目标进度条
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                        .cornerRadius(5)
                    
                    // 进度
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    timeManager.settings.activeGoalType == .time ? Color.green.opacity(0.7) : Color(hex: 0xFFD700).opacity(0.7),
                                    timeManager.settings.activeGoalType == .time ? Color.green : Color(hex: 0xFFD700)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(min(CGFloat(timeManager.getCurrentGoalProgress()) * (UIScreen.main.bounds.width - 40), UIScreen.main.bounds.width - 40), 10), height: 10)
                        .cornerRadius(5)
                        .animation(.linear, value: timeManager.getCurrentGoalProgress())
                }
                .padding(.horizontal, 20)

                // 添加目标设置的sheet
                .sheet(isPresented: $showGoalSettings) {
                    GoalSettingsView(timeManager: timeManager)
                        .environmentObject(timeManager)
                }
                // 重启LiveActivity按钮
                Button(action: {
                    timeManager.restartLiveActivity()
                }) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(Color(hex: 0xFFD700))
                        Text("重启通知栏动态")
                            .foregroundColor(Color(hex: 0xB8860B))
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xDAA520), lineWidth: 2)
                            .background(Color(hex: 0xFFF8E1).cornerRadius(10))
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: 20) {
                    // 开始/暂停按钮
                    Button(action: {
                        if timeManager.settings.isWorking {
                            timeManager.pauseWorking()
                        } else {
                            timeManager.startWorking()
                        }
                    }) {
                        Text(timeManager.settings.isWorking ? "暂停" : "开始")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                timeManager.settings.isWorking
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: 0xFFD700), Color(hex: 0xDAA520)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // 重置按钮
                    Button(action: {
                        timeManager.resetWorking()
                    }) {
                        Text("重置")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarItems(trailing: Button(action: {
                showInfo.toggle()
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(hex: 0xDAA520))
            })
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
            .padding()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 金色金属文字组件
struct GoldMetalText: View {
    let text: String
    let fontSize: CGFloat
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0xFFF3B0),  // 浅金色
                        Color(hex: 0xFFD700),  // 金色
                        Color(hex: 0xDAA520),  // 深金色
                        Color(hex: 0xB8860B),  // 暗金色
                        Color(hex: 0xFFD700)   // 回到金色
                    ]),
                    startPoint: UnitPoint(x: phase, y: 0),
                    endPoint: UnitPoint(x: phase + 1, y: 1)
                )
            )
            .overlay(
                Text(text)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0),
                                .white.opacity(0.9),
                                .white.opacity(0)
                            ]),
                            startPoint: UnitPoint(x: phase, y: 0),
                            endPoint: UnitPoint(x: phase + 0.1, y: 1)
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

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

// 信息视图
struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("使用说明")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: 0xB8860B))
                    .padding(.top)
                
                Text("1. 设置您的时薪")
                    .font(.headline)
                    .foregroundColor(Color(hex: 0xDAA520))
                Text("在主屏幕输入您的每小时工资，然后点击\"保存\"按钮。")
                    .padding(.bottom)
                
                Text("2. 开始计时")
                    .font(.headline)
                    .foregroundColor(Color(hex: 0xDAA520))
                Text("点击\"开始\"按钮来开始记录工作时间和计算收入。")
                    .padding(.bottom)
                
                Text("3. 锁屏小组件")
                    .font(.headline)
                    .foregroundColor(Color(hex: 0xDAA520))
                Text("长按锁屏，点击\"自定义\"，然后添加\"工资计算器\"小组件，这样您就可以在锁屏上实时查看您的收入。")
                    .padding(.bottom)
                
                Text("4. 控制")
                    .font(.headline)
                    .foregroundColor(Color(hex: 0xDAA520))
                Text("使用\"暂停\"按钮临时停止计时，使用\"重置\"按钮清零计时和收入。")
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TimeManager())
    }
}
