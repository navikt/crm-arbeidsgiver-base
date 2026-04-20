import { LightningElement, api, track } from 'lwc';

export default class CallToActionCard extends LightningElement {

    @api recordId;
    @api cardTitle   = 'Title';
    @api cardText    = 'Add a description for next best action.';
    @api buttonLabel = 'Create record';
    @api flowApiName;

    @track showFlowModal = false;

    handleAction() {
        event.stopPropagation();
        if (!this.flowApiName) {
            console.warn('nextBestActionCard: no flowApiName configured.');
            return;
        }
        this.showFlowModal = true;
        requestAnimationFrame(() => {
            const flowCmp = this.template.querySelector('lightning-flow');
            if (flowCmp) {
                flowCmp.startFlow(this.flowApiName, [
                    { name: 'recordId', type: 'String', value: this.recordId }
                ]);
            }
        });
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    closeModal() {
        this.showFlowModal = false;
    }
}