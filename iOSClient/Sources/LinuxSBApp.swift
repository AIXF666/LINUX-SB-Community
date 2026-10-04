import SwiftUI
import WebKit
import Network

@main
struct LinuxSBApp: App {
    var body: some Scene { WindowGroup { FullWebClient() } }
}

struct SavedPage: Codable, Identifiable {
    var id: String { url }
    let title: String
    let url: String
}

@MainActor
final class Browser: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView = WKWebView(frame: .zero)
    @Published var title = "LINUX SB"
    @Published var progress = 0.0
    @Published var loading = false
    @Published var back = false
    @Published var forward = false
    @Published var error: String?
    private let topicAppearance: Bool
    private let fullWebClient: Bool
    private var observations: [NSKeyValueObservation] = []
    private var testNavigationPerformed = false
    init(path: String = "/", topicAppearance: Bool = false, fullWeb: Bool = false) {
        self.topicAppearance = topicAppearance
        self.fullWebClient = fullWeb
        super.init()
        if topicAppearance {
            webView.configuration.userContentController.addUserScript(WKUserScript(source: TopicWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        webView.configuration.userContentController.addUserScript(WKUserScript(source: SearchWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        webView.configuration.userContentController.addUserScript(WKUserScript(source: MessagesWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        webView.configuration.userContentController.addUserScript(WKUserScript(source: AppleWebTheme.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if fullWeb {
            webView.configuration.userContentController.addUserScript(WKUserScript(source: TopicWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.configuration.userContentController.addUserScript(WKUserScript(source: FullWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.configuration.userContentController.addUserScript(WKUserScript(source: AppNavigationReply.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.configuration.userContentController.addUserScript(WKUserScript(source: LiveUpdates.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.configuration.userContentController.addUserScript(WKUserScript(source: AppleClientDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.configuration.userContentController.addUserScript(WKUserScript(source: MarketWebDesign.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(reload), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        observations = [
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.sync() } },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.sync() } },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.sync() } },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.sync() } }
        ]
        let initialURL = URL(string: path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL
        if fullWeb {
            SiteDNSProxy.shared.start { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let port):
                    var configuration = ProxyConfiguration(httpCONNECTProxy: .hostPort(host: "127.0.0.1", port: port))
                    configuration.matchDomains = ["linux.sb"]
                    configuration.allowFailover = false
                    self.webView.configuration.websiteDataStore.proxyConfigurations = [configuration]
                    self.open(initialURL)
                case .failure(let error): self.showConnectionError(error)
                }
            }
        } else { open(initialURL) }
    }
    func sync() {
        progress = webView.estimatedProgress
        loading = webView.isLoading
        back = webView.canGoBack
        forward = webView.canGoForward
        title = webView.title ?? "LINUX SB"
        if !loading { webView.scrollView.refreshControl?.endRefreshing() }
    }
    func open(_ url: URL) { error = nil; webView.load(URLRequest(url: url, cachePolicy: fullWebClient ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy)) }
    func home() { open(URL(string: "https://linux.sb/")!) }
    @objc func reload() { error = nil; webView.reload() }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sync(); error = nil
        #if DEBUG
        if ProcessInfo.processInfo.environment["LINUXSB_MARKET_DIAG"] == "1", webView.url?.path == "/gacha_market" {
            webView.evaluateJavaScript("(()=>{const f=Array.from(document.forms).find(f=>f.action.includes('/gacha_market_buy'));if(!f)return null;const accepted=f.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}));return JSON.stringify({accepted,dialog:!!document.getElementById('sb-market-confirm'),dataset:f.dataset,handler:f.getAttribute('onsubmit')})})()") { result, error in print("LINUXSB_MARKET_DIAG \(String(describing: result)) error=\(String(describing: error))"); fflush(stdout) }
        }
        if !testNavigationPerformed, ProcessInfo.processInfo.environment["LINUXSB_TEST_THREADS"] == "1", webView.url?.path.hasPrefix("/topic/") == true {
            testNavigationPerformed = true
            webView.evaluateJavaScript("(()=>{const roots=document.querySelectorAll('.quote-threads-thread-item:not(.quote-threads-child)');const children=document.querySelectorAll('.quote-threads-child');const root=roots[0];if(root)root.scrollIntoView({block:'start'});return {roots:roots.length,children:children.length,collapsed:document.querySelectorAll('.quote-threads-is-collapsed').length}})()") { result, _ in print("LINUXSB_THREAD_LAYOUT \(String(describing: result))"); fflush(stdout) }
        }
        if !testNavigationPerformed, ProcessInfo.processInfo.environment["LINUXSB_TEST_REPLY"] == "1", webView.url?.path.hasPrefix("/topic/") == true {
            testNavigationPerformed = true
            webView.evaluateJavaScript("({open:!!document.querySelector('.sb-reply-open'), panel:!!document.querySelector('#sb-reply-sheet'), route:location.pathname})") { result, error in
                print("LINUXSB_REPLY_UI_PRECHECK \(String(describing: result)) \(String(describing: error))")
                webView.evaluateJavaScript("document.querySelector('.sb-reply-open')?.click();") { opened, openError in
                    print("LINUXSB_REPLY_UI_OPENED \(String(describing: opened)) \(String(describing: openError))")
                    fflush(stdout)
                }
            }
        }
        if !testNavigationPerformed, let target = ProcessInfo.processInfo.environment["LINUXSB_TEST_TAP"], webView.url?.path == "/" {
            testNavigationPerformed = true
            let literal = String(decoding: try! JSONSerialization.data(withJSONObject: [target]), as: UTF8.self)
            webView.evaluateJavaScript("Array.from(document.querySelectorAll('#sb-client-tabs a')).find(a=>a.querySelector('span')?.textContent===\(literal)[0])?.click();", completionHandler: nil)
        }
        if let text = ProcessInfo.processInfo.environment["LINUXSB_TEST_SCROLL"], let offset = Double(text), offset >= 0 {
            webView.evaluateJavaScript("window.scrollTo(0, \(offset));", completionHandler: nil)
        }
        #endif
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError failure: Error) { failed(failure) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError failure: Error) { failed(failure) }
    func failed(_ failure: Error) {
        guard (failure as NSError).code != NSURLErrorCancelled else { return }
        error = failure.localizedDescription
        webView.scrollView.refreshControl?.endRefreshing()
        if fullWebClient { showConnectionError(failure) }
    }
    private func showConnectionError(_ failure: Error) {
        error = failure.localizedDescription
        webView.loadHTMLString("""
        <!doctype html><html lang="zh-CN"><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{font:17px/1.7 -apple-system,sans-serif;margin:0;padding:80px 24px;background:#f8fafc;color:#334155}h1{font-size:24px}p{color:#64748b}a{display:inline-block;background:#334155;color:white;padding:12px 20px;border-radius:14px;text-decoration:none}</style></head><body><h1>暂时无法连接社区</h1><p>指定的加密 DNS 或网络连接暂时不可用。请检查网络后重试。</p><a href="https://linux.sb/">重新连接</a></body></html>
        """, baseURL: nil)
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        let host = url.host?.lowercased() ?? ""
        if url.scheme == "https" && (host == "linux.sb" || host.hasSuffix(".linux.sb")) {
            decisionHandler(.allow)
        } else if action.targetFrame?.isMainFrame != false {
            decisionHandler(.cancel)
            if ["https", "http", "mailto", "tel"].contains(url.scheme ?? "") { UIApplication.shared.open(url) }
        } else { decisionHandler(.allow) }
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil, let url = action.request.url {
            let host = url.host?.lowercased() ?? ""
            if host == "linux.sb" || host.hasSuffix(".linux.sb") { open(url) }
            else if ["https", "http"].contains(url.scheme ?? "") { UIApplication.shared.open(url) }
        }
        return nil
    }
}

struct WebContent: UIViewRepresentable {
    let browser: Browser
    func makeUIView(context: Context) -> WKWebView { browser.webView }
    func updateUIView(_ view: WKWebView, context: Context) {}
}

struct ClientView: View {
    @StateObject private var browser = Browser()
    @AppStorage("savedPages") private var savedData = Data()
    @State private var showSaved = false
    private var pages: [SavedPage] { (try? JSONDecoder().decode([SavedPage].self, from: savedData)) ?? [] }
    var body: some View {
        NavigationStack {
            ZStack {
                WebContent(browser: browser)
                if let error = browser.error {
                    ContentUnavailableView {
                        Label("暂时无法打开", systemImage: "wifi.exclamationmark")
                    } description: { Text(error) } actions: {
                        Button("重试") { browser.reload() }.buttonStyle(.borderedProminent)
                    }.background(.background)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if browser.loading { ProgressView(value: browser.progress).tint(.blue) }
            }
            .navigationTitle("LINUX SB")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { browser.home() } label: { Image(systemName: "house") }.accessibilityLabel("首页")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("收藏当前页面", systemImage: "star") { save() }
                        Button("我的收藏", systemImage: "star.fill") { showSaved = true }
                        if let url = browser.webView.url {
                            ShareLink(item: url) { Label("分享页面", systemImage: "square.and.arrow.up") }
                            Button("在 Safari 中打开", systemImage: "safari") { UIApplication.shared.open(url) }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("页面操作")
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!browser.back).accessibilityLabel("返回")
                    Spacer()
                    Button { browser.webView.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!browser.forward).accessibilityLabel("前进")
                    Spacer()
                    Text(browser.webView.url?.host ?? "linux.sb").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button { browser.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("刷新")
                }
            }
            .sheet(isPresented: $showSaved) {
                NavigationStack {
                    List {
                        ForEach(pages) { page in
                            Button {
                                if let url = URL(string: page.url) { browser.open(url); showSaved = false }
                            } label: {
                                VStack(alignment: .leading) { Text(page.title); Text(page.url).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                            }
                        }.onDelete { offsets in
                            var updated = pages; updated.remove(atOffsets: offsets)
                            savedData = (try? JSONEncoder().encode(updated)) ?? Data()
                        }
                    }
                    .overlay { if pages.isEmpty { ContentUnavailableView("还没有收藏", systemImage: "star", description: Text("通过页面菜单收藏你喜欢的内容。")) } }
                    .navigationTitle("我的收藏")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { showSaved = false } } }
                }
            }
        }
    }
    private func save() {
        guard let url = browser.webView.url?.absoluteString else { return }
        var updated = pages.filter { $0.url != url }
        updated.insert(SavedPage(title: browser.title, url: url), at: 0)
        savedData = (try? JSONEncoder().encode(updated)) ?? Data()
    }
}
