import { LightningElement, api, wire } from 'lwc';
import createBadges from '@salesforce/apex/AccountBadgesController.createBadges';
import { publishToAmplitude } from 'c/amplitude';

export default class AccountBadges extends LightningElement {
    @api recordId; // Automatically populated in record context
    badges = [];
    renderBadges = false; // Should be true if badges are returned, false if not

    // Wire service to fetch badges
    @wire(createBadges, { accountId: '$recordId' })
    wiredBadges({ error, data }) {
        if (!this.recordId) {
            console.warn('recordId is null or undefined. Skipping Apex call.');
            this.renderBadges = false; // No badges to render
            return;
        }
        if (data) {
            this.badges = data;
            this.renderBadges = this.badges.length > 0; // Check if badges array is empty
            //console.log('Badges:', JSON.stringify(this.badges));
            this.appName = localStorage.getItem('currentAppName') || 'Unknown App';
            this.handleBadgeDisplay();
        } else if (error) {
            this.badges = [];
            this.renderBadges = false; // No badges to render
            console.error('Error fetching badges:', error);
        }
    }

    handleBadgeDisplay() {
        this.badges.forEach(badge => {
            if (badge.label.includes('Aktive tiltak')) {
                publishToAmplitude(this.appName, { type: 'Badge View - Tiltak' });
            } else if (badge.label.includes('Muligheter')) {
                publishToAmplitude(this.appName, { type: 'Badge View - Muligheter' });
            } else if (badge.helpText.includes('partnerstatus')) {
                publishToAmplitude(this.appName, { type: 'Badge View - Partnerstatus' });
            } else if (badge.helpText.includes('samarbeidsavtale')) {
                publishToAmplitude(this.appName, { type: 'Badge View - Samarbeidsavtale' });
            }
        });
    }

    handleBadgeClick(event) {
        const label = event.currentTarget.dataset.label;
        const helpText = event.currentTarget.dataset.helptext;

        if (label.includes('Aktive tiltak')) {
            publishToAmplitude(this.appName, { type: 'Badge Click - Tiltak' });
        } else if (label.includes('Muligheter')) {
            publishToAmplitude(this.appName, { type: 'Badge Click - Muligheter' });
        } else if (helpText.includes('partnerstatus')) {
            publishToAmplitude(this.appName, { type: 'Badge Click - Partnerstatus' });
        } else if (helpText.includes('samarbeidsavtale')) {
            publishToAmplitude(this.appName, { type: 'Badge Click - Samarbeidsavtale' });
        }
    }
}
