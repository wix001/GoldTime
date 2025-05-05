//
//  CurrencySelector.swift
//  GoldTime
//
//  Created by 徐蔚起 on 03/05/2025.
//

import SwiftUI

struct CurrencySelector: View {
    @EnvironmentObject var timeManager: TimeManager
    @State private var showSelector = false
    @Environment(\.colorScheme) var colorScheme

    // 可选货币类型（使用唯一 ID）
    private let currencies = [
        Currency(id: "CNY", symbol: "¥", name: "人民币"),
        Currency(id: "GBP", symbol: "£", name: "英镑"),
        Currency(id: "USD", symbol: "$", name: "美元"),
        Currency(id: "EUR", symbol: "€", name: "欧元"),
        Currency(id: "JPY", symbol: "¥", name: "日元")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("货币类型")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    withAnimation {
                        showSelector.toggle()
                    }
                }) {
                    HStack {
                        Text(timeManager.settings.currency)
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
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
            .padding(.horizontal)

            if showSelector {
                VStack(spacing: 0) {
                    ForEach(currencies) { currency in
                        Button(action: {
                            timeManager.setCurrency(currency.symbol)
                            withAnimation {
                                showSelector = false
                            }
                        }) {
                            HStack {
                                Text("\(currency.symbol) \(currency.name)")
                                    .padding(.vertical, 10)
                                    .foregroundColor(.primary)

                                Spacer()

                                if timeManager.settings.currency == currency.symbol {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                        }

                        if currency.id != currencies.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Currency 模型，遵循 Identifiable
struct Currency: Identifiable {
    let id: String     // 确保唯一
    let symbol: String
    let name: String
}

struct CurrencySelector_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CurrencySelector()
                .environmentObject(TimeManager())
                .preferredColorScheme(.light)

            CurrencySelector()
                .environmentObject(TimeManager())
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
    }
}

