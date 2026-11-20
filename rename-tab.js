const tabId = Number(location.hash.slice(1));
const input = document.querySelector("#tab-name");
const reset = document.querySelector("#reset");
const save = document.querySelector("#save");
const error = document.querySelector("#error");
let tabUrl;
let hasCustomName = false;

document.documentElement.lang = chrome.i18n.getUILanguage();
document.title = chrome.i18n.getMessage("renameTab");
for (const element of document.querySelectorAll("[data-message]")) {
  element.textContent = chrome.i18n.getMessage(element.dataset.message);
}

document.querySelector("form").addEventListener("submit", event => {
  event.preventDefault();
  if (!save.disabled) updateName(input.value);
});
input.addEventListener("input", () => { save.disabled = !input.value.trim(); });
reset.addEventListener("click", () => updateName(""));
window.addEventListener("keydown", event => {
  if (event.key === "Escape") window.close();
});

async function initializeEditor() {
  const tab = await chrome.tabs.get(tabId);
  tabUrl = tab.url;
  if (!/^https?:\/\//.test(tabUrl)) {
    showError("tabRenameUnavailable");
    return;
  }
  const key = `renamedTab:${tabId}`;
  const { [key]: saved } = await chrome.storage.session.get(key);
  hasCustomName = saved?.url === tabUrl && Boolean(saved?.name);
  input.value = hasCustomName ? saved.name : (tab.title ?? "").slice(0, input.maxLength);
  setBusy(false);
  input.select();
}

function setBusy(busy) {
  input.disabled = busy;
  save.disabled = busy || !input.value.trim();
  reset.disabled = busy || !hasCustomName;
}

function showError(message) {
  error.textContent = chrome.i18n.getMessage(message);
  error.hidden = false;
}

async function updateName(title) {
  error.hidden = true;
  setBusy(true);
  try {
    const result = await chrome.runtime.sendMessage({ action: "set_tab_name", url: tabUrl, title });
    if (result.ok) {
      window.close();
      return;
    }
    showError(result.error);
  } catch {
    showError("tabRenameUnavailable");
  }
  setBusy(false);
  input.focus();
}

initializeEditor().catch(() => showError("tabChanged"));
