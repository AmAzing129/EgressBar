import Foundation
import Security

enum KeychainStore {
    private static let tokenAccount = "ipinfo-token"

    private static var service: String {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return "\(bundleIdentifier).ipinfo"
        }

        return "com.amazing.egressbar.ipinfo"
    }

    static func readToken() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainStoreError.unexpectedStatus(status)
        }

        guard let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainStoreError.invalidData
        }

        return token
    }

    static func saveToken(_ token: String) throws {
        guard let normalizedToken = clean(token) else {
            try deleteToken()
            return
        }

        guard let data = normalizedToken.data(using: .utf8) else {
            throw KeychainStoreError.invalidData
        }

        let attributes = [
            kSecValueData as String: data
        ] as CFDictionary

        let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var query = baseQuery()
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainStoreError.unexpectedStatus(updateStatus)
        }
    }

    private static func deleteToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
    }
}

enum KeychainStoreError: LocalizedError {
    case invalidData
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Keychain item data is invalid"
        case .unexpectedStatus(let status):
            let message = SecCopyErrorMessageString(status, nil)
                .map { String($0) }
                ?? "OSStatus \(status)"
            return "Keychain error: \(message)"
        }
    }
}
