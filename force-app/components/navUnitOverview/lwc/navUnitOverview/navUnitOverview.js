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
            metricTrendValue: null,
            metricValue2: null,
            metricUnit2: null
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
                ? 'ingen henvendelser besvart siste 90 dager'
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

        const metric = this.createMetricObject(
            'custom:custom21', // replace with actual icon if available
            'Statistikk fra Rekrutteringsbistand',
            candidatesPlacedCount.toFixed(0),
            'formidlinger',
            'for siste 90 dager'
        );
        // Set additional metric values for multi-number display
        metric.metricValue2 = candidatesPresentedCount;
        metric.metricUnit2 = 'kandidatpresentasjoner';
        return metric;
    }

    get employersWithActivity() {
        const employersWithActivityCount = this.data?.employersWithActivityCount ?? 0;
        const metric = this.createMetricObject(
            'standard:account', // replace with actual icon if available
            'Arbeidsgivere med aktivitet siste 90 dager',
            employersWithActivityCount.toFixed(0),
            'stk',
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
