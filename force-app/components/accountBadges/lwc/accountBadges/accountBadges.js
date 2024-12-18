import { LightningElement, api, wire } from 'lwc';
import createBadges from '@salesforce/apex/AccountBadgesController.createBadges';

export default class AccountBadges extends LightningElement {
    @api recordId; // Automatically populated in record context
    badges = [];
    error;
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
            this.error = null;
            console.log('Badges:', JSON.stringify(this.badges));
        } else if (error) {
            this.badges = [];
            this.error = error;
            this.renderBadges = false; // No badges to render
            console.error('Error fetching badges:', error);
        }
    }
}
