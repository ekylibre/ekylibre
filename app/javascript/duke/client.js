// WebSocket client for the Duke service.
//
// Protocol contract is defined in Duke's transport/messages.py. We send
// JSON frames discriminated by a `type` field and emit events to
// listeners as messages come back. Reconnection is intentionally not
// implemented in iteration 6 — closing and re-opening the panel is the
// expected recovery path.

const HEARTBEAT_INTERVAL_MS = 30 * 1000;
const AUTH_TIMEOUT_MS = 10 * 1000;

export class DukeClient {
  constructor({ wsUrl, token, tenant, locale }) {
    this.wsUrl = wsUrl;
    this.token = token;
    this.tenant = tenant;
    this.locale = locale || 'fr';
    this.ws = null;
    this.heartbeatTimer = null;
    this.listeners = new Map();
    this.authResolve = null;
    this.authReject = null;
  }

  on(event, handler) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event).add(handler);
  }

  off(event, handler) {
    this.listeners.get(event)?.delete(handler);
  }

  _emit(event, payload) {
    this.listeners.get(event)?.forEach((h) => {
      try {
        h(payload);
      } catch (e) {
        console.error('[duke] listener error', event, e);
      }
    });
  }

  // Returns a Promise that resolves to the auth_ok payload on success
  // and rejects with the auth_error code on failure.
  connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.wsUrl);
      this.authResolve = resolve;
      this.authReject = reject;

      const authTimer = window.setTimeout(() => {
        if (this.authReject) {
          this.authReject(new Error('auth_timeout'));
          this.authResolve = null;
          this.authReject = null;
          this.ws?.close();
        }
      }, AUTH_TIMEOUT_MS);

      this.ws.addEventListener('open', () => {
        this._send({
          type: 'auth',
          token: this.token,
          tenant: this.tenant,
          locale: this.locale,
        });
      });

      this.ws.addEventListener('message', (event) => {
        let msg;
        try {
          msg = JSON.parse(event.data);
        } catch (e) {
          console.error('[duke] non-JSON frame', event.data);
          return;
        }
        this._dispatch(msg, authTimer);
      });

      this.ws.addEventListener('close', (event) => {
        window.clearTimeout(authTimer);
        this._stopHeartbeat();
        if (this.authReject) {
          this.authReject(new Error(`closed: ${event.code}`));
          this.authResolve = null;
          this.authReject = null;
        }
        this._emit('disconnect', { code: event.code, reason: event.reason });
      });

      this.ws.addEventListener('error', () => {
        // The 'close' handler will fire too; we surface a single 'error' event.
        this._emit('error', { code: 'WS_ERROR', message: 'connection error' });
      });
    });
  }

  _dispatch(msg, authTimer) {
    switch (msg.type) {
      case 'auth_ok':
        window.clearTimeout(authTimer);
        if (this.authResolve) {
          this.authResolve(msg);
          this.authResolve = null;
          this.authReject = null;
        }
        this._startHeartbeat();
        this._emit('ready', msg);
        return;

      case 'auth_error':
        window.clearTimeout(authTimer);
        if (this.authReject) {
          this.authReject(msg);
          this.authResolve = null;
          this.authReject = null;
        }
        return;

      case 'pong':
        return;

      case 'thinking':
      case 'assistant_token':
      case 'assistant_message':
      case 'intervention_draft':
      case 'intervention_created':
      case 'clarification_needed':
      case 'out_of_scope':
      case 'error':
        this._emit(msg.type, msg);
        return;

      default:
        console.warn('[duke] unhandled message type', msg.type);
    }
  }

  sendUserMessage(id, text) {
    this._send({ type: 'user_message', id, text });
  }

  confirmIntervention(id, draft) {
    this._send({ type: 'confirm_intervention', id, draft });
  }

  cancel(id) {
    this._send({ type: 'cancel', id });
  }

  close() {
    this._stopHeartbeat();
    this.ws?.close();
  }

  _send(payload) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      console.warn('[duke] WS not open, dropping', payload.type);
      return;
    }
    this.ws.send(JSON.stringify(payload));
  }

  _startHeartbeat() {
    this._stopHeartbeat();
    this.heartbeatTimer = window.setInterval(() => {
      this._send({ type: 'ping' });
    }, HEARTBEAT_INTERVAL_MS);
  }

  _stopHeartbeat() {
    if (this.heartbeatTimer) {
      window.clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }
}
