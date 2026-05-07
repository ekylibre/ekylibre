// Floating chat widget for Duke. Vanilla DOM, no framework.
//
// Layout:
//   #duke-widget-root            <- mount point in the backend layout
//     .duke-bubble                <- floating button (visible when closed)
//     .duke-panel                 <- chat panel (visible when open)
//       .duke-panel__header
//       .duke-panel__messages
//       .duke-panel__composer

import { DukeClient } from './client.js';

const I18N = {
  title: 'Duke',
  open: 'Ouvrir Duke',
  close: 'Fermer',
  placeholder: 'Décris ton intervention ou pose ta question…',
  send: 'Envoyer',
  thinking: 'Duke réfléchit…',
  validate: 'Valider',
  cancel: 'Annuler',
  connecting: 'Connexion à Duke…',
  connectionError: 'Impossible de joindre Duke.',
  authError: "L'authentification a échoué.",
  draftHeading: 'Fiche d\'intervention',
  fieldProcedure: 'Procédure',
  fieldStartedAt: 'Début',
  fieldStoppedAt: 'Fin',
  fieldTargets: 'Parcelles',
  fieldInputs: 'Intrants',
  successCreated: 'Intervention enregistrée',
  outOfScope: 'Cette fonction n\'est pas encore disponible.',
};

const ICON_BUBBLE = `
<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor" aria-hidden="true">
  <path d="M12 3a9 9 0 0 0-9 9c0 1.7.5 3.4 1.4 4.8L3 21l4.4-1.3A9 9 0 1 0 12 3z"/>
</svg>`;

let nextMessageId = 1;
function newId() {
  return `m${nextMessageId++}`;
}

export class DukeWidget {
  constructor(rootEl) {
    this.root = rootEl;
    this.configUrl = rootEl.dataset.configUrl;
    this.client = null;
    this.panelOpen = false;
    this.connecting = false;
    this.streamBuffers = new Map();
    this.draftsById = new Map();
    this._render();
  }

  // --- DOM ---

  _render() {
    this.root.classList.add('duke-widget');
    this.root.innerHTML = `
      <button type="button" class="duke-bubble" aria-label="${I18N.open}">
        ${ICON_BUBBLE}
      </button>
      <section class="duke-panel" role="dialog" aria-label="${I18N.title}" hidden>
        <header class="duke-panel__header">
          <strong>${I18N.title}</strong>
          <button type="button" class="duke-panel__close" aria-label="${I18N.close}">×</button>
        </header>
        <div class="duke-panel__messages" role="log" aria-live="polite"></div>
        <form class="duke-panel__composer" autocomplete="off">
          <textarea rows="2" placeholder="${I18N.placeholder}" required></textarea>
          <button type="submit">${I18N.send}</button>
        </form>
      </section>
    `;

    this.bubble = this.root.querySelector('.duke-bubble');
    this.panel = this.root.querySelector('.duke-panel');
    this.messagesEl = this.root.querySelector('.duke-panel__messages');
    this.composer = this.root.querySelector('.duke-panel__composer');
    this.textarea = this.composer.querySelector('textarea');

    this.bubble.addEventListener('click', () => this.open());
    this.root.querySelector('.duke-panel__close').addEventListener('click', () => this.close());
    this.composer.addEventListener('submit', (e) => {
      e.preventDefault();
      this._submitMessage();
    });
    this.textarea.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        this._submitMessage();
      }
    });
  }

  // --- Lifecycle ---

  async open() {
    this.panelOpen = true;
    this.bubble.hidden = true;
    this.panel.hidden = false;
    this.textarea.focus();

    if (!this.client) {
      await this._connect();
    }
  }

  close() {
    this.panelOpen = false;
    this.bubble.hidden = false;
    this.panel.hidden = true;
    if (this.client) {
      this.client.close();
      this.client = null;
    }
  }

  async _connect() {
    if (this.connecting) return;
    this.connecting = true;
    this._appendSystem(I18N.connecting);

    let cfg;
    try {
      const resp = await fetch(this.configUrl, {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' },
      });
      if (!resp.ok) throw new Error(`config ${resp.status}`);
      cfg = await resp.json();
    } catch (e) {
      this._appendError(I18N.connectionError);
      this.connecting = false;
      return;
    }

    this.client = new DukeClient({
      wsUrl: cfg.ws_url,
      token: cfg.token,
      tenant: cfg.tenant,
      locale: cfg.locale,
    });

    this.client.on('thinking', (msg) => this._showThinking(msg.id));
    this.client.on('assistant_token', (msg) => this._appendStreamToken(msg.id, msg.delta));
    this.client.on('assistant_message', (msg) => this._finalizeStream(msg.id, msg.text));
    this.client.on('intervention_draft', (msg) => this._renderDraft(msg));
    this.client.on('intervention_created', (msg) => this._renderInterventionCreated(msg));
    this.client.on('out_of_scope', (msg) => this._renderOutOfScope(msg));
    this.client.on('error', (msg) => this._appendError(msg.message || 'Erreur.'));
    this.client.on('disconnect', () => this._appendSystem('Déconnecté.'));

    try {
      await this.client.connect();
      this._appendSystem(`${cfg.user.full_name}, je t'écoute.`);
    } catch (err) {
      this._appendError(err?.message ? `${I18N.authError} (${err.message})` : I18N.authError);
      this.client = null;
    } finally {
      this.connecting = false;
    }
  }

  // --- Send ---

  _submitMessage() {
    const text = this.textarea.value.trim();
    if (!text || !this.client) return;

    const id = newId();
    this._appendUser(text);
    this.textarea.value = '';
    this.client.sendUserMessage(id, text);
  }

  // --- Render helpers ---

  _appendUser(text) {
    this._append('user', this._escape(text));
  }

  _appendSystem(text) {
    this._append('system', this._escape(text));
  }

  _appendError(text) {
    this._append('error', this._escape(text));
  }

  _showThinking(id) {
    const node = this._append('assistant thinking', `<em>${I18N.thinking}</em>`, id);
    this.streamBuffers.set(id, { node, text: '', thinking: true });
  }

  _appendStreamToken(id, delta) {
    let entry = this.streamBuffers.get(id);
    if (!entry) {
      const node = this._append('assistant', '', id);
      entry = { node, text: '', thinking: false };
      this.streamBuffers.set(id, entry);
    }
    if (entry.thinking) {
      entry.node.classList.remove('thinking');
      entry.thinking = false;
      entry.node.innerHTML = '';
    }
    entry.text += delta;
    entry.node.textContent = entry.text;
    this._scrollToBottom();
  }

  _finalizeStream(id, fullText) {
    const entry = this.streamBuffers.get(id);
    if (entry) {
      entry.node.classList.remove('thinking');
      entry.node.textContent = fullText;
      this.streamBuffers.delete(id);
    } else {
      this._append('assistant', this._escape(fullText), id);
    }
    this._scrollToBottom();
  }

  _renderDraft(msg) {
    const fields = msg.fields || {};
    this.draftsById.set(msg.id, fields);

    const targets = (fields.targets || [])
      .map((t) => this._escape(t.resolved_name || t.raw_name))
      .join(', ');
    const inputs = (fields.inputs || [])
      .map((i) => {
        const qty = i.quantity_value != null ? `${i.quantity_value} ${i.quantity_unit || ''}`.trim() : '';
        const name = this._escape(i.resolved_product_name || i.raw_name);
        return qty ? `${qty} de ${name}` : name;
      })
      .join(', ');

    const startedAt = fields.started_at ? this._formatDate(fields.started_at) : '—';
    const stoppedAt = fields.stopped_at ? this._formatDate(fields.stopped_at) : '—';
    const procedure = this._escape(fields.procedure_name || '—');

    const ambiguities = (msg.ambiguities || []).map((a) => `<li>${this._escape(a.question)}</li>`).join('');

    const html = `
      <div class="duke-draft">
        <div class="duke-draft__title">${I18N.draftHeading}</div>
        <dl>
          <dt>${I18N.fieldProcedure}</dt><dd>${procedure}</dd>
          <dt>${I18N.fieldStartedAt}</dt><dd>${startedAt}</dd>
          <dt>${I18N.fieldStoppedAt}</dt><dd>${stoppedAt}</dd>
          <dt>${I18N.fieldTargets}</dt><dd>${targets || '—'}</dd>
          <dt>${I18N.fieldInputs}</dt><dd>${inputs || '—'}</dd>
        </dl>
        ${ambiguities ? `<ul class="duke-draft__ambiguities">${ambiguities}</ul>` : ''}
        <div class="duke-draft__actions">
          <button type="button" class="duke-draft__confirm" data-msg-id="${msg.id}">${I18N.validate}</button>
          <button type="button" class="duke-draft__cancel" data-msg-id="${msg.id}">${I18N.cancel}</button>
        </div>
      </div>
    `;
    const node = this._append('assistant draft', html, msg.id);

    const blockSubmit = (msg.ambiguities || []).length > 0;
    const confirmBtn = node.querySelector('.duke-draft__confirm');
    if (blockSubmit) {
      confirmBtn.disabled = true;
    }
    confirmBtn.addEventListener('click', () => this._confirmDraft(msg.id));
    node.querySelector('.duke-draft__cancel').addEventListener('click', () => this._cancelDraft(msg.id, node));
  }

  _confirmDraft(id) {
    const draft = this.draftsById.get(id);
    if (!draft || !this.client) return;
    this.client.confirmIntervention(id, draft);
  }

  _cancelDraft(id, node) {
    if (this.client) this.client.cancel(id);
    this.draftsById.delete(id);
    node.classList.add('cancelled');
    node.querySelectorAll('button').forEach((b) => (b.disabled = true));
  }

  _renderInterventionCreated(msg) {
    const url = msg.url ? `<a href="${msg.url}" target="_blank" rel="noopener">#${msg.ekylibre_id}</a>` : `#${msg.ekylibre_id}`;
    this._append('assistant success', `${I18N.successCreated} ${url}`);
  }

  _renderOutOfScope(msg) {
    const suggestion = msg.suggestion ? ` — ${this._escape(msg.suggestion)}` : '';
    this._append('assistant out-of-scope', `<em>${this._escape(msg.reason || I18N.outOfScope)}</em>${suggestion}`);
  }

  // --- DOM utilities ---

  _append(kind, html, id = null) {
    const node = document.createElement('div');
    node.className = `duke-msg duke-msg--${kind.split(' ').join(' duke-msg--')}`;
    if (id) node.dataset.msgId = id;
    node.innerHTML = html;
    this.messagesEl.appendChild(node);
    this._scrollToBottom();
    return node;
  }

  _scrollToBottom() {
    this.messagesEl.scrollTop = this.messagesEl.scrollHeight;
  }

  _escape(s) {
    if (s == null) return '';
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  _formatDate(iso) {
    try {
      const d = new Date(iso);
      return d.toLocaleString('fr-FR', {
        day: '2-digit', month: '2-digit', year: 'numeric',
        hour: '2-digit', minute: '2-digit',
      });
    } catch (e) {
      return iso;
    }
  }
}
