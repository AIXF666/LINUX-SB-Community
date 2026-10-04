import SwiftUI
import WebKit

struct TopDestination: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

struct HybridTopBar: UIViewRepresentable {
    let open: (URL, String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(open: open) }
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.isScrollEnabled = false
        web.loadHTMLString(Self.html, baseURL: URL(string: "https://linux.sb/"))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    final class Coordinator: NSObject, WKNavigationDelegate {
        let open: (URL, String) -> Void
        init(open: @escaping (URL, String) -> Void) { self.open = open }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard action.navigationType == .linkActivated || action.navigationType == .formSubmitted else { decisionHandler(.allow); return }
            decisionHandler(.cancel)
            guard let url = action.request.url, url.scheme == "https", url.host == "linux.sb" else { return }
            let names = ["/leaderboard":"用户榜单", "/invite_center":"邀请中心", "/gacha":"称号中心", "/topic_collections":"淘帖中心", "/identity_center":"认证中心", "/search":"搜索", "/color_scheme":"色系切换"]
            open(url, names[url.path] ?? "社区")
        }
    }
    static let html = """
    <!doctype html><html lang="zh-CN"><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><style>
    :root{color-scheme:light dark}*{box-sizing:border-box}body{margin:0;font:15px -apple-system,BlinkMacSystemFont,sans-serif;background:Canvas;color:CanvasText;border-bottom:1px solid #8883}nav{display:flex;gap:24px;overflow-x:auto;white-space:nowrap;padding:15px 16px 10px;scrollbar-width:none}nav::-webkit-scrollbar{display:none}a{color:inherit;text-decoration:none}form{display:flex;gap:8px;padding:4px 14px 12px}input{flex:1;min-width:0;height:35px;border:1px solid #8884;border-radius:8px;padding:0 10px;background:Canvas;color:CanvasText;font:inherit}button,.theme{height:35px;border:1px solid #8884;border-radius:8px;background:Canvas;color:CanvasText;padding:6px 10px;font:inherit}.theme{font-size:20px;line-height:20px}
    </style></head><body><nav aria-label="社区导航"><a href="/leaderboard?type=points">用户榜单</a><a href="/invite_center">邀请中心</a><a href="/gacha">称号中心</a><a href="/topic_collections?tab=everyone">淘帖中心</a><a href="/identity_center">认证中心</a></nav><form><a href="/search" aria-label="搜索" style="flex:1;height:35px;border:1px solid #8884;border-radius:8px;padding:7px 10px;color:#888;display:flex;justify-content:space-between"><span>搜索</span><span>⌕</span></a><a class="theme" href="/color_scheme" aria-label="切换色系">☼</a></form></body></html>
    """
}

extension Color {
    static func siteCSS(_ source: String) -> Color? {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.hasPrefix("#") {
            var hex = String(text.dropFirst())
            if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
            guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
            return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
        }
        let named: [String:Color] = ["red":.red,"blue":.blue,"purple":.purple,"green":.green,"orange":.orange,"black":.primary]
        if let value = named[text] { return value }
        if text.hasPrefix("rgb("), text.hasSuffix(")") {
            let values = text.dropFirst(4).dropLast().split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            if values.count == 3 { return Color(red: values[0]/255, green: values[1]/255, blue: values[2]/255) }
        }
        return nil
    }
}
