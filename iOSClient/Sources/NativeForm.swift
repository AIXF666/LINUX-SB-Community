import SwiftUI
import SwiftSoup

struct RemoteField: Identifiable {
    var id: String { name }
    let name: String
    let label: String
    let type: String
    let options: [(String, String)]
    let required: Bool
}

struct RemoteForm {
    let action: URL
    let method: String
    let fields: [RemoteField]
    var values: [String: String]
    let verificationRequired: Bool
}

enum FormFailure: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

enum NativeFormService {
    static func load(path: String, selector: String) async throws -> RemoteForm {
        let doc = try await ForumService.document(path)
        guard let form = try doc.select(selector).first() else {
            throw FormFailure.message("当前页面没有可用操作表单，请先在 App 内登录，并确认账户具备操作权限。")
        }
        let base = URL(string: path, relativeTo: URL(string: "https://linux.sb")!)!.absoluteURL
        let actionText = try form.attr("action")
        let action = actionText.isEmpty ? base : URL(string: actionText, relativeTo: base)!.absoluteURL
        guard action.scheme == "https", action.host == "linux.sb" else { throw FormFailure.message("表单地址不属于社区。") }
        var values: [String: String] = [:]
        var fields: [RemoteField] = []
        for element in try form.select("input[name],textarea[name],select[name]") {
            let name = try element.attr("name")
            if element.hasAttr("disabled") || name.isEmpty { continue }
            let type = element.tagName() == "textarea" ? "textarea" : (element.tagName() == "select" ? "select" : try element.attr("type"))
            if ["submit", "button", "file", "reset"].contains(type) { continue }
            var value = try element.val()
            if ["checkbox", "radio"].contains(type), !element.hasAttr("checked") { continue }
            let options = try element.select("option").map { (try $0.attr("value"), try $0.text()) }
            if type == "select", value.isEmpty { value = options.first?.0 ?? "" }
            values[name] = value
            if type == "hidden" || name == "_csrf" { continue }
            let id = try element.attr("id")
            let label = id.isEmpty ? "" : try doc.select("label[for=\"\(id)\"]").text()
            fields.append(RemoteField(name: name, label: label.isEmpty ? labelFor(name) : label, type: type, options: options, required: element.hasAttr("required")))
        }
        return RemoteForm(action: action, method: try form.attr("method").uppercased(), fields: fields, values: values, verificationRequired: !(try form.select(".cf-turnstile,[name=cf-turnstile-response]").isEmpty()))
    }
    static func labelFor(_ name: String) -> String {
        ["title":"标题", "content":"内容", "message":"消息", "fid":"版块", "forum_id":"版块", "username":"用户名", "password":"密码", "q":"关键词", "keyword":"关键词", "bio":"个人简介", "nickname":"昵称"][name] ?? name
    }
    static func submit(_ form: RemoteForm, values: [String:String]) async throws -> String {
        guard !form.verificationRequired else { throw FormFailure.message("此操作需要站点验证，请先在社区页面完成验证。") }
        var request = URLRequest(url: form.action)
        request.httpMethod = form.method == "GET" ? "GET" : "POST"
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let encoded = values.sorted { $0.key < $1.key }.map { ($0.key.addingPercentEncoding(withAllowedCharacters: allowed) ?? "") + "=" + ($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "") }.joined(separator: "&")
        if request.httpMethod == "GET" {
            var components = URLComponents(url: form.action, resolvingAgainstBaseURL: true)!
            components.percentEncodedQuery = [components.percentEncodedQuery, encoded].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "&")
            request.url = components.url
        } else {
            request.httpBody = Data(encoded.utf8)
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://linux.sb", forHTTPHeaderField: "Origin")
        request.setValue(form.action.absoluteString, forHTTPHeaderField: "Referer")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw FormFailure.message("服务器拒绝操作，请刷新页面后重试。") }
        guard let result = try JSONSerialization.jsonObject(with: data) as? [String:Any] else { throw FormFailure.message("服务器返回了未识别的结果，请在社区页面核实操作状态，不要重复提交。") }
        guard result["ok"] as? Bool == true else { throw FormFailure.message(result["message"] as? String ?? "操作未成功") }
        return result["message"] as? String ?? result["tip"] as? String ?? "服务器已确认操作成功"
    }
}

struct NativeFormView: View {
    let path: String
    let selector: String
    let title: String
    @State private var form: RemoteForm?
    @State private var values: [String:String] = [:]
    @State private var status: String?
    @State private var busy = false
    @State private var completed = false
    var body: some View {
        Form {
            if let form {
                ForEach(form.fields) { field in
                    let binding = Binding(get: { values[field.name] ?? "" }, set: { values[field.name] = $0 })
                    if field.type == "select" {
                        Picker(field.label, selection: binding) { ForEach(field.options, id: \.0) { value, label in Text(label).tag(value) } }
                    } else if field.type == "textarea" {
                        Section(field.label) { TextEditor(text: binding).frame(minHeight: 180) }
                    } else if field.type == "password" { SecureField(field.label, text: binding) }
                    else { TextField(field.label, text: binding) }
                }
                if form.verificationRequired { Text("站点要求完成安全验证。").foregroundStyle(.secondary) }
                Button(completed ? "已提交" : "提交") { Task { await submit() } }.disabled(busy || completed || form.verificationRequired)
            }
            if busy { ProgressView() }
            if let status { Text(status).textSelection(.enabled) }
            if form == nil && !busy { Button("重新读取") { Task { await load() } } }
            NavigationLink("登录或完成站点验证") { SitePage(path: path) }
        }.navigationTitle(title).task { await load() }
    }
    func load() async {
        busy = true; defer { busy = false }
        do { let loaded = try await NativeFormService.load(path: path, selector: selector); form = loaded; values = loaded.values; status = nil }
        catch { status = error.localizedDescription }
    }
    func submit() async {
        guard let form else { return }
        for field in form.fields where field.required && (values[field.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { status = "请填写\(field.label)"; return }
        busy = true; defer { busy = false }
        do { status = try await NativeFormService.submit(form, values: values); completed = true }
        catch { status = error.localizedDescription }
    }
}
