//
//  CurrencySelector.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//
//
//  CurrencySelector.swift
//  GoldTime
//
//  Created on 03/05/2025.
//

import SwiftUI

struct CurrencySelector: View {
    @EnvironmentObject var timeManager: TimeManager
    @State private var showSelector = false
    
    // 可选货币类型
    private let currencies = [
        Currency(symbol: "¥", name: "人民币"),
        Currency(symbol: "£", name: "英镑"),
        Currency(symbol: "$", name: "美元"),
        Currency(symbol: "€", name: "欧元"),
        Currency(symbol: "¥", name: "日元")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("货币类型")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showSelector.toggle()
                }) {
                    HStack {
                        Text(timeManager.settings.currency)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(Angle(degrees: showSelector ? 180 : 0))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(.horizontal)
            
            if showSelector {
                VStack(spacing: 0) {
                    ForEach(currencies, id: \.symbol) { currency in
                        Button(action: {
                            timeManager.setCurrency(currency.symbol)
                            showSelector = false
                        }) {
                            HStack {
                                Text("\(currency.symbol) \(currency.name)")
                                    .padding(.vertical, 10)
                                
                                Spacer()
                                
                                if timeManager.settings.currency == currency.symbol {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }
                        .foregroundColor(.primary)
                        
                        if currency.symbol != currencies.last?.symbol {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.2), radius: 5)
                )
                .padding(.horizontal)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showSelector)
            }
        }
    }
}

// 货币模型
struct Currency {
    let symbol: String
    let name: String
}
