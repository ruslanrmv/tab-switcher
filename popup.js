// Query connection status from service worker with actual ping test
const statusEl = document.getElementById("status");
const statusTextEl = document.getElementById("status-text");

// Set initial checking state
statusEl.className = "status";
statusTextEl.textContent = "Проверяем подключение…";

// Request a real ping test from the service worker
chrome.runtime.sendMessage({ action: "ping_native_host" }, function(response) {
  if (chrome.runtime.lastError) {
    statusEl.className = "status disconnected";
    statusTextEl.textContent = "Расширение не отвечает";
    return;
  }

  if (response && response.connected) {
    statusEl.className = "status connected";
    statusTextEl.textContent = "Программа подключена";
  } else {
    statusEl.className = "status disconnected";
    statusTextEl.textContent = "Нет связи с программой. Проверьте её запуск.";
  }
});

var versionLabel = document.getElementById("version-label");
var currentVersion = chrome.runtime.getManifest().version;
versionLabel.textContent = "v" + currentVersion;

// Load custom shortcut display from storage
chrome.storage.local.get("shortcuts", function(data) {
  if (data.shortcuts) {
    if (data.shortcuts.tabSwitch) {
      var el = document.getElementById("tab-switch-keys");
      if (el) el.innerHTML = '<span class="key">' + data.shortcuts.tabSwitch + '</span>';
    }
    if (data.shortcuts.copyUrl) {
      var el = document.getElementById("copy-url-keys");
      if (el) el.innerHTML = '<span class="key">' + data.shortcuts.copyUrl + '</span>';
    }
  }
});
