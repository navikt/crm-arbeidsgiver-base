import { LightningElement, wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import LAST_NAME_FIELD from '@salesforce/schema/User.LastName';

export default class TagUserOfficeHeader extends LightningElement {
  @wire(getRecord, {
    recordId: USER_ID,
    fields: [FIRST_NAME_FIELD, LAST_NAME_FIELD]
  })
  userRecord;

  get fullName() {
    const data = this.userRecord.data;
    if (data) {
      const fn = data.fields.FirstName.value;
      const ln = data.fields.LastName.value;
      return `${fn} ${ln}`;
    }
    return '';
  }
}
