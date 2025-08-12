import { LightningElement, wire, api, track } from 'lwc';
import getRecentActions from '@salesforce/apex/TAG_RecentActionsListController.getRecentActions';

const DEFAULT_LIMIT = 10;

export default class TagRecentActionsList extends LightningElement {
    @api recordLimit = DEFAULT_LIMIT;
    @api allowedObjects = '';
    @api titleFieldsMapping = '';
    @api secondaryFieldsMapping = '';
    @api cardTitle = 'Siste aktivitet';
    @api helpText; // Hjelpetekst for komponenten
    @api lineSpacing = false;

    @track rawItems = [];
    @track error;

    @wire(getRecentActions, {
        limitSize: '$recordLimit',
        allowedObjects: '$allowedObjects',
        titleFieldsMapping: '$titleFieldsMapping',
        secondaryFieldsMapping: '$secondaryFieldsMapping'
    })
    wiredRecent({ error, data }) {
        if (data) {
            this.rawItems = data.map((rec) => ({
                recordId: rec.recordId,
                displayTitle: rec.displayTitle,
                secondaryOverride: rec.secondaryOverride,
                objectLabel: rec.objectLabel,
                lastViewedDate: rec.lastViewedDate,
                url: rec.url,
                iconName: rec.iconName
            }));
        } else if (error) {
            this.rawItems = [];
            this.error = error;
            console.error('Error in wiredRecent:', error);
        }
    }

    get items() {
        return this.rawItems.map((raw) => {
            const label = raw.objectLabel;
            const secondary = raw.secondaryOverride ? `${label} • ${raw.secondaryOverride}` : label;
            return {
                ...raw,
                secondaryText: secondary,
                rightText: this.formatDateTime(raw.lastViewedDate),
                itemClass: this.lineSpacing
                    ? 'slds-timeline__item slds-media line-spacing'
                    : 'slds-timeline__item slds-media'
            };
        });
    }

    get hasItems() {
        return this.items.length > 0;
    }

    get noItems() {
        return !this.hasItems && !this.error;
    }

    formatDateTime(dtString) {
        if (!dtString) {
            return '';
        }
        const dt = new Date(dtString);
        return dt.toLocaleString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });
    }
}