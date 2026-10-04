import SwiftUI

/// iOS hosts one persistent website session; all visible client controls are HTML.
struct FullWebClient: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var browser: Browser
    init() {
        #if DEBUG
        let path = ProcessInfo.processInfo.environment["LINUXSB_TEST_PATH"] ?? "/"
        #else
        let path = "/"
        #endif
        _browser = StateObject(wrappedValue: Browser(path: path, fullWeb: true))
    }
    var body: some View {
        WebContent(browser: browser)
            .ignoresSafeArea(.container, edges: .bottom)
            .background(
                (colorScheme == .dark
                    ? Color(red: 16 / 255, green: 23 / 255, blue: 32 / 255)
                    : Color(red: 244 / 255, green: 246 / 255, blue: 249 / 255))
                    .ignoresSafeArea()
            )
    }
}

enum FullWebDesign {
    static let script = #"""
    (()=>{
      if(location.hostname!=='linux.sb'||document.getElementById('sb-client-shell'))return;
      document.documentElement.dataset.sbClientPage=location.pathname==='/login'?'login':location.pathname==='/search'?'search':'community';
      document.documentElement.dataset.sbClientTopic=/^\/topic\/\d+/.test(location.pathname)?'yes':'no';
      const main=document.querySelector('.forum-main')||document.querySelector('.main-panel');
      const card=document.querySelector('.sidebar .user-card,.user-card');
      const style=document.createElement('style');style.textContent=`
      :root{--brand:#334155!important;--brand-hover:#1e293b!important;--brand-soft:#f1f5f9!important;--focus-ring:#33415533!important;--success:#334155!important}
      body{padding-top:calc(112px + env(safe-area-inset-top))!important;padding-bottom:calc(76px + env(safe-area-inset-bottom))!important;font-family:-apple-system,BlinkMacSystemFont,sans-serif!important}
      .bar,body>header,.header,.footer,.sidebar,.forum-enhancements-left,.forum-enhancements-left-region,.forum-nav,.breadcrumb{display:none!important}
      .wrap,.home-shell,.forum-layout,.forum-main,.main-panel{max-width:100%!important;width:100%!important;min-width:0!important;margin:0!important;padding:0!important;border:0!important;box-shadow:none!important;display:block!important}
      html[data-sb-client-page=login] .main-panel{padding:20px!important}
      *,*::before,*::after{box-sizing:border-box}
      .forum-enhancements-shell{display:block!important;grid-template-columns:minmax(0,1fr)!important;min-width:0!important;max-width:100%!important}
      .main-panel{padding:20px!important}
      .main-panel>.post-list{padding:0!important;margin:0!important}
      .main-panel>.post-list>.post-item:not(.post-entry){padding:18px 0!important}
      .post-body,.post-info,.post-title-row{min-width:0!important;max-width:100%!important}
      .post-title-row{flex-wrap:wrap!important}.post-title{overflow-wrap:anywhere!important}
      img,video,iframe{max-width:100%}pre{max-width:100%;overflow-x:auto}table{max-width:100%}
      html[data-sb-client-topic=yes] .main-panel{padding:0!important}
      html[data-sb-client-page=search] .main-panel{padding:0 20px 20px!important}
      html[data-sb-client-page=search] #client-search-shell{padding:12px 0 24px!important}
      .main-panel .profile-toolbar,.main-panel .forum-links{max-width:100%;overflow-x:auto;padding-block:8px}
      .mobile-forum-strip{display:none!important}
      #sb-client-shell{display:block!important;position:fixed;z-index:80;top:0;left:0;right:0;background:rgba(255,255,255,.94);backdrop-filter:blur(20px);padding-top:env(safe-area-inset-top);color:#19191b}
      .sb-client-title{display:flex;justify-content:space-between;align-items:center;min-height:44px;padding:0 16px;font-size:18px;font-weight:650;letter-spacing:-.015em}
      .sb-client-title a,.sb-client-title button{color:#334155;font-size:22px;min-width:44px;min-height:44px;display:grid;place-items:center;border:0;background:none}
      html[data-sb-client-topic=yes] .sb-client-links,html[data-sb-client-topic=yes] .sb-client-tools{display:none!important}
      html[data-sb-client-topic=yes] .topic-post-list>.post-entry{scroll-margin-top:60px}
      .sb-client-links{display:flex;gap:20px;padding:4px 18px;white-space:nowrap;overflow-x:auto;scrollbar-width:none;font-size:13px;color:#68707b}
      .sb-client-links a{min-height:30px;display:flex;align-items:center;text-decoration:none;color:inherit}
      .sb-client-tools{display:flex;gap:8px;padding:4px 18px 9px}.sb-client-search{flex:1;padding:4px 10px;border-radius:9px;background:#f1f5f9;color:#86909d;font-size:13px;text-decoration:none}.sb-client-theme{color:#334155;text-decoration:none;padding:0 8px}
      #sb-client-tabs{position:fixed;z-index:80;bottom:0;left:0;right:0;display:flex;justify-content:space-around;padding:8px 8px calc(8px + env(safe-area-inset-bottom));background:rgba(255,255,255,.94);backdrop-filter:blur(20px);box-shadow:0 -1px 0 #e9edf2;color:#8b929b}
      #sb-client-tabs a{display:grid;place-items:center;gap:3px;min-width:55px;min-height:44px;font-size:11px;text-decoration:none;color:inherit}#sb-client-tabs svg{width:23px;height:23px}#sb-client-tabs a.active{color:#334155;font-weight:650}
      .post-item{padding:18px!important;border-bottom:1px solid var(--line,#ececef)!important;box-shadow:none!important;border-radius:0!important}.post-title{font-size:17px;line-height:1.5;font-weight:650}.post-meta{font-size:12px!important}.post-avatar img{border-radius:50%!important}
      #sb-client-panel{padding:24px 20px}.sb-client-profile{padding-bottom:24px}.sb-client-profile img{width:80px;height:80px;border-radius:50%;object-fit:cover}.sb-client-profile .user-name{font-size:27px;font-weight:750;letter-spacing:-.025em}.sb-client-account-links{display:grid;background:#f3f4f6;border-radius:18px;padding:0 16px;margin-top:20px}.sb-client-account-links a{display:flex;align-items:center;gap:12px;min-height:55px;border-bottom:1px solid #e6e9ee;color:var(--text,#222);text-decoration:none;font-size:16px}.sb-client-account-links a:last-child{border:0}.sb-client-account-links a::after{content:'›';margin-left:auto;color:#9299a1}
      .sb-client-category-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.sb-client-category-grid a{padding:20px 14px;border-radius:16px;background:#f1f5f9;color:#334155;text-decoration:none;font-weight:600}
      .sb-client-profile-row{display:flex;align-items:center;gap:16px}.sb-client-profile img{width:76px!important;height:76px!important;min-width:76px!important;max-width:76px!important;border-radius:50%!important;object-fit:cover!important}.sb-client-profile-details{min-width:0;flex:1}.sb-client-profile-name{font-size:26px;font-weight:750;letter-spacing:-.025em;color:var(--text,#19191b);text-decoration:none;overflow-wrap:anywhere}.sb-client-profile-uid{font-size:13px;color:var(--text-muted,#888);margin-top:4px}.sb-client-profile-details .user-rank{margin-top:8px;font-size:14px}.sb-client-profile-details .gacha-title-badge{margin-top:8px}.sb-client-edit-profile{display:block;margin-top:22px;padding:13px;text-align:center;background:#f1f5f9;color:#334155;border-radius:14px;font-weight:600;text-decoration:none}
      .sidebar-promotions-card,.sidebar-promotions-slot,.sidebar-promotions-controls,[data-sidebar-promotions-click-form]{display:none!important}
      .sb-client-filters{display:flex;overflow-x:auto;white-space:nowrap;padding:14px 18px;gap:0;scrollbar-width:none}.sb-client-filters a{padding:8px 13px;border:1px solid #e6e9ed;margin-left:-1px;font-size:14px;color:var(--text,#555);text-decoration:none;min-height:40px}.sb-client-filters a:first-child{border-radius:9px 0 0 9px;margin-left:0}.sb-client-filters a:last-child{border-radius:0 9px 9px 0}.sb-client-filters a.active{background:#334155;border-color:#334155;color:white}.topic-toolbar{display:none!important}
      .main-panel>.sb-client-filters{padding-inline:0}
      @media(max-width:600px){.sb-client-filters{display:grid!important;grid-template-columns:repeat(4,minmax(0,1fr));gap:6px!important;white-space:normal!important;overflow:visible!important}.sb-client-filters a,.sb-client-filters a:first-child,.sb-client-filters a:last-child{margin:0!important;border-radius:9px!important;text-align:center;padding:9px 4px!important;min-width:0!important}.sb-client-links{gap:14px;flex-wrap:wrap;white-space:normal}.sb-client-links a{white-space:nowrap}}
      #sb-client-tabs a{position:relative}.sb-unread{position:absolute;top:0;right:7px;background:#dc4545;color:white;border-radius:10px;padding:0 5px;min-width:17px;font-size:10px;line-height:17px}
      #sb-notification-banner{position:fixed;z-index:180;top:calc(18px + env(safe-area-inset-top));left:18px;right:18px;padding:15px 16px;background:#334155;color:white;box-shadow:0 12px 36px #0f172a24;border-radius:16px;display:flex;align-items:center;gap:12px}#sb-notification-banner a{color:white;text-decoration:none;flex:1;font-size:14px}#sb-notification-banner button{background:none;border:0;color:white;min-width:40px;min-height:40px}
      #sb-checkin{position:fixed;z-index:200;left:20px;right:20px;top:calc(20px + env(safe-area-inset-top));background:#334155;color:white;padding:18px;border-radius:20px;box-shadow:0 12px 40px #0f172a24;display:flex;align-items:center;gap:14px;animation:sb-checkin-in .35s ease-out}
      #sb-checkin .mark{width:42px;height:42px;border-radius:50%;background:#ffffff20;display:grid;place-items:center;font-size:24px;flex:none}#sb-checkin strong{display:block;font-size:17px}#sb-checkin p{font-size:13px;margin:4px 0 0;opacity:.88}#sb-checkin button{background:none;border:0;color:white;min-width:44px;min-height:44px;margin-left:auto}
      @keyframes sb-checkin-in{from{opacity:0;transform:translateY(-12px)}to{opacity:1;transform:translateY(0)}}
      @media(prefers-color-scheme:dark){#sb-client-shell,#sb-client-tabs{background:rgba(22,27,34,.96);color:#d5dce5}.sb-client-search,.sb-client-category-grid a,.sb-client-account-links{background:#202936;color:#d5dce5}#sb-client-tabs a.active{color:#b2c4db}}
      @media(prefers-reduced-motion:reduce){#sb-checkin{animation:none!important}}@media(prefers-reduced-transparency:reduce){#sb-client-shell,#sb-client-tabs{backdrop-filter:none;background:Canvas}}`;
      document.head.appendChild(style);
      const shell=document.createElement('header');shell.id='sb-client-shell';
      const title=/^\/topic\/\d+/.test(location.pathname)?'话题':location.pathname==='/search'?'搜索':location.pathname==='/login'?'登录':new URLSearchParams(location.search).get('tab')==='notifications'?'消息':'LINUX SB';
      shell.innerHTML='<div class="sb-client-title"><button type="button" aria-label="返回" id="sb-client-back">‹</button><strong></strong><a href="/topic_edit" aria-label="发帖">✎</a></div><nav class="sb-client-links"><a href="/leaderboard?type=points">用户榜单</a><a href="/invite_center">邀请中心</a><a href="/gacha">称号中心</a><a href="/topic_collections?tab=everyone">淘帖中心</a><a href="/identity_center">认证中心</a></nav><div class="sb-client-tools"><a class="sb-client-search" href="/search">⌕　搜索</a><a class="sb-client-theme" href="/color_scheme" aria-label="切换色系">☼</a></div>';
      shell.querySelector('strong').textContent=title;shell.querySelector('button').onclick=()=>{if(history.length>1)history.back();else location.href='/'};document.body.prepend(shell);
      const accountLinks=card?Array.from(card.querySelectorAll('a[href]')):[];
      const accountLabel=anchor=>{const copy=anchor.cloneNode(true);copy.querySelectorAll('.notify-badge,.mobile-nav-unread,svg').forEach(e=>e.remove());return copy.textContent.trim().replace(/\s+/g,'')};
      const route=name=>accountLinks.find(a=>accountLabel(a)===name)?.getAttribute('href');
      const notificationBoot=document.querySelector('[data-notification-live-badge]');
      const notice=notificationBoot?.dataset.notificationsUrl||route('我的通知')||'/login';
      const icon=(path)=>'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="'+path+'"/></svg>';
      const tabs=[['话题','/',icon('M4 4h16v13H8l-4 3V4')],['分类','/#client-categories',icon('M4 4h6v6H4z M14 4h6v6h-6z M4 14h6v6H4z M14 14h6v6h-6z')],['搜索','/search',icon('M15 15l5 5 M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0')],['消息',notice,icon('M6 17h12l-2-3V9a4 4 0 0 0-8 0v5l-2 3 M10 20h4')],['我的','/#client-my',icon('M8 7a4 4 0 1 0 8 0 4 4 0 0 0-8 0 M4 21a8 8 0 0 1 16 0z')]];
      const bottom=document.createElement('nav');bottom.id='sb-client-tabs';bottom.setAttribute('aria-label','主导航');tabs.forEach(([name,path,svg])=>{const a=document.createElement('a');a.href=path;a.innerHTML=svg;const span=document.createElement('span');span.textContent=name;a.append(span);if((name==='搜索'&&location.pathname==='/search')||(name==='消息'&&location.search.includes('tab=notifications'))||(name==='话题'&&location.pathname==='/'&&!location.hash))a.className='active';bottom.append(a)});document.body.appendChild(bottom);
      bottom.addEventListener('click',event=>{const link=event.target.closest('a[href]');if(!link)return;const destination=new URL(link.href,location.href);if(destination.origin!==location.origin)return;event.preventDefault();event.stopImmediatePropagation();location.assign(destination.href)},true);
      const measureChrome=()=>{document.body.style.setProperty('padding-top','0px','important');if(!bottom.isConnected){document.body.style.setProperty('padding-bottom','24px','important');return}const rect=bottom.getBoundingClientRect();document.body.style.setProperty('padding-bottom',(rect.height+Math.max(0,innerHeight-rect.bottom)+12)+'px','important')};new ResizeObserver(measureChrome).observe(shell);new ResizeObserver(measureChrome).observe(bottom);measureChrome();
      if(main && (location.pathname==='/' || location.pathname==='/index.php' || location.pathname==='/topic_featured' || /^\/forum\/\d+/.test(location.pathname))){
        const filters=[['新评论','/index.php?sort=comment'],['新帖子','/index.php?sort=post'],['精华','/topic_featured'],['抽奖','/index.php?sort=lucky'],['发卡','/index.php?sort=card'],['红包','/index.php?sort=red_packet'],['足迹','/unread_topic_notice_footprint'],['申精','/topic_essence_review_list']];const filterNav=document.createElement('nav');filterNav.className='sb-client-filters';filterNav.setAttribute('aria-label','帖子筛选');const sort=new URLSearchParams(location.search).get('sort')||'comment';filters.forEach(([name,path])=>{const a=document.createElement('a');a.href=path;a.textContent=name;if((path.includes('sort='+sort)&&location.pathname!='/topic_featured')||(name==='精华'&&location.pathname==='/topic_featured'))a.className='active';filterNav.append(a)});main.prepend(filterNav);
      }
      function localPanel(){
        const mode=location.hash;if(!main||!['#client-my','#client-categories'].includes(mode))return;
        let panel=document.getElementById('sb-client-panel');if(!panel){panel=document.createElement('section');panel.id='sb-client-panel';main.parentNode.insertBefore(panel,main)}panel.replaceChildren();main.style.setProperty('display','none','important');shell.querySelector('strong').textContent=mode==='#client-my'?'我的':'分类';
        bottom.querySelectorAll('a').forEach(a=>a.classList.toggle('active',a.hash===mode));
        if(mode==='#client-my'){
          if(!card){const login=document.createElement('a');login.href='/login';login.className='btn';login.textContent='登录 LINUX SB';panel.append(login);return}
          const profile=document.createElement('div');profile.className='sb-client-profile';const row=document.createElement('div');row.className='sb-client-profile-row';const img=card.querySelector('img');if(img)row.append(img.cloneNode(true));const details=document.createElement('div');details.className='sb-client-profile-details';const sourceName=accountLinks.find(a=>/^\/user\/\d+$/.test(a.getAttribute('href')||'')&&a.textContent.trim());if(sourceName){const name=document.createElement('a');name.href=sourceName.getAttribute('href');name.className='sb-client-profile-name';name.textContent=sourceName.textContent.trim();details.append(name);const uid=document.createElement('div');uid.className='sb-client-profile-uid';uid.textContent='UID '+sourceName.getAttribute('href').split('/').pop();details.append(uid)}const rank=card.querySelector('.user-rank');if(rank)details.append(rank.cloneNode(true));row.append(details);profile.append(row);const editPath=route('个人设置');if(editPath){const edit=document.createElement('a');edit.href=editPath;edit.className='sb-client-edit-profile';edit.textContent='编辑资料';profile.append(edit)}panel.append(profile);
          const links=document.createElement('div');links.className='sb-client-account-links';const names=['我的主题','我的回帖','我的附件','社区活跃度','我的烧饼','我的私信','我的称号','我的积分','我的签名','我的广告','我的淘帖','我的收藏','屏蔽名单','我的隐私','我的通知','个人设置'];names.forEach(name=>{const source=accountLinks.find(a=>accountLabel(a)===name);if(source){const a=document.createElement('a');a.href=source.getAttribute('href');a.textContent=name;links.append(a)}});panel.append(links);
        }else{const grid=document.createElement('div');grid.className='sb-client-category-grid';const known=new Set();document.querySelectorAll('a[href^="/forum/"]').forEach(source=>{const href=source.getAttribute('href');if(known.has(href))return;known.add(href);const a=document.createElement('a');a.href=href;a.textContent=source.textContent.trim();grid.append(a)});panel.append(grid)}
      }
      window.addEventListener('hashchange',()=>{if(location.hash==='#client-my'||location.hash==='#client-categories')localPanel();else{document.getElementById('sb-client-panel')?.remove();main?.style.removeProperty('display')}});localPanel();
      function checkin(){const text=String(window.__pageFlash||'');if(!text.startsWith('您是')||!text.includes('已帮您完成自动签到'))return;
        const key='sb-client-checkin-'+(route('我的主题')||'account')+'-'+new Date().toLocaleDateString();try{if(sessionStorage.getItem(key))return;sessionStorage.setItem(key,'1')}catch(e){}
        const box=document.createElement('section');box.id='sb-checkin';box.setAttribute('role','status');box.innerHTML='<span class="mark">✓</span><div><strong>今日签到成功</strong><p></p></div><button type="button" aria-label="关闭签到提示">×</button>';box.querySelector('p').textContent=text;box.querySelector('button').onclick=()=>box.remove();document.body.append(box);setTimeout(()=>box.remove(),6000);
      }
      checkin();if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',checkin,{once:true});
      const boot=document.querySelector('[data-notification-live-badge]');
      if(boot && boot.dataset.statusUrl && boot.dataset.notificationsUrl){
        const statusURL=new URL(boot.dataset.statusUrl,location.href),notificationsURL=new URL(boot.dataset.notificationsUrl,location.href);
        if(statusURL.origin===location.origin && notificationsURL.origin===location.origin){
          const messageTab=Array.from(bottom.querySelectorAll('a')).find(a=>a.textContent==='消息');
          const cacheKey='sb-client-unread-'+notificationsURL.pathname;let pending=false;
          async function poll(){if(document.hidden||pending)return;pending=true;try{const response=await fetch(statusURL.href,{headers:{'X-Requested-With':'XMLHttpRequest'},credentials:'same-origin',cache:'no-store'});const data=await response.json();if(!response.ok||!data.ok)return;const count=Math.max(0,Number(data.unread)||0);let badge=messageTab?.querySelector('.sb-unread');if(count){if(!badge&&messageTab){badge=document.createElement('span');badge.className='sb-unread';messageTab.append(badge)}if(badge){badge.textContent=count>99?'99+':String(count);badge.setAttribute('aria-label',count+' 条未读通知')}}else badge?.remove();let previous=0;try{previous=Number(sessionStorage.getItem(cacheKey)||0);sessionStorage.setItem(cacheKey,String(count))}catch(e){}if(count>previous&&!location.search.includes('tab=notifications')){document.getElementById('sb-notification-banner')?.remove();const banner=document.createElement('section');banner.id='sb-notification-banner';banner.setAttribute('role','status');const link=document.createElement('a');link.href=notificationsURL.href;link.textContent='你有 '+count+' 条未读通知 · 点击查看';const close=document.createElement('button');close.type='button';close.textContent='×';close.setAttribute('aria-label','关闭通知提醒');close.onclick=()=>banner.remove();banner.append(link,close);document.body.append(banner);setTimeout(()=>banner.remove(),6000)}}catch(e){}finally{pending=false}}
          poll();const timer=setInterval(poll,30000);document.addEventListener('visibilitychange',()=>{if(!document.hidden)poll()});window.addEventListener('pagehide',()=>clearInterval(timer),{once:true});
        }
      }
    })();
    """#
}
