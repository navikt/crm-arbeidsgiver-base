/*
Tile consists of the following elements:
metric icon
metric label
metric data
metric trend data
metric trend direction
tile help text
*/
import { LightningElement, api } from 'lwc';

export default class SingleMetricTile extends LightningElement {
    // Public properties
    @api metricIcon;
    @api metricLabel; // The label text should serve as descriptive context for the view.
    @api metricValue; // value is a number representing the most recent reading for the metric available.
    @api metricUnit; // identifies the magnitude of the thing the metric is measuring
    @api metricNote; // text string that provides additional context for understanding what the metric means, why it is important, or anything else about it that a user might find helpful.
    @api metricHelpText;
    /* text and a directional icon with an accessible label to communicate which way the metric is trending. The amount of change can be given as an absolute value, a percentage, or both. The pointer direction is, by convention, up when the metric increases in value, down when it decreases, and pointed to the right when there is no change.
     */
    @api metricTrendIndicator;
    @api metricTrendValue;

    // Internal properties
    _metricValue;
    _metricUnit;
    _metricTrendIndicator;
    _metricTrendValue;
    _metricNote;
    _metricIcon;
    _metricLabel;
    _metricHelpText;

    metricTrend;
    connectedCallback() {
        this.setValues();
        //this.sampleData();
    }

    setValues() {
        this._metricIcon = this.metricIcon;
        this._metricLabel = this.metricLabel;
        this._metricValue = this.metricValue;
        this._metricUnit = this.metricUnit;
        this._metricTrendIndicator = this.metricTrendIndicator;
        this._metricTrendValue = this.metricTrendValue;
        this._metricNote = this.metricNote;
        this._metricHelpText = this.metricHelpText;
        // Parse the metric trend to display the appropriate symbol and value
        this.metricTrend = this.parseMetricTrend();
    }

    parseMetricTrend() {
        if (!this._metricTrendIndicator || !this._metricTrendValue) {
            return null;
        }
        if (this._metricTrendIndicator === 'up') {
            return '↑' + this._metricTrendValue;
        } else if (this._metricTrendIndicator === 'down') {
            return '↓' + this._metricTrendValue;
        } else if (this._metricTrendIndicator === 'right') {
            return '→' + this._metricTrendValue;
        }
        return null;
    }

    sampleData() {
        this._metricIcon = 'standard:account';
        this._metricLabel = 'Andel henvendelser siste 30 dager som ble besvart innen frist';
        this._metricValue = 42;
        this._metricUnit = '%';
        this._metricTrendIndicator = 'up';
        this._metricTrendValue = 10;
        this._metricNote = 'This is a sample note for the metric';
        this._metricHelpText = 'This is a sample help text for the metric';
        // Parse the metric trend to display the appropriate symbol and value
        this.metricTrend = this.parseMetricTrend();
    }
}
