import SwiftUI
import SwiftSoup

struct AccountEntry: Identifiable {
    var id: String { label }
    let label: String
    let icon: String
}

struct CommunityAccount {
    var name: String
    var avatar: URL?
    var badge: String
    var group: String
    var points: String
    var links: [String: String]
    var profilePath: String = ""

    static func parse(_ doc: Document) throws -> CommunityAccount? {
        let links = try doc.select("a[href]")
        guard let topics = try links.first(where: { try $0.text() == "我的主题" }) else { return nil }
        var panel = topics.parent()
        while let current = panel {
            let enoughLinks = try current.select("a").filter({ try $0.text().hasPrefix("我的") }).count >= 6
            let hasAvatar = try !current.select("img").isEmpty()
            if enoughLinks && hasAvatar { break }
            panel = current.parent()
        }
        guard let panel else { return nil }
        let topicPath = try topics.attr("href")
        let profilePath = topicPath.components(separatedBy: "?").first ?? ""
        let profile = try panel.select("a[href]").first(where: { try $0.attr("href") == profilePath && !$0.text().isEmpty })
        let image = try panel.select("img").first()
        let avatarPath = try image?.attr("src") ?? ""
        let avatar = avatarPath.isEmpty ? nil : URL(string: avatarPath, relativeTo: URL(string: "https://linux.sb")!)?.absoluteURL
        var routes: [String:String] = [:]
        for anchor in try panel.select("a[href]") {
            let label = try anchor.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let href = try anchor.attr("href")
            guard let url = URL(string: href, relativeTo: URL(string: "https://linux.sb")!)?.absoluteURL, url.host == "linux.sb", url.scheme == "https" else { continue }
            routes[label] = url.absoluteString
        }
        let panelText = try panel.text()
        let pattern = "积分\\s*([0-9,]+)"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(panelText.startIndex..., in: panelText)
        let match = regex.firstMatch(in: panelText, range: range)
        let points = match.flatMap { Range($0.range(at: 1), in: panelText) }.map { String(panelText[$0]) } ?? ""
        return CommunityAccount(name: try profile?.text() ?? image?.attr("alt") ?? "社区成员", avatar: avatar, badge: try panel.select(".gacha-title-badge").text(), group: try panel.select(".user-group,.user-uid-badge-group-name,.user-role").text(), points: points, links: routes, profilePath: profilePath)
    }
}

struct AccountCenter: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var account: CommunityAccount?
    @State private var loading = false
    @State private var error: String?
    @State private var loginShown = false
    private let entries = [
        AccountEntry(label: "我的主题", icon: "doc.text"), AccountEntry(label: "我的回帖", icon: "bubble.left"),
        AccountEntry(label: "我的附件", icon: "square.and.arrow.up"), AccountEntry(label: "社区活跃度", icon: "waveform.path.ecg"),
        AccountEntry(label: "我的烧饼", icon: "wallet.bifold"), AccountEntry(label: "我的私信", icon: "bell"),
        AccountEntry(label: "我的称号", icon: "star"), AccountEntry(label: "我的积分", icon: "medal"),
        AccountEntry(label: "我的签名", icon: "doc.text"), AccountEntry(label: "我的广告", icon: "doc.text"),
        AccountEntry(label: "我的淘帖", icon: "doc.text"), AccountEntry(label: "我的收藏", icon: "star"),
        AccountEntry(label: "屏蔽名单", icon: "person"), AccountEntry(label: "我的隐私", icon: "lock"),
        AccountEntry(label: "我的通知", icon: "bell"), AccountEntry(label: "个人设置", icon: "slider.horizontal.3")
    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                profileCard
                if let error { Text(error).font(.footnote).foregroundStyle(.secondary); Button("重新加载") { Task { await refresh() } } }
                if account != nil {
                    NavigationLink { SitePage(path: account?.links["个人设置"] ?? "/profile", title: "编辑资料") } label: { Text("编辑资料").font(.headline).foregroundStyle(.brown).frame(maxWidth: .infinity).padding(16).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16)) }
                }
                HStack(spacing: 12) {
                    if let route = account?.links["我的收藏"] {
                        NavigationLink { SitePage(path: route, title: "我的收藏") } label: { dashboardCard("我的收藏", subtitle: "站内帖子收藏", icon: "bookmark") }
                    } else { Button { loginShown = true } label: { dashboardCard("我的收藏", subtitle: "登录后查看", icon: "bookmark") } }
                    NavigationLink { ClientDraftEditor() } label: { dashboardCard("草稿箱", subtitle: "本机保存的内容", icon: "pencil") }
                }
                Text("我的参与与账户").font(.subheadline).foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(entries.filter { $0.label != "我的收藏" }) { entry in
                        if let route = account?.links[entry.label] {
                            NavigationLink { SitePage(path: route, title: entry.label) } label: { HStack { entryLabel(entry); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }.padding(17) }
                        } else {
                            Button { loginShown = true } label: { entryLabel(entry).opacity(account == nil ? 0.65 : 0.4).padding(17) }.disabled(account != nil)
                        }
                        if entry.label != entries.last?.label { Divider().padding(.leading, 52) }
                    }
                }.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                Divider()
                HStack {
                    NavigationLink { SitePage(path: "/topic_edit", title: "发表主题") } label: { Label("发表主题", systemImage: "square.and.pencil") }
                }.font(.subheadline)
            }
            .padding(4)
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await refresh() }
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await refresh() } } }
        .toolbar { if loading { ProgressView() } else if account != nil { NavigationLink { SitePage(path: account?.links["个人设置"] ?? "/profile", title: "个人设置") } label: { Image(systemName: "gearshape") } } }
        .sheet(isPresented: $loginShown, onDismiss: { Task { await refresh() } }) {
            NavigationStack {
                SitePage(path: "/login", title: "登录 LINUX SB")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { loginShown = false } } }
            }
        }
    }
    private func dashboardCard(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title).foregroundStyle(.brown)
            VStack(alignment: .leading, spacing: 6) { Text(title).font(.headline).foregroundStyle(.primary); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, minHeight: 78, alignment: .leading).padding(14).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
    private func entryLabel(_ entry: AccountEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon).font(.system(size: 18)).foregroundStyle(.secondary).frame(width: 24)
            Text(entry.label).font(.body).foregroundStyle(.primary)
        }.frame(maxWidth: .infinity, minHeight: 30, alignment: .leading).padding(.vertical, 3).contentShape(Rectangle())
    }
    @ViewBuilder private var profileCard: some View {
        if let account {
            HStack(spacing: 16) {
                AsyncImage(url: account.avatar) { image in image.resizable().scaledToFill() } placeholder: { Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.secondary) }
                    .frame(width: 84, height: 84).clipShape(Circle())
                VStack(alignment: .leading, spacing: 8) {
                    NavigationLink { SitePage(path: account.profilePath, title: account.name) } label: { HStack { Text(account.name).font(.title.bold()).foregroundStyle(.primary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) } }
                    Text("UID \(account.profilePath.split(separator: "/").last.map(String.init) ?? "")").font(.subheadline).foregroundStyle(.secondary)
                    if !account.badge.isEmpty { Text(account.badge).font(.subheadline.bold()).foregroundStyle(.orange).padding(.horizontal, 9).padding(.vertical, 4).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 7)) }
                    HStack { if !account.group.isEmpty { Text(account.group).foregroundStyle(.orange) }; if !account.points.isEmpty { Text("积分 \(account.points)").foregroundStyle(.secondary) } }.font(.subheadline)
                }
            }
        } else {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 64)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text(loading ? "读取账户中" : "登录社区").font(.title2.bold())
                    Text("在 App 内完成登录和人机验证").font(.caption).foregroundStyle(.secondary)
                    Button("登录 LINUX SB") { loginShown = true }.buttonStyle(.borderedProminent)
                }
            }
        }
    }
    private func refresh() async {
        guard !loading else { return }; loading = true; defer { loading = false }
        do { account = try CommunityAccount.parse(await ForumService.document("/")); error = nil }
        catch { self.error = error.localizedDescription }
    }
}
