//
//  WorkRecordEditView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

import SwiftUI

struct WorkRecordEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var timeManager: TimeManager
    @Environment(\.colorScheme) var colorScheme
    
    var isNewRecord: Bool
    var existingRecord: WorkRecord?
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hourlyRate: String
    @State private var selectedCurrency: String
    @State private var note: String
    
    // 可选货币类型（使用唯一 ID）
    private let currencies = [
        Currency(id: "CNY", symbol: "¥", name: "人民币"),
        Currency(id: "GBP", symbol: "£", name: "英镑"),
        Currency(id: "USD", symbol: "$", name: "美元"),
        Currency(id: "EUR", symbol: "€", name: "欧元"),
        Currency(id: "JPY", symbol: "¥", name: "日元")
    ]
    
    // 初始化方法
    init(isNewRecord: Bool, record: WorkRecord?) {
        self.isNewRecord = isNewRecord
        self.existingRecord = record
        
        _startDate = State(initialValue: record?.startDate ?? Date().addingTimeInterval(-3600))
        _endDate = State(initialValue: record?.endDate ?? Date())
        _hourlyRate = State(initialValue: record != nil ? String(format: "%.2f", record!.hourlyRate) : String(format: "%.2f", UserDefaultsManager.shared.loadUserSettings().hourlyRate))
        _selectedCurrency = State(initialValue: record?.currency ?? UserDefaultsManager.shared.loadUserSettings().currency)
        _note = State(initialValue: record?.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("时间信息")) {
                        DatePicker("开始时间", selection: $startDate)
                        DatePicker("结束时间", selection: $endDate)
                        
                        HStack {
                            Text("工作时长")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedDuration)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Section(header: Text("收入信息")) {
                        HStack {
                            Text("时薪")
                            Spacer()
                            TextField("输入时薪", text: $hourlyRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        Picker("货币类型", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.symbol) { currency in
                                Text("\(currency.symbol) \(currency.name)")
                                    .tag(currency.symbol)
                            }
                        }
                        
                        HStack {
                            Text("预计收入")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formattedEarnings)
                                .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
                        }
                    }
                    
                    Section(header: Text("备注")) {
                        TextField("添加备注（可选）", text: $note)
                            .frame(height: 80)
                    }
                    
                    Section {
                        Button(action: saveRecord) {
                            HStack {
                                Spacer()
                                Text(isNewRecord ? "添加记录" : "保存修改")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                            .background(Color.accentColor)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle(isNewRecord ? "添加打工记录" : "编辑打工记录")
            .navigationBarItems(
                trailing: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .accentColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
        }
    }
    
    // 格式化工作时长
    private var formattedDuration: String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d时%02d分", hours, minutes)
    }
    
    // 格式化预计收入
    private var formattedEarnings: String {
        let duration = endDate.timeIntervalSince(startDate)
        let hourlyRateValue = Double(hourlyRate) ?? 0
        let earnings = (duration / 3600) * hourlyRateValue
        return "\(selectedCurrency)\(String(format: "%.2f", earnings))"
    }
    
    // 保存记录
    private func saveRecord() {
        // 验证输入
        guard startDate < endDate,
              let hourlyRateValue = Double(hourlyRate),
              hourlyRateValue > 0 else {
            return
        }
        
        let newRecord = WorkRecord(
            id: existingRecord?.id ?? UUID(),
            startDate: startDate,
            endDate: endDate,
            hourlyRate: hourlyRateValue,
            currency: selectedCurrency,
            note: note.isEmpty ? nil : note
        )
        
        if isNewRecord {
            timeManager.addWorkRecord(newRecord)
        } else {
            timeManager.updateWorkRecord(newRecord)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct WorkRecordEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkRecordEditView(isNewRecord: true, record: nil)
                .environmentObject(TimeManager())
                .preferredColorScheme(.light)
            
            WorkRecordEditView(isNewRecord: true, record: nil)
                .environmentObject(TimeManager())
                .preferredColorScheme(.dark)
        }
    }
}
