//
//  WorkHistroyView.swift
//  GoldTime
//
//  Created by 徐蔚起 on 04/05/2025.
//
//
//  WorkHistoryView.swift
//  GoldTime
//
//  Created on 04/05/2025.
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
            VStack {
                // 总收入统计卡片
                VStack {
                    Text("总收入统计")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(totalEarnings.sorted(by: { $0.key < $1.key }), id: \.key) { currency, amount in
                        HStack {
                            Text("\(currency):")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(currency)\(String(format: "%.2f", amount))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: 0xB8860B))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: 0xFFF8E1), Color(hex: 0xFFF8DC)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .gray.opacity(0.3), radius: 3)
                )
                .padding()
                
                // 筛选按钮
                Button(action: {
                    showDateFilter.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color(hex: 0xDAA520))
                        Text(isFilterActive ? "筛选中: \(formatDate(startFilterDate)) - \(formatDate(endFilterDate))" : "筛选日期范围")
                            .foregroundColor(isFilterActive ? .primary : Color(hex: 0xB8860B))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .rotationEffect(Angle(degrees: showDateFilter ? 180 : 0))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: 0xDAA520), lineWidth: 1)
                            .background(isFilterActive ? Color(hex: 0xFFF8E1).cornerRadius(10) : Color(.systemBackground).cornerRadius(10))
                    )
                }
                .padding(.horizontal)
                
                if showDateFilter {
                    HStack {
                        VStack {
                            Text("开始日期")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $startFilterDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        VStack {
                            Text("结束日期")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $endFilterDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        Button(action: {
                            isFilterActive = true
                            showDateFilter = false
                        }) {
                            Text("应用")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: 0xDAA520))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        if isFilterActive {
                            Button(action: {
                                isFilterActive = false
                                showDateFilter = false
                            }) {
                                Text("清除")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showDateFilter)
                }
                
                // 历史记录列表
                if filteredRecords.isEmpty {
                    VStack {
                        Spacer()
                        Text("暂无打工记录")
                            .foregroundColor(.secondary)
                        if isFilterActive {
                            Text("尝试清除或修改日期筛选")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
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
            .navigationTitle("打工历史")
            .navigationBarItems(
                trailing: Button(action: {
                    showAddRecord = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: 0xDAA520))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                    .foregroundColor(Color(hex: 0xB8860B))
                    .fontWeight(.bold)
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
        .background(Color(.systemBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
