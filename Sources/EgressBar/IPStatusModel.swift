import AppKit
import Foundation
import Network
import ServiceManagement

@MainActor
final class IPStatusModel: ObservableObject {
    private static let legacyTokenDefaultsKey = "ipinfo.token"
    private static let refreshInterval: TimeInterval = 600

    @Published private(set) var info: IPInfo = .empty
    @Published private(set) var isRefreshing = false
    @Published private(set) var isNetworkAvailable = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var launchAtLoginEnabled = false

    @Published private(set) var token: String

    private let defaults: UserDefaults
    private let monitorQueue = DispatchQueue(label: "egressbar.network-monitor")
    private let decoder = JSONDecoder()

    private var didStart = false
    private var refreshLoopTask: Task<Void, Never>?
    private var pathMonitor: NWPathMonitor?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.token = Self.initialToken(defaults: defaults)

        Task { @MainActor [weak self] in
            self?.start()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
        pathMonitor?.cancel()
    }

    var menuTitle: String {
        if !isNetworkAvailable {
            return "Offline"
        }

        if isRefreshing, locationTitle == nil {
            return "Checking..."
        }

        if let locationTitle {
            return locationTitle
        }

        if errorMessage != nil {
            return "Location unavailable"
        }

        return "Checking..."
    }

    var locationTitle: String? {
        let components = [info.city, info.region, displayCountryCode]
            .compactMap(clean)
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) {
                    result.append(value)
                }
            }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    var displayCountryCode: String? {
        guard let country = clean(info.country) else {
            return nil
        }

        if country.count == 2 {
            return country.uppercased()
        }

        return Self.regionCode(forCountryName: country) ?? country
    }

    var displayCity: String? {
        info.city
    }

    var displayIP: String? {
        info.ip
    }

    var networkStatusText: String {
        isNetworkAvailable ? "Online" : "Offline"
    }

    var lastUpdatedText: String {
        guard let lastUpdated else {
            return "Never"
        }

        return Self.lastUpdatedFormatter.string(from: lastUpdated)
    }

    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        refreshLaunchAtLoginStatus()
        startNetworkMonitor()
        restartRefreshLoop()

        Task {
            await refresh()
        }
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        errorMessage = nil

        do {
            let url = endpointURL()
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 12

            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response: response)

            let decoded = try decoder.decode(IPInfoResponse.self, from: data)
            info = decoded.normalized
            isNetworkAvailable = true
            lastUpdated = Date()
        } catch {
            errorMessage = readableError(error)
            if isNetworkUnavailable(error) {
                isNetworkAvailable = false
            }
        }

        isRefreshing = false
    }

    func copyIP() {
        guard let ip = info.ip else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ip, forType: .string)
    }

    func updateConfiguration(token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try KeychainStore.saveToken(normalizedToken)
            defaults.removeObject(forKey: Self.legacyTokenDefaultsKey)

            self.token = normalizedToken
            errorMessage = nil
        } catch {
            errorMessage = readableError(error)
            return
        }

        restartRefreshLoop()

        Task {
            await refresh()
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            errorMessage = nil
        } catch {
            errorMessage = readableError(error)
        }

        refreshLaunchAtLoginStatus()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    private func endpointURL() -> URL {
        if clean(token) == nil {
            return URL(string: "https://ipinfo.io/json")!
        }

        var components = URLComponents(string: "https://ipinfo.io/json")!
        components.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        return components.url!
    }

    private func restartRefreshLoop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                let interval = UInt64(Self.refreshInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: interval)

                if !Task.isCancelled {
                    await self.refresh()
                }
            }
        }
    }

    private func startNetworkMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                if isOnline {
                    self.isNetworkAvailable = true
                    if self.errorMessage == "Network unavailable" {
                        self.errorMessage = nil
                    }
                    await self.refresh()
                } else {
                    self.isNetworkAvailable = false
                    self.errorMessage = "Network unavailable"
                }
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IPStatusError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw IPStatusError.httpStatus(httpResponse.statusCode)
        }
    }

    private func readableError(_ error: Error) -> String {
        if let statusError = error as? IPStatusError {
            return statusError.localizedDescription
        }

        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Network unavailable"
            case .timedOut:
                return "Request timed out"
            default:
                return urlError.localizedDescription
            }
        }

        return error.localizedDescription
    }

    private func isNetworkUnavailable(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private static func regionCode(forCountryName countryName: String) -> String? {
        let locales = [Locale(identifier: "en_US"), .current]

        for region in Locale.Region.isoRegions {
            let code = region.identifier
            guard code.count == 2 else {
                continue
            }

            for locale in locales {
                guard let localizedName = locale.localizedString(forRegionCode: code),
                      localizedName.caseInsensitiveCompare(countryName) == .orderedSame else {
                    continue
                }

                return code.uppercased()
            }
        }

        return nil
    }

    private static func initialToken(defaults: UserDefaults) -> String {
        if let keychainToken = try? KeychainStore.readToken(),
           let normalizedToken = clean(keychainToken) {
            return normalizedToken
        }

        if let legacyToken = clean(defaults.string(forKey: legacyTokenDefaultsKey)) {
            try? KeychainStore.saveToken(legacyToken)
            defaults.removeObject(forKey: legacyTokenDefaultsKey)
            return legacyToken
        }

        return clean(ProcessInfo.processInfo.environment["IPINFO_TOKEN"]) ?? ""
    }

    private static let lastUpdatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

enum IPStatusError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpStatus(let code):
            return "HTTP \(code)"
        }
    }
}
