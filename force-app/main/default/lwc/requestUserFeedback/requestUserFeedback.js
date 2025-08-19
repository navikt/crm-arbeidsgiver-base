import { LightningElement, track, api } from 'lwc';
import handleNewRating from '@salesforce/apex/TAG_FeedbackHandler.handleNewRating';

export default class RateThisComponent extends LightningElement {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    @api componentName; // Name of the component.
    @api page;
    @api question; // Optional question to display when not rated
    @api thankYouMessage; // Optional thank you message to display after rating
    @api floatRight;
    @track _displayThankYouMessage = false;
    @track _isRated = false;
    @track _hasCheckedDatabase = false;

    get displayFeedbackRequest() {
        // Check database only once when component loads
        if (!this._hasCheckedDatabase) {
            this.checkDatabaseForPreviousRating();
        }
        return !this._isRated;
    }

    get displayThankYouMessage() {
        if (this.thankYouMessage && this._displayThankYouMessage) {
            return true;
        }
        return false;
    }
    get cssThankYouMessage() {
        return this.displayThankYouMessage ? 'slds-transition-show' : 'slds-hide';
    }
    get cssFeedbackRequest() {
        return this.displayFeedbackRequest ? 'slds-transition-show' : 'slds-hide';
    }

    get cssGridClass() {
        let cssClasses = 'slds-grid slds-grid_vertical-align-center slds-var-p-left_medium';
        if (this.floatRight) {
            cssClasses += ' slds-grid_align-end';
        }
        return cssClasses;
    }

    get displayContent() {
        return this.displayThankYouMessage || this.displayFeedbackRequest;
    }

    toggleVisibilityTest() {
        this._displayThankYouMessage = !this._displayThankYouMessage;
    }

    connectedCallback() {
        // Initialize database check when component connects
        this.checkDatabaseForPreviousRating();
    }

    // =========================
    // DATABASE / APEX METHODS
    // =========================
    checkDatabaseForPreviousRating() {
        if (this._hasCheckedDatabase) {
            return; // Already checked, don't check again
        }

        this._hasCheckedDatabase = true;
        this._isRated = this.getHasRated(this.componentName);
    }

    saveRating(rating) {
        // Logic to save the rating to the database
        handleNewRating({ componentName: this.componentName, page: this.page, question: this.question, vote: rating })
            .then(() => {
                this.saveHasRated(this.componentName); // Save rating status in browser storage
                console.log('Rating saved successfully');
                this._displayThankYouMessage = true; // Show thank you message after rating
            })
            .catch((error) => {
                this._isRated = false;
                this.deleteHasRated(this.componentName);
                this._displayThankYouMessage = false;
                this.handleError('Error saving rating', error);
            });
    }

    // =========================
    // EVENT HANDLERS
    // =========================

    handleLikeClick() {
        if (!this._isRated) {
            this._isRated = true;
            this.saveRating(1);
        }
    }

    handleDislikeClick() {
        // Handle dislike button click
        if (!this._isRated) {
            this._isRated = true;
            this.saveRating(-1);
        }
    }

    // =========================
    // UTILITY METHODS
    // =========================

    saveHasRated(componentName) {
        const data = this.localStoreData;
        if (!data.components.includes(componentName)) {
            data.components.push(componentName);
            this.saveLocalStoreData(data);
        }
    }

    getHasRated(componentName) {
        let ratedComponentsList = this.localStoreData.components;
        if (ratedComponentsList.includes(componentName)) {
            return true;
        }
        return false;
    }

    deleteHasRated(componentName) {
        const data = this.localStoreData;
        const index = data.components.indexOf(componentName);
        if (index > -1) {
            data.components.splice(index, 1);
            this.saveLocalStoreData(data);
        }
    }

    get localStoreData() {
        const storedData = localStorage.getItem('requestUserFeedback');
        if (!storedData) {
            const obj = {
                components: []
            };
            return obj;
        }
        const obj = JSON.parse(storedData);
        return obj;
    }

    saveLocalStoreData(data) {
        localStorage.setItem('requestUserFeedback', JSON.stringify(data));
    }

    handleError(message, error) {
        console.error(message, error);
        // Add user-friendly error handling here
    }
}
