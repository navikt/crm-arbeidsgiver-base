import { LightningElement, wire, api, track } from 'lwc';
import getRecentItems from '@salesforce/apex/TAG_RecentItemsListController.getRecentItems';

const DEFAULT_LIMIT = 10;

export default class TagRecentItemsList extends LightningElement {
    @api recordLimit = DEFAULT_LIMIT;
    @api allowedObjects = '';
    @api titleFieldsMapping = '';
    @api cardTitle = 'Siste aktivitet';
    @api lineSpacing = false;

    @track rawItems = [];
    @track error;

    @wire(getRecentItems, {
        limitSize: '$recordLimit',
        allowedObjects: '$allowedObjects',
        titleFieldsMapping: '$titleFieldsMapping'
    })
    wiredRecent({ error, data }) {
        if (data) {
            this.rawItems = data.map((rec) => ({
                recordId: rec.recordId,
                displayTitle: rec.displayTitle,
                sobjectType: rec.sobjectType,
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
        if (!this.rawItems || this.rawItems.length === 0) {
            return [];
        }
        return this.rawItems.map((raw) => ({
            ...raw,
            secondaryText: `${raw.sobjectType} • ${this.formatDateTime(raw.lastViewedDate)}`,
            itemClass: this.computeItemClass()
        }));
    }

    get hasItems() {
        return Array.isArray(this.items) && this.items.length > 0;
    }

    get noItems() {
        return !this.hasItems && !this.error;
    }

    computeItemClass() {
        let cls = 'slds-timeline__item slds-media';
        if (this.lineSpacing) {
            cls += ' line-spacing';
        }
        return cls;
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