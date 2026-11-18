import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class EmployerAbsenceChart extends LightningElement {
    @api recordId;

    error;

    loadingRecords = true;
    chartData;

    get isLoading() {
        return !this.error && this.loadingRecords;
    }

    // calculate 4 years ago based on current year
    get cutoffYear() {
        return new Date().getFullYear() - 4;
    }

    get absenceFilter() {
        return `{ and: [{ CRM_AbsenceCategory__c: { eq: "VIRKSOMHET" } }, { CRM_Year__c: { gt: ${this.cutoffYear} } }] }`;
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Absence__r',
        fields: ['Absence__c.CRM_YearQuarter__c', 'Absence__c.CRM_Percent__c', 'Absence__c.CRM_IndustryCodePercent__c'],
        sortBy: ['Absence__c.CRM_YearQuarter__c'],
        where: '$absenceFilter',
        pageSize: 1999
    })
    wiredAbsences({ error, data }) {
        if (data) {
            this.error = undefined;
            if (data.nextPageToken) {
                this.error = 'For mange sykefraværsposter til å vise hele diagrammet';
            } else if (data.records.length === 0) {
                this.error = 'Ingen sykefraværsdata tilgjengelig';
            } else {
                this.processAbsenceData(data.records);
            }
            this.loadingRecords = false;
        } else if (error) {
            this.error = 'Feil ved henting av sykefraværsdata';
            this.chartData = undefined;
            this.loadingRecords = false;
            console.error('Error fetching absence data:', error);
        }
    }

    processAbsenceData(records) {
        const quarters = new Map();
        records.forEach(({ fields }) => {
            const quarter = fields.CRM_YearQuarter__c.value;
            const totals = quarters.get(quarter) || { employer: null, industry: null };
            const employer = fields.CRM_Percent__c.value;
            const industry = fields.CRM_IndustryCodePercent__c.value;
            if (employer !== null) {
                totals.employer = (totals.employer ?? 0) + employer;
            }
            if (industry !== null) {
                totals.industry = (totals.industry ?? 0) + industry;
            }
            quarters.set(quarter, totals);
        });
        const labels = this.createQuarterLabels();
        this.chartData = {
            labels,
            datasets: [
                {
                    label: 'Virksomheten',
                    data: labels.map((quarter) => quarters.get(quarter)?.employer ?? null),
                    borderColor: '#90d0fe',
                    fill: false,
                    tension: 0.4
                },
                {
                    label: 'Næringen',
                    data: labels.map((quarter) => quarters.get(quarter)?.industry ?? null),
                    borderColor: '#2e2e2e',
                    fill: false,
                    tension: 0.4
                }
            ]
        };
    }

    createQuarterLabels() {
        const now = new Date();
        const currentYear = now.getFullYear();
        const currentQuarter = Math.floor(now.getMonth() / 3) + 1;
        const labels = [];
        for (let year = this.cutoffYear + 1; year <= currentYear; year++) {
            const lastQuarter = year === currentYear ? currentQuarter : 4;
            for (let quarter = 1; quarter <= lastQuarter; quarter++) {
                labels.push(`${year}-${quarter}`);
            }
        }
        return labels;
    }

    get chartDatasets() {
        // console.log('Chart datasets:', JSON.stringify(this.chartData?.datasets ?? []));
        return this.chartData?.datasets ?? [];
    }
    get chartLabels() {
        // console.log('Chart labels:', JSON.stringify(this.chartData?.labels ?? []));
        return this.chartData?.labels ?? [];
    }
}
