'use strict';
const list = document.getElementById('tabs');
let tabs = [];
let selected = 0;
let finished = false;
let pendingDirection = 0;
let pendingFinish = false;
function draw() {
  list.replaceChildren(...tabs.map((tab, index) => {
    const card = document.createElement('div');
    card.className = 'card'; card.role = 'option'; card.setAttribute('aria-selected', index === selected ? 'true' : 'false');
    if (tab.preview) { const image = document.createElement('img'); image.className='preview'; image.src=tab.preview; image.alt=''; card.append(image); }
    else { const fallback=document.createElement('div'); fallback.className='fallback'; fallback.textContent='◉'; card.append(fallback); }
    const title=document.createElement('div'); title.className='title';
    if (tab.favIconUrl) { const icon=document.createElement('img'); icon.className='favicon'; icon.src=tab.favIconUrl; icon.alt=''; title.append(icon); }
    const label=document.createElement('span'); label.textContent=tab.title; title.append(label); card.append(title);
    card.addEventListener('click', () => finish(index));
    return card;
  }));
  list.children[selected]?.scrollIntoView({block:'nearest', inline:'center'});
}
function move(direction) {
  if (!tabs.length) { pendingDirection += direction; return; }
  selected = (selected + direction + tabs.length) % tabs.length;
  chrome.runtime.sendMessage({type:'selection', selected}).catch(() => {});
  draw();
}
function finish(index = selected, cancel = false) {
  if (finished) return;
  if (!cancel && !tabs.length) { pendingFinish = true; return; }
  finished = true;
  chrome.runtime.sendMessage(cancel ? {type:'cancel'} : {type:'choose',tabId:tabs[index]?.id}).catch(() => window.close());
}
window.addEventListener('keydown', event => {
  if (event.key === 'Tab') { event.preventDefault(); move(event.shiftKey ? -1 : 1); }
  else if (event.key === 'Escape') { event.preventDefault(); finish(0, true); }
  else if (event.key === 'Enter') { event.preventDefault(); finish(); }
});
window.addEventListener('keyup', event => { if (event.key === 'Control') finish(); });
chrome.runtime.onMessage.addListener(message => {
  if (message.type !== 'cycle' || !Number.isInteger(message.selected)) return;
  if (!tabs.length) return;
  selected = message.selected;
  draw();
});
chrome.runtime.sendMessage({type:'get-session'}).then(data => {
  if (!data?.tabs?.length) { window.close(); return; }
  tabs = data.tabs; selected = (data.selected + pendingDirection % tabs.length + tabs.length) % tabs.length; draw();
  if (pendingFinish) finish();
}).catch(() => window.close());
