import { LightningElement, api } from 'lwc';

export default class relatedRecordsTable extends LightningElement {
    @api records;

    get hasFields() {
        return this.records && this.records.length > 0 && this.records[0].fields?.length > 0;
    }

    // Samler alle felt-labels for tabellhodet
    get fieldLabels() {
        try {
            const labels = new Set();
            this.records.forEach((rec) => {
                (rec.fields || []).forEach((field) => labels.add(field.label));
            });
            return Array.from(labels);
        } catch (error) {
            this.handleError('Error creating recordListTable', error);
        }
        return [];
    }

    get recordListTable() {
        if (this.records && this.records.length > 0) {
            try {
                // Create a new list by mapping over the original records
                const newRecordsList = this.records.map((record) => {
                    // Ensure fields array exists and has at least one element
                    if (record.fields && record.fields.length > 0) {
                        const fieldsCopy = [...record.fields];
                        const field = fieldsCopy.shift(); // Remove the first field

                        return {
                            ...record,
                            title: field.value,
                            fields: fieldsCopy // Keep the remaining fields intact
                        };
                    }

                    // Return the record as-is if fields are empty or undefined
                    return { ...record, fields: [] };
                });

                return newRecordsList;
            } catch (error) {
                this.handleError('Error creating recordListTable', error);
                return [];
            }
        }
        return [];
    }
    /* HELPERS */
    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
}
