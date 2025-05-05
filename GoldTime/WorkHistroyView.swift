//
//  WorkHistoryView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//

import SwiftUI

struct WorkHistoryView: View {
    @EnvironmentObject var timeManager: TimeManager
    @State private var showAddRecord = false
    @State private var editingRecord: WorkRecord?
    @State private var showDateFilter = false
    @State private var startFilterDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endFilterDate = Date()
    @State private var isFilterActive = false
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredRecords: [WorkRecord] {
        if !isFilterActive {
            return timeManager.workRecords.sorted(by: { $0.startDate > $1.startDate })
        } else {
            return timeManager.workRecords.filter {
                $0.startDate >= startFilterDate && $0.endDate <= endFilterDate
            }.sorted(by: { $0.startDate > $1.startDate })
        }
    }
    
    private var totalEarnings: [String: Double] {
        var totals: [String: Double] = [:]
        
        for record in filteredRecords {
            if let current = totals[record.currency] {
                totals[record.currency] = current + record.earnings
            } else {
                totals[record.currency] = record.earnings
            }
        }
        
        return totals
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // 总收入统计卡片
                    VStack(spacing: 10) {
                        Text("总收入统计")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        ForEach(totalEarnings.sorted(by: { $0.key < $1.key }), id: \.key) { currency, amount in
                            HStack {
                                Text("\(currency):")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(currency)\(String(format: "%.2f", amount))")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // 筛选按钮
                    Button(action: {
                        withAnimation {
                            showDateFilter.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.accentColor)
                            Text(isFilterActive ? "筛选中: \(formatDate(startFilterDate)) - \(formatDate(endFilterDate))" : "筛选日期范围")
                                .foregroundColor(isFilterActive ? .primary : .secondary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .rotationEffect(Angle(degrees: showDateFilter ? 180 : 0))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemBackground))
                        )
                    }
                    .padding(.horizontal)
                    
                    if showDateFilter {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("开始日期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $startFilterDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("结束日期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $endFilterDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            Spacer()
                            
                            VStack {
                                Button(action: {
                                    isFilterActive = true
                                    showDateFilter = false
                                }) {
                                    Text("应用")
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                
                                if isFilterActive {
                                    Button(action: {
                                        isFilterActive = false
                                        showDateFilter = false
                                    }) {
                                        Text("清除")
                                            .font(.footnote)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemRed))
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                    
                    // 历史记录列表
                    if filteredRecords.isEmpty {
                        Spacer()
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("暂无打工记录")
                                .foregroundColor(.secondary)
                            
                            if isFilterActive {
                                Text("尝试清除或修改日期筛选")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredRecords) { record in
                                WorkRecordCell(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingRecord = record
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            timeManager.deleteWorkRecord(withID: record.id)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("打工历史")
            .navigationBarItems(
                trailing: Button(action: {
                    showAddRecord = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showAddRecord) {
                WorkRecordEditView(isNewRecord: true, record: nil)
                    .environmentObject(timeManager)
            }
            .sheet(item: $editingRecord) { record in
                WorkRecordEditView(isNewRecord: false, record: record)
                    .environmentObject(timeManager)
            }
            .onAppear {
                timeManager.refreshWorkRecords()
            }
        }
        .accentColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// 工作记录单元格
struct WorkRecordCell: View {
    let record: WorkRecord
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(record.startDate))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("→")
                    .foregroundColor(.secondary)
                
                Text(formatDate(record.endDate))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(record.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("时薪: \(record.currency)\(String(format: "%.2f", record.hourlyRate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(record.formattedEarnings)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? Color(hex: 0xFFD700) : Color(hex: 0xB8860B))
            }
            
            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkHistoryView()
                .environmentObject(TimeManager())
                .preferredColorScheme(.light)
            
            WorkHistoryView()
                .environmentObject(TimeManager())
                .preferredColorScheme(.dark)
        }
    }
}
