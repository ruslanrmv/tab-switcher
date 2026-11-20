(() => {
  const menuId = "rename-tab";
  const editorUrl = chrome.runtime.getURL("rename-tab.html");
  const pending = new Map();
  const storageKey = tabId => `renamedTab:${tabId}`;

  chrome.runtime.onInstalled.addListener(() => {
    try {
      chrome.contextMenus.create({
        id: menuId,
        title: chrome.i18n.getMessage("renameTabMenu"),
        contexts: ["tab"]
      }, () => {
        if (chrome.runtime.lastError) {
          console.debug("Rename tab menu:", chrome.runtime.lastError.message);
        }
      });
    } catch (error) {
      // Older Chromium versions reject the tab context during argument validation.
      console.debug("Rename tab menu:", error.message);
    }
  });

  chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId !== menuId || !tab?.id) return;
    openEditor(tab).catch(error => console.warn("Could not open tab name editor:", error.message));
  });

  async function openEditor(tab) {
    const { left, top, width, height } = await chrome.windows.get(tab.windowId);
    const editorWidth = 420;
    const editorHeight = 235;
    await chrome.windows.create({
      url: `${editorUrl}#${tab.id}`,
      type: "popup",
      width: editorWidth,
      height: editorHeight,
      left: left + Math.round((width - editorWidth) / 2),
      top: top + Math.round((height - editorHeight) / 2),
      focused: true
    });
  }

  chrome.runtime.onMessage.addListener((request, sender, respond) => {
    if (!sender.url?.startsWith(`${editorUrl}#`) || request.action !== "set_tab_name") return;
    const tabId = Number(new URL(sender.url).hash.slice(1));
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
