import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class TagActivityTimelineNewObject extends NavigationMixin(LightningElement) {

	@api recordId;
	@api row;
	@track fieldValues;


	createRecord() {


		this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: { objectApiName: this.row.SObjectChild__c, actionName: 'new' },
			state: {
				nooverride: '1',
				recordTypeId: this.row.CreataleObject_RecordType__c,
				// setRedirect: 'true', // not working
				// navigationLocation: 'LIST_VIEW',  // works in a hacky fashion, won't open tasks afterwards
				useRecordTypeCheck: 1,
				defaultFieldValues: this.fieldValues
			}
		});

	}

	connectedCallback() {
		let tmp = new Array();

		let relationship = this.getKeyAndValueIfValid(this.row.SObjectRelationshipField__c, this.recordId);
		if (relationship !== null) { tmp.push(relationship); }

		let type = this.getKeyAndValueIfValid(this.row.SObjectTypeField__c, this.row.SObjectTypeValue__c);
		if (type !== null) { tmp.push(type); }



		// combine them all
		let tmpFieldValues = '';
		for (let i = 0; i < tmp.length; i++) {
			tmpFieldValues += tmp[i] + ',';
		}
		this.fieldValues = tmpFieldValues.substring(0, tmpFieldValues.length - 1);

	}

	getKeyAndValueIfValid(key, value) {
		let keyInvalid = this.isInvalid(key);
		let valueInvalid = this.isInvalid(value);
		if (!(keyInvalid || valueInvalid)) {
			return key + "=" + value;
		} else {
			return null;
		}
	}

	isInvalid(input) {

		let checkNull = input === null;
		let checkUndefined = input === undefined;
		let checkStringNull = input === 'null';
		let checkListInvalid = false;

		if (!(checkNull || checkUndefined || checkStringNull)) {
			checkListInvalid = input.includes(';');
		}
		return checkNull || checkUndefined || checkStringNull || checkListInvalid;
	}
}
