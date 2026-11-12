import { createElement } from 'lwc';
import EmployerAbsenceChart from 'c/employerAbsenceChart';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { loadScript } from 'lightning/platformResourceLoader';

jest.mock('lightning/platformResourceLoader', () => ({ loadScript: jest.fn() }), { virtual: true });

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
};

const record = (quarter, employer, industry) => ({
    fields: {
        CRM_YearQuarter__c: { value: quarter },
        CRM_Percent__c: { value: employer },
        CRM_IndustryCodePercent__c: { value: industry }
    }
});

describe('c-employer-absence-chart', () => {
    let chart;

    beforeEach(() => {
        jest.spyOn(Date.prototype, 'getFullYear').mockReturnValue(2026);
        jest.spyOn(Date.prototype, 'getMonth').mockReturnValue(9);
        chart = { update: jest.fn(), destroy: jest.fn() };
        window.Chart = jest.fn().mockImplementation(() => chart);
        loadScript.mockResolvedValue();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        delete window.Chart;
        jest.restoreAllMocks();
        jest.clearAllMocks();
    });

    function mount() {
        const element = createElement('c-employer-absence-chart', { is: EmployerAbsenceChart });
        element.recordId = '001000000000001AAA';
        document.body.appendChild(element);
        return element;
    }

    it('uses the account related list and groups UI API records by quarter', async () => {
        const element = mount();
        await flushPromises();
        expect(getRelatedListRecords.getLastConfig()).toMatchObject({
            parentRecordId: element.recordId,
            relatedListId: 'Absence__r',
            where: `{ and: [{ CRM_AbsenceCategory__c: { eq: "VIRKSOMHET" } }, { CRM_Year__c: { gt: ${new Date().getFullYear() - 5} } }] }`,
            pageSize: 1999
        });
        getRelatedListRecords.emit({
            records: [record('2026-2', 4, null), record('2026-1', 2, 3), record('2026-1', 1, 2)]
        });
        await flushPromises();
        const config = window.Chart.mock.calls[0][1];
        expect(config.data.labels).toEqual(
            Array.from({ length: 20 }, (_, index) => `${2022 + Math.floor(index / 4)}-${(index % 4) + 1}`)
        );
        expect(config.data.datasets.map((dataset) => dataset.data)).toEqual([
            [...Array(16).fill(null), 3, 4, null, null],
            [...Array(16).fill(null), 5, null, null, null]
        ]);
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('calculates the cutoff year when the component is instantiated', async () => {
        jest.spyOn(Date.prototype, 'getFullYear').mockReturnValue(2030);
        mount();
        await flushPromises();
        expect(getRelatedListRecords.getLastConfig().where).toBe(
            '{ and: [{ CRM_AbsenceCategory__c: { eq: "VIRKSOMHET" } }, { CRM_Year__c: { gt: 2025 } }] }'
        );
    });

    it('waits for ChartJS when records arrive first', async () => {
        let resolveScript;
        loadScript.mockImplementation(
            () =>
                new Promise((resolve) => {
                    resolveScript = resolve;
                })
        );
        mount();
        getRelatedListRecords.emit({ records: [record('2026-1', 2, 3)] });
        await flushPromises();
        expect(window.Chart).not.toHaveBeenCalled();
        resolveScript();
        await flushPromises();
        expect(window.Chart).toHaveBeenCalledTimes(1);
    });

    it('updates the chart on new wire data and destroys it on disconnect', async () => {
        const element = mount();
        await flushPromises();
        getRelatedListRecords.emit({ records: [record('2026-1', 2, 3)] });
        await flushPromises();
        element.recordId = '001000000000002AAA';
        await flushPromises();
        expect(getRelatedListRecords.getLastConfig().parentRecordId).toBe(element.recordId);
        getRelatedListRecords.emit({ records: [record('2026-2', 5, 6)] });
        await flushPromises();
        expect(chart.update).toHaveBeenCalledTimes(1);
        expect(chart.data.labels).toHaveLength(20);
        expect(chart.data.datasets[0].data[17]).toBe(5);
        expect(chart.data.datasets[0].data[16]).toBeNull();
        document.body.removeChild(element);
        expect(chart.destroy).toHaveBeenCalledTimes(1);
    });

    it('handles an empty related list', async () => {
        mount();
        await flushPromises();
        getRelatedListRecords.emit({ records: [] });
        await flushPromises();
        const { data } = window.Chart.mock.calls[0][1];
        expect(data.labels).toHaveLength(20);
        expect(data.datasets.every((dataset) => dataset.data.every((value) => value === null))).toBe(true);
    });

    it('keeps missing quarters at the beginning, middle and end of both series', async () => {
        mount();
        await flushPromises();
        getRelatedListRecords.emit({
            records: [record('2022-2', 0, 3), record('2022-4', 4, 0), record('2026-3', 7, 8)]
        });
        await flushPromises();
        const { labels, datasets } = window.Chart.mock.calls[0][1].data;
        expect(labels[0]).toBe('2022-1');
        expect(labels[labels.length - 1]).toBe('2026-4');
        expect(datasets[0].data.slice(0, 4)).toEqual([null, 0, null, 4]);
        expect(datasets[1].data.slice(0, 4)).toEqual([null, 3, null, 0]);
        expect(datasets.map((dataset) => dataset.data.slice(-2))).toEqual([
            [7, null],
            [8, null]
        ]);
    });

    it.each([
        [0, '2026-1', 17],
        [3, '2026-2', 18],
        [6, '2026-3', 19],
        [9, '2026-4', 20]
    ])('ends the axis at the current quarter for month %i', async (month, lastLabel, length) => {
        Date.prototype.getMonth.mockReturnValue(month);
        mount();
        await flushPromises();
        getRelatedListRecords.emit({ records: [record('2027-1', 9, 9)] });
        await flushPromises();
        const { labels, datasets } = window.Chart.mock.calls[0][1].data;
        expect(labels).toHaveLength(length);
        expect(labels[0]).toBe('2022-1');
        expect(labels[labels.length - 1]).toBe(lastLabel);
        expect(datasets.every((dataset) => dataset.data.every((value) => value === null))).toBe(true);
    });

    it('shows wire errors instead of stale data', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        const element = mount();
        await flushPromises();
        getRelatedListRecords.emit({ records: [record('2026-1', 2, 3)] });
        await flushPromises();
        getRelatedListRecords.error();
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('Feil ved henting av sykefraværsdata');
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(chart.destroy).toHaveBeenCalledTimes(1);
    });

    it('rejects truncated data rather than displaying incomplete sums', async () => {
        const element = mount();
        await flushPromises();
        getRelatedListRecords.emit({ records: [record('2026-1', 2, 3)], nextPageToken: 'next' });
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('For mange sykefraværsposter');
        expect(window.Chart).not.toHaveBeenCalled();
    });

    it('shows script loading errors', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        loadScript.mockRejectedValue(new Error('Load failed'));
        const element = mount();
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('Feil ved lasting av diagram');
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });
});
