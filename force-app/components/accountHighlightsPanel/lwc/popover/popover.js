import { LightningElement, api, track } from 'lwc';

/**
 * A generic popover button utility component that displays the specified icon name with the
 * given attributes.
 * @param iconName: Passed onto the button's `iconName` attribute
 * @param tooltip: Passed onto the button's `tooltip` attribute
 * @param title: Passed onto the button's `title` attribute
 * @param linkUrl: URL for the trigger link (if any)
 * @param linkLabel: Text for the trigger link (if any)
 * @slot body The HTML to place in the popup window's body
 */
export default class Popover extends LightningElement {
    static delegatesFocus = true;

    // ========================================
    // Constants
    // ========================================
    POPOVER_ANCHOR_ID = 'popover-link';

    // ========================================
    // Public API Properties
    // ========================================
    @api iconName = 'utility:preview'; // Icon displayed in trigger button
    @api tooltip = ''; // Tooltip text for button
    @api title = ''; // Title for popover dialog
    @api linkUrl = ''; // URL for the trigger link
    @api linkLabel = 'Show Popover'; // Text for the trigger link

    // ========================================
    // State Management
    // ========================================
    showPopover = false; // Controls popover visibility
    triggerId = ''; // Tracks what triggered popover ('popover-link' or 'popover-button')
    hasButtonFocus = false; // Tracks if button has focus
    keepPopoverOpen = false; // Flag to prevent accidental closing

    // ========================================
    // Timers
    // ========================================
    keyDownListener = null; // Reference to keyboard event listener
    hideTimer; // Timer for delayed popover hiding (hover mode)

    // ========================================
    // Styling & Positioning
    // ========================================
    @track popoverStyle = 'transform: translate(0px, 0px);'; // Dynamic popover position
    @track pointerStyle = 'top: 0px; left: 0px;'; // Dynamic nubbin/pointer position

    // Position data for nubbin (the small pointer/arrow)
    nubbin = {
        width: 0,
        height: 0,
        x: 0,
        y: 0
    };

    // Position and size data for popover
    popover = {
        width: 380,
        minHeight: 100,
        x: 0,
        y: 0,
        position: 'left' // Can be 'left' or 'below'
    };

    // Position data for anchor element (trigger link)
    anchor = {
        width: 0,
        height: 0,
        x: 0,
        y: 0
    };

    // ========================================
    // Computed Properties / Getters
    // ========================================

    /* Ensure trigger elements are above backdrop */
    get triggerContainerStyle() {
        return this.showPopover ? 'position: relative; z-index: 6001;' : '';
    }
    /**
     * Show backdrop only when popover is opened via button click (not hover)
     * Backdrop catches clicks outside popover to close it
     */
    get shouldShowBackdrop() {
        return this.showPopover && this.triggerId === 'popover-button';
    }

    /**
     * Dynamic CSS classes for the pointer/nubbin based on position
     */
    get pointerClassNames() {
        return `popover-pointer pointer_${this.popover.position}`;
    }

    /**
     * Dynamic CSS classes for trigger button (shows when focused)
     */
    get triggerButtonClassNames() {
        return 'trigger-button' + (this.hasButtonFocus ? ' trigger-button-focus' : '');
    }

    /**
     * ARIA attribute indicating popover state
     */
    get ariaHaspopup() {
        return this.showPopover;
    }

    /**
     * Get first focusable element within popover
     * Used for setting initial focus when popover opens
     */
    get firstFocusableElementId() {
        const popover = this.template.querySelector('.popover-wrapper');
        if (!popover) {
            return null;
        }
        return popover.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    }

    // ========================================
    // Event Handlers - Mouse/Hover Interactions
    // ========================================

    /**
     * Handle mouse entering trigger link (hover to open)
     */
    handleMouseEnter(event) {
        this.debugEvent(event);
        if (event.target.dataset.id === this.POPOVER_ANCHOR_ID) {
            this.triggerId = 'popover-link';
            // Clear any pending hide timer
            if (this.hideTimer) {
                window.clearTimeout(this.hideTimer);
                this.hideTimer = null;
            }

            // Only open popover if it's not already open
            if (!this.showPopover) {
                this.popoverPosition();
                this.showPopover = true;

                // Use setTimeout to ensure DOM is updated before setting focus
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {}, 0);
                this.addKeyDownListener();
            }
        }
    }

    /**
     * Handle mouse leaving trigger link or popover
     * Delays closing to allow mouse movement between link and popover
     */
    handleMouseLeave(event) {
        this.debugEvent(event);
        if (this.triggerId === 'popover-link') {
            if (this.hideTimer) {
                window.clearTimeout(this.hideTimer);
            }

            // Delay closing popover to allow mouse movement to popover content
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.hideTimer = window.setTimeout(() => {
                this.closePopover();
            }, 500);
        } else if (this.triggerId === 'popover-button') {
            // Don't auto-close when triggered by button
        }
    }

    /**
     * Handle mouse entering popover content
     * Cancels delayed closing to keep popover open
     */
    handlePopoverEnter(event) {
        this.debugEvent(event);
        if (this.triggerId === 'popover-link') {
            // Prevent hiding when entering the popover
            if (this.hideTimer) {
                window.clearTimeout(this.hideTimer);
                this.hideTimer = null;
            }
        }
    }

    // ========================================
    // Event Handlers - Button/Click Interactions
    // ========================================

    /**
     * Handle button click to toggle popover
     * Opens/closes popover and manages focus
     */
    handleButtonClick(event) {
        this.debugEvent(event);
        this.triggerId = 'popover-button';
        this.showPopover = !this.showPopover;
        this.hasButtonFocus = true;
        this.keepPopoverOpen = this.showPopover;

        if (this.showPopover) {
            this.popoverPosition();
            // Use setTimeout to ensure DOM is updated before setting focus
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                const element = this.firstFocusableElementId;
                if (element) {
                    console.log('Setting focus to first focusable element:', element);
                    //element.focus();
                } else {
                    console.warn('No focusable element found, falling back to close button');
                    // this.setFocusToElement('popover-close');
                }
            }, 0);
            this.addKeyDownListener();
        } else {
            this.removeKeyDownListener();
        }
    }

    /**
     * Handle clicks on the backdrop (outside popover)
     * Only active when popover is opened via button click
     */
    handleBackdropClick() {
        console.log('Backdrop clicked - closing popover');
        this.hasButtonFocus = false;
        this.closePopover();
    }

    /**
     * Handle close button click
     */
    handlePopoverClose() {
        if (this.triggerId === 'popover-button') {
            this.hasButtonFocus = true;
            // Set focus back to trigger button
            this.setFocusToElement(this.triggerId);
        }
        this.closePopover();
    }

    // ========================================
    // Event Handlers - Focus Management
    // ========================================

    /**
     * Handle focus entering button or link
     */
    handleButtonFocusIn(event) {
        this.hasButtonFocus = true;
        this.debugEvent(event);
    }

    /**
     * Handle focus leaving button or link
     */
    handleButtonFocusOut(event) {
        this.hasButtonFocus = this.showPopover ? true : false;
        this.debugEvent(event);
    }

    // ========================================
    // Positioning Logic
    // ========================================

    /**
     * Calculate popover and pointer position relative to trigger link
     * Positions popover to the left of trigger, or below if not enough space
     */
    popoverPosition() {
        const target = this.template.querySelector(`[data-id="${this.POPOVER_ANCHOR_ID}"]`);
        const rect = target.getBoundingClientRect();
        this.anchor.height = rect.height;
        this.anchor.width = rect.width;
        this.anchor.x = rect.x;
        this.anchor.y = rect.y;

        // Positioned left of target
        this.popover.position = 'left';
        const targetVerticalCenter = this.anchor.y + this.anchor.height / 2;

        const pointerSize = this.remToPx(1.25) + this.remToPx(0.0625); // pointer size is calc(1.25rem + 0.0625rem), 29.7px/2 = 14.85px
        this.nubbin.width = pointerSize;
        this.nubbin.height = pointerSize;
        const nubbinXoffset = pointerSize * Math.sqrt(2); // 21px

        this.nubbin.x = this.anchor.x - nubbinXoffset; // Position nubbin at the right edge of the link
        this.nubbin.y = targetVerticalCenter - this.nubbin.height / 2; // Center pointer vertically
        this.pointerStyle = `top: ${this.nubbin.y}px; left: ${this.nubbin.x}px;`;

        this.popover.x = this.nubbin.x - this.popover.width + this.nubbin.width / 2; // Til venstre
        this.popover.y = this.anchor.y - this.popover.minHeight / 2;
        this.popoverStyle = `width: ${this.popover.width}px; min-height: ${this.popover.minHeight}px; transform: translate(${this.popover.x}px, ${this.popover.y}px);`;

        if (this.popover.x < 0) {
            // Vis popover under target
            this.popover.position = 'below';
            const targetHorizontalCenter = this.anchor.x + this.anchor.width / 2;
            this.nubbin.x = targetHorizontalCenter - this.nubbin.width / 2; // Center pointer vertically
            //  const nubbinYoffset = pointerSize * Math.sqrt(2); // 21px
            this.nubbin.y = this.anchor.y + this.anchor.height; // Position nubbin at the bottom edge of the link
            this.pointerStyle = `top: ${this.nubbin.y}px; left: ${this.nubbin.x}px;`;

            this.popover.x = this.anchor.x;
            this.popover.y = this.nubbin.y + this.nubbin.width / 2;
            this.popoverStyle = `width: ${this.popover.width}px; min-height: ${this.popover.minHeight}px; transform: translate(${this.popover.x}px, ${this.popover.y}px);`;
        }
    }

    /**
     * Convert rem units to pixels based on root font size
     */
    remToPx(rem) {
        const rootFontSize = parseFloat(getComputedStyle(document.documentElement).fontSize);
        console.log('rootFontSize:', rootFontSize);
        return rem * rootFontSize;
    }

    // ========================================
    // Keyboard & Accessibility
    // ========================================

    /**
     * Add keyboard event listener for Escape and Tab keys
     * Escape closes popover, Tab traps focus within popover
     */
    addKeyDownListener() {
        console.log('Adding keydown listener for popover');
        this.removeKeyDownListener(); // Ensure no duplicate listeners
        this.keyDownListener = (event) => {
            if (['Escape', 'Esc'].includes(event.key)) {
                this.closePopover();
                this.setFocusToElement(this.triggerId);
            } else if (event.key === 'Tab') {
                this.trapFocus(event);
            }
        };
        window.addEventListener('keydown', this.keyDownListener, false);
    }

    /**
     * Remove keyboard event listener
     */
    removeKeyDownListener() {
        console.log('Removing keydown listener for popover');
        if (this.keyDownListener) {
            window.removeEventListener('keydown', this.keyDownListener, false);
            this.keyDownListener = null;
        }
    }

    /**
     * Close popover and clean up state
     * Removes keyboard listener and resets trigger state
     */
    closePopover() {
        console.log('Closing popover');
        this.showPopover = false;
        this.removeKeyDownListener();

        this.triggerId = '';
        this.keepPopoverOpen = false;
    }

    // ========================================
    // Lifecycle Hooks
    // ========================================

    /**
     * Cleanup when component is removed from DOM
     * Removes event listeners and clears timers
     */
    disconnectedCallback() {
        this.removeKeyDownListener();

        if (this.hideTimer) {
            window.clearTimeout(this.hideTimer);
        }
    }

    // ========================================
    // Focus Management
    // ========================================

    /**
     * Set focus to a specific element by data-id
     */
    setFocusToElement(elementId) {
        const element = this.template.querySelector(`[data-id="${elementId}"]`);

        if (element) {
            console.log('Setting focus:', element);
            element.focus();
        } else {
            console.warn(`[data-id="${elementId}"] element not found`);
        }
    }

    /**
     * Trap focus within popover using Tab key
     * Cycles between first (close button) and last (end marker) focusable elements
     */
    trapFocus(event) {
        const myPopoverStart = this.template.querySelector('[data-id="popover-close"]');
        const myPopoverEnd = this.template.querySelector('[data-id="mypopoverend"]');

        if (!myPopoverStart || !myPopoverEnd) {
            console.warn('mypopoverstart or mypopoverend not found');
            return;
        }

        const currentActiveElement = this.template.activeElement || document.activeElement;
        console.log('Currently focused element:', currentActiveElement);

        if (event.shiftKey) {
            // Shift + Tab - going backwards
            if (currentActiveElement === myPopoverStart) {
                event.preventDefault();
                myPopoverEnd.focus();
                console.log('Focus trapped backwards: moved to mypopoverend');
            }
        } else {
            // Tab - going forwards
            if (currentActiveElement === myPopoverEnd) {
                event.preventDefault();
                myPopoverStart.focus();
                console.log('Focus trapped forwards: moved to mypopoverstart');
            }
        }
    }

    // ========================================
    // Utility Functions
    // ========================================

    /**
     * Debug helper to log event information
     */
    debugEvent(event) {
        console.log('event.type:', event.type);
        console.log('CurrentTarget:', event.currentTarget.dataset.id);
    }
}
