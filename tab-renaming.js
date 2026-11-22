/*
 * The RotateCcw icon is from Lucide (ISC License).
 * Copyright (c) 2026 Lucide Icons and Contributors
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
(() => {
  const menuId = "rename-tab";
  const editorUrl = chrome.runtime.getURL("rename-tab.html");
  const pending = new Map();
  const storageKey = tabId => `renamedTab:${tabId}`;

  function ensureMenu() {
    const properties = { title: chrome.i18n.getMessage("renameTabMenu"), contexts: ["tab"] };
    try {
      chrome.contextMenus.update(menuId, properties, () => {
        if (!chrome.runtime.lastError) return;
        chrome.contextMenus.create({ id: menuId, ...properties }, () => {
          if (chrome.runtime.lastError) console.debug("Rename tab menu:", chrome.runtime.lastError.message);
        });
      });
    } catch (error) {
      console.debug("Rename tab menu:", error.message);
    }
  }
  chrome.runtime.onInstalled.addListener(ensureMenu);
  ensureMenu();

  chrome.commands.onCommand.addListener(command => {
    if (command !== "rename_current_tab") return;
    chrome.tabs.query({active: true, lastFocusedWindow: true}).then(tabs => {
      if (tabs[0]?.id) return openEditor(tabs[0]);
    }).catch(error => console.warn("Could not open tab name editor:", error.message));
  });

  chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId !== menuId || !tab?.id) return;
    openEditor(tab).catch(error => console.warn("Could not open tab name editor:", error.message));
  });

  async function openEditor(tab) {
    // Chrome does not expose the tab-strip text field. Keep editing over the page.
    const key = storageKey(tab.id);
    const { [key]: saved } = await chrome.storage.session.get(key);
    await chrome.tabs.update(tab.id, {active: true});
    try {
      await chrome.scripting.executeScript({target: {tabId: tab.id}, func: showInlineEditor,
        args: [tab.url, saved?.url === tab.url ? saved.name : (tab.title || ""), Boolean(saved?.name)]});
    } catch {
      // Restricted Chrome pages cannot host extension UI; show the existing explanation.
      const { left, top, width, height } = await chrome.windows.get(tab.windowId);
      await chrome.windows.create({url: `${editorUrl}#${tab.id}`, type: "popup", width: 420, height: 235,
        left: left + Math.round((width - 420) / 2), top: top + Math.round((height - 235) / 2), focused: true});
    }
  }

  function showInlineEditor(url, initialName, hasCustomName) {
    document.getElementById('tab-switcher-inline-editor')?.remove();
    const host = document.createElement('div');
    host.id = 'tab-switcher-inline-editor';
    Object.assign(host.style, {position:'fixed', top:'50%', left:'50%', transform:'translate(-50%, -50%)', zIndex:'2147483647'});
    const shadow = host.attachShadow({mode:'closed'});
    shadow.innerHTML = `<style>
      .box{width:min(340px, calc(100vw - 32px));box-sizing:border-box;padding:18px;background:#181927;color:#f7f7ff;border:1px solid #44465d;border-radius:14px;box-shadow:0 12px 44px #0009;font:13px -apple-system,BlinkMacSystemFont,sans-serif}
      label{font-weight:700;font-size:14px;display:block;margin-bottom:9px}input{box-sizing:border-box;width:100%;border:1px solid #55586f;border-radius:8px;background:#272938;color:white;padding:9px;font:inherit;outline:none}input:focus{border-color:#9996ff}
      .actions{display:flex;align-items:center;gap:8px;margin-top:14px}.actions-spacer{flex:1;min-width:0}button{box-sizing:border-box;height:36px;display:inline-flex;align-items:center;justify-content:center;white-space:nowrap;border:0;border-radius:9px;padding:0 13px;background:#333548;color:#f7f7ff;cursor:pointer;font:500 12px -apple-system,BlinkMacSystemFont,sans-serif}button:hover:not(:disabled){filter:brightness(1.12)}button:focus-visible{outline:2px solid #aaa6ff;outline-offset:2px}button[type=submit]{background:#9691ff;color:#161622;font-weight:700}button:disabled{opacity:.35;cursor:default}#reset{width:36px;min-width:36px;padding:0;background:#292b3c}.error:not(:empty){color:#ffaaaa;margin-top:10px;line-height:1.35}
    </style><form class="box"><label for="name"></label><input id="name" maxlength="200" autocomplete="off"><div class="actions">
      <button type="button" id="reset">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
          <path d="M3 3v5h5"/>
        </svg>
      </button>
      <span class="actions-spacer"></span><button type="button" id="cancel"></button><button type="submit"></button></div><div class="error" role="alert"></div></form>`;
    document.documentElement.appendChild(host);
    const input=shadow.querySelector('input'), form=shadow.querySelector('form');
    shadow.querySelector('label').textContent=chrome.i18n.getMessage('tabName');
    shadow.querySelector('#reset').title=chrome.i18n.getMessage('resetTabName');
    shadow.querySelector('#reset').setAttribute('aria-label',chrome.i18n.getMessage('resetTabName'));
    shadow.querySelector('#reset').disabled=!hasCustomName;
    shadow.querySelector('#cancel').textContent=chrome.i18n.getMessage('cancelTabName');
    shadow.querySelector('[type=submit]').textContent=chrome.i18n.getMessage('saveTabName');
    input.value=initialName.slice(0,200); input.focus(); input.select();
    const save = async title => {
      try {
        const result=await chrome.runtime.sendMessage({action:'set_tab_name_inline', url, title});
        if(result?.ok) {host.remove();return;}
        shadow.querySelector('.error').textContent=chrome.i18n.getMessage(result?.error || 'tabRenameUnavailable');
      } catch {shadow.querySelector('.error').textContent=chrome.i18n.getMessage('tabRenameUnavailable');}
    };
    form.addEventListener('submit', event=>{event.preventDefault();if(input.value.trim()) save(input.value);});
    shadow.querySelector('#reset').addEventListener('click',()=>save(''));
    shadow.querySelector('#cancel').addEventListener('click',()=>host.remove());
    form.addEventListener('keydown',event=>{event.stopPropagation();if(event.key==='Escape'){event.preventDefault();host.remove();}});
  }

  chrome.runtime.onMessage.addListener((request, sender, respond) => {
    const inline = request.action === "set_tab_name_inline" && sender.tab?.id && sender.frameId === 0;
    const popup = request.action === "set_tab_name" && sender.url?.startsWith(`${editorUrl}#`);
    if (!inline && !popup) return;
    const tabId = inline ? sender.tab.id : Number(new URL(sender.url).hash.slice(1));
    if (!Number.isInteger(tabId) || tabId <= 0) return;
    enqueue(tabId, () => saveTitle(tabId, request)).then(
      respond,
      () => respond({ error: "tabRenameUnavailable" })
    );
    return true;
  });

  async function saveTitle(tabId, { url, title }) {
    const tab = await chrome.tabs.get(tabId).catch(() => null);
    if (!tab || tab.url !== url || (tab.pendingUrl && tab.pendingUrl !== url)) {
      return { error: "tabChanged" };
    }

    const name = title.trim().replace(/[\t\n\f\r ]+/g, " ").slice(0, 200);
    const applied = await applyTitle(tabId, url, name);
    if (!applied) return { error: "tabChanged" };

    const key = storageKey(tabId);
    if (name) {
      await chrome.storage.session.set({ [key]: { url, name } });
    } else {
      await chrome.storage.session.remove(key);
    }
    return { ok: true };
  }

  chrome.tabs.onUpdated.addListener((tabId, change) => {
    if (!change.url && change.status !== "complete") return;
    enqueue(tabId, async () => {
      const key = storageKey(tabId);
      const { [key]: saved } = await chrome.storage.session.get(key);
      if (!saved) return;
      const tab = await chrome.tabs.get(tabId);
      if (saved.url !== tab.url) {
        await chrome.storage.session.remove(key);
        if (change.url) await applyTitle(tabId, tab.url, "");
      } else if (tab.status === "complete") {
        await applyTitle(tabId, saved.url, saved.name);
      }
    }).catch(() => {}); // The tab may have closed or restricted script access.
  });

  chrome.tabs.onRemoved.addListener(tabId => {
    enqueue(tabId, () => chrome.storage.session.remove(storageKey(tabId))).catch(() => {});
  });

  function enqueue(tabId, operation) {
    const next = (pending.get(tabId) ?? Promise.resolve()).catch(() => {}).then(operation);
    pending.set(tabId, next);
    return next.finally(() => {
      if (pending.get(tabId) === next) pending.delete(tabId);
    });
  }

  async function applyTitle(tabId, url, name) {
    const [injection] = await chrome.scripting.executeScript({
      target: { tabId },
      func: updateDocumentTitle,
      args: [url, name]
    });
    return injection?.result;
  }

  function updateDocumentTitle(expectedUrl, name) {
    if (location.href !== expectedUrl) return false;
    const previous = globalThis.tabSwitcherTitleOverride;
    if (name && previous?.url === expectedUrl && previous.name === name) return true;
    previous?.stop();
    if (!name) return true;

    let original = document.title;
    const observer = new MutationObserver(() => {
      if (location.href !== expectedUrl) {
        stop();
      } else if (document.title !== name) {
        original = document.title;
        document.title = name;
      }
    });

    function stop() {
      observer.disconnect();
      window.removeEventListener("pagehide", stop);
      if (document.title === name) document.title = original;
      delete globalThis.tabSwitcherTitleOverride;
    }

    globalThis.tabSwitcherTitleOverride = { url: expectedUrl, name, stop };
    document.title = name;
    observer.observe(document.head ?? document.documentElement, {
      subtree: true,
      childList: true,
      characterData: true
    });
    window.addEventListener("pagehide", stop, { once: true });
    return true;
  }
})();
