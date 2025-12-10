import { LightningElement, api, wire, track } from 'lwc';
import fetchOpenTasks from '@salesforce/apex/TAG_NarrowListViewActivitiesController.fetchOpenTasks';
import fetchOpenEvents from '@salesforce/apex/TAG_NarrowListViewActivitiesController.fetchOpenEvents';
import closeTask from '@salesforce/apex/TAG_NarrowListViewActivitiesController.closeTask';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getIaRecordTypeIds from '@salesforce/apex/TAG_NarrowListViewActivitiesController.getIaRecordTypeIds';

export default class TagNarrowListViewActivities extends NavigationMixin(LightningElement) {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    // Configuration Properties
    @api objectApiName; // = 'CustomOpportunity__c';
    @api listViewApiName; // = 'TAG_Mine_pne_muligheter'; // List view navn for å hente records
    @api newRecordButton; // = false; // Om knappen for å opprette ny record skal vises
    @api altTextNewRecordButton; // = 'Opprett ny mulighet'; // Alternativ tekst for knappen for å opprette ny record
    @api pageSize; // = 10; // Maks antall records å hente
    @api previewRecords; // = 4;
    @api titleText; // = 'Mine muligheter'; // Tittel for komponentet
    @api helpText; // = 'Dette er en hjelpetekst for komponentet.'; // Hjelpetekst for komponentet
    @api iconName; // = 'custom:custom14';
    @api titleFieldInput; // = 'TAG_Link__c';
    @api detailFieldInput; // = 'Account__r.Name'; // Felt som brukes for å vise detaljer i listen
    @api warningTextInput; // = 'Denne oppføringen er eldre enn 1 dag og er i "Ny henvendelse" stadiet.';
    @api warningCriteriaInput; // = 'ActivityDate < LAST_N_DAYS:1'; // Kriterier for å vise advarsel

    @api flowName = 'TAG_New_Activity';
    @api recordId;
    showModal = false;

    // State Properties
    error;
    records = [];
    isRefreshing = true;
    // Wire Results
    wiredListViewRecordsResult;
    nextPageToken;
    count;
    wiredOpenTasksResult;
    iaTaskRecordTypeId;
    iaEventRecordTypeId;

    connectedCallback() {
        getIaRecordTypeIds()
            .then((result) => {
                if (Array.isArray(result)) {
                    result.forEach((rt) => {
                        if (rt.developerName === 'IA_task') {
                            this.iaTaskRecordTypeId = rt.id;
                        } else if (rt.developerName === 'IA_event') {
                            this.iaEventRecordTypeId = rt.id;
                        }
                    });
                }
            })
            .catch((error) => {
                console.error('Error loading IA record types', error);
            });
    }
    // Action Configuration
    @track recordLevelActions = [
        { id: 'record-edit-1', label: 'Rediger', value: 'edit' },
        { id: 'record-complete-1', label: 'Fullfør oppgave', value: 'complete' },
        { id: 'record-followup-1', label: 'Opprett oppfølgingsoppgave', value: 'followup' },
        { id: 'record-followup-1', label: 'Opprett oppfølgingsmøte', value: 'followupEvent' }
    ];

    get hasMoreRecords() {
        return this.nextPageToken === null ? false : true;
    }

    get listViewUrl() {
        return `/lightning/o/${this.objectApiName}/list?filterName=${this.listViewApiName}`;
    }

    get cardTitle() {
        if (this.isRefreshing) {
            return this.titleText + ' (...)';
        }
        if (this.hasMoreRecords) {
            return this.titleText + ' (' + this.count + '+)';
        }
        return this.titleText + ' (' + this.count + ')';
    }

    get paddedRecords() {
        const padded = [...this.records];
        const placeholdersNeeded = this.previewRecords - padded.length;
        for (let i = 0; i < placeholdersNeeded; i++) {
            padded.push({ id: `placeholder-${i}`, isPlaceholder: true });
        }
        return padded;
    }

    // =========================
    // WIRE METHODS
    // =========================

    @wire(fetchOpenTasks, { limitSize: '$pageSize' })
    wiredTasks(result) {
        if (this.objectApiName !== 'Task') return;
        this.processResult(result);
    }

    @wire(fetchOpenEvents, { limitSize: '$pageSize' })
    wiredEvents(result) {
        if (this.objectApiName !== 'Event') return;
        this.processResult(result);
    }

    processResult(result) {
        this.wiredOpenTasksResult = result;
        const { data, error } = result;
        this.isRefreshing = false;

        if (data) {
            this.error = undefined;
            this.count = data.records.length;
            this.nextPageToken = data.count > this.pageSize ? 'MORE' : null;

            this.records = data.records.slice(0, this.previewRecords).map((item) => {
                const now = new Date();
                const todayMid = new Date(now.getFullYear(), now.getMonth(), now.getDate());

                const dueDate = item.ActivityDate ? new Date(item.ActivityDate) : null;
                const isOverdue = dueDate && dueDate < todayMid;

                let title;
                if (this.objectApiName === 'Event') {
                    const start = item.StartDateTime
                        ? new Date(item.StartDateTime).toLocaleString(undefined, {
                              year: 'numeric',
                              month: '2-digit',
                              day: '2-digit',
                              hour: '2-digit',
                              minute: '2-digit'
                          })
                        : '';

                    title = `${start} - ${item.Subject || ''}`;
                } else {
                    // Task
                    title = item.Subject || '';
                }

                return {
                    id: item.Id,
                    title: title,
                    whatId: item.WhatId,
                    whoId: item.WhoId,
                    relatedObject: item.What?.Type,
                    titleLink: `/lightning/r/${this.objectApiName}/${item.Id}/view`,
                    detailLine: this.getSObjectFieldValue(item, this.detailFieldInput),
                    showWarning: isOverdue
                };
            });
        } else if (error) {
            this.error = error;
            this.records = [];
            console.error('Error fetching open tasks/events:', error);
        }
    }

    // =========================
    // EVENT HANDLERS
    // =========================

    handleRecordLevelAction(event) {
        // Get the value of the selected action
        const selectedItemValue = event.detail.value;
        const recordId = event.target.dataset.recordId; // Hent recordId fra data attributtet
        const rec = this.records.find((r) => r.id === recordId);

        switch (selectedItemValue) {
            case 'edit':
                this.navigateToRecordEdit(recordId);
                break;

            case 'complete':
                this.markTaskComplete(recordId);
                break;

            case 'followup':
                this.createFollowUpTask(rec);
                break;

            case 'followupEvent':
                this.createFollowUpEvent(rec);
                break;

            default:
                console.warn('Ukjent handling valgt:', selectedItemValue);
        }
    }

    handleNewRecord() {
        this.showModal = true;

        requestAnimationFrame(() => {
            const flowCmp = this.template.querySelector('lightning-flow');
            if (flowCmp) {
                let inputVars = [];
                flowCmp.startFlow(this.flowName, inputVars);
            }
        });
    }

    handleFlowStatusChange(event) {
        const status = event.detail.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN' || status === 'ERROR') {
            this.showModal = false;
        }
    }

    closeModal() {
        this.showModal = false;
    }

    // =========================
    // NAVIGATION METHODS
    // =========================

    navigateToRecordEdit(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'edit'
            }
        });
    }

    navigateToListView(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: this.listViewApiName
            }
        });
    }

    navigateToRecord(event) {
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }

    async markTaskComplete(taskId) {
        try {
            await closeTask({ taskId });
            this.showToast('Success', 'Oppgaven ble fullført', 'success');
            refreshApex(this.wiredOpenTasksResult);
        } catch (e) {
            this.showToast('Error', 'Fullføring av oppgaven feilet: ' + e.body.message, 'error');
        }
    }

    createFollowUpTask(currentRecord) {
        const defaultValues = {};

        defaultValues.Subject = currentRecord.title;
        if (currentRecord.whatId) defaultValues.WhatId = currentRecord.whatId;
        if (currentRecord.whoId) defaultValues.WhoId = currentRecord.whoId;
        if (currentRecord.relatedObject === 'IACooperation__c' && this.iaTaskRecordTypeId) {
            defaultValues.TAG_IsIAPriority__c = true;
            defaultValues.TAG_ActivityType__c = 'Forebygge sykefravær og redusere frafall';
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { objectApiName: 'Task', actionName: 'new' },
                state: {
                    recordTypeId: this.iaTaskRecordTypeId,
                    defaultFieldValues: encodeDefaultFieldValues(defaultValues)
                }
            });
        }

        if (currentRecord.relatedObject !== 'IACooperation__c' && this.iaTaskRecordTypeId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: { objectApiName: 'Task', actionName: 'new' },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(defaultValues)
                }
            });
        }
    }

    createFollowUpEvent(currentRecord) {
        const defaultValues = {};

        if (currentRecord.whatId) {
            defaultValues.WhatId = currentRecord.whatId;
        }
        if (currentRecord.whoId) {
            defaultValues.WhoId = currentRecord.whoId;
        }
        if (currentRecord.relatedObject === 'IACooperation__c' && this.iaEventRecordTypeId) {
            defaultValues.TAG_IsIAPriority__c = true;
            defaultValues.TAG_ActivityType__c = 'Forebygge sykefravær og redusere frafall';
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Event',
                    actionName: 'new'
                },
                state: {
                    recordTypeId: this.iaEventRecordTypeId,
                    defaultFieldValues: encodeDefaultFieldValues(defaultValues)
                }
            });
        }

        if (currentRecord.relatedObject !== 'IACooperation__c' && this.iaEventRecordTypeId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Event',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues(defaultValues)
                }
            });
        }
    }

    // =========================
    // RECORD PROCESSING
    // =========================

    getSObjectFieldValue(record, fieldPath) {
        if (!record || !fieldPath) return '';
        return (
            fieldPath.split('.').reduce((obj, part) => (obj && obj[part] !== undefined ? obj[part] : null), record) ||
            ''
        );
    }

    // =========================
    // UTILITY METHODS
    // =========================

    refreshList() {
        return refreshApex(this.wiredOpenTasksResult);
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}