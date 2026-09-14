import { createElement } from 'lwc';
import NavUnitOverview from 'c/navUnitOverview';
import getOverview from '@salesforce/apex/TAG_NavUnitOverviewController.getOverview';

jest.mock(
    '@salesforce/apex/TAG_NavUnitOverviewController.getOverview',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const flushPromises = () => Promise.resolve();

const overviewData = {
    inquiriesClosedCount: 12,
    inquiriesClosedWithinDeadlineCount: 9,
    candidatesPlacedCount: 3,
    candidatesPresentedCount: 4,
    employersWithActivityCount: 7,
    daysSinceLastActivity: 5,
    dataRetrivalTimestamp: '2024-01-15T14:35:22.000Z'
};

describe('c-nav-unit-overview', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows a loading spinner while overview data is loading', () => {
        const element = createElement('c-nav-unit-overview', {
            is: NavUnitOverview
        });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
    });

    it('renders normalized metrics when overview data is returned', async () => {
        const element = createElement('c-nav-unit-overview', {
            is: NavUnitOverview
        });
        element.recordId = 'a01000000000001AAA';
        document.body.appendChild(element);

        getOverview.emit(overviewData);
        await flushPromises();

        const metricTiles = element.shadowRoot.querySelectorAll('c-single-metric-tile');
        expect(metricTiles).toHaveLength(4);
        expect(metricTiles[0].metricValue).toBe('75');
        expect(metricTiles[0].metricUnit).toBe('%');
        expect(metricTiles[0].metricNote).toBe('9 av 12 besvart innen frist siste 90 dager');
        expect(metricTiles[1].metricValue).toBe('75');
        expect(metricTiles[2].metricValue).toBe('7');
        expect(metricTiles[3].metricValue).toBe('5');
    });

    it('formats the retrieval timestamp as hh:mm:ss in addition to relative time', async () => {
        const element = createElement('c-nav-unit-overview', {
            is: NavUnitOverview
        });
        element.recordId = 'a01000000000001AAA';
        document.body.appendChild(element);

        getOverview.emit(overviewData);
        await flushPromises();

        expect(element.dataRetrivalTimestamp).toBe('2024-01-15T14:35:22.000Z');
        expect(element.dataRetrivalTimestampValue).toMatch(/^\d{2}:\d{2}:\d{2}$/);
        expect(element.dataRetrivalTimestampTitle).toContain('Sist oppdatert:');
    });

    it('shows the Apex error message when overview data cannot be loaded', async () => {
        const element = createElement('c-nav-unit-overview', {
            is: NavUnitOverview
        });
        document.body.appendChild(element);

        getOverview.error({ message: 'Tilgang nektet' });
        await flushPromises();

        const errorMessage = element.shadowRoot.querySelector('[role="alert"]');
        expect(errorMessage).not.toBeNull();
        expect(errorMessage.textContent).toBe('Tilgang nektet');
    });
});
