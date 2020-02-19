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
				recordTypeId: this.row.Activity_Timeline_Child__r.CreateableObject_RecordType__c,
				navigationLocation: 'LOOKUP',
				useRecordTypeCheck: 1,
				defaultFieldValues: this.fieldValues
			}
		});
	}

	connectedCallback() {
		let fields = new Array();

		let relationship = this.getKeyAndValueIfValid(this.row.SObjectRelationshipField__c, this.recordId);
		if (relationship !== null) { fields.push(relationship); }

		let type = this.getKeyAndValueIfValid(this.row.Activity_Timeline_Child__r.SObjectTypeField__c, this.row.Activity_Timeline_Child__r.SObjectTypeValue__c);
		if (type !== null) { fields.push(type); }

		let val1 = this.getKeyAndValueIfValid(this.row.Activity_Timeline_Child__r.CreateableObject_Field1__c, this.row.Activity_Timeline_Child__r.CreateableObject_Value1__c);
		if (val1 !== null) { fields.push(val1); }

		let val2 = this.getKeyAndValueIfValid(this.row.Activity_Timeline_Child__r.CreateableObject_Field2__c, this.row.Activity_Timeline_Child__r.CreateableObject_Value2__c);
		if (val2 !== null) { fields.push(val2); }

		let val3 = this.getKeyAndValueIfValid(this.row.Activity_Timeline_Child__r.CreateableObject_Field3__c, this.row.Activity_Timeline_Child__r.CreateableObject_Value3__c);
		if (val3 !== null) { fields.push(val3); }

		// combine them all
		let fieldsCombined = '';
		for (let i = 0; i < fields.length; i++) {
			fieldsCombined += fields[i] + ',';
		}

		var d = new Date();
		fieldsCombined = fieldsCombined.replace('{today}', d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate());
		this.fieldValues = fieldsCombined.substring(0, fieldsCombined.length - 1);
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