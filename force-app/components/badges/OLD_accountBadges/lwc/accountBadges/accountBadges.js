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
            if (badge.badgeType === 'Tiltak') {
                publishToAmplitude(this.appName, { type: 'Badge View - Tiltak' });
            } else if (badge.badgeType === 'Muligheter') {
                publishToAmplitude(this.appName, { type: 'Badge View - Muligheter' });
            } else if (badge.badgeType === 'Partnerstatus') {
                publishToAmplitude(this.appName, { type: 'Badge View - Partnerstatus' });
            } else if (badge.badgeType === 'Samarbeidsavtale') {
                publishToAmplitude(this.appName, { type: 'Badge View - Samarbeidsavtale' });
            } else if (badge.badgeType === 'Stillinger') {
                publishToAmplitude(this.appName, { type: 'Badge View - Stillinger' });
            } else if (badge.badgeType === 'IA-samarbeid') {
                publishToAmplitude(this.appName, { type: 'Badge View - IA-samarbeid' });
            }
        });
    }

    handleBadgeClick(event) {
        const badgetype = event.currentTarget.dataset.badgetype;

        if (badgetype === 'Tiltak') {
            publishToAmplitude(this.appName, { type: 'Badge Click - Tiltak' });
        } else if (badgetype === 'Muligheter') {
            publishToAmplitude(this.appName, { type: 'Badge Click - Muligheter' });
        } else if (badgetype === 'Partnerstatus') {
            publishToAmplitude(this.appName, { type: 'Badge Click - Partnerstatus' });
        } else if (badgetype === 'Samarbeidsavtale') {
            publishToAmplitude(this.appName, { type: 'Badge Click - Samarbeidsavtale' });
        } else if (badgetype === 'Stillinger') {
            publishToAmplitude(this.appName, { type: 'Badge Click - Stillinger' });
        } else if (badgetype === 'IA-samarbeid') {
            publishToAmplitude(this.appName, { type: 'Badge Click - IA-samarbeid' });
        }
    }
}
