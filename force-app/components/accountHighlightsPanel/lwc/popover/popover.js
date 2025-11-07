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
    hasButtonFocus = false; // Tracks if button has focus
    keepPopoverOpen = false; // Flag to prevent accidental closing

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

    /* Ensure trigger elements are above backdrop */
    get triggerContainerStyle() {
        return this.showPopover ? 'position: relative; z-index: 6001;' : '';
    }
    /**
     * Show backdrop only when popover is opened via button click (not hover)
     * Backdrop catches clicks outside popover to close it
     */
    get shouldShowBackdrop() {
        return this.showPopover && this.triggerId === this.TRIGGER_BUTTON_ID;
    }

    /**
     * Dynamic CSS classes for the pointer/nubbin based on position
     */
    get pointerClassNames() {
        return `cmp-popover__pointer cmp-popover__pointer--${this.currentPopoverPosition}`;
    }

    /**
     * Dynamic CSS classes for trigger button (shows when focused)
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
     * Get first focusable element within popover
     * Used for setting initial focus when popover opens
     */
    get firstFocusableElementId() {
        const popover = this.template.querySelector(this.CONTENT_WRAPPER_SELECTOR);
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
        if (event.target.dataset.id === this.TRIGGER_LINK_ID) {
            this.triggerId = this.TRIGGER_LINK_ID;
            // Clear any pending hide timer
            if (this.hideTimer) {
                window.clearTimeout(this.hideTimer);
                this.hideTimer = null;
            }

            // Only open popover if it's not already open
            if (!this.showPopover) {
                // Delay opening popover by 300ms
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this.showTimer = window.setTimeout(() => {
                    this.calculatePopoverPosition();
                    this.showPopover = true;

                    // Use setTimeout to ensure DOM is updated before setting focus
                    // eslint-disable-next-line @lwc/lwc/no-async-operation
                    setTimeout(() => {}, 0);
                    this.addKeyDownListener();
                }, 300);
            }
        }
    }

    /**
     * Handle mouse leaving trigger link or popover
     * Delays closing to allow mouse movement between link and popover
     */
    handleMouseLeave() {
        if (this.triggerId === this.TRIGGER_LINK_ID) {
            // Clear any pending show timer
            if (this.showTimer) {
                window.clearTimeout(this.showTimer);
                this.showTimer = null;
            }

            if (this.hideTimer) {
                window.clearTimeout(this.hideTimer);
            }

            // Delay closing popover to allow mouse movement to popover content
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.hideTimer = window.setTimeout(() => {
                this.closePopover();
            }, 500);
        }
    }

    /**
     * Handle mouse entering popover content
     * Cancels delayed closing to keep popover open
     */
    handlePopoverEnter() {
        if (this.triggerId === this.TRIGGER_LINK_ID) {
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
    handleButtonClick() {
        this.triggerId = this.TRIGGER_BUTTON_ID;
        this.showPopover = !this.showPopover;
        this.hasButtonFocus = true;
        this.keepPopoverOpen = this.showPopover;

        if (this.showPopover) {
            this.calculatePopoverPosition();
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
        this.hasButtonFocus = false;
        this.closePopover();
    }

    /**
     * Handle close button click
     */
    handlePopoverClose() {
        if (this.triggerId === this.TRIGGER_BUTTON_ID) {
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
    handleButtonFocusIn() {
        this.hasButtonFocus = true;
    }

    /**
     * Handle focus leaving button or link
     */
    handleButtonFocusOut() {
        this.hasButtonFocus = this.showPopover ? true : false;
    }

    // ========================================
    // Positioning Logic
    // ========================================

    /**
     * Calculate popover and pointer position relative to trigger link
     * Positions popover to the left of trigger, or below if not enough space
     */
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

    canFitToLeft(rect, popoverWidth, pointerSize) {
        // Check if there is enough space to the left
        return rect.left >= popoverWidth + pointerSize;
    }

    calculateLeft(rect, pointerSize, popoverWidth, popoverHeight) {
        const pointerDiameter = pointerSize * Math.sqrt(2);
        this.pointer.x = 0 - pointerDiameter; // Move pointer to left edge
        this.pointer.y = 0 + rect.height / 2 - pointerSize / 2; // Align pointer to vertical center
        this.popover.x = this.pointer.x - popoverWidth + pointerSize / 2; // Move popover to left edge and add offset to account for pointer and popover overlap
        this.popover.y = this.pointer.y - popoverHeight / 2; // Align popover to vertical center
    }

    calculateBelow(rect, pointerSize) {
        this.pointer.y = 0 + rect.height; // Move pointer to bottom edge
        this.pointer.x = 0 + rect.width / 2 - pointerSize / 2; // Align center
        this.popover.y = this.pointer.y + pointerSize / 2; // Move popover to bottom edge and add offset to account for pointer and popover overlap
        this.popover.x = 0; // Align popover with left edge
    }

    /**
     * Convert rem units to pixels based on root font size
     */
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
