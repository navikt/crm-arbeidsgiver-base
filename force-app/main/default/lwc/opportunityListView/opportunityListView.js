import { LightningElement, api, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import { NavigationMixin } from 'lightning/navigation';

export default class OpportunityListView extends NavigationMixin(LightningElement) {
    @api objectApiName; // = 'CustomOpportunity__c';
    @api listViewApiName; // = 'TAG_Mine_pne_muligheter'; // List view navn for å hente records
    @api pageSize; // = 4; // Maks antall records å vise

    @api titleText; // = 'Mine muligheter'; // Tittel for komponentet
    @api helpText; // = 'Dette er en hjelpetekst for komponentet.'; // Hjelpetekst for komponentet
    @api iconName; // = 'custom:custom14';

    @api titleFieldInput; // = 'TAG_Link__c';
    @api detailFieldInput; // = 'Account__r.Name'; // Felt som brukes for å vise detaljer i listen

   @api warningCriteriaInput; // = '{{TAG_Age__c}} > 1 && {{InclusionStage__c}} == "Ny henvendelse"';
   @api warningTextInput;// = 'Denne oppføringen er eldre enn 1 dag og er i "Ny henvendelse" stadiet.'; 

    error;
    records = [];
    displayColumns;
    listReference;
    isRefreshing = true;
    wiredListViewRecordsResult;

    nextPageToken; // For å håndtere neste side
    count;

    @track recordLevelActions = [{ id: 'record-edit-1', label: 'Edit', value: 'edit' }];

    get warningFields() {
        if (!this.warningCriteriaInput) return [];
        // Finn alle feltnavn i warningCriteriaInput som er omsluttet av {{ }}
       // const fieldPattern = /\{{([^}]+)\}}/g;
        const fieldPattern = /\{\{([^}]+)\}\}/g;
        const fieldNames = [];
        let match;
        
        while ((match = fieldPattern.exec(this.warningCriteriaInput)) !== null) {
            fieldNames.push(match[1]);
        }
        console.log('warningFields:', JSON.stringify(fieldNames, null, 2));
        return fieldNames;
    }

    get queryFields() {
        let fields = [];
        fields.push(this.objectApiName + '.' + this.titleFieldInput);
        fields.push(this.objectApiName + '.' + this.detailFieldInput);
        this.warningFields.forEach((field) => {
            fields.push(this.objectApiName + '.' + field);
        });
     console.log('queryFields:', JSON.stringify(fields, null, 2));
        return fields;
    }

    displayWarning(record) {
         if (!this.warningCriteriaInput || !this.warningFields.length) {return false;}
        try {
        let condition = this.warningCriteriaInput.replace(/\bTODAY\b/g, `"${new Date().toISOString().split('T')[0]}"`);
        // Iterate fields used in warning criteria and replace them with their values
        this.warningFields.forEach((field) => {
            // Get field data from record
            const fieldData = record.fields?.[field];
            if (!fieldData) {
                console.warn(`Field ${field} not found in record`);
                return;
            }
            // Add "" around string values
            const value = typeof fieldData.value === 'string' 
                    ? `"${fieldData.value}"`
                    : fieldData.value;
            
            // Replace {{field}} with value
            const fieldPattern = `{{${field}}}`;
            condition = condition.replaceAll(fieldPattern, value);
        });
        return this.evaluateBooleanExpression(condition); 
    } catch (error) {
        console.error('Error evaluating warning criteria:', error);
        return false;
    }
    }

    // Hent records når listViewId og felter er tilgjengelige
    @wire(getListRecordsByName, {
        objectApiName: '$objectApiName',
        listViewApiName: '$listViewApiName',
        fields: '$queryFields',
        pageSize: '$pageSize'
    })
    wiredListViewRecords(result) {
        if (result.data) {
            // console.log('listRecords data:', JSON.stringify(result.data, null, 2));
            this.records = result.data.records.map((record) => {
                let title = record.fields[this.titleFieldInput]
                    ? this.sanitizeHtml(record.fields[this.titleFieldInput].value)
                    : null;
                let detailLine;
                if (this.isRelatedField(this.detailFieldInput)) {
                    detailLine = this.getNestedFieldValue(record, this.detailFieldInput);
                } else {
                    detailLine = record.fields[this.detailFieldInput]
                        ? record.fields[this.detailFieldInput].value
                        : null;
                }

                let listRecord = {
                    id: record.id,
                    title: title,
                    titleLink: '/lightning/r/' + record.apiName + '/' + record.id + '/view',
                    detailLine: detailLine,
                    showWarning: this.displayWarning(record)
                };
                return listRecord;
            });
            // console.log('this.records data:', JSON.stringify(this.records, null, 2));
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


    // NavigationMixin

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

    // Helpers
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
     * Safely evaluate boolean expressions without Function constructor
     * @param {string} expression - Processed expression string
     * @returns {boolean} - Evaluation result
     */
    evaluateBooleanExpression(expression) {
        // Simple regex-based parser for basic expressions
        // This handles: field comparisons, AND/OR operators, parentheses

        // Remove extra whitespace
        expression = expression.trim();

        // Split by AND/OR operators while preserving them
        const tokens = expression.split(/(\s+&&\s+|\s+\|\|\s+|\s+AND\s+|\s+OR\s+)/i);

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

        return result;
    }

    /**
     * Evaluate a single comparison
     * @param {string} comparison - Single comparison expression
     * @returns {boolean} - Comparison result
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

    /**
     * Parse string value to appropriate type
     * @param {string} value - String value to parse
     * @returns {any} - Parsed value
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
