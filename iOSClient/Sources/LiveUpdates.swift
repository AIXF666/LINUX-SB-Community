import Foundation

enum LiveUpdates {
    static let script = #"""
    (()=>{
      if(location.hostname!=='linux.sb'||document.getElementById('sb-live-update'))return;
      const home=location.pathname==='/'||location.pathname==='/index.php'||location.pathname==='/topic_featured'||/^\/forum\/\d+\/?$/.test(location.pathname);
      const topic=/^\/topic\/\d+\/?$/.test(location.pathname);
      if(!home&&!topic)return;
      const sample=doc=>topic?Array.from(doc.querySelectorAll('.topic-post-list .post-entry')).map(e=>e.id).filter(Boolean).sort().join('|')+'#'+(doc.querySelector('.post-content-stats')?.textContent.match(/\d+/g)?.[1]||'0'):
        Array.from(doc.querySelectorAll('.forum-main a.post-title[href^="/topic/"]')).slice(0,5).map(a=>a.getAttribute('href')).join('|');
      let baseline=sample(document),running=false,stopped=false;
      const bar=document.getElementById('sb-client-tabs');if(!bar)return;
      const info=document.createElement('aside');info.id='sb-live-update';info.hidden=true;info.setAttribute('role','status');
      const message=document.createElement('span'),refresh=document.createElement('button'),close=document.createElement('button');refresh.type=close.type='button';refresh.textContent=topic?'查看新评论':'查看新帖子';close.textContent='×';close.setAttribute('aria-label','关闭');info.append(message,refresh,close);document.body.append(info);
      const style=document.createElement('style');style.textContent=`#sb-live-update{position:fixed;z-index:170;top:calc(126px + env(safe-area-inset-top));left:20px;right:20px;display:flex;align-items:center;gap:10px;padding:8px 12px 8px 16px;border-radius:14px;background:#334155;color:#fff;box-shadow:0 8px 24px #0f172a24;font:14px -apple-system,BlinkMacSystemFont,sans-serif}#sb-live-update[hidden]{display:none!important}#sb-live-update span{flex:1}#sb-live-update button{min-height:40px;border:0;border-radius:10px;padding:6px 10px;background:#ffffff1c;color:#fff;font:inherit}#sb-live-update button:active{transform:scale(.97)}@media(prefers-reduced-motion:reduce){#sb-live-update button:active{transform:none}}`;
      document.head.append(style);
      refresh.onclick=()=>{try{sessionStorage.setItem('sb-client-restore-scroll',String(scrollY))}catch(e){}location.reload()};close.onclick=()=>{info.hidden=true};
      const restore=()=>{try{const y=sessionStorage.getItem('sb-client-restore-scroll');if(y!==null){sessionStorage.removeItem('sb-client-restore-scroll');scrollTo(0,Number(y)||0)}}catch(e){}};
      if(document.readyState==='complete')restore();else window.addEventListener('load',restore,{once:true});
      const poll=async()=>{
        if(stopped)return;if(document.visibilityState==='hidden'){setTimeout(poll,1000);return}if(running){setTimeout(poll,1000);return}running=true;
        try{const response=await fetch(location.href,{credentials:'same-origin',cache:'no-store',headers:{'X-Requested-With':'XMLHttpRequest'}});if(!response.ok)throw new Error('refresh');const fresh=sample(new DOMParser().parseFromString(await response.text(),'text/html'));if(baseline&&fresh&&baseline!==fresh){message.textContent=topic?'这篇帖子有新评论':'有新帖子';info.hidden=false;baseline=fresh}}
        catch(e){}finally{running=false;if(!stopped)setTimeout(poll,1000)}
      };
      setTimeout(poll,1000);document.addEventListener('visibilitychange',()=>{if(!document.hidden&&!stopped)setTimeout(poll,0)});window.addEventListener('pagehide',()=>{stopped=true},{once:true});
    })();
    """#
}
