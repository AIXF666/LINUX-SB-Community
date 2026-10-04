import SwiftUI

struct ClientDraftEditor: View {
    @AppStorage("clientDraftTitle") private var title = ""
    @AppStorage("clientDraftContent") private var content = ""
    var body: some View {
        Form {
            TextField("标题", text: $title)
            Section("正文 · 支持 Markdown") { TextEditor(text: $content).frame(minHeight: 240) }
            Text("内容自动保存在本机，提交前在社区编辑器选择版块并确认。").font(.footnote).foregroundStyle(.secondary)
            NavigationLink("继续编辑并发布") { WebDraft(title: title, content: content) }.disabled(title.isEmpty && content.isEmpty)
        }.navigationTitle("草稿箱")
    }
}

struct WebDraft: View {
    let title: String
    let content: String
    @StateObject private var browser = Browser(path: "/topic_edit")
    @State private var seeded = false
    var body: some View {
        WebContent(browser: browser).navigationTitle("发表主题")
            .onChange(of: browser.loading) { _, loading in
                guard !loading, !seeded, browser.webView.url?.path == "/topic_edit" else { return }
                let data = try! JSONSerialization.data(withJSONObject: [title, content])
                let args = String(decoding: data, as: UTF8.self)
                browser.webView.evaluateJavaScript("""
                (()=>{const values=\(args);const form=Array.from(document.forms).find(f=>f.querySelector('textarea'));if(!form)return false;const text=form.querySelector('input[name=title],input[type=text]');const body=form.querySelector('textarea');if(text){text.value=values[0];text.dispatchEvent(new Event('input',{bubbles:true}))}body.value=values[1];body.dispatchEvent(new Event('input',{bubbles:true}));return true})()
                """) { result, _ in if result as? Bool == true { seeded = true } }
            }
    }
}
