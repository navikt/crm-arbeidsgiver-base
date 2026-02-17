import { LightningElement, api, wire, track } from 'lwc';
import createBadges from '@salesforce/apex/BadgeController.createBadgesWithRelatedRecords';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Badges extends LightningElement {
    @api recordId; // Automatically populated in record context
    @api badgesToDisplay; // = 'Muligheter, Stillinger,Tiltak,IA-samarbeid, Strategisk partner,Markedssammarbeid';
    badges = []; // List of badges to display
    renderBadges = false; // Should be true if badges are returned, false if not
    @track records = []; // Records that will be displayed in popup
    cachedRecords = new Map(); // Stores response from getRecords with badge type as key.
    @track columns; // Columns that will be displayed in popup

    @track showPopover = false; // Control popover display

    // Popover size configuration - adjust as needed
    maxTilesPerRow = 1; // Maximum number of record tiles per row to display in popover
    tileWidth = 400; // Width of each record tile displayed in popover (including padding/margin)

    // Wire service to fetch badges
    @wire(createBadges, { recordId: '$recordId', keys: '$badgesToDisplay' })
    wiredBadges({ error, data }) {
        if (!this.recordId && !this.badgesToDisplay) {
            console.warn('recordId is null or undefined. Skipping Apex call.');
            this.renderBadges = false; // No badges to render
            return;
        }
        if (data) {
            this.badges = data.map((badge) => {
                // create new property for popover width
                return {
                    ...badge,
                    popoverWidth: this.calculatePopoverWidth(badge.relatedRecords.length),
                    isSingleRecord: badge.relatedRecords.length === 1,
                    pageref: {
                        type: 'standard__component',
                        attributes: {
                            componentName: 'c__badgePage'
                        },
                        state: {
                            c__id: this.recordId,
                            c__badge: badge.badgeKey
                        }
                    }
                };
            });
            this.renderBadges = this.badges.length > 0; // Check if badges array is empty
            this.cachedRecords.clear(); // Clear cached records when new badges are fetched
            // console.log('Badges:', JSON.stringify(this.badges));
        } else if (error) {
            this.badges = [];
            this.renderBadges = false; // No badges to render
            console.error('Error fetching badges:', error);
        }
    }

    addNewProperty(obj, key, value) {
        return { ...obj, [key]: value };
    }

    /**
     * Calculate popover width based on number of returned records, number of tiles per row, and tile width.
     * Width is either number of records * tile width, or max tiles per row * tile width, whichever is smaller.
     */
    calculatePopoverWidth(recordCount) {
        var width = 0;
        if (recordCount === 1) {
            width = this.tileWidth;
        } else if (recordCount > 1) {
            width = this.windowWidth;
        }
        console.log('calculatePopoverWidth: ' + width);
        return width;
    }

    /* HELPERS */

    // Get window size
    get windowWidth() {
        return window.innerWidth;
    }

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }

    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
    remToPx(rem) {
        const rootFontSize = parseFloat(getComputedStyle(document.documentElement).fontSize);
        return rem * rootFontSize;
    }
}
