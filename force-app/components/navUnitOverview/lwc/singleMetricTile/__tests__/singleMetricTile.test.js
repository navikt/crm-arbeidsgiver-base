import { createElement } from '@lwc/engine-dom';
import SingleMetricTile from 'c/singleMetricTile';

describe('c-single-metric-tile', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the supplied metric details and icon', () => {
        const element = createElement('c-single-metric-tile', {
            is: SingleMetricTile
        });
        element.metricIcon = 'standard:account';
        element.metricLabel = 'Arbeidsgivere med aktivitet';
        element.metricValue = '7';
        element.metricUnit = 'stk';
        element.metricNote = 'Basert på fullførte møter og oppgaver';

        document.body.appendChild(element);

        const icon = element.shadowRoot.querySelector('lightning-icon');
        expect(icon.iconName).toBe('standard:account');
        expect(icon.alternativeText).toBe('Illustrativ');
        expect(element.shadowRoot.querySelector('.metric-label-wrapper').textContent).toBe(
            'Arbeidsgivere med aktivitet'
        );
        expect(element.shadowRoot.querySelector('.metric-value').textContent).toBe('7');
        expect(element.shadowRoot.querySelectorAll('.metric-normal')[1].textContent).toBe('stk');
        expect(element.shadowRoot.querySelectorAll('.metric-weak')[1].textContent).toBe(
            'Basert på fullførte møter og oppgaver'
        );
    });

    it.each([
        ['up', '10', '↑10'],
        ['down', '4%', '↓4%'],
        ['right', '0', '→0'],
        [undefined, '10', ''],
        ['unknown', '10', '']
    ])('formats a %s trend as %s', (indicator, value, expectedTrend) => {
        const element = createElement('c-single-metric-tile', {
            is: SingleMetricTile
        });
        element.metricTrendIndicator = indicator;
        element.metricTrendValue = value;

        document.body.appendChild(element);

        const trend = element.shadowRoot.querySelectorAll('.metric-weak')[0];
        expect(trend.textContent).toBe(expectedTrend);
    });
});
