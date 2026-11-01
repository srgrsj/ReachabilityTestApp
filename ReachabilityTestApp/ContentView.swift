//
//  ContentView.swift
//  ReachabilityTestApp
//
//  Created by Sergei Zhukov on 01.11.2026.
//

import SwiftUI
import Reachability

struct ContentView: View {
    @StateObject private var demo = ReachabilityDemo()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(demo.isMonitoring ? "Наблюдение включено" : "Наблюдение выключено",
                          systemImage: demo.isMonitoring ? "antenna.radiowaves.left.and.right" : "pause.circle")
                        .foregroundStyle(demo.isMonitoring ? .green : .secondary)

                    HStack(spacing: 14) {
                        Image(systemName: connectionSymbol)
                            .font(.largeTitle)
                            .foregroundStyle(connectionColor)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(demo.connection?.description ?? "Ещё нет данных")
                                .font(.title2.bold())
                            Text(demo.isMonitoring ? "Последнее полученное состояние" : "Нажмите «Начать» для наблюдения")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)

                    HStack {
                        Button(action: demo.start) {
                            Label("Начать", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(demo.isMonitoring)

                        Button(action: demo.stop) {
                            Label("Остановить", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!demo.isMonitoring)
                    }

                    if let error = demo.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Reachability.swift · v5.2.4")
                }

                Section("Путь события") {
                    DisclosureGroup("Как доставляется событие") {
                        Text("SystemConfiguration → callback → flags → didSet → notifyReachabilityChanged()")
                            .font(.system(.caption, design: .monospaced))
                        Label("whenReachable / whenUnreachable", systemImage: "1.circle")
                        Label("NotificationCenter", systemImage: "2.circle")
                        Text("Оба канала вызываются на главной очереди. Две записи означают один цикл доставки, а не два изменения сети. Начальная проверка тоже может вызвать событие.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if demo.entries.isEmpty {
                        Text("Журнал пуст")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(demo.entries.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(entry.channel)
                                    .font(.caption.bold())
                                    .foregroundStyle(channelColor(entry.channel))
                                Spacer()
                                Text(entry.time, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Text(entry.message)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 3)
                    }
                } header: {
                    HStack {
                        Text("Журнал · новые сверху")
                        Spacer()
                        Button("Очистить", action: demo.clearLog)
                            .textCase(nil)
                            .disabled(demo.entries.isEmpty)
                    }
                }
            }
            .navigationTitle("Сетевая доступность")
        }
        .onDisappear { demo.stop() }
    }

    private var connectionSymbol: String {
        switch demo.connection {
        case .wifi: "wifi"
        case .cellular: "antenna.radiowaves.left.and.right"
        case .unavailable: "wifi.slash"
        case nil: "questionmark.circle"
        }
    }

    private var connectionColor: Color {
        switch demo.connection {
        case .wifi, .cellular: .green
        case .unavailable: .red
        case nil: .secondary
        }
    }

    private func channelColor(_ channel: String) -> Color {
        switch channel {
        case "closure": .blue
        case "NotificationCenter": .purple
        case "Ошибка": .red
        default: .secondary
        }
    }
}

#Preview {
    ContentView()
}
