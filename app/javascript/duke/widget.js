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
  micStart: 'Dicter le message',
  micStop: 'Arrêter la dictée',
  micUnavailable: 'Reconnaissance vocale indisponible sur ce navigateur.',
  micPermission: 'Accès au micro refusé. Autorise-le dans les réglages du navigateur.',
  micNoSpeech: 'Aucune voix détectée.',
  micError: 'La dictée a rencontré un problème.',
  clarifyPlaceholder: 'Réponds à la question ci-dessus pour préciser…',
};

const ICON_BUBBLE = `
<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor" aria-hidden="true">
  <path d="M12 3a9 9 0 0 0-9 9c0 1.7.5 3.4 1.4 4.8L3 21l4.4-1.3A9 9 0 1 0 12 3z"/>
</svg>`;

const ICON_MIC = `
<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true">
  <path d="M12 14a3 3 0 0 0 3-3V5a3 3 0 1 0-6 0v6a3 3 0 0 0 3 3zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11z"/>
</svg>`;

// Browser-side STT lives in the widget by design (REQUIREMENTS.md §2): Duke
// only ever sees text. We use the Web Speech API (Chrome/Edge — Firefox lacks
// support as of 2026, Safari requires user gesture and supports it on iOS 14+).
function getSpeechRecognitionCtor() {
  return window.SpeechRecognition || window.webkitSpeechRecognition || null;
}

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
    this.recognition = null;     // active SpeechRecognition instance (or null)
    this.recognizing = false;    // true while the mic is live
    this._committedTranscript = '';  // text already accepted; interim results append to it
    this.pendingClarifyId = null;    // when set, textarea sends `clarify` instead of `user_message`
    this._defaultPlaceholder = I18N.placeholder;
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
          <button type="button" class="duke-mic" aria-label="${I18N.micStart}" hidden>
            ${ICON_MIC}
          </button>
          <button type="submit">${I18N.send}</button>
        </form>
      </section>
    `;

    this.bubble = this.root.querySelector('.duke-bubble');
    this.panel = this.root.querySelector('.duke-panel');
    this.messagesEl = this.root.querySelector('.duke-panel__messages');
    this.composer = this.root.querySelector('.duke-panel__composer');
    this.textarea = this.composer.querySelector('textarea');
    this.micButton = this.composer.querySelector('.duke-mic');

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

    if (getSpeechRecognitionCtor()) {
      this.micButton.hidden = false;
      this.micButton.addEventListener('click', () => this._toggleRecognition());
    }
  }

  // --- Voice input (Web Speech API) ---

  _toggleRecognition() {
    if (this.recognizing) {
      this.recognition?.stop();
      return;
    }
    const Ctor = getSpeechRecognitionCtor();
    if (!Ctor) {
      this._appendSystem(I18N.micUnavailable);
      return;
    }

    const recognition = new Ctor();
    recognition.lang = 'fr-FR';
    recognition.interimResults = true;
    recognition.continuous = false;
    recognition.maxAlternatives = 1;

    this._committedTranscript = this.textarea.value
      ? this.textarea.value.trimEnd() + ' '
      : '';

    recognition.onstart = () => {
      this.recognizing = true;
      this.micButton.classList.add('duke-mic--recording');
      this.micButton.setAttribute('aria-label', I18N.micStop);
    };

    recognition.onresult = (event) => {
      let interim = '';
      for (let i = event.resultIndex; i < event.results.length; i += 1) {
        const result = event.results[i];
        const transcript = result[0]?.transcript || '';
        if (result.isFinal) {
          this._committedTranscript += transcript;
        } else {
          interim += transcript;
        }
      }
      this.textarea.value = (this._committedTranscript + interim).trimStart();
    };

    recognition.onerror = (event) => {
      // 'aborted' fires on user-initiated stop and is not an error to surface.
      const fatal = event.error && event.error !== 'aborted';
      if (fatal) {
        this._appendSystem(this._micErrorMessage(event.error));
      }
    };

    recognition.onend = () => {
      this.recognizing = false;
      this.recognition = null;
      this.micButton.classList.remove('duke-mic--recording');
      this.micButton.setAttribute('aria-label', I18N.micStart);
      this.textarea.focus();
    };

    this.recognition = recognition;
    try {
      recognition.start();
    } catch (e) {
      // Calling start() on an already-running recognition throws InvalidStateError.
      // Surface as a soft system message rather than an exception in the console.
      this._appendSystem(I18N.micError);
      this.recognition = null;
    }
  }

  _micErrorMessage(code) {
    switch (code) {
      case 'not-allowed':
      case 'service-not-allowed':
        return I18N.micPermission;
      case 'no-speech':
        return I18N.micNoSpeech;
      default:
        return I18N.micError;
    }
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
    if (this.recognizing) this.recognition?.stop();
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

    const missing = [];
    if (!cfg.user?.email) missing.push('email');
    if (!cfg.token) missing.push('token');
    if (!cfg.tenant) missing.push('tenant');
    if (missing.length) {
      // Surfaces missing fields immediately rather than letting the WS handshake
      // fail with a generic "Invalid auth payload". Usually means the widget
      // pack wasn't rebuilt or the controller response is mis-shaped.
      this._appendError(`${I18N.authError} (config incomplet: ${missing.join(', ')})`);
      this.connecting = false;
      return;
    }

    this.client = new DukeClient({
      wsUrl: cfg.ws_url,
      email: cfg.user.email,
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
    if (this.recognizing) this.recognition?.stop();
    const text = this.textarea.value.trim();
    if (!text || !this.client) return;

    if (this.pendingClarifyId) {
      // Continuation of the open draft: answers the pending question rather
      // than starting a new turn. Duke re-extracts and re-emits the draft.
      this._appendUser(text);
      this.client.clarify(this.pendingClarifyId, text);
      this.textarea.value = '';
      this._committedTranscript = '';
      return;
    }

    const id = newId();
    this._appendUser(text);
    this.textarea.value = '';
    this._committedTranscript = '';
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
    // Reuse the existing card if any (e.g. on a clarify round-trip the draft
    // node carries the same id and should briefly show "Duke réfléchit…"
    // before being re-rendered). Without reuse we'd stack a fresh thinking
    // node on top of the draft, leaving "Duke réfléchit…" visible after the
    // new draft replaces only the original node.
    let node = this.messagesEl.querySelector(`[data-msg-id="${id}"]`);
    if (node) {
      node.className = 'duke-msg duke-msg--assistant duke-msg--thinking';
      node.innerHTML = `<em>${I18N.thinking}</em>`;
    } else {
      node = this._append('assistant thinking', `<em>${I18N.thinking}</em>`, id);
    }
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

    const ambiguities = (msg.ambiguities || [])
      .map((a, idx) => {
        const opts = (a.options || [])
          .map(
            (opt) =>
              `<button type="button" class="duke-draft__option" ` +
              `data-msg-id="${msg.id}" data-amb-idx="${idx}" ` +
              `data-option="${this._escape(opt)}">${this._escape(opt)}</button>`,
          )
          .join('');
        return (
          `<li>${this._escape(a.question)}` +
          (opts ? `<div class="duke-draft__options">${opts}</div>` : '') +
          `</li>`
        );
      })
      .join('');

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

    // After a clarify round-trip, Duke re-emits a draft with the same id.
    // Replace the existing card in place rather than stacking a new one.
    const existing = this.messagesEl.querySelector(`[data-msg-id="${msg.id}"]`);
    let node;
    if (existing) {
      existing.classList.remove('cancelled');
      existing.innerHTML = html;
      node = existing;
    } else {
      node = this._append('assistant draft', html, msg.id);
    }

    const hasAmbiguities = (msg.ambiguities || []).length > 0;
    const confirmBtn = node.querySelector('.duke-draft__confirm');
    if (hasAmbiguities) {
      confirmBtn.disabled = true;
      this._setClarifying(msg.id);
    } else if (this.pendingClarifyId === msg.id) {
      this._clearClarifying();
    }
    confirmBtn.addEventListener('click', () => this._confirmDraft(msg.id));
    node.querySelector('.duke-draft__cancel').addEventListener('click', () => this._cancelDraft(msg.id, node));

    node.querySelectorAll('.duke-draft__option').forEach((btn) => {
      btn.addEventListener('click', () => {
        if (!this.client) return;
        const option = btn.dataset.option;
        // Surface the choice in the message log so the user has a record.
        this._appendUser(option);
        this.client.clarify(msg.id, option);
        // Disable all options on this card to prevent double-clicks.
        node.querySelectorAll('.duke-draft__option').forEach((b) => (b.disabled = true));
      });
    });
  }

  _confirmDraft(id) {
    const draft = this.draftsById.get(id);
    if (!draft || !this.client) return;
    if (this.pendingClarifyId === id) this._clearClarifying();
    this.client.confirmIntervention(id, draft);
  }

  _cancelDraft(id, node) {
    if (this.client) this.client.cancel(id);
    this.draftsById.delete(id);
    if (this.pendingClarifyId === id) this._clearClarifying();
    node.classList.add('cancelled');
    node.querySelectorAll('button').forEach((b) => (b.disabled = true));
  }

  _setClarifying(id) {
    this.pendingClarifyId = id;
    this.textarea.placeholder = I18N.clarifyPlaceholder;
    this.composer.classList.add('duke-panel__composer--clarifying');
    this.textarea.focus();
  }

  _clearClarifying() {
    this.pendingClarifyId = null;
    this.textarea.placeholder = this._defaultPlaceholder;
    this.composer.classList.remove('duke-panel__composer--clarifying');
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
