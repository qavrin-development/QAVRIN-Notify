(() => {
    const container = document.getElementById('notifications');
    const resourceName = (() => {
        try {
            return typeof GetParentResourceName === 'function' ? GetParentResourceName() : null;
        } catch {
            return null;
        }
    })();
    const validPositions = ['top-right', 'top-left', 'bottom-right', 'bottom-left'];
    const allowedTypes = ['success', 'info', 'warning', 'error'];
    const icons = {
        success: '<path d="M5 10.5 8.5 14 15.5 7"/><circle cx="10" cy="10" r="8"/>',
        info: '<circle cx="10" cy="10" r="8"/><path d="M10 9v5M10 6.25h.01"/>',
        warning: '<path d="M9.1 3.5a1 1 0 0 1 1.8 0l7 12.5a1 1 0 0 1-.9 1.5H3a1 1 0 0 1-.9-1.5l7-12.5ZM10 7.5v4M10 14.2h.01"/>',
        error: '<circle cx="10" cy="10" r="8"/><path d="m7.4 7.4 5.2 5.2m0-5.2-5.2 5.2"/>'
    };
    const state = {
        position: 'top-right',
        maxVisible: 5,
        defaultDuration: 5000,
        maxDuration: 15000
    };

    function post(name, data) {
        if (!resourceName) return;

        fetch(`https://${resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {})
        }).catch(() => {});
    }

    function clampInteger(value, fallback, min, max) {
        const numeric = Math.floor(Number(value));
        if (!Number.isFinite(numeric)) return fallback;
        return Math.max(min, Math.min(numeric, max));
    }

    function trimNotifications() {
        while (container.children.length > state.maxVisible) {
            container.firstElementChild.remove();
        }
    }

    function applyConfig(data) {
        if (!data) return;

        if (validPositions.includes(data.position)) {
            state.position = data.position;
        }

        state.maxVisible = clampInteger(data.maxVisible, state.maxVisible, 1, Number.MAX_SAFE_INTEGER);
        state.maxDuration = clampInteger(data.maxDuration, state.maxDuration, 1000, 2147483647);
        state.defaultDuration = clampInteger(data.defaultDuration, state.defaultDuration, 1000, state.maxDuration);
        container.dataset.position = state.position;
        trimNotifications();
    }

    function addNotification(data) {
        const type = allowedTypes.includes(data.type) ? data.type : 'info';
        const duration = clampInteger(data.duration, state.defaultDuration, 1000, state.maxDuration);
        const card = document.createElement('section');
        card.className = `notification ${type}`;
        card.style.setProperty('--duration', `${duration}ms`);

        const icon = document.createElement('span');
        icon.className = 'notification__icon';
        icon.setAttribute('aria-hidden', 'true');
        icon.innerHTML = `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${icons[type]}</svg>`;

        const content = document.createElement('div');
        content.className = 'notification__content';

        const header = document.createElement('div');
        header.className = 'notification__header';

        const title = document.createElement('span');
        title.className = 'notification__title';
        title.textContent = String(data.title || type);

        const tag = document.createElement('span');
        tag.className = 'notification__tag';
        tag.textContent = type;

        const description = document.createElement('div');
        description.className = 'notification__description';
        description.textContent = String(data.description || '');

        const track = document.createElement('div');
        track.className = 'notification__progress-track';
        track.setAttribute('aria-hidden', 'true');

        const progress = document.createElement('div');
        progress.className = 'notification__progress';
        track.appendChild(progress);
        header.append(title, tag);
        content.append(header, description);
        card.append(icon, content, track);
        container.appendChild(card);
        trimNotifications();

        window.setTimeout(() => {
            card.classList.add('leaving');
            window.setTimeout(() => card.remove(), 200);
        }, duration);
    }

    window.addEventListener('message', (event) => {
        const message = event.data;

        if (!message || !message.action) return;

        if (message.action === 'qavrin:config') {
            applyConfig(message.data);
            return;
        }

        if (message.action === 'qavrin:hello') {
            post('qavrinReady');
            return;
        }

        if (message.action === 'qavrin:notify' && message.data) {
            addNotification(message.data);
        }
    });

    container.dataset.position = state.position;
    post('qavrinReady');
})();
