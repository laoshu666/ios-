# iOS 智能体起步项目

这是 SwiftUI 源码项目，包含用户自填 OpenAI 兼容 API Base URL / API Key、获取 `/models`、模型选择、Keychain 保存 API Key、思考强度选项，以及基础对话请求。

## 当前状态

- API Key 存在 iOS Keychain；模型服务配置存在 UserDefaults。
- 兼容 `/models` 与 `/chat/completions` 的服务可直接尝试使用。
- 思考强度通过 `reasoning_effort` 发送；部分服务商不接受此参数，需要选择“关闭”。
- 当前对话是非流式请求；工具调用、MCP、Skill 在界面中标为待接入，尚未实现。

## 打开与编译

Linux 服务器没有 Xcode，不能在服务器上构建可安装 IPA。把 ZIP 下载到 Mac，安装 XcodeGen 后在项目目录运行：

```sh
xcodegen generate
open AgentIOS.xcodeproj
```

在 Xcode 中选择签名 Team 和 Bundle Identifier，连接 iPhone 或选择归档构建，再导出 IPA。将生成的 `.ipa` 导入全能签进行签名/安装。源代码 ZIP 本身不能作为 IPA 安装包。

## 安全说明

API Key 直接由 iOS App 请求用户配置的服务商，不经过本项目服务器。客户端密钥仍可能被设备所有者提取；不要在此输入他人或组织共享的密钥。


## GitHub Actions 云构建

把整个项目目录推送到 GitHub 仓库后，Actions 会在推送到 `main` / `master` 时构建，也可以在仓库 Actions 页面手动运行 `Build iOS IPA`。完成后从该次运行的 Artifacts 下载 `AgentIOS-unsigned-ipa`，解压得到 `AgentIOS-unsigned.ipa`，再导入全能签完成签名和安装。

此工作流在 macOS runner 上用 Xcode 编译，不上传签名证书或 API Key。首次发布前建议把 `project.yml` 中的示例 Bundle Identifier 改成你自己唯一的标识。
