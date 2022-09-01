import { LightningElement, api, wire, track } from 'lwc';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';
import Id from '@salesforce/user/Id';
import deleteTeamMember from '@salesforce/apex/accountTeamMemberController.deleteTeamMember';
import getData from '@salesforce/apex/accountTeamMemberController.getData';

const actions = [
  { label: 'Rediger', name: 'edit' },
  { label: 'Slett', name: 'delete' }
];

const columns = [
  { label: 'Navn', fieldName: 'UserId', initialWidth: 200 },
  { label: 'Rolle', fieldName: 'TeamMemberRole', initialWidth: 200 },
  { label: 'Tema', fieldName: 'Departments' },
  { label: 'NAV-Kontor', fieldName: 'CompanyName', initialWidth: 200 },
  { label: 'Telefon', fieldName: 'MobilePhone', initialWidth: 150 },
  {
    type: 'action',
    typeAttributes: { rowActions: actions }
  }
];

export default class AccountTeamMember extends NavigationMixin(LightningElement) {
  @api recordId;
  @track data;
  @track amount = 0;
  @track columns = columns;
  @track showData = false;
  @track isModalOpen = false;
  @track currentRowId;
  @track currentRowUserId;

  refreshTable;
  error;
  userId = Id;

  @wire(getData, { recordId: '$recordId' })
  member(result) {
    this.refreshTable = result;
    if (result.data) {
      this.data = result.data;
      this.amount = result.data.length;
      this.showData = result.data.length > 0;

      let dataList = [];
      this.data.forEach((element) => {
        let dataElement = {};
        dataElement.Id = element.Id;
        dataElement.UserId = element.User.Name;
        dataElement.TeamMemberRole = element.TeamMemberRole;
        dataElement.Departments = element.Departments__c;
        dataElement.CompanyName = element.User.CompanyName;
        dataElement.MobilePhone = element.User.MobilePhone;
        dataList.push(dataElement);
      });

      this.data = dataList;
    }
  }

  handleRowActions(event) {
    let actionName = event.detail.action.name;
    let row = event.detail.row;
    this.currentRowId = row.Id;
    this.currentRowUserId = row.UserId;

    switch (actionName) {
      case 'delete':
        this.isModalOpen = true;
        break;
      case 'edit':
        this.editRow(row);
        break;
      default:
        break;
    }
  }

  deleteRow() {
    this.isModalOpen = false;
    deleteTeamMember({ atmId: this.currentRowId })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            message: 'Kontaktperson ' + this.currentRowUserId + ' slettet ',
            variant: 'success'
          })
        );

        return refreshApex(this.refreshTable);
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Feil',
            message: error.message,
            variant: 'error'
          })
        );
      });
  }

  editRow(currentRow) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: currentRow.Id,
        objectApiName: 'AccountTeamMember',
        actionName: 'edit'
      }
    });
  }

  navigateToNewRecordPage() {
    const defaultValues = encodeDefaultFieldValues({
      AccountId: this.recordId,
      UserId: this.userId
    });

    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
        objectApiName: 'AccountTeamMember',
        actionName: 'new'
      },
      state: {
        navigationLocation: 'RELATED_LIST',
        defaultFieldValues: defaultValues
      }
    });
  }
  refreshData() {
    return refreshApex(this.refreshTable);
  }
  closeModal() {
    this.isModalOpen = false;
  }

  get isDesktop() {
    return FORM_FACTOR === 'Large' ? true : false;
  }
}
