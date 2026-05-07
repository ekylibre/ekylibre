// Duke chat widget pack. Boots once per page on DOM ready and mounts the
// widget into #duke-widget-root (rendered by app/views/shared/_duke_widget.html.haml).

import { DukeWidget } from 'duke/widget';

function boot() {
  const root = document.getElementById('duke-widget-root');
  if (!root || root.dataset.dukeBooted === '1') return;
  root.dataset.dukeBooted = '1';
  new DukeWidget(root);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot, { once: true });
} else {
  boot();
}
