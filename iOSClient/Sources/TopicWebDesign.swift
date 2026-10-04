import SwiftUI
import WebKit

enum TopicWebDesign {
    static let css = """
    :root{--font-size-md:17px;--font-size-lg:19px;--font-size-xl:26px}
    body{margin:0!important;font-family:-apple-system,BlinkMacSystemFont,sans-serif!important}
    body>header,.header,.bar,.footer,.breadcrumb,.forum-enhancements-left,.forum-enhancements-left-sidebar,.forum-enhancements-sidebar-card,.sidebar,.forum-nav,.forum-more-panel,.back-to-top{display:none!important}
    .wrap,.home-shell,.forum-layout,.forum-main,.main-panel{width:100%!important;max-width:none!important;min-width:0!important;margin:0!important;padding:0!important;display:block!important;box-shadow:none!important;border:0!important;background:var(--panel,var(--bg))!important}
    .forum-enhancements-shell{display:block!important;grid-template-columns:1fr!important;padding:0!important}
    .post-topic-title{display:block!important;padding:22px 20px 18px!important;border:0!important}
    .post-content-title{font-size:27px!important;line-height:1.35!important;font-weight:750!important;margin:0 0 12px!important;overflow-wrap:anywhere}
    .post-content-stats{color:var(--text-muted);font-size:13px!important;margin-top:10px}
    .topic-post-list{padding:0!important;margin:0!important;list-style:none!important}
    .topic-post-list>.post-entry{position:relative!important;display:block!important;padding:22px 18px!important;margin:0 16px 14px!important;border:1px solid var(--line,#e8edf2)!important;border-radius:18px!important;background:var(--panel,var(--bg))!important;overflow:visible!important}
    .topic-post-list>.sb-comments-container{display:block!important;list-style:none!important;margin:0 16px 16px!important;padding:0!important;border:1px solid var(--line,#e8edf2)!important;border-radius:20px!important;background:var(--panel,var(--bg))!important;min-width:0!important;max-width:calc(100% - 32px)!important}
    .sb-comments-items{list-style:none!important;margin:0!important;padding:0!important}
    .topic-post-list .sb-comments-items>.post-entry{position:relative!important;display:block!important;padding:22px 18px!important;margin:0!important;border:0!important;border-bottom:1px solid var(--line,#e8edf2)!important;border-radius:0!important;background:transparent!important;min-width:0!important;overflow:visible!important}
    .topic-post-list .sb-comments-items>.post-entry:last-child{border-bottom:0!important}
    .topic-post-list .sb-comments-items>.post-entry>.post-avatar{position:absolute!important;top:22px!important;left:18px!important;float:none!important;margin:0!important;width:42px!important}
    .topic-post-list>.post-entry>.post-avatar{position:absolute!important;top:22px!important;left:18px!important;float:none!important;margin:0!important;width:42px!important}
    .post-avatar img{width:42px!important;height:42px!important;border-radius:50%!important;object-fit:cover}
    .post-entry>.post-body{display:block!important;min-width:0!important;width:100%!important;overflow:visible!important}
    .topic-post-list>.post-entry>*:not(.post-avatar):not(.post-body),.post-entry>.post-body>*{grid-column:1/-1!important;min-width:0!important;max-width:100%!important}
    .post-entry .post-head{width:auto!important;max-width:calc(100% - 54px)!important;min-width:0!important;min-height:42px!important;display:block!important;margin:0 0 16px 54px!important;padding:0!important}
    .post-info{min-width:0;display:flex!important;align-items:center!important;flex-wrap:wrap!important;gap:6px!important}
    .post-author{font-size:18px!important;font-weight:700!important}
    .post-info{width:100%!important;max-width:100%!important;overflow:visible!important}
    .post-author{max-width:100%!important;white-space:normal!important;overflow-wrap:anywhere}
    .post-info>.post-author{flex:0 0 auto!important;width:auto!important;max-width:100%!important;word-break:normal!important}
    .topic-post-list .post-entry .post-head .post-info{display:flex!important;flex-wrap:wrap!important;white-space:normal!important;overflow:visible!important;gap:6px!important;max-width:100%!important;min-width:0!important;width:100%!important;flex:1 1 100%!important}
    .post-head .post-time{flex:0 0 100%!important;width:auto!important;min-width:0!important;white-space:normal!important;font-size:12px!important;line-height:1.5!important}
    .post-entry .post-meta{display:flex!important;flex-wrap:wrap!important;align-items:center!important;gap:6px 10px!important;line-height:1.6!important}
    .post-entry .post-user-group,.post-entry .topic-op-badge,.post-entry .gacha-title-badge,.post-entry [class*=pinned-badge]{display:inline-flex!important;align-items:center!important;width:auto!important;min-width:max-content!important;max-width:100%!important;white-space:nowrap!important;word-break:normal!important;overflow-wrap:normal!important;line-height:1.4!important}
    .post-entry .post-actions{flex-wrap:wrap!important}
    .post-entry .post-content{clear:both!important;min-width:0!important;width:100%!important;margin:18px 0!important;font-size:17px!important;line-height:1.75!important;overflow-wrap:anywhere}
    .post-entry::after{content:'';display:block;clear:both}
    .post-entry .post-actions,.post-entry .post-footer{clear:both!important;display:flex!important;flex-wrap:wrap!important;align-items:center!important;gap:8px 14px!important;padding-top:14px!important;border-top:1px solid var(--line,#e8edf2)!important;min-width:0!important}
    .post-content p{margin:0 0 16px!important}.post-content img{display:block!important;width:auto!important;max-width:100%!important;height:auto!important;max-height:68svh!important;object-fit:contain!important;margin:12px auto!important;border-radius:10px}
    .post-content pre{max-width:100%;overflow-x:auto;padding:14px!important;border-radius:10px;background:var(--bg,#8881);font-size:13px;line-height:1.6;white-space:pre}
    .post-content table{display:block;max-width:100%;overflow-x:auto}.post-content blockquote{margin:14px 0!important;border-left:3px solid var(--brand,#b08020);padding:8px 14px!important;background:var(--bg,#8881)}
    .post-content video,.post-content iframe{max-width:100%!important}
    .post-entry .post-actions,.post-entry .post-footer,.post-entry .post-signature,.post-entry .quick-reply-main-action{grid-column:1/-1!important}
    .post-entry .post-actions{display:flex!important;align-items:center;gap:14px!important;padding-top:10px}
    .sb-replies-heading{display:block!important;list-style:none;font-size:18px;font-weight:700;padding:18px!important;margin:0!important;border-bottom:1px solid var(--line,#e8edf2)!important}
    .reply-panel{padding:20px!important;margin:0!important;border:0!important;border-radius:0!important}
    .pagination,.pager{padding:16px 20px!important;overflow-x:auto;max-width:100%}
    """
    static var script: String {
        let literal = String(data: try! JSONSerialization.data(withJSONObject: [css]), encoding: .utf8)!
        return """
        if (/^\\/topic\\/\\d+/.test(location.pathname)) {
            const style=document.createElement('style');style.id='linuxsb-client-topic';style.textContent=\(literal)[0];document.head.appendChild(style);
            document.querySelectorAll('.forum-enhancements-left, .forum-enhancements-left-region').forEach(e=>e.style.display='none');
            const list=document.querySelector('.topic-post-list');
            if(list){
                const heading=document.createElement('li');heading.className='sb-replies-heading';heading.textContent='全部回复';
                let scheduled=false;
                const placeHeading=()=>{scheduled=false;const target=list.querySelector(':scope>.post-entry[data-floor]');if(target&&heading.nextElementSibling!==target)list.insertBefore(heading,target)};
                placeHeading();new MutationObserver(()=>{if(!scheduled){scheduled=true;requestAnimationFrame(placeHeading)}}).observe(list,{childList:true});
            }
        }
        """
    }
}

struct TopicReader: View {
    let topic: ForumTopic
    @StateObject private var browser: Browser
    @AppStorage("nativeTopics") private var saved = Data()
    @State private var replyMessage: String?
    init(topic: ForumTopic) {
        self.topic = topic
        _browser = StateObject(wrappedValue: Browser(path: topic.path, topicAppearance: true))
    }
    var bookmarked: Bool { ((try? JSONDecoder().decode([ForumTopic].self, from: saved)) ?? []).contains { $0.id == topic.id } }
    var body: some View {
        ZStack {
            WebContent(browser: browser)
            if let error = browser.error {
                ContentUnavailableView { Label("帖子未能加载", systemImage: "wifi.exclamationmark") }
                    description: { Text(error) }
                    actions: { Button("重试") { browser.open(URL(string: topic.path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL) } }
                    .background(.background)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { if browser.loading { ProgressView(value: browser.progress) } }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 16) {
                Button { focusReply() } label: {
                    Label("回复话题", systemImage: "arrowshape.turn.up.left").frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                }.foregroundStyle(.secondary)
                Button { bookmark() } label: { Image(systemName: bookmarked ? "bookmark.fill" : "bookmark").font(.title2) }.accessibilityLabel(bookmarked ? "取消本地收藏" : "本地收藏")
                Button { browser.reload() } label: { Image(systemName: "arrow.clockwise").font(.title3) }.accessibilityLabel("刷新帖子及评论")
            }.padding(.horizontal, 16).padding(.vertical, 8).background(.regularMaterial)
        }
        .navigationTitle("话题").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                ShareLink(item: URL(string: topic.path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL)
                NavigationLink("原站排版") { SitePage(path: topic.path, title: "帖子") }
                Button("刷新评论") { browser.reload() }
            } label: { Image(systemName: "ellipsis") }.accessibilityLabel("话题操作")
        }
        .alert("回复", isPresented: Binding(get: { replyMessage != nil }, set: { if !$0 { replyMessage = nil } })) { Button("知道了") { replyMessage = nil } } message: { Text(replyMessage ?? "") }
    }
    func focusReply() {
        browser.webView.evaluateJavaScript("""
        (()=>{const box=document.querySelector('.reply-panel');if(!box)return false;box.scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth',block:'start'});const input=box.querySelector('textarea');if(input)input.focus();return true})()
        """) { result, _ in
            if result as? Bool != true { replyMessage = "当前页面没有回复框，请确认登录状态或使用原站排版。" }
        }
    }
    func bookmark() {
        var topics = (try? JSONDecoder().decode([ForumTopic].self, from: saved)) ?? []
        if topics.contains(where: { $0.id == topic.id }) { topics.removeAll { $0.id == topic.id } }
        else { topics.insert(topic, at: 0) }
        saved = (try? JSONEncoder().encode(topics)) ?? Data()
    }
}
