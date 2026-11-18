import { LightningElement, api } from 'lwc';

import chartjs from '@salesforce/resourceUrl/TAG_chartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class TagLineChart extends LightningElement {
    error;
    chart;
    chartjsInitialized = false;

    @api chartLabels;
    @api chartData;
    @api xTitle;
    @api yTitle;

    async renderedCallback() {
        if (this.chartjsInitialized) {
            return;
        }
        this.chartjsInitialized = true;

        try {
            await loadScript(this, chartjs);
            const canvas = document.createElement('canvas');
            this.template.querySelector('div.chart').appendChild(canvas);
            const ctx = canvas.getContext('2d');
            const config = this.lineChartConfig(this.chartData, this.chartLabels, this.xTitle, this.yTitle);

            console.log('Chart config:', JSON.stringify(config, null, 2));
            this.chart = new window.Chart(ctx, config);
        } catch (error) {
            this.error = error;
        }
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
