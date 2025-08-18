import { LightningElement, track, api } from 'lwc';
import hasVoted from '@salesforce/apex/POAGDataHandler.hasVoted';
import handleNewRating from '@salesforce/apex/POAGDataHandler.handleNewRating';
import userId from '@salesforce/user/Id';

export default class RateThisComponent extends LightningElement {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    userId = userId; // Use the imported user ID
    @api componentName; // Name of the component.

    @api question; // Optional question to display when not rated
    @api thankYouMessage; // Optional thank you message to display after rating
    @track _displayThankYouMessage = false;
    @track _isRated = false;
    @track _hasCheckedDatabase = false;

    get isRated() {
        // Check database only once when component loads
        if (!this._hasCheckedDatabase) {
            this.checkDatabaseForPreviousRating();
        }
        return this._isRated;
    }

    get displayThankYouMessage() {
        if (this.thankYouMessage && this._displayThankYouMessage) {
            return true;
        }
        return false;
    }

    connectedCallback() {
        // Initialize database check when component connects
        this.checkDatabaseForPreviousRating();
    }

    // =========================
    // APEX METHODS
    // =========================
    checkDatabaseForPreviousRating() {
        if (this._hasCheckedDatabase) {
            return; // Already checked, don't check again
        }

        this._hasCheckedDatabase = true;

        hasVoted({ componentName: this.componentName, userId: this.userId })
            .then((data) => {
                this._isRated = data;
                console.log(`Database check complete for key ${this.componentName}:`, data);
            })
            .catch((error) => {
                this.handleError('Error retrieving previous rating', error);
                //this._hasCheckedDatabase = false; // Allow retry on error. Causing loop issue
            });
    }

    saveRating(rating) {
        // Logic to save the rating to the database
        handleNewRating({ componentName: this.componentName, userId: this.userId, vote: rating })
            .then(() => {
                console.log('Rating saved successfully');
                this._displayThankYouMessage = true; // Show thank you message after rating
            })
            .catch((error) => {
                this._isRated = false;
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

    handleError(message, error) {
        console.error(message, error);
        // Add user-friendly error handling here
    }
}
