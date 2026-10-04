import SwiftUI

struct MessagesCenter: View {
    @State private var account: CommunityAccount?
    @State private var loaded = false
    @State private var error: String?
    var path: String? { account?.links["我的通知"] }
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("通知").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 11))
                Text("聊天").foregroundStyle(.tertiary).frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityLabel("本站尚未确认提供独立聊天功能")
            }.padding(4).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 18)
            if let path {
                SitePage(path: path, title: "消息").id(path)
            } else if !loaded { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
            else {
                ContentUnavailableView {
                    Label("登录后查看消息", systemImage: "bell")
                } description: { Text(error ?? "在 App 内登录社区后查看通知。") }
                actions: { NavigationLink("登录社区") { SitePage(path: "/login", title: "登录") }; Button("刷新状态") { Task { await load() } } }
            }
        }.navigationTitle("消息").navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }
    private func load() async {
        do { account = try CommunityAccount.parse(await ForumService.document("/")); error = nil }
        catch { self.error = error.localizedDescription }
        loaded = true
    }
}

enum MessagesWebDesign {
    static let script = #"""
    (()=>{
      const notifications=/^\/user\/\d+\/?$/.test(location.pathname)&&new URLSearchParams(location.search).get('tab')==='notifications';
      if(!notifications&&!location.pathname.startsWith('/direct_messages'))return;
      const style=document.createElement('style');style.id='client-messages-design';style.textContent=`
      body{font-family:-apple-system,BlinkMacSystemFont,sans-serif}
      .bar,.header,.footer,.sidebar,.breadcrumb,.forum-enhancements-left,.forum-enhancements-left-region{display:none!important}
      .wrap,.home-shell,.forum-layout,.forum-main,.main-panel{display:block!important;max-width:100%!important;width:100%!important;margin:0!important;padding:0!important;border:0!important;box-shadow:none!important}
      .notification-list,.notify-list,.direct-messages-list{list-style:none!important;padding:0!important;margin:0!important}
      .notification-item,.notify-item,.direct-message-item{padding:18px!important;border-bottom:1px solid var(--line,#8882)!important;border-radius:0!important;line-height:1.6}
      .notification-item img,.notify-item img,.direct-message-item img{width:44px!important;height:44px!important;border-radius:50%!important;object-fit:cover}
      .notification-item a,.notify-item a,.direct-message-item a{font-size:16px;line-height:1.6}
      .notification-item time,.notify-item time,.direct-message-item time{font-size:12px;color:var(--text-muted,#888)}
      .card{border-radius:0!important;box-shadow:none!important}
      .profile-toolbar{display:none!important}
      .forum-main .post-item .post-avatar,.forum-main .post-item .avatar-profile-link{width:44px!important;min-width:44px!important;height:44px!important;min-height:44px!important;max-height:44px!important;flex:0 0 44px!important;overflow:visible!important;align-self:flex-start!important}
      .forum-main .post-item .avatar-profile-link{display:block!important}
      .forum-main .post-item .post-avatar img.avatar-img,.forum-main .post-item .post-avatar img{display:block!important;width:44px!important;min-width:44px!important;max-width:44px!important;height:44px!important;min-height:44px!important;max-height:44px!important;aspect-ratio:1/1!important;border-radius:50%!important;object-fit:cover!important;object-position:center!important;clip-path:circle(50%)!important;margin:0!important;transform:none!important}
      `;document.head.appendChild(style);
    })();
    """#
}
