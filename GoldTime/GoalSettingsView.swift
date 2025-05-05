//
//  GoalSettingsView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

import SwiftUI

struct GoalSettingsView: View {
    @EnvironmentObject var timeManager: TimeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var timeGoalHours: Double
    @State private var timeGoalMinutes: Double
    @State private var incomeGoal: String
    @State private var selectedGoalType: GoalType
    
    init(timeManager: TimeManager) {
        let settings = timeManager.settings
        
        // 分解时间目标为小时和分钟
        let hours = Int(settings.timeGoal)
        let minutes = Int((settings.timeGoal - Double(hours)) * 60)
        
        _timeGoalHours = State(initialValue: Double(hours))
        _timeGoalMinutes = State(initialValue: Double(minutes))
        _incomeGoal = State(initialValue: String(format: "%.2f", settings.incomeGoal))
        _selectedGoalType = State(initialValue: settings.activeGoalType)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("目标类型")) {
                        Picker("目标类型", selection: $selectedGoalType) {
                            HStack {
                                Image(systemName: "clock")
                                Text("时间目标")
                            }
                            .tag(GoalType.time)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                Text("收入目标")
                            }
                            .tag(GoalType.income)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedGoalType) { newValue in
                            timeManager.settings.activeGoalType = newValue
                            timeManager.updateLiveActivityIfNeeded()
                        }
                    }
                    
                    Section(header:
                            HStack {
                                Image(systemName: "clock")
                                Text("时间目标设置")
                            }
                    ) {
                        HStack {
                            Text("小时")
                            Spacer()
                            Stepper("\(Int(timeGoalHours)) 小时", value: $timeGoalHours, in: 0...24)
                        }
                        
                        HStack {
                            Text("分钟")
                            Spacer()
                            Stepper("\(Int(timeGoalMinutes)) 分钟", value: $timeGoalMinutes, in: 0...59)
                        }
                        
                        // 显示当前设置的时间目标
                        HStack {
                            Text("当前设置")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(timeGoalHours))时\(Int(timeGoalMinutes))分")
                                .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : .green)
                        }
                    }
                    
                    Section(header:
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                Text("收入目标设置")
                            }
                    ) {
                        HStack {
                            Text("目标收入")
                            Spacer()
                            TextField("输入目标收入", text: $incomeGoal)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        // 显示当前设置的收入目标
                        HStack {
                            Text("当前设置")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(timeManager.settings.currency)\(incomeGoal)")
                                .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
                        }
                    }
                    
                    Section {
                        Button(action: saveSettings) {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                Text("保存目标设置")
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("目标设置")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .accentColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
        }
    }
    
    private func saveSettings() {
        // 计算总时间目标（小时）
        let totalHours = timeGoalHours + (timeGoalMinutes / 60)
        timeManager.setTimeGoal(totalHours)
        
        // 保存收入目标
        if let incomeValue = Double(incomeGoal) {
            timeManager.setIncomeGoal(incomeValue)
        }
        
        // 保存目标类型
        timeManager.settings.activeGoalType = selectedGoalType
        UserDefaultsManager.shared.saveUserSettings(timeManager.settings)
        
        // 更新LiveActivity
        timeManager.updateLiveActivityIfNeeded()
        
        // 关闭视图
        presentationMode.wrappedValue.dismiss()
    }
}

struct GoalSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GoalSettingsView(timeManager: TimeManager())
                .environmentObject(TimeManager())
                .preferredColorScheme(.light)
            
            GoalSettingsView(timeManager: TimeManager())
                .environmentObject(TimeManager())
                .preferredColorScheme(.dark)
        }
    }
}
