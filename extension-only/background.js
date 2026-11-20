'use strict';

// Screenshots stay in this worker's memory and disappear when it stops.
const previews = new Map();
const MAX_PREVIEWS = 20;
let captureTimer;
let lastCaptureAt = 0;
let captureInFlight = false;
let opening = false;
let session = null;
let queuedCycles = 0;

async function captureActive(tabId, windowId) {
  if (captureInFlight) return;
  captureInFlight = true;
  try {
    const [tab, win] = await Promise.all([chrome.tabs.get(tabId), chrome.windows.get(windowId)]);
    if (!tab.active || !win.focused || !/^https?:/.test(tab.url || '')) return;
    const data = await chrome.tabs.captureVisibleTab(windowId, {format: 'jpeg', quality: 45});
    const active = await chrome.tabs.query({active: true, windowId});
    if (active[0]?.id !== tabId) return;
    const bitmap = await createImageBitmap(await (await fetch(data)).blob());
    const width = Math.min(bitmap.width, 440);
    const canvas = new OffscreenCanvas(width, Math.max(1, Math.round(bitmap.height * width / bitmap.width)));
    canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    bitmap.close();
    const blob = await canvas.convertToBlob({type: 'image/jpeg', quality: .65});
    const bytes = new Uint8Array(await blob.arrayBuffer());
    let binary = '';
    for (const byte of bytes) binary += String.fromCharCode(byte);
    previews.delete(tabId);
    previews.set(tabId, `data:image/jpeg;base64,${btoa(binary)}`);
    while (previews.size > MAX_PREVIEWS) previews.delete(previews.keys().next().value);
    lastCaptureAt = Date.now();
  } catch (_) { /* Restricted pages or closed tabs have no preview. */ }
  finally { captureInFlight = false; }
}
function scheduleCapture(tabId, windowId) {
  clearTimeout(captureTimer);
  captureTimer = setTimeout(() => captureActive(tabId, windowId), Math.max(700, 1100 - (Date.now() - lastCaptureAt)));
}
chrome.tabs.onActivated.addListener(({tabId, windowId}) => scheduleCapture(tabId, windowId));
chrome.tabs.onUpdated.addListener((tabId, change, tab) => {
  if (change.status === 'complete' && tab.active && tab.windowId != null) scheduleCapture(tabId, tab.windowId);
});
chrome.tabs.onRemoved.addListener(tabId => previews.delete(tabId));
chrome.tabs.query({active:true, lastFocusedWindow:true}).then(tabs => {
  const tab = tabs[0];
  if (tab?.id != null && tab.windowId != null) scheduleCapture(tab.id, tab.windowId);
}).catch(() => {});

async function openSwitcher() {
  if (opening || session) return;
  opening = true;
  try {
    const current = await chrome.windows.getLastFocused({windowTypes: ['normal']});
    if (!current?.id) return;
    const tabs = await chrome.tabs.query({windowId: current.id});
    const ordered = tabs.filter(t => t.id != null).sort((a,b) => (b.lastAccessed || 0) - (a.lastAccessed || 0));
    if (ordered.length < 2) return;
    session = {
      sourceWindowId: current.id,
      tabs: ordered.map(t => ({id:t.id, title:t.title || t.url || 'Tab', favIconUrl:t.favIconUrl || '', preview:previews.get(t.id) || ''})),
      selected: (1 + queuedCycles % ordered.length + ordered.length) % ordered.length,
      popupId: null
    };
    queuedCycles = 0;
    const width = Math.min(1040, Math.max(480, (current.width || 1080) - 40));
    const height = 250;
    const bounds = {width, height};
    if ([current.left, current.top, current.width, current.height].every(Number.isFinite)) {
      bounds.left = Math.round(current.left + (current.width - width) / 2);
      bounds.top = Math.round(current.top + (current.height - height) / 2);
    }
    const popup = await chrome.windows.create({url:'switcher.html', type:'popup', focused:true, ...bounds});
    if (session) session.popupId = popup.id;
  } catch (error) { session = null; queuedCycles = 0; console.error('Could not open switcher:', error.message); }
  finally { opening = false; if (!session) queuedCycles = 0; }
}
chrome.commands.onCommand.addListener(command => {
  if (command !== 'open-switcher' && command !== 'cycle-backward') return;
  const direction = command === 'cycle-backward' ? -1 : 1;
  if (session) {
    session.selected = (session.selected + direction + session.tabs.length) % session.tabs.length;
    chrome.runtime.sendMessage({type: 'cycle', selected: session.selected}).catch(() => {});
  } else if (opening) {
    queuedCycles += direction;
  } else {
    if (direction < 0) queuedCycles = -2;
    void openSwitcher();
  }
});
chrome.action.onClicked.addListener(() => { void openSwitcher(); });
chrome.windows.onRemoved.addListener(id => { if (session?.popupId === id) session = null; });
chrome.runtime.onMessage.addListener((message, sender, respond) => {
  if (sender.id !== chrome.runtime.id || !session) return;
  if (message.type === 'get-session') { respond({tabs: session.tabs, selected: session.selected}); return; }
  if (message.type === 'selection' && Number.isInteger(message.selected) && message.selected >= 0 && message.selected < session.tabs.length) {
    session.selected = message.selected;
    respond({ok:true});
    return;
  }
  if (message.type === 'choose' || message.type === 'cancel') {
    const current = session;
    session = null;
    (async () => {
      if (message.type === 'choose' && current.tabs.some(t => t.id === message.tabId)) {
        try { await chrome.tabs.update(message.tabId, {active:true}); } catch (_) {}
      }
      try { await chrome.windows.update(current.sourceWindowId, {focused:true}); } catch (_) {}
      if (current.popupId != null) try { await chrome.windows.remove(current.popupId); } catch (_) {}
    })().finally(() => respond({ok:true}));
    return true;
  }
});
