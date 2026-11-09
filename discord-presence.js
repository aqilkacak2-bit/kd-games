/* Discord identity and shared room presence. Game simulation remains local. */
(() => {
    'use strict';

    const ROOMS = new Set(['rm_select', 'rm_showcase', 'rm_kl', 'rm_main', 'rm_range', 'rm_rooftop']);
    const LOOK_LIMITS = { hair: 5, hair_col: 9, face: 5, skin: 5, top: 5, top_col: 9, bottom: 2, bottom_col: 7 };
    const peers = new Map();
    let hooks, panel, elements, user = null, socket = null, room = null;
    let configured = false, checking = true, loggingOut = false, navigating = false, paused = false;
    let connection = 'offline', notice = '', authVersion = 0;
    let nextConnect = 0, retryDelay = 1000, lastSent = 0, lastFrame = 0;
    let connectTimeout = null, heartbeat = null;

    function validState(value) {
        if (!value || !Number.isFinite(value.x) || !Number.isFinite(value.y) || !Number.isFinite(value.frame)) return null;
        if (!['idle', 'walk'].includes(value.state) || ![-1, 1].includes(value.facing) || !value.look) return null;
        const look = {};
        for (const [key, max] of Object.entries(LOOK_LIMITS)) {
            const number = value.look[key];
            if (!Number.isInteger(number) || number < 0 || number > max) return null;
            look[key] = number;
        }
        return { x: value.x, y: value.y, facing: value.facing, state: value.state, frame: value.frame, look };
    }

    function acceptPlayer(value) {
        if (!value || typeof value.id !== 'string' || typeof value.name !== 'string' || value.id === user?.id) return;
        const state = value.state === null ? null : validState(value.state);
        if (value.state !== null && !state) return;
        const old = peers.get(value.id);
        peers.set(value.id, {
            id: value.id, name: value.name.slice(0, 64), state,
            x: old?.x ?? state?.x ?? 0, y: old?.y ?? state?.y ?? 0,
            receivedAt: performance.now()
        });
    }

    function closeSocket() {
        clearTimeout(connectTimeout);
        clearInterval(heartbeat);
        const previous = socket;
        socket = null;
        peers.clear();
        if (previous) previous.close(1000, 'Leaving room');
    }

    function setUser(nextUser) {
        closeSocket();
        user = nextUser;
        room = null;
        paused = false;
        connection = 'offline';
        nextConnect = 0;
        retryDelay = 1000;
        hooks.onIdentity(user);
    }

    function avatarUrl(value) {
        try {
            const url = new URL(value);
            return url.protocol === 'https:' && ['cdn.discordapp.com', 'media.discordapp.net'].includes(url.hostname) ? url.href : '';
        } catch { return ''; }
    }

    function render() {
        if (!elements) return;
        const busy = checking || loggingOut || navigating;
        elements.name.textContent = user ? user.name : 'KD Discord';
        let detail = 'Guest play · sign in to appear online';
        if (checking) detail = 'Checking Discord sign-in…';
        else if (!configured) detail = 'Discord sign-in is temporarily unavailable';
        else if (user) {
            if (paused) detail = 'Active in another tab';
            else if (!navigator.onLine) detail = 'Offline · waiting for your connection';
            else if (!room) detail = 'Signed in · enter the game to join';
            else if (connection === 'online') detail = `${peers.size + 1} in this room`;
            else if (connection === 'connecting') detail = 'Joining your room…';
            else detail = 'Connection lost · reconnecting…';
        }
        elements.detail.textContent = detail;
        elements.login.hidden = !!user;
        elements.login.setAttribute('aria-disabled', String(busy || !configured));
        elements.login.tabIndex = busy || !configured ? -1 : 0;
        elements.logout.hidden = !user;
        elements.logout.disabled = busy;
        elements.logout.textContent = loggingOut ? 'Signing out…' : 'Sign out';
        elements.retry.hidden = !(paused || (!checking && !configured));
        elements.retry.disabled = busy;
        elements.retry.textContent = paused ? 'Use this tab' : 'Retry';
        elements.notice.textContent = notice;
        elements.notice.hidden = !notice;
        const avatar = user ? avatarUrl(user.avatar) : '';
        elements.avatar.hidden = !avatar;
        if (avatar && elements.avatar.getAttribute('src') !== avatar) elements.avatar.src = avatar;
        if (!avatar) elements.avatar.removeAttribute('src');
        panel.classList.toggle('connected', connection === 'online');
        panel.setAttribute('aria-busy', String(busy));
    }

    async function refreshSession() {
        const version = ++authVersion;
        checking = true;
        render();
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 10000);
        try {
            const response = await fetch('/api/me', { credentials: 'same-origin', cache: 'no-store', signal: controller.signal });
            if (response.status === 401 || response.status === 403) {
                if (version !== authVersion) return;
                configured = true;
                setUser(null);
                notice = response.status === 403 ? 'KD server membership is required. Join KD Discord, then sign in again.' : 'Your Discord session has ended. Sign in again to appear online.';
                return;
            }
            if (!response.ok) throw new Error('session_unavailable');
            const data = await response.json();
            if (version !== authVersion) return;
            configured = data.configured === true;
            const identity = data.user;
            setUser(identity && typeof identity.id === 'string' && typeof identity.name === 'string'
                ? { id: identity.id, name: identity.name.slice(0, 64), avatar: identity.avatar || '' } : null);
            if (user) notice = '';
            if (!configured) notice = 'You can continue playing as a guest. Retry Discord sign-in later.';
        } catch {
            if (version !== authVersion) return;
            configured = false;
            setUser(null);
            notice = 'Could not check Discord sign-in. Guest play is available. Select Retry to reconnect.';
        } finally {
            clearTimeout(timeout);
            if (version === authVersion) { checking = false; render(); }
        }
    }

    async function logout() {
        if (loggingOut) return;
        loggingOut = true;
        render();
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 10000);
        try {
            const response = await fetch('/auth/logout', { method: 'POST', credentials: 'same-origin', headers: { Accept: 'application/json' }, signal: controller.signal });
            if (!response.ok) throw new Error('logout_failed');
            ++authVersion;
            checking = false;
            notice = '';
            setUser(null);
        } catch {
            notice = 'Sign out could not be completed. Please try again.';
        } finally {
            clearTimeout(timeout);
            loggingOut = false;
            render();
        }
    }

    function connect() {
        closeSocket();
        connection = 'connecting';
        render();
        const url = new URL('/api/presence', location.href);
        url.protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        url.searchParams.set('room', room);
        let ws;
        try { ws = new WebSocket(url); }
        catch {
            connection = 'offline';
            nextConnect = performance.now() + retryDelay;
            retryDelay = Math.min(retryDelay * 2, 30000);
            render();
            return;
        }
        socket = ws;
        connectTimeout = setTimeout(() => { if (socket === ws && ws.readyState === WebSocket.CONNECTING) ws.close(); }, 10000);
        ws.addEventListener('open', () => {
            if (socket !== ws) return;
            clearTimeout(connectTimeout);
            connection = 'online';
            retryDelay = 1000;
            lastSent = 0;
            heartbeat = setInterval(() => {
                if (socket === ws && ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'ping' }));
            }, 25000);
            render();
        });
        ws.addEventListener('message', event => {
            if (socket !== ws || typeof event.data !== 'string' || event.data.length > 65536) return;
            let message;
            try { message = JSON.parse(event.data); } catch { return; }
            if (!message || typeof message !== 'object') return;
            if (message.type === 'replaced') {
                paused = true;
                connection = 'offline';
                closeSocket();
                render();
                return;
            }
            const previousCount = peers.size;
            if (message.type === 'welcome' && Array.isArray(message.players)) {
                peers.clear();
                for (const player of message.players.slice(0, 256)) acceptPlayer(player);
            } else if (message.type === 'presence' && (peers.has(message.player?.id) || peers.size < 256)) acceptPlayer(message.player);
            else if (message.type === 'leave') peers.delete(message.id);
            if (message.type === 'welcome' || peers.size !== previousCount) render();
        });
        ws.addEventListener('close', event => {
            if (socket !== ws) return;
            clearTimeout(connectTimeout);
            clearInterval(heartbeat);
            socket = null;
            peers.clear();
            connection = 'offline';
            if (event.code === 4009) paused = true;
            else if (event.code === 4401 || event.code === 4403) { void refreshSession(); return; }
            nextConnect = performance.now() + retryDelay;
            retryDelay = Math.min(retryDelay * 2, 30000);
            render();
        });
    }

    function update(now) {
        if (!hooks) return;
        const snapshot = hooks.getState();
        panel.hidden = panel.classList.contains('floating') && snapshot.typing;
        const nextRoom = ROOMS.has(snapshot.room) ? snapshot.room : null;
        if (nextRoom !== room) {
            closeSocket();
            room = nextRoom;
            nextConnect = 0;
            connection = 'offline';
            render();
        }
        if (user && !checking && configured && room && navigator.onLine && !paused) {
            if (!socket && now >= nextConnect) connect();
            if (socket?.readyState === WebSocket.OPEN && socket.bufferedAmount < 16384) {
                if (now - lastSent >= 100) {
                    const state = validState(snapshot.state);
                    if (state) { socket.send(JSON.stringify({ type: 'state', state })); lastSent = now; }
                }
            }
        }
        const elapsed = lastFrame ? Math.min(now - lastFrame, 250) : 16;
        lastFrame = now;
        const amount = 1 - Math.exp(-elapsed / 70);
        for (const peer of peers.values()) {
            if (!peer.state) continue;
            const snap = Math.hypot(peer.state.x - peer.x, peer.state.y - peer.y) > 120;
            peer.x += (peer.state.x - peer.x) * (snap ? 1 : amount);
            peer.y += (peer.state.y - peer.y) * (snap ? 1 : amount);
        }
    }

    function init(callbacks) {
        if (hooks) return;
        hooks = callbacks;
        const style = document.createElement('style');
        style.textContent = `
            #kd-community{display:flex;align-items:center;flex-wrap:wrap;gap:8px;margin:0 0 16px;padding:12px;border:1px solid #35443d;border-radius:12px;background:#111920;color:#eef4f1;font:13px/1.35 "Segoe UI",Arial,sans-serif;box-sizing:border-box}
            #kd-community[hidden],#kd-community [hidden]{display:none!important}
            #kd-community .kd-session-info{flex:1;min-width:112px}
            #kd-community strong,#kd-community .kd-session-detail{display:block}
            #kd-community strong{max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
            #kd-community .kd-session-detail{font-size:12px;color:#b4c2bb}
            #kd-community.connected .kd-session-detail{color:#7be89c}
            #kd-community img{width:32px;height:32px;border-radius:50%;flex:none}
            #kd-community a,#kd-community button{display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:0 12px;box-sizing:border-box;border:1px solid #485451;border-radius:8px;background:#1d2a25;color:#eef4f1;font-family:inherit;font-size:12px;font-weight:700;line-height:1.2;text-decoration:none;cursor:pointer;white-space:nowrap;transition:background .12s,transform .06s}
            #kd-community .kd-session-login{background:#5865f2;border-color:#7781ff;color:#fff}
            #kd-community a:hover,#kd-community button:hover{background:#31463b}
            #kd-community .kd-session-login:hover{background:#4752c4}
            #kd-community a:active,#kd-community button:active{transform:translateY(1px)}
            #kd-community a:focus-visible,#kd-community button:focus-visible{outline:2px solid #86efa6;outline-offset:3px}
            #kd-community [aria-disabled="true"],#kd-community button:disabled{opacity:.55;cursor:not-allowed}
            #kd-community .kd-session-notice{flex-basis:100%;margin:0;color:#f5d09d;font-size:12px}
            #kd-community.floating{position:fixed;z-index:40;top:max(8px,env(safe-area-inset-top,0px));left:50%;transform:translateX(-50%);width:max-content;max-width:calc(100vw - 24px);margin:0;padding:4px 8px;box-shadow:0 4px 16px #0005}
            #kd-community.floating .kd-session-info{min-width:0}
            #kd-community.floating .kd-session-notice{max-width:340px;padding:4px 0}
            @media(max-width:560px){#kd-community.floating strong{max-width:104px}#kd-community.floating .kd-session-detail{max-width:148px;font-size:11px}#kd-community.floating a,#kd-community.floating button{padding:0 8px;font-size:11px}}
            @media(prefers-reduced-motion:reduce){#kd-community a,#kd-community button{transition:none}}
        `;
        document.head.append(style);
        panel = document.createElement('section');
        panel.id = 'kd-community';
        panel.setAttribute('aria-label', 'KD Discord community');
        panel.innerHTML = '<img alt="" referrerpolicy="no-referrer" hidden><div class="kd-session-info"><strong>KD Discord</strong><span class="kd-session-detail" role="status" aria-live="polite"></span></div><a class="kd-session-login" href="/auth/discord">Sign in with Discord</a><button class="kd-session-retry" type="button" hidden>Retry</button><button class="kd-session-logout" type="button" hidden>Sign out</button><p class="kd-session-notice" role="status" aria-live="polite" hidden></p>';
        document.getElementById('go').before(panel);
        elements = {
            avatar: panel.querySelector('img'), name: panel.querySelector('strong'), detail: panel.querySelector('.kd-session-detail'),
            login: panel.querySelector('a'), retry: panel.querySelector('.kd-session-retry'), logout: panel.querySelector('.kd-session-logout'), notice: panel.querySelector('p')
        };
        panel.addEventListener('keydown', event => event.stopPropagation());
        panel.addEventListener('keyup', event => event.stopPropagation());
        panel.addEventListener('focusin', () => hooks.onFocus());
        elements.login.addEventListener('click', event => {
            if (checking || navigating || !configured) event.preventDefault();
            else {
                hooks.beforeLogin();
                navigating = true;
                elements.login.textContent = 'Opening Discord…';
                render();
            }
        });
        elements.logout.addEventListener('click', () => { void logout(); });
        elements.retry.addEventListener('click', () => {
            notice = '';
            if (paused) { paused = false; nextConnect = 0; render(); }
            else void refreshSession();
        });
        window.addEventListener('offline', () => { closeSocket(); connection = 'offline'; render(); });
        window.addEventListener('online', () => { nextConnect = 0; render(); });
        window.addEventListener('pagehide', closeSocket);
        window.addEventListener('pageshow', event => {
            if (!event.persisted) return;
            navigating = false;
            elements.login.textContent = 'Sign in with Discord';
            void refreshSession();
        });
        const url = new URL(location.href);
        const result = url.searchParams.get('login');
        const messages = {
            not_member: 'KD server membership is required. Join the KD Discord server, then sign in again.',
            denied: 'Discord sign-in was cancelled. You can try again.',
            error: 'Discord sign-in could not be completed. Please try again.'
        };
        notice = messages[result] || '';
        if (result) { url.searchParams.delete('login'); history.replaceState(null, '', url.pathname + url.search + url.hash); }
        void refreshSession();
    }

    window.KD_PRESENCE = {
        init, update,
        enterGame() { if (panel) { document.body.append(panel); panel.classList.add('floating'); } },
        get user() { return user; },
        players() {
            const now = performance.now();
            return Array.from(peers.values()).filter(peer => peer.state).map(peer => ({
                ...peer, frame: peer.state.frame + (now - peer.receivedAt) / 1000 * (peer.state.state === 'walk' ? 10 : 4)
            }));
        }
    };
})();
