import Foundation

enum MarketWebDesign {
    static let script = #"""
    (()=>{
      if(!location.pathname.startsWith('/gacha'))return;
      const css=document.createElement('style');css.textContent=`
      .main-panel form[method=get],.main-panel .gacha-market-filters{display:grid!important;grid-template-columns:minmax(0,1fr)!important;gap:12px!important;align-items:start!important;height:auto!important;min-height:0!important}
      .main-panel form[method=get] label{display:block!important;height:auto!important;min-height:0!important;margin:0!important;align-self:start!important;flex:none!important}
      .main-panel form[method=get] input,.main-panel form[method=get] select{display:block!important;width:100%!important;height:44px!important;min-height:44px!important;margin-top:6px!important;flex:none!important}
      .main-panel form[method=get]>div{height:auto!important;min-height:0!important;gap:8px!important;align-content:start!important}
      .sb-market-nav{display:flex!important;flex-wrap:wrap!important;gap:6px!important;overflow:visible!important;height:auto!important;white-space:normal!important;padding:12px!important}
      .sb-market-nav a{font-size:12px!important;min-height:34px!important;border-radius:11px!important;padding:7px 10px!important}
      .gacha-market-item,.gacha-market-listing{border-radius:22px!important;padding:16px!important}.gacha-market-item form,.gacha-market-listing form{display:flex!important;gap:10px!important;align-items:center!important;flex-wrap:wrap!important}
      `;document.head.append(css);
      document.querySelectorAll('.main-panel a[href^="/gacha"]').forEach(a=>{const p=a.parentElement;if(p&&p.querySelectorAll(':scope > a').length>2)p.classList.add('sb-market-nav')});
      let approved=null,activeTrade=null;
      function submitTrade(form,submitter,confirm){
        if(form.dataset.sbTradePending==='1')return;
        if(!form.reportValidity())return;
        form.dataset.sbTradePending='1';confirm.disabled=true;confirm.textContent='正在提交…';
        if(submitter?.name){const field=document.createElement('input');field.type='hidden';field.name=submitter.name;field.value=submitter.value;form.append(field)}
        // The user already confirmed above. Submit the original form once, with its CSRF fields,
        // without re-entering browser confirm() or conflicting AJAX submit listeners.
        HTMLFormElement.prototype.submit.call(form);
      }
      document.addEventListener('submit',event=>{
        const form=event.target;const handler=form.getAttribute('onsubmit')||'';const match=handler.match(/gachaMarketConfirm\(this,\s*['"](buy|publish)['"]\)/);if(!match||approved===form)return;
        event.preventDefault();event.stopImmediatePropagation();if(document.getElementById('sb-market-confirm'))return;
        const type=match[1],option=form.querySelector('[name=title_id]')?.selectedOptions[0];const quantity=Number(form.querySelector('[name=quantity]')?.value||0),price=type==='buy'?Number(form.dataset.gachaMarketPrice):Number(form.querySelector('[name=unit_price]')?.value||0);const title=type==='buy'?form.dataset.gachaMarketTitle:option?.dataset.title;if(!title||quantity<1||price<1||!Number.isFinite(quantity*price))return;
        activeTrade={form,submitter:event.submitter};
        const overlay=document.createElement('div');overlay.id='sb-market-confirm';overlay.style.cssText='position:fixed;inset:0;z-index:250;background:#17212d66;display:grid;place-items:center;padding:24px';const dialog=document.createElement('section');dialog.setAttribute('role','dialog');dialog.setAttribute('aria-modal','true');dialog.style.cssText='background:var(--sb-surface);color:var(--sb-text);padding:24px;border-radius:26px;max-width:380px;width:100%';const heading=document.createElement('h2');heading.textContent=type==='buy'?'确认购买':'确认发布';const text=document.createElement('p');text.style.whiteSpace='pre-line';text.textContent='称号：'+title+'\n数量：'+quantity+'\n单价：'+price+' 积分\n总额：'+quantity*price+' 积分'+(type==='publish'?'\n发布后称号将立即托管。':'');const cancel=document.createElement('button');cancel.type='button';cancel.textContent='取消';const confirm=document.createElement('button');confirm.type='button';confirm.textContent=heading.textContent;for(const b of [cancel,confirm])b.style.cssText='min-height:44px;border:0;border-radius:14px;padding:10px 18px;margin:8px 8px 0 0;background:var(--sb-soft);color:var(--sb-text)';const prior=document.activeElement;const close=()=>{overlay.remove();prior?.focus()};cancel.onclick=close;overlay.onclick=e=>{if(e.target===overlay)close()};overlay.onkeydown=e=>{if(e.key==='Escape')close()};confirm.onclick=()=>{close();const original=form.onsubmit;approved=form;try{form.onsubmit=null;form.requestSubmit(event.submitter||undefined)}finally{form.onsubmit=original;approved=null}};dialog.append(heading,text,cancel,confirm);overlay.append(dialog);document.body.append(overlay);cancel.focus();
      },true);
      document.addEventListener('click',event=>{const overlay=document.getElementById('sb-market-confirm');if(!overlay||!activeTrade)return;const buttons=overlay.querySelectorAll('button');if(event.target!==buttons[1])return;event.preventDefault();event.stopImmediatePropagation();submitTrade(activeTrade.form,activeTrade.submitter,buttons[1])},true);
    })();
    """#
}
