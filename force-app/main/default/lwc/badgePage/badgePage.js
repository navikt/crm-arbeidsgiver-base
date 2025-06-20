import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getSettings from '@salesforce/apex/BadgeController.getSettings';
import { getRecord } from 'lightning/uiRecordApi';
import getRecords from '@salesforce/apex/BadgeController.getRecords';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class BadgePage extends LightningElement {
    @track recordId;
    @track badgeKey;
    @track isConfigLoaded = false;

    @track iconName;
    @track cardTitle;

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }

    @track records = [];
    @track error;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef) {
            this.badgeKey = pageRef?.state?.c__badge;
            this.recordId = pageRef?.state?.c__id;
            this.initBadgeFlow();
        }
    }

    initBadgeFlow() {
        if (this.recordId && this.badgeKey) {
            getSettings({ badgeKey: this.badgeKey })
                .then((data) => {
                    if (data) {
                        this.cardTitle = data.listTitle;
                        this.iconName = data.icon;
                        this.isConfigLoaded = true;
                        this.getList();
                    } else {
                        console.error('No settings found for badge type:', this.badgeKey);
                    }
                })
                .catch((error) => {
                    this.handleError('Error retrieving badge settings', error);
                });
        }
    }

    // Fetch related records
    getList() {
        getRecords({
            recordId: this.recordId,
            badgeKey: this.badgeKey
        })
            .then((data) => {
                this.records = data && data.length > 0 ? data : [];
                // console.log('Records returned:', JSON.stringify(this.records));
            })
            .catch((error) => {
                this.handleError('Error retrieving related records', error);
            });
    }

    /** Get Account name from breadcrumbs */

    @wire(getRecord, { recordId: '$recordId', fields: '$dynamicField' })
    wiredRecordFields({ error, data }) {
        if (data) {
            this.parentRecordName = data.fields[this.fieldApiName].value;
        } else if (error) {
            // Handle error
            console.error(error);
        }
    }
    get dynamicField() {
        return [`${this.parentRecordObject}.${this.fieldApiName}`];
    }
    parentRecordObject = 'Account';
    fieldApiName = 'Name';
    parentRecordName;

    get parentRecordUrl() {
        return `/${this.recordId}`;
    }

    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
}
