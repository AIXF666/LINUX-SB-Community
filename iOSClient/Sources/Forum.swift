import SwiftUI
import SwiftSoup
import WebKit

struct ForumTopic: Identifiable, Hashable, Codable {
    var id: String { path }
    let path: String
    let title: String
    let author: String
    let category: String
    let avatar: String
    let meta: String
    var titleColor: String? = nil
    var badges: [String]? = nil
}

enum ForumService {
    static func document(_ path: String) async throws -> Document {
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        for cookie in HTTPCookieStorage.shared.cookies ?? [] where cookie.domain == "linux.sb" || cookie.domain.hasSuffix(".linux.sb") { HTTPCookieStorage.shared.deleteCookie(cookie) }
        for cookie in cookies where cookie.domain == "linux.sb" || cookie.domain.hasSuffix(".linux.sb") { HTTPCookieStorage.shared.setCookie(cookie) }
        let url = URL(string: path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
    }
    static func topics(_ path: String) async throws -> [ForumTopic] {
        let doc = try await document(path)
        return try doc.select("li.post-item").compactMap { item in
            guard let link = try item.select("a.post-title").first() else { return nil }
            let style = try link.attr("style")
            let color = style.split(separator: ";").first { $0.split(separator: ":").first?.trimmingCharacters(in: .whitespaces).lowercased() == "color" }?.split(separator: ":", maxSplits: 1).last.map { String($0).trimmingCharacters(in: .whitespaces) }
            let badges = try item.select(".post-title-row .topic-badge,.post-title-row .topic-stamp-badge,.post-title-row .red-packet-title-status,.post-title-row .card-title-status,.post-title-row .lucky-title-status").map { try $0.text() }
            return try ForumTopic(path: link.attr("href"), title: link.text(), author: item.select(".post-meta a[href^=/user/]").first()?.text() ?? "", category: item.select(".post-forum-meta").text(), avatar: item.select(".avatar-img").attr("src"), meta: item.select(".post-meta").text(), titleColor: color, badges: badges)
        }
    }
    static func posts(_ path: String) async throws -> [(String, String)] {
        let doc = try await document(path)
        return try doc.select(".topic-post-list .post-item").compactMap { item in
            let content = try item.select(".post-content").text()
            guard !content.isEmpty else { return nil }
            return (try item.select(".avatar-img").attr("alt"), content)
        }
    }
}

struct ForumRoot: View {
    @State private var topDestination: TopDestination?
    var body: some View {
        VStack(spacing: 0) {
            HybridTopBar { url, title in topDestination = TopDestination(url: url, title: title) }.frame(height: 106)
        TabView {
            NavigationStack { TopicFeed(path: "/", title: "LINUX SB") }.tabItem { Label("社区", systemImage: "bubble.left.and.bubble.right") }
            NavigationStack { CategoryList() }.tabItem { Label("分类", systemImage: "square.grid.2x2") }
            NavigationStack { NativeSaved() }.tabItem { Label("收藏", systemImage: "star") }
            NavigationStack { MessagesCenter() }.tabItem { Label("消息", systemImage: "bell") }
            NavigationStack { AccountCenter() }.tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        }
        .sheet(item: $topDestination) { destination in
            NavigationStack {
                SitePage(path: destination.url.absoluteString, title: destination.title)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { topDestination = nil } } }
            }
        }
    }
}

struct CategoryList: View {
    let categories = [(1,"错误地方"),(4,"技术交流"),(3,"资源分享"),(2,"福利放送"),(5,"求助问答"),(8,"我要推广"),(6,"社区治理"),(9,"社区公告"),(10,"大禹治水")]
    var body: some View {
        List(categories, id: \.0) { id, name in NavigationLink(name) { TopicFeed(path: "/forum/\(id)", title: name) } }.navigationTitle("社区分类")
    }
}

struct TopicFeed: View {
    let path: String
    let title: String
    @State private var topics: [ForumTopic] = []
    @State private var error: String?
    @State private var loading = false
    @State private var page = 1
    @State private var query = ""
    var visible: [ForumTopic] { query.isEmpty ? topics : topics.filter { $0.title.localizedCaseInsensitiveContains(query) } }
    var body: some View {
        List {
            ForEach(visible) { topic in NavigationLink { TopicReader(topic: topic) } label: { TopicRow(topic: topic) } }
            if let error { Text(error).foregroundStyle(.red); Button("重试") { Task { await load(reset: topics.isEmpty) } } }
            if loading { ProgressView() }
            else { Button("加载更多") { Task { await load(reset: false) } } }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .searchable(text: $query, prompt: "筛选已加载帖子")
        .refreshable { await load(reset: true) }
        .task { if topics.isEmpty { await load(reset: true) } }
    }
    func load(reset: Bool) async {
        guard !loading else { return }; loading = true; error = nil
        defer { loading = false }
        let requested = reset ? 1 : page + 1
        do {
            let result = try await ForumService.topics(path + (path.contains("?") ? "&" : "?") + "p=\(requested)")
            if reset { topics = result } else { let ids = Set(topics.map(\.id)); topics += result.filter { !ids.contains($0.id) } }
            page = requested
        } catch { self.error = error.localizedDescription }
    }
}

struct TopicRow: View {
    let topic: ForumTopic
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: topic.avatar, relativeTo: URL(string: "https://linux.sb"))) { image in image.resizable().scaledToFill() } placeholder: { Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.secondary) }
                .frame(width: 38, height: 38).clipShape(Circle())
            VStack(alignment: .leading, spacing: 7) {
                Text(topic.title).font(.headline).foregroundStyle(topic.titleColor.flatMap(Color.siteCSS) ?? .primary).lineLimit(3)
                if let badges = topic.badges, !badges.isEmpty {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 5) { ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in Text(badge).font(.caption2.bold()).foregroundStyle(badge.contains("红包") ? .red : .orange).padding(.horizontal, 6).padding(.vertical, 3).background((badge.contains("红包") ? Color.red : Color.orange).opacity(0.08), in: Capsule()) } }
                        Text(badges.joined(separator: " · ")).font(.caption2).foregroundStyle(.orange)
                    }
                }
                Text(topic.category).font(.caption).foregroundStyle(.blue)
                Text(topic.meta).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }.padding(.vertical, 5)
        }
    }
}

struct LegacyTextTopicReader: View {
    let topic: ForumTopic
    @State private var posts: [(String, String)] = []
    @State private var error: String?
    @AppStorage("nativeTopics") private var saved = Data()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(topic.title).font(.title2.bold()).foregroundStyle(topic.titleColor.flatMap(Color.siteCSS) ?? .primary)
                Text(topic.meta).font(.caption).foregroundStyle(.secondary)
                if let error { Text(error); Button("重试") { Task { await load() } } }
                if posts.isEmpty && error == nil { ProgressView() }
                ForEach(posts.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(posts[index].0.isEmpty ? (index == 0 ? topic.author : "社区成员") : posts[index].0, systemImage: "person.crop.circle").font(.subheadline.bold())
                        Text(posts[index].1).font(.body).textSelection(.enabled)
                    }
                    Divider()
                }
                NavigationLink("回复帖子") { NativeFormView(path: topic.path, selector: "form.ajax-reply-form", title: "回复") }.buttonStyle(.bordered)
                NavigationLink("活动和完整图文") { SitePage(path: topic.path) }.buttonStyle(.bordered)
            }.padding()
        }
        .navigationTitle("帖子").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { var topics = (try? JSONDecoder().decode([ForumTopic].self, from: saved)) ?? []; topics.removeAll { $0.id == topic.id }; topics.insert(topic, at: 0); saved = (try? JSONEncoder().encode(topics)) ?? Data() } label: { Image(systemName: "star") }.accessibilityLabel("收藏帖子")
            ShareLink(item: URL(string: topic.path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL)
        }
        .task { await load() }
    }
    func load() async { error = nil; do { posts = try await ForumService.posts(topic.path); if posts.isEmpty { error = "未能读取正文，请打开完整图文。" } } catch { self.error = error.localizedDescription } }
}

struct NativeSaved: View {
    @AppStorage("nativeTopics") private var data = Data()
    var topics: [ForumTopic] { (try? JSONDecoder().decode([ForumTopic].self, from: data)) ?? [] }
    var body: some View {
        List { ForEach(topics) { topic in NavigationLink { TopicReader(topic: topic) } label: { TopicRow(topic: topic) } }.onDelete { indexes in var updated = topics; updated.remove(atOffsets: indexes); data = (try? JSONEncoder().encode(updated)) ?? Data() } }
            .overlay { if topics.isEmpty { ContentUnavailableView("暂无收藏", systemImage: "star") } }.navigationTitle("收藏帖子")
    }
}

struct SitePage: View {
    let path: String
    let title: String
    @StateObject private var browser: Browser
    init(path: String, title: String = "社区操作") {
        self.path = path; self.title = title
        _browser = StateObject(wrappedValue: Browser(path: path))
    }
    var body: some View {
        ZStack {
            WebContent(browser: browser)
            if let error = browser.error {
                ContentUnavailableView { Label("页面未能加载", systemImage: "wifi.exclamationmark") }
                    description: { Text(error) }
                    actions: { Button("重试") { browser.open(URL(string: path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL) } }
                    .background(.background)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { if browser.loading { ProgressView(value: browser.progress) } }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!browser.back).accessibilityLabel("网页返回")
                Spacer()
                Button { browser.webView.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!browser.forward).accessibilityLabel("网页前进")
                Spacer()
                Button { browser.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("刷新网页")
            }
        }
    }
}
