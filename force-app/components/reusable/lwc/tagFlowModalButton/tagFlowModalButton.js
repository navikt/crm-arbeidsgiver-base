import { LightningElement, api, track } from 'lwc';

const FOCUS_TRAP_START_ID = 'focus-trap-start';
const FOCUS_TRAP_END_ID = 'focus-trap-end';

export default class TagFlowModalButton extends LightningElement {
    @api flowApiName;
    @api flowInputVariables;
    @api buttonLabel = 'Åpne';
    @api buttonVariant = 'neutral';
    @api buttonIconName;
    @api buttonIconPosition = 'left';
    @api buttonTitle;
    @api modalHeading = '';
    @api closeOnBackdropClick = false;
    @api keepOpenOnFinish = false;

    @track isOpen = false;

    _triggerEl;
    _hasFocused = false;

    @api
    open() {
        this.openModal();
    }

    @api
    close() {
        this.closeModal();
    }

    openModal() {
        this._triggerEl = this.template.querySelector('.triggerButton');
        this.isOpen = true;
        this._hasFocused = false;
    }

    closeModal() {
        if (!this.isOpen) return;
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
        Promise.resolve().then(() => this._restoreFocus());
    }

    renderedCallback() {
        if (this.isOpen && !this._hasFocused) {
            const start = this.template.querySelector(`[data-id="${FOCUS_TRAP_START_ID}"]`);
            if (start) {
                start.focus();
                this._hasFocused = true;
            }
        }
    }

    handleStatusChange(event) {
        const status = event.detail?.status;
        this.dispatchEvent(
            new CustomEvent('statuschange', {
                detail: event.detail
            })
        );
        if (!this.keepOpenOnFinish && (status === 'FINISHED' || status === 'FINISHED_SCREEN')) {
            this.closeModal();
        }
    }

    handleBackdropClick() {
        if (this.closeOnBackdropClick) {
            this.closeModal();
        }
    }

    handleKeyDown(event) {
        if (event.key === 'Escape' || event.key === 'Esc') {
            event.stopPropagation();
            this.closeModal();
            return;
        }
        if (event.key === 'Tab') {
            this._trapFocus(event);
        }
    }

    _trapFocus(event) {
        const start = this.template.querySelector(`[data-id="${FOCUS_TRAP_START_ID}"]`);
        const end = this.template.querySelector(`[data-id="${FOCUS_TRAP_END_ID}"]`);
        if (!start || !end) return;

        const active = this.template.activeElement || document.activeElement;
        if (event.shiftKey) {
            if (active === start) {
                event.preventDefault();
                end.focus();
            }
        } else {
            if (active === end) {
                event.preventDefault();
                start.focus();
            }
        }
    }

    _restoreFocus() {
        if (this._triggerEl && typeof this._triggerEl.focus === 'function') {
            this._triggerEl.focus();
        }
        this._triggerEl = null;
    }
}
