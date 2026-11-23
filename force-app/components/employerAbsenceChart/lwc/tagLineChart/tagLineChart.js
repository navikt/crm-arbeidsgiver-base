import { LightningElement, api } from 'lwc';

import chartjs from '@salesforce/resourceUrl/TAG_chartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class TagLineChart extends LightningElement {
    error;
    chart;
    chartjsInitialized = false;
    loadingScript = false;
    renderedConfig;

    labels;
    datasets;
    horizontalTitle;
    verticalTitle;
    renderScheduled = false;

    @api
    get chartLabels() {
        return this.labels;
    }
    set chartLabels(value) {
        this.labels = value;
        this.scheduleChartRender();
    }

    @api
    get chartData() {
        return this.datasets;
    }
    set chartData(value) {
        this.datasets = value;
        this.scheduleChartRender();
    }

    @api
    get xTitle() {
        return this.horizontalTitle;
    }
    set xTitle(value) {
        this.horizontalTitle = value;
        this.scheduleChartRender();
    }

    @api
    get yTitle() {
        return this.verticalTitle;
    }
    set yTitle(value) {
        this.verticalTitle = value;
        this.scheduleChartRender();
    }

    scheduleChartRender() {
        if (this.renderScheduled) {
            return;
        }
        this.renderScheduled = true;
        Promise.resolve().then(() => {
            this.renderScheduled = false;
            this.renderChart();
        });
    }

    renderedCallback() {
        this.renderChart();
    }

    async renderChart() {
        if (!this.isConnected || !this.template.querySelector('div.chart')) {
            return;
        }
        if (this.loadingScript || this.error || !Array.isArray(this.chartData) || !Array.isArray(this.chartLabels)) {
            return;
        }

        try {
            if (!this.chartjsInitialized) {
                this.loadingScript = true;
                await loadScript(this, chartjs);
                this.chartjsInitialized = true;
            }
            if (!this.isConnected) {
                return;
            }
            const config = this.lineChartConfig(this.chartData, this.chartLabels, this.xTitle, this.yTitle);
            const serializedConfig = JSON.stringify(config);
            if (serializedConfig === this.renderedConfig) {
                return;
            }
            if (this.chart) {
                this.chart.data = config.data;
                this.chart.options = config.options;
                this.chart.update();
            } else {
                const container = this.template.querySelector('div.chart');
                let canvas = container.querySelector('canvas');
                if (!canvas) {
                    canvas = document.createElement('canvas');
                    container.appendChild(canvas);
                }
                this.chart = new window.Chart(canvas.getContext('2d'), config);
            }
            this.renderedConfig = serializedConfig;
        } catch {
            this.error = 'Kunne ikke laste eller tegne diagrammet';
        } finally {
            this.loadingScript = false;
        }
    }

    disconnectedCallback() {
        this.chart?.destroy();
        this.chart = undefined;
        this.renderedConfig = undefined;
    }

    handleRetry() {
        this.chart?.destroy();
        this.chart = undefined;
        this.renderedConfig = undefined;
        this.error = undefined;
    }

    lineChartConfig(chartDatasets, chartLabels, xTitle, yTitle) {
        const labels = [...chartLabels];
        return {
            type: 'line',
            data: {
                labels: labels,
                datasets: chartDatasets.map((dataset) => ({
                    label: dataset.label,
                    data: [...dataset.data],
                    borderColor: dataset.borderColor,
                    fill: false,
                    tension: 0.4
                }))
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: { display: true, text: yTitle }
                    },
                    x: {
                        title: { display: true, text: xTitle }
                    }
                }
            }
        };
    }
}
