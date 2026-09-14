import { LightningElement, api, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getNavUnitIdByCompanyName from '@salesforce/apex/TAG_UserOfficeHeaderController.getNavUnitIdByCompanyName';

import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import COMPANY_NAME_FIELD from '@salesforce/schema/User.CompanyName';
import REGION_NAME_FIELD from '@salesforce/schema/User.Region__c';
import NAVUNIT_OBJECT from '@salesforce/schema/NavUnit__c';

const FIELDS = [FIRST_NAME_FIELD, LAST_NAME_FIELD, COMPANY_NAME_FIELD, REGION_NAME_FIELD];

export default class TagUserOfficeHeader extends NavigationMixin(LightningElement) {
    @api headerUserAffiliation;
    @api showWelcomeMessage;

    navUnitId;
    navUnitName;
    navUnitUrl;
    userData;
    error;

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    userRecord({ error, data }) {
        if (data) {
            this.userData = data;
            if (this.isNavOffice) {
                this.fetchNavUnit(data.fields.CompanyName.value);
            }
        } else if (error) {
            this.error = error;
        }
    }

    async fetchNavUnit(companyName) {
        if (!companyName) {
            return;
        }
        try {
            const recordId = await getNavUnitIdByCompanyName({ companyName });
            if (recordId) {
                this.navUnitId = recordId;
                this.navUnitName = companyName;
                this.navUnitUrl = `/lightning/r/NavUnit__c/${recordId}/view`;
            }
        } catch (error) {
            this.error = error;
        }
    }

    get isUser() {
        return this.headerUserAffiliation === 'User';
    }

    get isNavOffice() {
        return this.headerUserAffiliation === 'Nav office';
    }

    get isNavRegion() {
        return this.headerUserAffiliation === 'Nav region';
    }

    get isCustom() {
        return !this.isUser && !this.isNavOffice && !this.isNavRegion && !this.isHidden;
    }

    get isHidden() {
        return this.headerUserAffiliation === 'Hidden';
    }
    get headerText() {
        if (this.isUser) {
            return this.fullName;
        }
        if (this.isNavOffice) {
            return this.companyName;
        }
        if (this.isNavRegion) {
            return this.regionName;
        }
        if (this.isCustom) {
            return this.customTitle;
        }
        return '';
    }

    get fullName() {
        const data = this.userData;
        if (data) {
            return `${data.fields.FirstName.value} ${data.fields.LastName.value}`;
        }
        return '';
    }

    get companyName() {
        const data = this.userData;
        return data ? data.fields.CompanyName.value : '';
    }

    get regionName() {
        const data = this.userData;
        return data ? data.fields.Region__c.value : '';
    }

    get customTitle() {
        return this.headerUserAffiliation;
    }

    get showNavUnitLink() {
        return this.isNavOffice && !!this.navUnitId;
    }

    handleNavUnitClick(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.navUnitId,
                objectApiName: NAVUNIT_OBJECT.objectApiName,
                actionName: 'view'
            }
        });
    }
}
