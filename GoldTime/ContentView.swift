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
    @State private var showHistoryView: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // 获取当前赚取的工资
    private var earningsText: String {
        return timeManager.formattedEarnings()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // 标题
                    Text("工时工资计算器")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0x916A08))
                        .padding(.top, 10)
                    
                    // 信息卡片
                    VStack(spacing: 12) {
                        HStack {
                            Text("已工作时间:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(timeManager.formattedWorkTime)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        // 工资显示
                        VStack {
                            Text("已赚取:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(earningsText)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
                                .padding(.vertical, 15)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // 货币选择器
                    CurrencySelector()
                        .padding(.vertical, 5)
                    
                    // 时薪设置
                    VStack(alignment: .leading) {
                        Text("设置时薪")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.leading)
                        
                        HStack {
                            Text(timeManager.settings.currency)
                                .font(.title3)
                                .foregroundColor(.primary)
                            
                            TextField("输入每小时工资", text: $hourlyRateText)
                                .keyboardType(.decimalPad)
                                .padding()
                                .foregroundColor(.primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.tertiarySystemBackground))
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
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 目标设置按钮
                    Button(action: {
                        showGoalSettings.toggle()
                    }) {
                        HStack {
                            Image(systemName: "target")
                            Text("设置工作目标")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // 显示当前目标类型和进度
                            Text(timeManager.getCurrentGoalDescription())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemBackground))
                        )
                    }
                    .padding(.horizontal)
                    
                    // 目标进度条
                    ProgressView(value: timeManager.getCurrentGoalProgress())
                        .progressViewStyle(LinearProgressViewStyle(tint: timeManager.settings.activeGoalType == .time ? .green : Color.accentColor))
                        .padding(.horizontal)
                    
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
                            Text("重启通知栏动态")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .foregroundColor(.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemBackground))
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 控制按钮
                    HStack(spacing: 16) {
                        // 开始/暂停按钮
                        Button(action: {
                            if timeManager.settings.isWorking {
                                timeManager.pauseWorking()
                            } else {
                                timeManager.startWorking()
                            }
                        }) {
                            HStack {
                                Image(systemName: timeManager.settings.isWorking ? "pause.fill" : "play.fill")
                                Text(timeManager.settings.isWorking ? "暂停" : "开始")
                            }
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                timeManager.settings.isWorking
                                ? Color.orange
                                : Color.accentColor
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // 重置按钮
                        Button(action: {
                            timeManager.resetWorking()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("重置")
                            }
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemRed))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    // 显示历史记录视图
                    showHistoryView.toggle()
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                },
                trailing: Button(action: {
                    showInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
            )
            .sheet(isPresented: $showHistoryView) {
                WorkHistoryView()
                    .environmentObject(timeManager)
            }
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
        }
        .accentColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
    }
    
    // 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 信息视图
struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("使用说明")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
                        .padding(.top)
                    
                    InfoItem(title: "1. 设置您的时薪",
                             description: "在主屏幕输入您的每小时工资，然后点击\"保存\"按钮。")
                    
                    InfoItem(title: "2. 开始计时",
                             description: "点击\"开始\"按钮来开始记录工作时间和计算收入。")
                    
                    InfoItem(title: "3. 锁屏小组件",
                             description: "长按锁屏，点击\"自定义\"，然后添加\"工资计算器\"小组件，这样您就可以在锁屏上实时查看您的收入。")
                    
                    InfoItem(title: "4. 控制",
                             description: "使用\"暂停\"按钮临时停止计时，使用\"重置\"按钮清零计时和收入。")
                    
                    InfoItem(title: "5. 工作历史",
                             description: "点击左上角时钟图标查看您的所有工作记录和统计信息。")
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
        }
    }
}

struct InfoItem: View {
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xDAA520))
            
            Text(description)
                .foregroundColor(.primary)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TimeManager())
            .preferredColorScheme(.light)
        
        ContentView()
            .environmentObject(TimeManager())
            .preferredColorScheme(.dark)
    }
}
