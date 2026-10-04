import Foundation

/// Shared visual rules for website content; does not replace forms or activity scripts.
enum AppleWebTheme {
    static let css = #"""
    html{font-optical-sizing:auto;-webkit-text-size-adjust:100%;color-scheme:light dark}
    body{font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',sans-serif;line-height:1.6}
    h1,h2,h3{font-optical-sizing:auto;letter-spacing:-.018em;line-height:1.3}
    button,input,textarea,select{font:inherit;touch-action:manipulation}
    button,a.btn,input[type=submit]{min-height:44px;border-radius:12px}
    input[type=text],input[type=search],input[type=password],input[type=email],textarea,select{border-radius:12px;min-height:44px}
    textarea{line-height:1.7}
    button:active,a.btn:active{transform:scale(.97);filter:brightness(.96)}
    a:focus-visible,button:focus-visible,input:focus-visible,textarea:focus-visible,select:focus-visible{outline:2px solid #a17822;outline-offset:3px}
    img{max-width:100%}pre,code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
    #client-search-design~*{font-optical-sizing:auto}
    .client-search-tabs button{min-height:44px!important}.client-history-row button{min-height:44px!important}
    .topic-post-list>.post-entry{scroll-margin-top:16px}
    @media(prefers-reduced-motion:reduce){html{scroll-behavior:auto!important}*,*::before,*::after{animation-duration:.001ms!important;animation-iteration-count:1!important;transition-duration:.001ms!important}button:active,a.btn:active{transform:none}}
    @media(prefers-contrast:more){button,input,textarea,select{border:1px solid currentColor!important}.client-history-row{border-bottom:1px solid currentColor!important}}
    @media(prefers-reduced-transparency:reduce){.client-material{backdrop-filter:none!important;background:Canvas!important}}
    """#
    static var script: String {
        let literal = String(data: try! JSONSerialization.data(withJSONObject: [css]), encoding: .utf8)!
        return "const clientTheme=document.createElement('style');clientTheme.id='linuxsb-apple-theme';clientTheme.textContent=\(literal)[0];document.head.appendChild(clientTheme);"
    }
}
