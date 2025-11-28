import { LightningElement, api, wire, track } from 'lwc';
import createBadges from '@salesforce/apex/BadgeController.createBadges';
import getRecords from '@salesforce/apex/BadgeController.getRecords';
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
    hoverTimer; // Control popover display
    hideTimer; // Control popover display

    @track popoverStyle = ''; // Controls popover position
    popoverIsPinned = false; // Prevents popover close from mouse events
    triggerButton = null;

    // Wire service to fetch badges
    @wire(createBadges, { recordId: '$recordId', keys: '$badgesToDisplay' })
    wiredBadges({ error, data }) {
        if (!this.recordId && !this.badgesToDisplay) {
            console.warn('recordId is null or undefined. Skipping Apex call.');
            this.renderBadges = false; // No badges to render
            return;
        }
        if (data) {
            this.badges = data;
            this.renderBadges = this.badges.length > 0; // Check if badges array is empty
            this.cachedRecords.clear(); // Clear cached records when new badges are fetched
            // console.log('Badges:', JSON.stringify(this.badges));
        } else if (error) {
            this.badges = [];
            this.renderBadges = false; // No badges to render
            console.error('Error fetching badges:', error);
        }
    }

    /* POPOVER */
    getFocusableElements(container) {
        return [
            ...container.querySelectorAll(
                'a[href], area[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), [tabindex]:not([tabindex="-1"])'
            )
        ].filter((el) => el.offsetParent !== null || el.getAttribute('tabindex') === '0');
    }

    handleMouseEnter(event) {
        if (this.isDesktop && !this.popoverIsPinned) {
            const triggerRect = event.currentTarget.getBoundingClientRect();
            const hostRect = this.template.host.getBoundingClientRect();
            const top = triggerRect.bottom - hostRect.top + 8; // 8px spacing
            const left = triggerRect.left - hostRect.left;
            this.popoverStyle = `position: absolute; top: ${top}px; left: ${left}px;`;
            const badgeKey = event.currentTarget.dataset.badgekey;

            this.hoverTimer = window.setTimeout(() => {
                this.getList(badgeKey);
                this.showPopover = true;
            }, 500);
        }
    }

    // Når mus forlater badge-området. Forsinker skjuling litt for å tillate flytting mellom lenke og ikon
    handleMouseLeave() {
        if (!this.popoverIsPinned) {
            window.clearTimeout(this.hoverTimer);
            this.hideTimer = window.setTimeout(() => {
                this.handlePopoverClose();
            }, 200);
        }
    }

    // Prevent hiding when mouse enters popover
    handlePopoverEnter() {
        window.clearTimeout(this.hideTimer);
    }

    handlePreviewClick(event) {
        if (this.isDesktop) {
            // Calculate popover position
            const triggerRect = event.currentTarget.getBoundingClientRect();
            const hostRect = this.template.host.getBoundingClientRect();
            const top = triggerRect.bottom - hostRect.top + 8; // 8px spacing
            const left = triggerRect.left - hostRect.left;
            this.popoverStyle = `position: absolute; top: ${top}px; left: ${left}px;`;

            // Get data to display in popover
            const badgeKey = event.currentTarget.dataset.badgekey;
            this.getList(badgeKey);

            this.triggerButton = event.currentTarget;
            this.popoverIsPinned = true;
            this.showPopover = true;
            // Place focus on the first focusable element that isn't the close button. If the close button is the only focusable element, focus should be placed there.
            requestAnimationFrame(() => {
                setTimeout(() => {
                    const popover = this.template.querySelector('.badgepopover');
                    const focusables = this.getFocusableElements(popover);
                    const firstFocusable =
                        focusables.find((el) => el.dataset.id !== 'badge-popover-close') || focusables[0];

                    if (firstFocusable) {
                        firstFocusable.focus();
                    } else {
                        console.warn('No focusable element found in popover');
                    }
                }, 0);
            });
        }
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            event.preventDefault();
            this.handlePopoverClose();
        }
    }

    handlePopoverClose() {
        this.showPopover = false;
        this.records = []; // clear list
        this.popoverIsPinned = false;
        // Return focus to trigger button
        if (this.triggerButton) {
            this.triggerButton.focus();
            this.triggerButton = null;
        }
    }

    /* RELATED RECORDS */
    getList(badgeKey) {
        if (this.cachedRecords.has(badgeKey)) {
            this.records = this.cachedRecords.get(badgeKey);
            return;
        }
        getRecords({
            recordId: this.recordId,
            badgeKey: badgeKey
        })
            .then((data) => {
                this.cachedRecords.set(badgeKey, data);
                this.records = data && data.length > 0 ? data : [];
                // console.log('Records returned:', JSON.stringify(this.records));
            })
            .catch((error) => {
                this.handleError('Error retrieving related records', error);
            });
    }

    /* HELPERS */

    get isMobile() {
        return FORM_FACTOR === 'Small';
    }
    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }

    handleError(message, error) {
        console.error(`${message}:`, JSON.stringify(error));
    }
}
