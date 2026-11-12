import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import chartjs from '@salesforce/resourceUrl/TAG_chartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class EmployerAbsenceChart extends LightningElement {
    @api recordId;

    error;
    chart;
    chartjsInitialized = false;
    loadingRecords = true;
    chartData;

    get isLoading() {
        return !this.error && (this.loadingRecords || !this.chartjsInitialized);
    }

    // calculate 4 years ago based on current year
    get cutoffYear() {
        return new Date().getFullYear() - 4;
    }

    get absenceFilter() {
        return `{ and: [{ CRM_AbsenceCategory__c: { eq: "VIRKSOMHET" } }, { CRM_Year__c: { gt: ${this.cutoffYear} } }] }`;
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

    async connectedCallback() {
        try {
            await loadScript(this, chartjs);
            this.chartjsInitialized = true;
        } catch (error) {
            this.error = 'Feil ved lasting av diagram';
            console.error('EmployerAbsenceChart error:', error);
        }
    }

    disconnectedCallback() {
        this.chart?.destroy();
        this.chart = undefined;
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
                this.chartData = undefined;
                this.chart?.destroy();
                this.chart = undefined;
            } else {
                this.processAbsenceData(data.records);
                if (this.chart) {
                    this.chart.data = this.chartData;
                    this.chart.update();
                }
            }
            this.loadingRecords = false;
        } else if (error) {
            this.error = 'Feil ved henting av sykefraværsdata';
            this.chartData = undefined;
            this.chart?.destroy();
            this.chart = undefined;
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
                    borderColor: '#1b96ff',
                    backgroundColor: 'rgba(27, 150, 255, 0.1)',
                    fill: false,
                    tension: 0.4
                },
                {
                    label: 'Næringen',
                    data: labels.map((quarter) => quarters.get(quarter)?.industry ?? null),
                    borderColor: '#3ba755',
                    backgroundColor: 'rgba(59, 167, 85, 0.1)',
                    fill: false,
                    tension: 0.4
                }
            ]
        };
    }

    renderedCallback() {
        if (this.chart || !this.chartData || this.isLoading || this.error) {
            return;
        }

        try {
            const config = {
                type: 'line',
                data: this.chartData,
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'top' },
                        title: {
                            display: true,
                            text: 'Sykefravær - Virksomhet vs Næring'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: { display: true, text: 'Prosent (%)' }
                        },
                        x: {
                            title: { display: true, text: 'År/Kvartal' }
                        }
                    }
                }
            };
            const canvas = this.template.querySelector('canvas');
            this.chart = new window.Chart(canvas.getContext('2d'), config);
        } catch (error) {
            console.error('Error rendering chart:', error);
            this.error = 'Feil ved tegning av diagram';
        }
    }
}
