import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOverview from '@salesforce/apex/TAG_NavUnitOverviewController.getOverview';

export default class NavUnitOverview extends LightningElement {
    @api recordId;

    data;
    error;
    isRefreshing = false;
    wiredResult;

    @wire(getOverview, { navUnitId: '$recordId' })
    wiredOverview(result) {
        this.wiredResult = result;
        this.isRefreshing = false;
        if (result.data) {
            this.data = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
    }

    // to standarize input for metric tiles
    createMetricObject(icon, label, value, unit, note) {
        const metric = {
            metricIcon: icon,
            metricLabel: label,
            metricValue: value,
            metricUnit: unit,
            metricNote: note,
            metricHelpText: null,
            metricTrendIndicator: null,
            metricTrendValue: null
        };
        return metric;
    }

    get hasError() {
        return !!this.error;
    }

    get errorMessage() {
        return this.error?.body?.message || 'Kunne ikke hente nøkkeltall for enheten';
    }

    get isLoading() {
        return !this.data && !this.error;
    }

    get dataRetrivalTimestamp() {
        return this.data?.dataRetrivalTimestamp ?? null;
    }

    get inquiriesAnsweredOnTime() {
        const inquiriesClosedCount = this.data?.inquiriesClosedCount ?? 0;
        const inquiriesClosedWithinDeadlineCount = this.data?.inquiriesClosedWithinDeadlineCount ?? 0;
        const inquiriesAnsweredOnTimePercent =
            inquiriesClosedCount > 0 ? (inquiriesClosedWithinDeadlineCount / inquiriesClosedCount) * 100 : 0;

        const inquiriesSubtitle =
            inquiriesClosedCount === 0
                ? 'Ingen henvendelser besvart siste 90 dager'
                : `${inquiriesClosedWithinDeadlineCount} av ${inquiriesClosedCount} besvart innen frist siste 90 dager`;
        const metric = this.createMetricObject(
            'custom:custom28', // replace with actual icon if available
            'Henvendelser besvart innen frist',
            inquiriesAnsweredOnTimePercent.toFixed(0),
            '%',
            inquiriesSubtitle
        );
        return metric;
    }

    get candidatesPlaced() {
        const candidatesPlacedCount = this.data?.candidatesPlacedCount ?? 0;
        const candidatesPresentedCount = this.data?.candidatesPresentedCount ?? 0;
        const candidatesPlacedPercent =
            candidatesPresentedCount > 0 ? (candidatesPlacedCount / candidatesPresentedCount) * 100 : 0;

        const candidatesPlacedSubtitle =
            candidatesPresentedCount === 0
                ? 'Ingen kandidatpresentasjoner siste 90 dager'
                : `${candidatesPresentedCount} presentert og ${candidatesPlacedCount} formidlet siste 90 dager`;

        const metric = this.createMetricObject(
            'custom:custom21', // replace with actual icon if available
            'Andel kandidatpresentasjoner som ender i formidling',
            candidatesPlacedPercent.toFixed(0),
            '%',
            candidatesPlacedSubtitle
        );
        return metric;
    }

    get employersWithActivity() {
        const employersWithActivityCount = this.data?.employersWithActivityCount ?? 0;
        const metric = this.createMetricObject(
            'standard:account', // replace with actual icon if available
            'Antall arbeidsgivere med aktivitet siste 90 dager',
            employersWithActivityCount.toFixed(0),
            'stk',
            'basert på fullførte møter og oppgaver'
        );
        return metric;
    }

    get daysSinceLastActivity() {
        const daysCount = this.data?.daysSinceLastActivity ?? 0;
        const metric = this.createMetricObject(
            'standard:account',
            'Dager siden siste aktivitet med en arbeidsgiver',
            daysCount.toFixed(0),
            'dager',
            'basert på fullførte møter og oppgaver'
        );
        return metric;
    }

    async handleRefresh() {
        this.data = null;
        this.error = null;
        this.isRefreshing = true;
        await refreshApex(this.wiredResult);
    }

    printJson(value) {
        console.log(JSON.stringify(value, null, 2));
    }
}
