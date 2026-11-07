import Foundation

struct ModelList: Decodable { let data: [ModelEntry] }
struct ModelEntry: Decodable { let id: String }
struct ChatResponse: Decodable { let choices: [Choice] }
struct Choice: Decodable { let message: Message }
struct Message: Decodable { let content: String? }

@MainActor
struct OpenAICompatibleClient {
    let settings: ProviderSettings

    private func endpoint(_ path: String) throws -> URL {
        let base = settings.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        return url
    }
    private func request(_ path: String) throws -> URLRequest {
        var request = URLRequest(url: try endpoint(path))
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        return request
    }
    func listModels() async throws -> [String] {
        let (data, response) = try await URLSession.shared.data(for: request("/models"))
        try validate(response)
        return try JSONDecoder().decode(ModelList.self, from: data).data.map(\.id).sorted()
    }
    func chat(prompt: String, reasoning: String) async throws -> String {
        var req = try request("/chat/completions")
        var body: [String: Any] = ["model": settings.model,
                                   "messages": [["role": "user", "content": prompt]],
                                   "stream": false]
        if reasoning != "off" { body["reasoning_effort"] = reasoning }
        req.httpMethod = "POST"
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response)
        return try JSONDecoder().decode(ChatResponse.self, from: data).choices.first?.message.content ?? "（模型没有返回文本）"
    }
    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "AgentIOS", code: 1, userInfo: [NSLocalizedDescriptionKey: "请求失败。请检查 Base URL、API Key、模型和接口兼容性。"])
        }
    }
}
