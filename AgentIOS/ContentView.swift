import SwiftUI

struct ContentView: View {
    @StateObject private var settings = ProviderSettings()
    @State private var prompt = ""
    @State private var answer = ""
    @State private var busy = false
    @State private var error: String?
    @State private var models: [String] = []
    @State private var reasoning = "medium"

    var body: some View {
        NavigationStack {
            Form {
                Section("模型服务") {
                    TextField("服务商名称", text: $settings.name)
                    TextField("API Base URL", text: $settings.baseURL)
                        .textInputAutocapitalization(.never).keyboardType(.URL)
                    SecureField("API Key", text: $settings.apiKey)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    HStack {
                        TextField("模型名称", text: $settings.model)
                            .textInputAutocapitalization(.never)
                        Button("获取模型") { Task { await loadModels() } }
                            .disabled(busy || settings.apiKey.isEmpty)
                    }
                    if !models.isEmpty {
                        Picker("选择模型", selection: $settings.model) {
                            ForEach(models, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    Button("保存配置") { settings.save() }
                }
                Section("思考强度") {
                    Picker("推理预算", selection: $reasoning) {
                        Text("关闭").tag("off")
                        Text("低").tag("low")
                        Text("中").tag("medium")
                        Text("高").tag("high")
                    }.pickerStyle(.segmented)
                    Text("兼容接口会尝试发送 reasoning_effort；不支持该参数的服务商可能需要关闭思考强度。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Agent 对话") {
                    TextField("输入消息", text: $prompt, axis: .vertical)
                        .lineLimit(2...5)
                    Button(busy ? "正在请求…" : "发送") { Task { await send() } }
                        .disabled(busy || prompt.isEmpty || settings.apiKey.isEmpty || settings.model.isEmpty)
                    if !answer.isEmpty { Text(answer).textSelection(.enabled) }
                    if let error { Text(error).foregroundStyle(.red) }
                }
                Section("工具 / MCP / Skill") {
                    Label("工具调用框架：待接入", systemImage: "wrench.and.screwdriver")
                    Label("远程 MCP：待接入 Streamable HTTP", systemImage: "point.3.connected.trianglepath.dotted")
                    Label("Skill：待接入本地 Markdown 指令包", systemImage: "sparkles")
                }
            }
            .navigationTitle("智能体")
        }
        .task { settings.load() }
    }

    @MainActor private func loadModels() async {
        busy = true; error = nil
        defer { busy = false }
        do { models = try await OpenAICompatibleClient(settings: settings).listModels() }
        catch { self.error = error.localizedDescription }
    }

    @MainActor private func send() async {
        busy = true; error = nil; answer = ""
        defer { busy = false }
        do {
            answer = try await OpenAICompatibleClient(settings: settings).chat(prompt: prompt, reasoning: reasoning)
            prompt = ""
        } catch { self.error = error.localizedDescription }
    }
}
