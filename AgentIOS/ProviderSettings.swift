import Foundation
import Combine
import Security

@MainActor final class ProviderSettings: ObservableObject {
    @Published var name = "自定义 OpenAI 兼容服务"
    @Published var baseURL = "https://api.openai.com/v1"
    @Published var model = ""
    @Published var apiKey = ""
    private let keychainAccount = "agent-ios-provider-api-key"

    func save() {
        let values = ["name": name, "baseURL": baseURL, "model": model]
        UserDefaults.standard.set(values, forKey: "provider-settings")
        let data = Data(apiKey.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: keychainAccount]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    func load() {
        if let values = UserDefaults.standard.dictionary(forKey: "provider-settings") {
            name = values["name"] as? String ?? name
            baseURL = values["baseURL"] as? String ?? baseURL
            model = values["model"] as? String ?? model
        }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: keychainAccount,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data, let key = String(data: data, encoding: .utf8) { apiKey = key }
    }
}
