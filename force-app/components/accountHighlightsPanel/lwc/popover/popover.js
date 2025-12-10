import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

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
export default class Popover extends NavigationMixin(LightningElement) {
    static delegatesFocus = true;

    // ========================================
    // Constants
    // ========================================
    TRIGGER_WAPPER_ID = 'cmp-popover__trigger-wrapper';
    TRIGGER_LINK_ID = 'cmp-popover__trigger-link';
    TRIGGER_BUTTON_ID = 'cmp-popover__trigger-button';
    CLOSE_BUTTON_ID = 'cmp-popover__close-button';
    FOCUS_TRAP_END_ID = 'cmp-popover__focus-trap-end';
    CONTENT_WRAPPER_SELECTOR = '.cmp-popover__content-wrapper';
    // ========================================
    // Public API Properties
    // ========================================
    @api iconName; // Icon displayed in trigger button
    @api tooltip; // Tooltip text for button
    @api title; // Title for popover dialog
    @api linkUrl; // URL for the trigger link
    @api linkLabel; // Text for the trigger link
    @api popoverWidth; // Width of the popover in pixels

    // ========================================
    // State Management
    // ========================================
    showPopover = false; // Controls popover visibility
    triggerId = ''; // Tracks what triggered popover ('popover-link' or 'popover-button')
    hasButtonFocus = false; // Tracks if button should be visible (keyboard navigation only)

    // ========================================
    // Timers
    // ========================================
    keyDownListener = null; // Reference to keyboard event listener
    hideTimer; // Timer for delayed popover hiding (hover mode)
    showTimer; // Timer for delayed popover showing (hover mode)

    // ========================================
    // Styling & Positioning
    // ========================================
    @track popoverStyle = 'transform: translate(0px, 0px);'; // Dynamic popover position
    @track pointerStyle = 'top: 0px; left: 0px;'; // Dynamic pointer/nubbin position

    // Position for pointer/nubbin (the small arrow)
    pointer = {
        x: 0,
        y: 0
    };

    // Position for popover
    popover = {
        x: 0,
        y: 0
    };

    currentPopoverPosition = 'west'; // Placement of popover relative to trigger ('west' or 'south')

    // ========================================
    // Computed Properties / Getters
    // ========================================

    get _iconName() {
        return this.iconName || 'utility:preview';
    }
    get _tooltip() {
        return this.tooltip || this.title || 'Show Popover';
    }
    get _title() {
        return this.title || 'Details';
    }
    get _linkUrl() {
        return this.linkUrl || '';
    }
    get _linkLabel() {
        return this.linkLabel || 'Show Popover';
    }
    /** Width of the popover in pixels */
    get _popoverWidth() {
        // Parse the value as integer, fallback to default if invalid
        const width = parseInt(this.popoverWidth, 10);
        // Return parsed value if it's a valid number, otherwise return default
        return !isNaN(width) && width > 0 ? width : 380;
    }
    get _popoverMinHeight() {
        // return this.popoverMinHeight || 100;
        return 100;
    }

    /** Ensure trigger elements are above backdrop */
    get triggerContainerStyle() {
        return this.showPopover ? 'position: relative; z-index: 6001;' : '';
    }
    /**
     * Show backdrop only when popover is opened via button click (not on hover).
     * The backdrop catches clicks outside popover to close it.
     */
    get shouldShowBackdrop() {
        return this.showPopover && this.triggerId === this.TRIGGER_BUTTON_ID;
    }

    /**
     * Dynamic CSS classes for the pointer/nubbin based on popover position.
     */
    get pointerClassNames() {
        return `cmp-popover__pointer cmp-popover__pointer--${this.currentPopoverPosition}`;
    }

    /**
     * Dynamic CSS classes for trigger button visibility based on focus state
     */
    get triggerButtonClassNames() {
        return 'cmp-popover__trigger-button' + (this.hasButtonFocus ? ' cmp-popover__trigger-button--focus' : '');
    }

    /**
     * ARIA attribute indicating popover state
     */
    get ariaHaspopup() {
        return this.showPopover;
    }

    /**
     * Get first focusable element within popover.
     * Used for setting initial focus when popover opens. Currently don't work (shadow DOM restrictions?).
     */
    get firstFocusableElementId() {
        const popover = this.template.querySelector(this.CONTENT_WRAPPER_SELECTOR);
        if (!popover) {
            return null;
        }
        return popover.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    }

    // ========================================
    // Event Handlers
    // ========================================

    /** Handle mouse hover trigger elements. Opens popover after delay.  */
    handleTriggerMouseEnter(event) {
        this.triggerId = this.TRIGGER_LINK_ID;
        this.hasButtonFocus = false;
        // Clear any pending hide timer
        if (this.hideTimer) {
            window.clearTimeout(this.hideTimer);
            this.hideTimer = null;
        }
        // Only open popover if it's not already open
        if (!this.showPopover) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.showTimer = window.setTimeout(() => {
                this.openPopover(false);
            }, 300);
        }
    }

    /** Handle mouse leaving link or popover. Closes popover after delay, unless triggered by button (accessibility reasons). */
    handleTriggerMouseLeave(event) {
        if (this.triggerId === this.TRIGGER_BUTTON_ID) {
            return;
        }
        this.hasButtonFocus = false;
        // Clear any pending show timer
        if (this.showTimer) {
            window.clearTimeout(this.showTimer);
            this.showTimer = null;
        }
        if (this.hideTimer) {
            window.clearTimeout(this.hideTimer);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.hideTimer = window.setTimeout(() => {
            this.closePopover(false);
        }, 500);
    }

    /**
     * Handle mouse entering popover content. Prevent hiding when entering the popover.
     * Cancels delayed closing to keep popover open
     */
    handlePopoverEnter() {
        if (this.hideTimer) {
            window.clearTimeout(this.hideTimer);
            this.hideTimer = null;
        }
    }
    /** When trigger link or button is focused, the trigger button is shown. */
    handleTriggerFocusIn(event) {
        this.hasButtonFocus = true;
    }

    /** Hide button when focus is lost, unless the popover is open. */
    handleTriggerFocusOut(event) {
        this.hasButtonFocus = this.showPopover ? true : false;
    }

    /** Handle link click to navigate to record page */
    handleLinkClick(event) {
        event.preventDefault();
        this.hasButtonFocus = false;
        // https://page-flow-7636.scratch.lightning.force.com/lightning/r/001JW000012P7MTYA0/view
        // Get record id from _linkUrl. Find a better way to do this later.
        // Split by '/' and get the last segment. If last segment is 'view', get the second last segment.
        let urlParts = this._linkUrl.split('/');
        let recordId =
            urlParts[urlParts.length - 1] === 'view' ? urlParts[urlParts.length - 2] : urlParts[urlParts.length - 1];
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    /** Prevent focus when link is clicked by mouse (mousedown event) */
    handleLinkMouseDown(event) {
        event.preventDefault();
    }
    /**
     * Handle button click to toggle popover
     * Opens/closes popover and manages focus
     */
    handlePreviewButtonClick() {
        this.hasButtonFocus = true;
        this.triggerId = this.TRIGGER_BUTTON_ID;
        if (!this.showPopover) {
            this.openPopover(true);
        } else {
            this.closePopover(true);
        }
    }

    /**
     * Handle clicks on the backdrop (outside popover).
     * Only active when popover is opened via button click
     */
    handleBackdropClick() {
        this.hasButtonFocus = false;
        this.closePopover(false);
    }

    /**
     * Handle close button click inside popover.
     * Closes popover and returns focus to trigger if opened via button.
     */
    handleCloseButtonClick() {
        if (this.triggerId === this.TRIGGER_BUTTON_ID) {
            this.closePopover(true);
        } else {
            this.hasButtonFocus = false;
            this.closePopover(false);
        }
    }

    // ========================================
    // Open and close popover
    // ========================================

    /**
     * Open popover, calculates position, traps focus if specified, and adds keyboard listener.
     * @param trapFocus Boolean indicating whether to trap focus within popover
     */
    openPopover(trapFocus) {
        this.showPopover = true;
        this.calculatePopoverPosition();
        if (trapFocus) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                const element = this.firstFocusableElementId;
                if (element) {
                    element.focus();
                }
            }, 0);
        }
        this.addKeyDownListener();
    }

    /**
     * Hides popover, removes keyboard listener and resets trigger state.
     * @param returnFocus Boolean indicating whether to return focus to trigger element
     */
    closePopover(returnFocus) {
        this.showPopover = false;

        if (returnFocus) {
            this.setFocusToElement(this.triggerId);
        }
        this.removeKeyDownListener();
        this.triggerId = '';
    }

    // ========================================
    // Positioning Logic
    // ========================================

    /** Calculate popover and pointer position relative to trigger link. Positions popover to the left of trigger, or below if not enough space */
    calculatePopoverPosition() {
        const target = this.template.querySelector(`[data-id="${this.TRIGGER_LINK_ID}"]`);
        const rect = target.getBoundingClientRect();

        const pointerSize = this.remToPx(1.25) + this.remToPx(0.0625); // pointer size is calc(1.25rem + 0.0625rem), 29.7px/2 = 14.85px

        const popoverWidth = this._popoverWidth;
        const popoverMinHeight = this._popoverMinHeight;

        if (this.canFitToLeft(rect, popoverWidth, pointerSize)) {
            // Positioned left of target
            this.calculateLeft(rect, pointerSize, popoverWidth, popoverMinHeight);
            this.currentPopoverPosition = 'west';
        } else {
            // Position popover under target
            this.currentPopoverPosition = 'south';
            this.calculateBelow(rect, pointerSize);
        }
        this.pointerStyle = `top: ${this.pointer.y}px; left: ${this.pointer.x}px;`;
        this.popoverStyle = `width: ${popoverWidth}px; min-height: ${popoverMinHeight}px; transform: translate(${this.popover.x}px, ${this.popover.y}px);`;
    }

    /** Check if there is enough space to the left of the target to fit the popover */
    canFitToLeft(rect, popoverWidth, pointerSize) {
        return rect.left >= popoverWidth + pointerSize;
    }

    /** Calculate positions when popover is to the left of target */
    calculateLeft(rect, pointerSize, popoverWidth, popoverHeight) {
        const pointerDiameter = pointerSize * Math.sqrt(2);
        this.pointer.x = 0 - pointerDiameter; // Move pointer to left edge
        this.pointer.y = 0 + rect.height / 2 - pointerSize / 2; // Align pointer to vertical center
        this.popover.x = this.pointer.x - popoverWidth + pointerSize / 2; // Move popover to left edge and add offset to account for pointer and popover overlap
        this.popover.y = this.pointer.y - popoverHeight / 2; // Align popover to vertical center
    }
    /** Calculate positions when popover is below target */
    calculateBelow(rect, pointerSize) {
        this.pointer.y = 0 + rect.height; // Move pointer to bottom edge
        this.pointer.x = 0 + rect.width / 2 - pointerSize / 2; // Align center
        this.popover.y = this.pointer.y + pointerSize / 2; // Move popover to bottom edge and add offset to account for pointer and popover overlap
        this.popover.x = 0; // Align popover with left edge
    }

    /** Convert rem units to pixels based on root font size */
    remToPx(rem) {
        const rootFontSize = parseFloat(getComputedStyle(document.documentElement).fontSize);
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
        this.removeKeyDownListener(); // Ensure no duplicate listeners
        this.keyDownListener = (event) => {
            if (['Escape', 'Esc'].includes(event.key)) {
                if (this.triggerId === this.TRIGGER_BUTTON_ID) {
                    this.closePopover(true);
                } else {
                    this.closePopover(false);
                }
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
        if (this.keyDownListener) {
            window.removeEventListener('keydown', this.keyDownListener, false);
            this.keyDownListener = null;
        }
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

        if (this.showTimer) {
            window.clearTimeout(this.showTimer);
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
        const focusTrapStart = this.template.querySelector(`[data-id="${this.CLOSE_BUTTON_ID}"]`);
        const focusTrapEnd = this.template.querySelector(`[data-id="${this.FOCUS_TRAP_END_ID}"]`);

        if (!focusTrapStart || !focusTrapEnd) {
            return;
        }

        const currentActiveElement = this.template.activeElement || document.activeElement;

        if (event.shiftKey) {
            // Shift + Tab - going backwards
            if (currentActiveElement === focusTrapStart) {
                event.preventDefault();
                focusTrapEnd.focus();
            }
        } else {
            // Tab - going forwards
            if (currentActiveElement === focusTrapEnd) {
                event.preventDefault();
                focusTrapStart.focus();
            }
        }
    }

    // ========================================
    // Utility Functions
    // ========================================
}
