import { LightningElement, wire, api, track } from 'lwc';
import getRecentItems from '@salesforce/apex/TAG_RecentItemsListController.getRecentItems';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

const DEFAULT_LIMIT = 10;

export default class TagRecentItemsList extends LightningElement {
    @api recordLimit = DEFAULT_LIMIT;
    @api allowedObjects = '';
    @api titleFieldsMapping = '';
    @api secondaryFieldsMapping = '';
    @api cardTitle = 'Siste aktivitet';
    @api lineSpacing = false;

    @track rawItems = [];
    @track error;
    @track objectApiNames = [];
    @track objectLabels = {};

    @wire(getRecentItems, {
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
                sobjectType: rec.sobjectType,
                lastViewedDate: rec.lastViewedDate,
                url: rec.url,
                iconName: rec.iconName
            }));
            this.objectApiNames = [...new Set(this.rawItems.map((i) => i.sobjectType))];
        } else if (error) {
            this.rawItems = [];
            this.error = error;
            console.error('Error in wiredRecent:', error);
        }
    }

    @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
    wiredInfos({ error, data }) {
        if (data) {
            const labels = {};
            Object.keys(data).forEach((apiName) => {
                labels[apiName] = data[apiName].label;
            });
            this.objectLabels = labels;
        } else if (error) {
            console.error('Error fetching object labels', error);
        }
    }

    get items() {
        return this.rawItems.map((raw) => {
            const label = this.objectLabels[raw.sobjectType] || raw.sobjectType;
            const secondaryField = raw.secondaryOverride;
            return {
                ...raw,
                secondaryText: secondaryField ? `${label} • ${secondaryField}` : `${label}`,
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