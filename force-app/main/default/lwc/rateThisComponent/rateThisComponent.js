import { LightningElement, track, api } from 'lwc';
import hasRecords from '@salesforce/apex/POAGDataHandler.hasRecords';
import handleNewRating from '@salesforce/apex/POAGDataHandler.handleNewRating';
import handleDeleteRating from '@salesforce/apex/POAGDataHandler.handleDeleteRating';
import userId from '@salesforce/user/Id';

export default class RateThisComponent extends LightningElement {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    userId = userId; // Use the imported user ID
    @api voteKey; // Key for the component, can be set from a parent component or page property
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

        hasRecords({ voteKey: this.voteKey, userId: this.userId })
            .then((data) => {
                this._isRated = data;
                console.log(`Database check complete for key ${this.voteKey}:`, data);
            })
            .catch((error) => {
                this.handleError('Error retrieving previous rating', error);
                this._hasCheckedDatabase = false; // Allow retry on error
            });
    }

    saveRating(rating) {
        // Logic to save the rating to the database
        handleNewRating({ voteKey: this.voteKey, userId: this.userId, liked: rating })
            .then(() => {
                console.log('Rating saved successfully');
                this._isRated = true; // Update local state to prevent further voting
                this._displayThankYouMessage = true; // Show thank you message after rating
            })
            .catch((error) => {
                this.handleError('Error saving rating', error);
            });
    }

    deleteRating() {
        // Logic to delete the rating from the database
        handleDeleteRating({ voteKey: this.voteKey, userId: this.userId })
            .then(() => {
                console.log('Rating deleted successfully');
                this._isRated = false; // Update local state to allow voting again
            })
            .catch((error) => {
                this.handleError('Error deleting rating', error);
            });
    }
    // =========================
    // EVENT HANDLERS
    // =========================

    handleLikeClick() {
        if (!this._isRated) {
            this.saveRating(true);
        }
    }

    handleUndoClick() {
        // Logic to undo the rating
        this.deleteRating();
    }

    handleDislikeClick() {
        // Handle dislike button click
        if (!this._isRated) {
            this.saveRating(false);
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
