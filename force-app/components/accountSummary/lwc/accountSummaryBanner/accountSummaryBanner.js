import { LightningElement, api, wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getSummary from '@salesforce/apex/AccountSummaryController.getSummary';
import getRecords from '@salesforce/apex/AccountSummaryController.getRecords';

const HOVER_DELAY_MS = 500;
const HIDE_DELAY_MS = 200;

const ONGOING_NOUNS = {
    avtale: ['aktiv avtale', 'aktive avtaler'],
    stilling: ['aktiv direktemeldt stilling', 'aktive direktemeldte stillinger'],
    tiltak: ['aktivt tiltak', 'aktive tiltak'],
    ia: ['pågående IA-samarbeid', 'pågående IA-samarbeid'],
    mulighet: ['åpen mulighet', 'åpne muligheter'],
    henvendelse: ['åpen henvendelse', 'åpne henvendelser'],
    planlagt: ['planlagt møte/oppgave', 'planlagte møter/oppgaver']
};

const INQUIRY_CONTEXT_NOUNS = {
    henvendelse: ['annen åpen henvendelse', 'andre åpne henvendelser']
};

const HISTORY_NOUNS = {
    avtale: ['avsluttet avtale', 'avsluttede avtaler'],
    stilling: ['avsluttet stilling', 'avsluttede stillinger'],
    tiltak: ['avsluttet tiltak', 'avsluttede tiltak'],
    ia: ['avsluttet IA-samarbeid', 'avsluttede IA-samarbeid'],
    mulighet: ['avsluttet mulighet', 'avsluttede muligheter'],
    henvendelse: ['avsluttet henvendelse', 'avsluttede henvendelser'],
    mote: ['gjennomført møte/oppgave', 'gjennomførte møter/oppgaver'],
    kommunikasjon: ['loggført telefon/e-post/SMS', 'loggførte telefoner/e-poster/SMS'],
    formidling: ['formidling/kandidat/kampanje', 'formidlinger/kandidater/kampanjer']
};

function noun(nouns, key, count) {
    const forms = nouns[key];
    if (!forms) {
        return '';
    }
    return count === 1 ? forms[0] : forms[1];
}

export default class AccountSummaryBanner extends LightningElement {
    @api recordId;
    @api months = '6';
    @api hideHistory = false;
    @api hideWhenEmpty = false;

    summary;
    error;

    showPopover = false;
    popoverStyle = '';
    popoverKey;
    popoverRecords = [];
    popoverLoading = false;
    popoverError;
    popoverIsPinned = false;
    cachedRecords = new Map();
    hoverTimer;
    hideTimer;
    triggerElement;

    @wire(getSummary, { recordId: '$recordId', months: '$monthsAsNumber' })
    wiredSummary({ data, error }) {
        if (data) {
            this.summary = data;
            this.error = undefined;
        } else if (error) {
            this.summary = undefined;
            this.error = error;
        }
    }

    get monthsAsNumber() {
        return parseInt(this.months, 10) === 12 ? 12 : 6;
    }

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }

    /* CONTENT */

    get hasOngoingActivity() {
        return this.summary?.hasOngoingActivity === true;
    }

    get hasHistory() {
        return !this.hideHistory && this.historyLines.length > 0;
    }

    get hasNavContact() {
        return !!this.summary?.navContact;
    }

    get isInquiryContext() {
        return this.summary?.isInquiryContext === true;
    }

    get renderBanner() {
        if (!this.summary?.hasAccount) {
            return false;
        }
        return !this.hideWhenEmpty || this.hasOngoingActivity || this.hasHistory;
    }

    get bannerClass() {
        return `summary-banner slds-grid${this.hasOngoingActivity ? ' summary-banner_active' : ' summary-banner_neutral'}`;
    }

    get title() {
        return this.hasOngoingActivity
            ? 'Pågående aktivitet: Anbefalt å koordinere før du tar kontakt'
            : 'Ingen pågående aktivitet registrert';
    }

    get ongoingLines() {
        const nouns = this.isInquiryContext ? { ...ONGOING_NOUNS, ...INQUIRY_CONTEXT_NOUNS } : ONGOING_NOUNS;
        return (this.summary?.ongoing || [])
            .filter((row) => row.isAccessible && row.count > 0)
            .map((row) => {
                const text = `${row.count} ${noun(nouns, row.key, row.count)}`;
                return {
                    key: row.key,
                    text,
                    details: [row.details, row.pill, row.secondaryDetails].filter((part) => !!part).join(' · '),
                    ariaLabel: `${text}. Vis poster`,
                    helpText: row.helpText
                };
            });
    }

    get navContactText() {
        const contact = this.summary?.navContact;
        if (!contact) {
            return '';
        }
        const unit = contact.unit ? ` · ${contact.unit}` : '';
        const more = contact.additionalCount > 0 ? ` (+${contact.additionalCount})` : '';
        return `Kontaktperson i Nav: ${contact.name}${unit}${more}`;
    }

    get historyTitle() {
        return `Siste ${this.monthsAsNumber} mnd`;
    }

    get historyLines() {
        return (this.summary?.historyTotals || []).map((item) => ({
            key: item.key,
            text: `${item.count} ${noun(HISTORY_NOUNS, item.key, item.count)}`
        }));
    }

    get accountUrl() {
        return this.summary?.accountId ? `/lightning/r/Account/${this.summary.accountId}/view` : undefined;
    }

    /* POPOVER */

    handleLineMouseEnter(event) {
        if (this.isMobile || this.popoverIsPinned) {
            return;
        }
        const target = event.currentTarget;
        window.clearTimeout(this.hideTimer);
        window.clearTimeout(this.hoverTimer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.hoverTimer = window.setTimeout(() => {
            this.openPopover(target, target.dataset.key);
        }, HOVER_DELAY_MS);
    }

    handleLineMouseLeave() {
        if (this.popoverIsPinned) {
            return;
        }
        window.clearTimeout(this.hoverTimer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.hideTimer = window.setTimeout(() => {
            this.closePopover(false);
        }, HIDE_DELAY_MS);
    }

    handlePopoverMouseEnter() {
        window.clearTimeout(this.hideTimer);
    }

    handleLineClick(event) {
        window.clearTimeout(this.hoverTimer);
        const target = event.currentTarget;
        this.triggerElement = target;
        this.popoverIsPinned = true;
        this.openPopover(target, target.dataset.key);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.template.querySelector('[data-id="popover-close"]')?.focus();
        });
    }

    handlePopoverKeyDown(event) {
        if (event.key === 'Escape') {
            event.preventDefault();
            this.closePopover(true);
        }
    }

    handlePopoverClose() {
        this.closePopover(true);
    }

    openPopover(target, key) {
        const triggerRect = target.getBoundingClientRect();
        const hostRect = this.template.host.getBoundingClientRect();
        const top = triggerRect.bottom - hostRect.top + 8;
        const left = this.isMobile ? 0 : Math.max(0, triggerRect.left - hostRect.left);
        this.popoverStyle = `top: ${top}px; left: ${left}px;`;
        this.popoverKey = key;
        this.showPopover = true;
        this.loadRecords(key);
    }

    closePopover(returnFocus) {
        this.showPopover = false;
        this.popoverIsPinned = false;
        this.popoverKey = undefined;
        this.popoverRecords = [];
        this.popoverError = undefined;
        if (returnFocus && this.triggerElement) {
            this.triggerElement.focus();
        }
        this.triggerElement = undefined;
    }

    loadRecords(key) {
        this.popoverError = undefined;
        if (this.cachedRecords.has(key)) {
            this.popoverRecords = this.cachedRecords.get(key);
            this.popoverLoading = false;
            return;
        }
        this.popoverRecords = [];
        this.popoverLoading = true;
        getRecords({ recordId: this.recordId, key })
            .then((data) => {
                const records = data || [];
                this.cachedRecords.set(key, records);
                if (this.popoverKey === key) {
                    this.popoverRecords = records;
                }
            })
            .catch((error) => {
                if (this.popoverKey === key) {
                    this.popoverError = error?.body?.message || 'Kunne ikke hente poster.';
                }
            })
            .finally(() => {
                if (this.popoverKey === key) {
                    this.popoverLoading = false;
                }
            });
    }

    get popoverRow() {
        if (this.popoverKey === 'navkontakt') {
            return {
                label: 'Kontaktpersoner i Nav',
                icon: 'standard:team_member',
                count: this.summary?.navContact?.count
            };
        }
        return (this.summary?.ongoing || []).find((row) => row.key === this.popoverKey) || {};
    }

    get hasPopoverRecords() {
        return !this.popoverLoading && !this.popoverError && this.popoverRecords.length > 0;
    }

    get showPopoverEmpty() {
        return !this.popoverLoading && !this.popoverError && this.popoverRecords.length === 0;
    }

    get popoverClass() {
        return `summary-popover slds-popover slds-nubbin_top-left${this.isMobile ? ' summary-popover_mobile' : ''}`;
    }

    disconnectedCallback() {
        window.clearTimeout(this.hoverTimer);
        window.clearTimeout(this.hideTimer);
    }
}
