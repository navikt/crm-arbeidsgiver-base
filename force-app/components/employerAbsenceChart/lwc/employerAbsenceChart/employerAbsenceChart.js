import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class EmployerAbsenceChart extends LightningElement {
    accountId;

    @api
    get recordId() {
        return this.accountId;
    }
    set recordId(value) {
        if (value !== this.accountId) {
            this.accountId = value;
            this.chartData = undefined;
            this.error = undefined;
            this.loadingRecords = true;
        }
    }

    error;

    loadingRecords = true;
    chartData;
    userMessage;

    get isLoading() {
        return !this.error && this.loadingRecords;
    }

    get showChart() {
        return !this.isLoading && !this.error && !!this.chartData;
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
            this.userMessage = undefined;
            this.chartData = undefined;
            if (data.nextPageToken) {
                this.error = 'For mange sykefraværsposter til å vise hele diagrammet';
            } else if (data.records.length === 0) {
                this.userMessage = 'Ingen sykefraværsdata tilgjengelig';
            } else {
                this.processAbsenceData(data.records);
            }
            this.loadingRecords = false;
        } else if (error) {
            if (error?.body?.statusCode === 400) {
                this.error = 'Sykefraværsdata utilgjengelig';
            } else {
                this.error = 'Feil ved henting av sykefraværsdata';
            }
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
        return this.chartData?.datasets ?? [];
    }
    get chartLabels() {
        return this.chartData?.labels ?? [];
    }
}
