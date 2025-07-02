import { LightningElement, api, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import { NavigationMixin } from 'lightning/navigation';
export default class OpportunityListView extends NavigationMixin(LightningElement) {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    // Configuration Properties
    @api objectApiName; // = 'CustomOpportunity__c';
    @api listViewApiName; // = 'TAG_Mine_pne_muligheter'; // List view navn for å hente records
    @api pageSize; // = 4; // Maks antall records å vise
    @api titleText; // = 'Mine muligheter'; // Tittel for komponentet
    @api helpText; // = 'Dette er en hjelpetekst for komponentet.'; // Hjelpetekst for komponentet
    @api iconName; // = 'custom:custom14';
    @api titleFieldInput; // = 'TAG_Link__c';
    @api detailFieldInput; // = 'Account__r.Name'; // Felt som brukes for å vise detaljer i listen
    @api warningCriteriaInput; // = '{{TAG_Age__c}} > 1 && {{InclusionStage__c}} == "Ny henvendelse"';
    @api warningTextInput; // = 'Denne oppføringen er eldre enn 1 dag og er i "Ny henvendelse" stadiet.';

    // State Properties
    error;
    records = [];
    isRefreshing = true;
    // Wire Results
    wiredListViewRecordsResult;
    nextPageToken;
    count;
    // Action Configuration
    @track recordLevelActions = [{ id: 'record-edit-1', label: 'Edit', value: 'edit' }];

    get warningFields() {
        return this.extractMergeFields(this.warningCriteriaInput);
    }

    get queryFields() {
        let fields = [];
        fields.push(this.objectApiName + '.' + this.titleFieldInput);
        if (this.detailFieldInput) {
            fields.push(this.objectApiName + '.' + this.detailFieldInput);
        }

        this.warningFields.forEach((field) => {
            fields.push(this.objectApiName + '.' + field);
        });
        return fields;
    }

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

    // =========================
    // WIRE METHODS
    // =========================

    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$queryFields',
        pageSize: '$pageSize'
    })
    wiredListViewRecords(result) {
        this.wiredListViewRecordsResult = result;
        if (result.data) {
            console.log('listRecords data:', JSON.stringify(result.data, null, 2));
            this.records = result.data.records.map((record) => this.createDataItemFromRecord(record));
            this.nextPageToken = result.data.nextPageToken;
            this.count = result.data.count;
            this.error = undefined;
            this.isRefreshing = false;
        } else if (result.error) {
            console.error('Feil ved henting av records:', result.error);
            this.error = result.error;
            this.records = [];
            this.isRefreshing = false;
        }
    }

    // =========================
    // EVENT HANDLERS
    // =========================

    handleRecordLevelAction(event) {
        // Get the value of the selected action
        const selectedItemValue = event.detail.value;
        const recordId = event.target.dataset.recordId; // Hent recordId fra data attributtet
        if (selectedItemValue === 'edit') {
            // Håndter redigeringshandling
            this.navigateToRecordEdit(recordId, this.objectApiName);
        } else {
            console.warn('Ukjent handling valgt:', selectedItemValue);
        }
    }

    handleNewRecord() {
        this.navigateToRecordNew(this.objectApiName);
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

    navigateToRecordNew(objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'
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

    // =========================
    // RECORD PROCESSING
    // =========================

    createDataItemFromRecord(record) {
        return {
            id: record.id,
            title: this.getFieldValue(record, this.titleFieldInput),
            titleLink: '/lightning/r/' + record.apiName + '/' + record.id + '/view',
            detailLine: this.getFieldValue(record, this.detailFieldInput),
            showWarning: this.shouldShowWarning(record)
        };
    }

    getFieldValue(record, fieldName) {
        if (!fieldName) {
            return '';
        }
        if (this.isRelatedField(fieldName)) {
            return this.getNestedFieldValue(record, fieldName);
        }
        const fieldData = record.fields[fieldName];
        if (!fieldData) {
            return '';
        }
        if (fieldName === this.titleFieldInput) {
            return this.sanitizeHtml(fieldData.value);
        }
        return fieldData.displayValue ?? fieldData.value ?? '';
    }

    // =========================
    // WARNING LOGIC
    // =========================

    shouldShowWarning(record) {
        if (!this.warningCriteriaInput) {
            return false;
        }
        try {
            const warningCondition = this.resolveMergeFields(this.warningCriteriaInput, record);

            return this.evaluateBooleanExpression(warningCondition);
        } catch (error) {
            console.error('Error evaluating warning criteria:', error);
            return false;
        }
    }

    resolveMergeFields(mergeTemplate, record) {
        let condition = mergeTemplate.replace(/\bTODAY\b/g, `"${new Date().toISOString().split('T')[0]}"`);
        // Iterate fields used in warning criteria and replace them with their values
        this.extractMergeFields(mergeTemplate).forEach((field) => {
            // Get field data from record
            const fieldData = record.fields?.[field];
            if (!fieldData) {
                console.warn(`Field ${field} not found in record`);
                return;
            }
            // Add "" around string values
            const value = typeof fieldData.value === 'string' ? `"${fieldData.value}"` : fieldData.value;

            // Replace {{field}} with value
            const fieldPattern = `{{${field}}}`;
            condition = condition.replaceAll(fieldPattern, value);
        });
        //console.log('Resolved '+mergeTemplate+' to '+ condition);
        return condition;
    }

    /**
     * Simple regex-based parser for basic expressions. Handles field comparisons, AND/OR operators, parentheses
     */
    evaluateBooleanExpression(expression) {
        expression = expression.trim();
        // Split by AND/OR operators while preserving them
        const tokens = expression.split(/(\s+&&\s+|\s+\|\|\s+|\s+AND\s+|\s+OR\s+)/i);
        // Evaluate first comparison
        let result = this.evaluateComparison(tokens[0]);

        for (let i = 1; i < tokens.length; i += 2) {
            const operator = tokens[i].trim().toUpperCase();
            const nextComparison = this.evaluateComparison(tokens[i + 1]);

            if (operator === '&&' || operator === 'AND') {
                result = result && nextComparison;
            } else if (operator === '||' || operator === 'OR') {
                result = result || nextComparison;
            }
        }
        //console.log('Evaluated expression '+ expression+'to '+ result);
        return result;
    }

    /**
     * Evaluate a single comparison
     */
    evaluateComparison(comparison) {
        comparison = comparison.trim();
        // Handle different comparison operators
        const operators = ['>=', '<=', '!=', '==', '>', '<'];
        for (const op of operators) {
            if (comparison.includes(op)) {
                const [left, right] = comparison.split(op).map((s) => s.trim());
                const leftValue = this.parseValue(left);
                const rightValue = this.parseValue(right);

                switch (op) {
                    case '==':
                        return leftValue === rightValue;
                    case '!=':
                        return leftValue !== rightValue;
                    case '>':
                        return leftValue > rightValue;
                    case '<':
                        return leftValue < rightValue;
                    case '>=':
                        return leftValue >= rightValue;
                    case '<=':
                        return leftValue <= rightValue;
                }
            }
        }
        // If no operator found, treat as boolean value
        return this.parseValue(comparison);
    }

    // =========================
    // UTILITY METHODS
    // =========================

    extractMergeFields(mergeTemplate) {
        if (!mergeTemplate) return [];
        // Finn alle feltnavn i warningCriteriaInput som er omsluttet av {{ }}
        const fieldPattern = /\{\{([^}]+)\}\}/g;
        const fieldNames = [];
        let match;
        while ((match = fieldPattern.exec(mergeTemplate)) !== null) {
            fieldNames.push(match[1]);
        }
        return fieldNames;
    }

    sanitizeHtml(input) {
        return input?.replace(/<[^>]+>/g, '') ?? '';
    }

    isRelatedField(fieldName) {
        return fieldName.includes('__r.');
    }

    getNestedFieldValue(record, fieldName) {
        const parts = fieldName.split('.');

        let current = record.fields;

        for (const part of parts) {
            const field = current?.[part];
            if (!field) return '';

            // Hvis vi er på siste del
            if (part === parts.at(-1)) {
                return field.displayValue ?? field.value ?? '';
            }

            // Gå ett nivå dypere
            current = field.value?.fields;
            if (!current) return '';
        }

        return '';
    }

    /**
     * Parse string value to appropriate type
     */
    parseValue(value) {
        value = value.trim();

        // Remove quotes from strings
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            return value.slice(1, -1);
        }

        // Parse numbers
        if (!isNaN(value) && !isNaN(parseFloat(value))) {
            return parseFloat(value);
        }

        // Parse booleans
        if (value.toLowerCase() === 'true') return true;
        if (value.toLowerCase() === 'false') return false;

        // Return as string
        return value;
    }
}
