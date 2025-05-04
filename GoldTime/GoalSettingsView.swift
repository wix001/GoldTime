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
            Form {
                Section(header: Text("目标类型")) {
                    Picker("目标类型", selection: $selectedGoalType) {
                        Text("时间目标").tag(GoalType.time)
                        Text("收入目标").tag(GoalType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedGoalType) { newValue in
                        timeManager.settings.activeGoalType = newValue
                        timeManager.updateLiveActivityIfNeeded()
                    }
                }
                
                Section(header: Text("时间目标设置")) {
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
                }
                
                Section(header: Text("收入目标设置")) {
                    HStack {
                        Text("目标收入")
                        TextField("输入目标收入", text: $incomeGoal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("保存目标设置") {
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("目标设置")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
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
    }
}
