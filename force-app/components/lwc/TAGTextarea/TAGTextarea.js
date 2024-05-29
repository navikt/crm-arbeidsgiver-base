import { LightningElement } from 'lwc';

export default class TAGTextarea extends LightningElement {

    handleChange(event) {
        this.myVal = event.target.value;

        Tag

        //finne en måte å lagre teksten på, så den ikke forsvinner.
        // har jo laget et objekt som heter TAGAdminField__c som vi kan bruke er et rich text area som heter Tavle__c
        // trenger vel apex tror jeg. 
    }

}