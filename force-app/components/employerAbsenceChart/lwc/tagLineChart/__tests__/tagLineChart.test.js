import { createElement } from 'lwc';
import TagLineChart from 'c/tagLineChart';
import { loadScript } from 'lightning/platformResourceLoader';

jest.mock('lightning/platformResourceLoader', () => ({ loadScript: jest.fn() }), { virtual: true });

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
};

describe('c-tag-line-chart', () => {
    let chart;

    beforeEach(() => {
        chart = { update: jest.fn(), destroy: jest.fn() };
        window.Chart = jest.fn(() => chart);
        loadScript.mockResolvedValue();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        delete window.Chart;
        jest.clearAllMocks();
    });

    function mount(withData = true) {
        const element = createElement('c-tag-line-chart', { is: TagLineChart });
        if (withData) {
            element.chartLabels = ['2026-1'];
            element.chartData = [{ label: 'Virksomheten', data: [2] }];
        }
        document.body.appendChild(element);
        return element;
    }

    it('updates data and titles without creating another chart', async () => {
        const element = mount();
        await flushPromises();
        element.chartLabels = ['2026-2'];
        element.chartData = [{ label: 'Virksomheten', data: [5] }];
        element.yTitle = 'Prosent';
        await flushPromises();
        expect(window.Chart).toHaveBeenCalledTimes(1);
        expect(chart.update).toHaveBeenCalledTimes(1);
        expect(chart.data.labels).toEqual(['2026-2']);
        expect(chart.data.datasets[0].data).toEqual([5]);
        expect(chart.options.scales.y.title.text).toBe('Prosent');
    });

    it('waits for inputs and creates mutable copies of parent arrays', async () => {
        const element = mount(false);
        await flushPromises();
        expect(loadScript).not.toHaveBeenCalled();
        const values = Object.freeze([null, 3]);
        element.chartLabels = Object.freeze(['2026-1', '2026-2']);
        element.chartData = Object.freeze([Object.freeze({ label: 'Test', data: values })]);
        await flushPromises();
        const config = window.Chart.mock.calls[0][1];
        config.data.datasets[0].data.push(4);
        config.data.labels.push('2026-3');
        expect(values).toEqual([null, 3]);
    });

    it('destroys the chart when removed and recreates it when reconnected', async () => {
        const element = mount();
        await flushPromises();
        element.remove();
        expect(chart.destroy).toHaveBeenCalledTimes(1);
        document.body.appendChild(element);
        await flushPromises();
        expect(window.Chart).toHaveBeenCalledTimes(2);
    });

    it('does not create a chart after being removed while the script loads', async () => {
        let resolveScript;
        loadScript.mockImplementationOnce(
            () =>
                new Promise((resolve) => {
                    resolveScript = resolve;
                })
        );
        const element = mount();
        await flushPromises();
        element.remove();
        resolveScript();
        await flushPromises();
        expect(window.Chart).not.toHaveBeenCalled();
    });

    it('allows retry after script loading fails', async () => {
        loadScript.mockRejectedValueOnce(new Error('Load failed'));
        const element = mount();
        await flushPromises();
        expect(element.shadowRoot.textContent).toContain('Kunne ikke laste eller tegne diagrammet');
        element.shadowRoot.querySelector('lightning-button').click();
        await flushPromises();
        expect(loadScript).toHaveBeenCalledTimes(2);
        expect(window.Chart).toHaveBeenCalledTimes(1);
    });
});
