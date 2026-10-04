import Foundation

enum AppNavigationReply {
    static let script = #"""
    (()=>{
      const shell=document.getElementById('sb-client-shell');if(!shell)return;
      const stackKey='sb-client-navigation',restoreKey='sb-client-return-scroll';
      function readStack(){try{return JSON.parse(sessionStorage.getItem(stackKey)||'[]').filter(x=>x&&typeof x.url==='string'&&new URL(x.url,location.href).origin===location.origin).slice(-40)}catch(e){return []}}
      function writeStack(stack){try{sessionStorage.setItem(stackKey,JSON.stringify(stack))}catch(e){}}
      function remember(){const stack=readStack();const current={url:location.href,scroll:scrollY};if(stack[stack.length-1]?.url===current.url)stack[stack.length-1]=current;else stack.push(current);writeStack(stack)}
      document.addEventListener('click',event=>{const link=event.target.closest('a[href]');if(!link||link.hasAttribute('download'))return;const destination=new URL(link.href,location.href);if(destination.origin!==location.origin||destination.href===location.href)return;remember()},true);
      const back=document.getElementById('sb-client-back');
      back.innerHTML='<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"><path d="m15 5-7 7 7 7"/></svg>';
      back.setAttribute('aria-label','返回上一层页面');
      if(location.pathname==='/'&&!location.hash)back.style.visibility='hidden';
      back.onclick=()=>{const stack=readStack();let entry;while(stack.length){const candidate=stack.pop();if(candidate.url!==location.href){entry=candidate;break}}writeStack(stack);if(entry){try{sessionStorage.setItem(restoreKey,JSON.stringify(entry))}catch(e){}location.assign(entry.url)}else location.assign('/')};
      try{const restore=JSON.parse(sessionStorage.getItem(restoreKey)||'null');if(restore&&restore.url===location.href){sessionStorage.removeItem(restoreKey);requestAnimationFrame(()=>scrollTo(0,Math.max(0,Number(restore.scroll)||0)))}}catch(e){}
      if(!/^\/topic\/\d+/.test(location.pathname))return;
      function findReplyPanel(){const textarea=document.querySelector('#reply textarea[name=body],.reply-panel textarea[name=body],form.ajax-reply-form textarea[name=body],form[action*="reply"] textarea[name=body]');if(!textarea||textarea.disabled)return null;return textarea.closest('#reply,.reply-panel')||textarea.closest('form')}
      let panel=findReplyPanel();
      const bottom=document.getElementById('sb-client-tabs');
      const css=document.createElement('style');css.textContent=`
      #sb-client-tabs.sb-topic-actions{justify-content:flex-start;align-items:center;gap:12px;padding-inline:18px}.sb-reply-open{flex:1;text-align:left;border:0;border-radius:22px;background:#f1f5f9;color:#64748b;padding:11px 16px;font:inherit;font-size:15px;min-height:44px}.sb-show-replies{background:none;border:0;color:#334155;font:inherit;min-height:44px}
      #sb-reply-scrim{position:fixed;inset:0;z-index:210;background:rgba(15,23,42,.35)}
      #sb-reply-sheet{position:fixed;z-index:211;bottom:0;left:0;right:0;background:var(--panel,#fff);color:var(--text,#19191b);border-radius:24px 24px 0 0;box-shadow:0 -12px 44px #0f172a20;padding:0 18px calc(14px + env(safe-area-inset-bottom));max-height:82svh;display:flex;flex-direction:column;will-change:transform}
      #sb-reply-sheet[hidden],#sb-reply-scrim[hidden]{display:none!important}
      .sb-reply-grab{height:24px;display:grid;place-items:center;touch-action:none;flex:none}.sb-reply-grab::after{content:'';height:4px;width:34px;border-radius:4px;background:#cbd5e1}
      .sb-reply-heading{display:flex;align-items:center;justify-content:space-between;gap:12px;padding-bottom:10px;flex:none}.sb-reply-heading strong{font-size:17px;overflow-wrap:anywhere}.sb-reply-heading button{width:44px;height:44px;border:0;background:none;color:var(--text-muted,#64748b);font-size:25px}
      .sb-reply-content{overflow-y:auto;overscroll-behavior:contain;min-height:0;max-height:calc(82svh - 90px)}
      #sb-reply-sheet .reply-panel{padding:0!important;margin:0!important;border:0!important;background:none!important}#sb-reply-sheet .reply-panel-head{display:none!important}#sb-reply-sheet textarea{width:100%!important;min-height:120px!important;max-height:220px;font:inherit;font-size:16px;line-height:1.6;border-radius:14px;background:var(--bg,#f1f5f9);padding:12px;box-sizing:border-box}
      #sb-reply-sheet .ajax-reply-form button[type=submit]{min-height:44px;background:#334155;color:#fff;border:0;border-radius:14px;padding:9px 20px;margin-top:10px}
      @media(prefers-reduced-motion:reduce){#sb-reply-sheet{will-change:auto}}`;
      document.head.append(css);
      const scrim=document.createElement('div');scrim.id='sb-reply-scrim';scrim.hidden=true;
      const sheet=document.createElement('section');sheet.id='sb-reply-sheet';sheet.hidden=true;sheet.setAttribute('role','dialog');sheet.setAttribute('aria-modal','true');sheet.setAttribute('aria-labelledby','sb-reply-heading-text');
      sheet.innerHTML='<div class="sb-reply-grab" aria-label="下滑收起回复"></div><div class="sb-reply-heading"><strong id="sb-reply-heading-text">回复话题</strong><button type="button" aria-label="关闭回复">×</button></div><div class="sb-reply-content"></div>';
      document.body.append(scrim,sheet);
      let placeholder=null,oldOverflow='',oldScroll=0,position=0,velocity=0,frame=0,closing=false,lastFocus=null;
      const reduced=()=>matchMedia('(prefers-reduced-motion:reduce)').matches;
      function apply(){sheet.style.transform='translateY('+position+'px)'}
      function finishClose(){sheet.hidden=true;scrim.hidden=true;closing=false;if(panel&&placeholder){placeholder.replaceWith(panel);placeholder=null;panel.style.display='none'}document.body.style.overflow=oldOverflow;scrollTo(0,oldScroll);lastFocus?.focus({preventScroll:true})}
      function settle(target,initialVelocity=0){cancelAnimationFrame(frame);velocity=initialVelocity;let previous=performance.now();if(reduced()){position=target;apply();if(closing)finishClose();return}function step(now){const dt=Math.min(.032,(now-previous)/1000);previous=now;const acceleration=320*(target-position)-36*velocity;velocity+=acceleration*dt;position+=velocity*dt;apply();if(Math.abs(target-position)<.5&&Math.abs(velocity)<2){position=target;apply();if(closing)finishClose();return}frame=requestAnimationFrame(step)}frame=requestAnimationFrame(step)}
      function close(){if(sheet.hidden)return;panel?.querySelector('textarea')?.blur();closing=true;settle(sheet.offsetHeight,velocity)}
      function open(quote){panel=findReplyPanel();if(!panel)return;lastFocus=document.activeElement;const textarea=panel.querySelector('textarea[name=body],textarea');let name=quote?.dataset.username||'';let floor=quote?.dataset.floor||'';sheet.querySelector('strong').textContent=name?'回复 '+name+(floor?' · #'+floor:''):'回复话题';if(quote&&textarea){const mention='@'+name+(/^\d+$/.test(floor)&&Number(floor)>0?' #'+floor:'')+' ';if(!textarea.value.includes(mention)){textarea.value+=(textarea.value&&!textarea.value.endsWith('\n')?'\n':'')+mention;textarea.dispatchEvent(new Event('input',{bubbles:true}))}}
        if(sheet.hidden){oldScroll=scrollY;oldOverflow=document.body.style.overflow;placeholder=document.createElement('div');panel.parentNode.insertBefore(placeholder,panel);sheet.querySelector('.sb-reply-content').append(panel);panel.style.display='block';sheet.hidden=false;scrim.hidden=false;position=reduced()?0:Math.min(sheet.offsetHeight,280);apply()}closing=false;document.body.style.overflow='hidden';settle(0,velocity);textarea?.focus({preventScroll:true});if(textarea)textarea.setSelectionRange(textarea.value.length,textarea.value.length)}
      if(panel)panel.style.display='none';
      scrim.onclick=close;sheet.querySelector('.sb-reply-heading button').onclick=close;
      document.addEventListener('keydown',event=>{if(event.key==='Escape'&&!sheet.hidden)close()});
      document.addEventListener('click',event=>{const quote=event.target.closest('.quote-reply,[data-quick-reply-action]');if(!quote)return;panel=findReplyPanel();if(!panel)return;event.preventDefault();event.stopImmediatePropagation();open(quote.classList.contains('quote-reply')?quote:null)},true);
      const handle=sheet.querySelector('.sb-reply-grab');let dragStart=0,dragBase=0,lastY=0,lastTime=0;
      handle.addEventListener('pointerdown',event=>{cancelAnimationFrame(frame);closing=false;handle.setPointerCapture(event.pointerId);dragStart=lastY=event.clientY;dragBase=position;lastTime=performance.now();velocity=0});
      handle.addEventListener('pointermove',event=>{if(!handle.hasPointerCapture(event.pointerId))return;const now=performance.now();velocity=(event.clientY-lastY)/Math.max(.001,(now-lastTime)/1000);lastY=event.clientY;lastTime=now;position=Math.max(0,dragBase+event.clientY-dragStart);apply()});
      handle.addEventListener('pointerup',event=>{if(!handle.hasPointerCapture(event.pointerId))return;handle.releasePointerCapture(event.pointerId);if(position>sheet.offsetHeight*.22||velocity>650)close();else settle(0,velocity)});
      handle.addEventListener('pointercancel',()=>settle(0,0));
      document.addEventListener('bbs1:reply-saved',close);
      if(bottom){bottom.remove();document.body.style.paddingBottom='24px'}
    })();
    """#
}
