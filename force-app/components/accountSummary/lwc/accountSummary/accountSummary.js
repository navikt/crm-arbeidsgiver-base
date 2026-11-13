import { LightningElement, api, wire } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getSummary from '@salesforce/apex/AccountSummaryController.getSummary';
import getRecords from '@salesforce/apex/AccountSummaryController.getRecords';

const HOVER_DELAY_MS = 500;
const HIDE_DELAY_MS = 200;
const NAV_CONTACT_KEY = 'navkontakt';
const PERIOD_OPTIONS = [
    { label: '6 mnd', value: '6' },
    { label: '12 mnd', value: '12' }
];

export default class AccountSummary extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api cardTitle;
    @api hideEmptyRows = false;

    months = '6';
    periodOptions = PERIOD_OPTIONS;
    summary;
    error;
    isLoading = true;

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
            this.isLoading = false;
        } else if (error) {
            this.summary = undefined;
            this.error = error;
            this.isLoading = false;
        }
    }

    get monthsAsNumber() {
        return parseInt(this.months, 10);
    }

    /* HEADER AND CONTEXT */

    get title() {
        if (this.cardTitle) {
            return this.cardTitle;
        }
        return this.isInquiryContext ? 'Om arbeidsgiveren' : 'Arbeidsgiveroversikt';
    }

    get isInquiryContext() {
        return this.summary?.isInquiryContext === true;
    }

    get hasSummary() {
        return !!this.summary && this.summary.hasAccount;
    }

    get showNoAccount() {
        return !!this.summary && !this.summary.hasAccount;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Kunne ikke hente oversikt over arbeidsgiveren.';
    }

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }

    /* SUMMARY TEXT */

    get summaryParts() {
        return (this.summary?.summaryParts || []).map((part, index) => ({ ...part, key: `part-${index}` }));
    }

    /* ONGOING */

    get ongoingRows() {
        return (this.summary?.ongoing || [])
            .filter((row) => row.isAccessible)
            .filter((row) => !this.hideEmptyRows || row.count > 0)
            .map((row) => {
                const isEmpty = row.count === 0;
                return {
                    ...row,
                    isEmpty,
                    isClickable: !isEmpty,
                    rowClass: `summary-row slds-grid slds-grid_vertical-align-center${isEmpty ? ' summary-row_empty' : ''}`,
                    ariaLabel: `${row.label}: ${row.count}. Vis poster`
                };
            });
    }

    get hasNavContact() {
        return !!this.summary?.navContact;
    }

    get navContact() {
        return this.summary?.navContact || {};
    }

    get coordinationNotice() {
        return this.summary?.coordinationNotice;
    }

    get hasOngoingActivity() {
        return this.summary?.hasOngoingActivity === true;
    }

    get hasAdditionalNavContacts() {
        return this.navContact.additionalCount > 0;
    }

    get navContactAriaLabel() {
        return `Kontaktpersoner i Nav: ${this.navContact.count}. Vis poster`;
    }

    /* HISTORY */

    get historyMonths() {
        const months = this.summary?.history || [];
        const max = Math.max(1, ...months.map((month) => month.total));
        return months.map((month) => ({
            ...month,
            segments: month.segments.map((segment) => ({
                ...segment,
                id: `${month.key}-${segment.key}`,
                cssClass: `chart-segment history-color_${segment.key}`,
                style: `height: ${(segment.count / max) * 100}%;`,
                title: `${month.fullLabel}: ${segment.label} ${segment.count}`
            }))
        }));
    }

    get chartStyle() {
        return `grid-template-columns: repeat(${this.summary?.history?.length || 6}, 1fr);`;
    }

    get chartAriaLabel() {
        const months = this.summary?.history || [];
        const description = months.map((month) => `${month.fullLabel}: ${month.total}`).join(', ');
        return `Aktivitet per måned siste ${this.months} måneder. ${description}`;
    }

    get historyTotals() {
        return (this.summary?.historyTotals || []).map((item) => ({
            ...item,
            swatchClass: `legend-swatch history-color_${item.key}`
        }));
    }

    get hasHistory() {
        return this.summary?.historyTotal > 0;
    }

    get legendClass() {
        return this.isInquiryContext || this.isMobile ? 'legend legend_single' : 'legend';
    }

    handlePeriodChange(event) {
        this.months = event.detail.value;
    }

    get accountUrl() {
        return this.summary?.accountId ? `/lightning/r/Account/${this.summary.accountId}/view` : undefined;
    }

    /* POPOVER */

    handleRowMouseEnter(event) {
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

    handleRowMouseLeave() {
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

    handleRowClick(event) {
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
        this.popoverStyle = `top: ${top}px;`;
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
        if (this.popoverKey === NAV_CONTACT_KEY) {
            return { label: 'Kontaktpersoner i Nav', icon: 'standard:team_member', count: this.navContact.count };
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
