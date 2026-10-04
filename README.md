# LINUX SB Community

LINUX SB 社区的非官方 iOS 网页客户端。网页承载导航、帖子、评论、搜索、通知和账户界面，WKWebView 保存用户在 App 内建立的登录会话。

## 安装与签名

Release 中 `*-unsigned.ipa` 是 **未签名的 iPhone/iPad 设备包，不能直接安装**。需用自己的 Apple 开发账户签名；开发签名的设备范围与有效期由 Apple 描述文件决定。这不是 App Store、TestFlight 或 Ad Hoc 分发包。

本次设备 Release Archive 无签名构建通过。自动签名失败：Xcode 无法使用配置团队账户，且缺少匹配描述文件。未完成真机安装验证。

## 从源码构建

1. 打开 `iOSClient/LinuxSB.xcodeproj`，选择 LinuxSB scheme。
2. 在 Signing & Capabilities 选择自己的 Team，必要时更换 Bundle Identifier。
3. 选择 iPhone 并运行。最低 iOS 17；站点专用 DNS 代理配置依赖较新的系统能力。
4. 修改工程配置后可使用 XcodeGen：在 `iOSClient` 目录运行 `xcodegen generate`。

包含 SwiftSoup 源码依赖及其 MIT 许可证。源码不包含网站服务端、用户登录 Cookie、密码、签名私钥或描述文件。

## 当前状态与边界

- 圆角、石板蓝、系统字体与深色模式；顶部区域随页面滚动。
- 站内导航加载骨架、回复抽屉、真实站点楼中楼、搜索历史。
- 站点专用 DoH，不改系统 DNS；DNS 不能保证绕过网络连通性限制。
- 称号熔炼和交易的网页确认适配仍需端到端验证。
- 部分页面已在 iOS Simulator 只读检查；实际购买、发布、打赏与全部活动流程 **未完成验证**。本版本为预览版，不承诺所有业务功能可用。
- 不自动点击广告；人机验证与敏感操作由用户完成。

站点 HTML 或插件改变时，客户端适配可能需要更新。请勿把客户端称为站点官方产品。
