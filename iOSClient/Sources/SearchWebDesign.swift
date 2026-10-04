import Foundation

enum SearchWebDesign {
    static let script = #"""
    (function(){
      if(location.pathname !== '/search' || document.getElementById('client-search-design')) return;
      const candidates=Array.from(document.forms);
      const form=candidates.find(f=>!f.querySelector('input[type=password]') && f.querySelector('input[type=search],input[type=text][name]'));
      if(!form) return;
      const input=form.querySelector('input[type=search],input[type=text][name]');
      if(!input) return;
      document.querySelectorAll('h1,h2').forEach(e=>{if(e.textContent.trim()==='搜索')e.hidden=true});
      document.querySelectorAll('.forum-main a,.main-panel a').forEach(e=>{if(e.textContent.trim()==='用户')e.remove()});
      form.querySelectorAll('select option').forEach(e=>{if(e.textContent.includes('用户'))e.remove()});
      const css=document.createElement('style');css.id='client-search-design';css.textContent=`
      :root{--font-size-md:17px}body{font-family:-apple-system,BlinkMacSystemFont,sans-serif}
      .bar,.header,.footer,.sidebar,.breadcrumb,.forum-enhancements-left,.forum-enhancements-left-region{display:none!important}
      .wrap,.home-shell,.forum-layout,.forum-main,.main-panel{display:block!important;max-width:100%!important;width:100%!important;margin:0!important;padding:0!important;border:0!important;box-shadow:none!important}
      #client-search-shell{padding:12px 18px 24px;background:var(--panel,var(--bg))}
      .client-search-tabs{display:flex;background:var(--bg,#eee);border-radius:12px;padding:4px;gap:4px;margin:0 0 14px}
      .client-search-tabs button{flex:1;border:0;border-radius:9px;padding:10px 3px;font:inherit;background:transparent;color:var(--text,#111)}
      .client-search-tabs button.active{background:var(--panel,#fff);box-shadow:0 1px 4px #0001}.client-search-tabs button:disabled{opacity:.4}
      #client-search-shell input[type=text],#client-search-shell input[type=search]{width:100%!important;box-sizing:border-box;min-height:52px;padding:12px 16px;border:0;border-radius:16px;font-size:18px;background:var(--bg,#eee);color:var(--text,#111)}
      #client-search-shell form{padding:0!important;border:0!important;box-shadow:none!important;margin:0!important}
      #client-search-shell form{display:flex!important;flex-wrap:wrap;gap:8px;align-items:center}#client-search-shell form input[type=text],#client-search-shell form input[type=search]{flex:1;min-width:0;width:auto!important}#client-search-shell form button[type=submit]{border-radius:12px!important;min-height:44px}
      .client-history-head{display:flex;align-items:center;justify-content:space-between;margin:28px 0 8px;font-size:19px;font-weight:700}
      .client-history-head button{border:0;background:transparent;color:var(--brand,#9b771c);font:inherit;font-weight:400}
      .client-history-row{display:flex;gap:12px;align-items:center;padding:16px 0;border-bottom:1px solid var(--line,#8882)}
      .client-history-row button{border:0;background:transparent;color:var(--text,#111);font:inherit;text-align:left}.client-history-row .term{flex:1}.client-history-row .remove{color:var(--text-muted,#888)}
      .client-category-grid{display:flex;flex-wrap:wrap;gap:10px;padding:18px 0}.client-category-grid a{padding:9px 12px;background:#fff3cf;color:#8c681b;border-radius:9px;text-decoration:none}
      .client-search-note{font-size:13px;color:var(--text-muted,#888);padding-top:8px}
      `;document.head.appendChild(css);
      const shell=document.createElement('section');shell.id='client-search-shell';form.parentNode.insertBefore(shell,form);
      shell.appendChild(form);
      form.classList.add('client-search-form');
      input.placeholder='搜索话题和帖子';
      const history=document.createElement('section');history.className='client-search-history';shell.append(history);
      const key='linuxsb.client.searchHistory';
      function read(){try{return JSON.parse(localStorage.getItem(key)||'[]').filter(x=>typeof x==='string').slice(0,20)}catch(e){return []}}
      function write(items){try{localStorage.setItem(key,JSON.stringify(items))}catch(e){}}
      function render(){history.replaceChildren();const head=document.createElement('div');head.className='client-history-head';const label=document.createElement('span');label.textContent='最近搜索';const clear=document.createElement('button');clear.type='button';clear.textContent='清空';clear.onclick=()=>{write([]);render()};head.append(label,clear);history.append(head);
        const terms=read();if(!terms.length){const empty=document.createElement('p');empty.className='client-search-note';empty.textContent='还没有最近搜索';history.append(empty)}
        terms.forEach(term=>{const row=document.createElement('div');row.className='client-history-row';const icon=document.createElement('span');icon.textContent='◷';const btn=document.createElement('button');btn.type='button';btn.className='term';btn.textContent=term;btn.onclick=()=>{input.value=term;form.requestSubmit()};const remove=document.createElement('button');remove.type='button';remove.className='remove';remove.textContent='×';remove.setAttribute('aria-label','删除搜索记录');remove.onclick=()=>{write(read().filter(x=>x!==term));render()};row.append(icon,btn,remove);history.append(row)})}
      form.addEventListener('submit',()=>{const term=input.value.trim();if(term){write([term,...read().filter(x=>x!==term)].slice(0,20))}});render();
    })();
    """#
}
