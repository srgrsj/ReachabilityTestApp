import Combine
import Foundation
import Reachability

@MainActor
final class ReachabilityDemo: ObservableObject {
    struct Entry: Identifiable {
        let id = UUID()
        let time = Date()
        let channel: String
        let message: String
    }

    @Published private(set) var isMonitoring = false
    @Published private(set) var connection: Reachability.Connection?
    @Published private(set) var entries: [Entry] = []
    @Published private(set) var errorMessage: String?

    private var reachability: Reachability?
    private var observer: NSObjectProtocol?

    init() {
        prepareReachability()
    }

    private func prepareReachability() {
        do {
            let monitor = try Reachability()

            monitor.whenReachable = { [weak self] reachability in
                MainActor.assumeIsolated {
                    self?.receive(reachability, channel: "closure", handler: "whenReachable")
                }
            }
            monitor.whenUnreachable = { [weak self] reachability in
                MainActor.assumeIsolated {
                    self?.receive(reachability, channel: "closure", handler: "whenUnreachable")
                }
            }

            observer = monitor.notificationCenter.addObserver(
                forName: .reachabilityChanged,
                object: monitor,
                queue: nil
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let reachability = notification.object as? Reachability else { return }
                    self?.receive(reachability, channel: "NotificationCenter", handler: "reachabilityChanged")
                }
            }

            reachability = monitor
            errorMessage = nil
            log("Управление", "Создан Reachability 5.2.4. Оба канала подписаны; нажмите «Начать».")
        } catch {
            errorMessage = error.localizedDescription
            log("Ошибка", "Не удалось создать Reachability: \(error)")
        }
    }

    func start() {
        guard !isMonitoring else { return }
        if reachability == nil { prepareReachability() }
        guard let reachability else { return }

        log("Управление", "Вызов startNotifier(): регистрация callback и начальная проверка.")
        do {
            try reachability.startNotifier()
            isMonitoring = true
            errorMessage = nil
        } catch {
            reachability.stopNotifier()
            errorMessage = error.localizedDescription
            log("Ошибка", "startNotifier(): \(error)")
        }
    }

    func stop() {
        guard isMonitoring else { return }
        reachability?.stopNotifier()
        isMonitoring = false
        log("Управление", "stopNotifier(): системная регистрация снята. Состояние на экране — последнее полученное.")
    }

    func clearLog() {
        entries.removeAll()
    }

    private func receive(_ reachability: Reachability, channel: String, handler: String) {
        let current = reachability.connection
        connection = current
        let suffix = isMonitoring ? "" : " · доставка после остановки"
        log(channel, "\(handler) → \(current.description) · main queue\(suffix)")
    }

    private func log(_ channel: String, _ message: String) {
        entries.append(Entry(channel: channel, message: message))
        if entries.count > 200 { entries.removeFirst(entries.count - 200) }
        print("[\(channel)] \(message)")
    }

    deinit {
        reachability?.stopNotifier()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
