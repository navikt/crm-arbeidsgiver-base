import { createElement } from '@lwc/engine-dom';
import Popover from 'c/popover';

describe('c-popover', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllTimers();
    });

    // === RENDERING & INITIAL STATE ===
    it('should render without errors', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);
        expect(element).toBeTruthy();
    });

    it('should not show popover initially', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const popover = element.shadowRoot.querySelector('.popover-wrapper');
        expect(popover).toBeNull();
    });

    it('should render trigger link and button', () => {
        const element = createElement('c-popover', { is: Popover });
        element.linkLabel = 'Test Link';
        element.iconName = 'utility:info';
        element.tooltip = 'Info Icon';
        element.title = 'Test Popover Title';
        element.linkUrl = 'https://example.com';
        document.body.appendChild(element);

        const link = element.shadowRoot.querySelector('[data-id="popover-link"]');
        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');

        expect(link).toBeTruthy();
        expect(link.textContent).toBe('Test Link');
        expect(link.href).toContain('example.com');
        expect(button).toBeTruthy();
        expect(button.iconName).toBe('utility:info');
        expect(button.tooltip).toBe('Info Icon');
        expect(button.title).toBe('Test Popover Title');
    });

    it('should handle slotted content', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);
        // ToDo
    });

    // === BUTTON CLICK INTERACTIONS ===
    it('should open popover when button is clicked', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');
        button.click();

        return Promise.resolve().then(() => {
            const popover = element.shadowRoot.querySelector('.popover-wrapper');
            expect(popover).toBeTruthy();
        });
    });

    it('should show backdrop when opened via button click', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');
        button.click();

        return Promise.resolve().then(() => {
            const backdrop = element.shadowRoot.querySelector('.outside-click-capture');
            expect(backdrop).toBeTruthy();
        });
    });

    it('should close popover when backdrop is clicked', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');
        button.click();

        return Promise.resolve()
            .then(() => {
                const backdrop = element.shadowRoot.querySelector('.outside-click-capture');
                backdrop.click();

                return Promise.resolve();
            })
            .then(() => {
                const popover = element.shadowRoot.querySelector('.popover-wrapper');
                expect(popover).toBeNull();
            });
    });

    // === KEYBOARD ACCESSIBILITY ===
    it('should close popover when ESC key is pressed', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');
        button.click();

        return Promise.resolve()
            .then(() => {
                const escEvent = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true });
                window.dispatchEvent(escEvent);

                return Promise.resolve();
            })
            .then(() => {
                const popover = element.shadowRoot.querySelector('.popover-wrapper');
                expect(popover).toBeNull();
            });
    });
    // === ARIA & ACCESSIBILITY ===
    it('should set aria-haspopup when popover is open', () => {
        const element = createElement('c-popover', { is: Popover });
        document.body.appendChild(element);

        const button = element.shadowRoot.querySelector('[data-id="popover-button"]');
        expect(button.getAttribute('aria-haspopup')).toBe('false');
        button.click();

        return Promise.resolve().then(() => {
            const popover = element.shadowRoot.querySelector('.popover-wrapper');
            expect(popover).toBeTruthy();
            expect(button.getAttribute('aria-haspopup')).toBe('true');
        });
    });
});
