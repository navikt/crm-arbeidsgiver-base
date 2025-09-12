import { LightningElement, track, api } from 'lwc';
import handleNewRating from '@salesforce/apex/TAG_FeedbackHandler.handleNewRating';
import hasFeedbackPermission from '@salesforce/customPermission/Arbeidsgiver_Se_sp_rsm_l_fra_In_App_Feedback';


export default class RateThisComponent extends LightningElement {
    // =========================
    // PROPERTIES & GETTERS
    // =========================

    @api componentName; // Name of the component.
    @api page;
    @api question; // Optional question to display when not rated
    @api thankYouMessage; // Optional thank you message to display after rating
    @api followUpMessage; //'Fortell oss gjerne hva du savner <a href="https://engage.cloud.....">i kanalen vår på Yammer</a>'; // Optional follow up message to display after rating
    @api floatRight;
    @track _isRated = false;
    @track _hasCheckedDatabase = false;
    @track _rating;
    loadContent = false;
    
    get canUseFeedback() {
        return hasFeedbackPermission;
    }
    get feedbackSubmitted() {
        if (this._rating === 1) {
            return true;
        }
        if (this._rating === -1) {
            return true;
        }
        return false;
    }

    get messageText(){
        if (this.thankYouMessage && this._rating === 1) {
            return this.thankYouMessage;
        }
        if (this.followUpMessage && this._rating === -1) {
            return this.followUpMessage;
        }
        return '';
    }

    get cssMessage() {
        return this.messageText
            ? 'slds-transition-show custom-transition-slow slds-col slds-no-flex slds-var-p-right_xx-small'
            : 'slds-transition-hide custom-transition slds-col slds-no-flex slds-var-p-right_xx-small';
    }


    get cssGridClass() {
        let cssClasses = 'slds-grid slds-grid_vertical-align-center slds-var-p-left_medium';
        if (this.floatRight) {
            cssClasses += ' slds-grid_align-end';
        }
        return cssClasses;
    }

    

    connectedCallback() {
        if(!this.canUseFeedback){
            this.loadContent = false;
        }
        else {
            this.checkDatabaseForPreviousRating();
            this.loadContent = !this._isRated; // Load content if not rated
        }
    }

    // =========================
    // DATABASE / APEX METHODS
    // =========================
    checkDatabaseForPreviousRating() {
        this._hasCheckedDatabase = true;
        this._isRated = this.getHasRated(this.componentName);
        
    }

    saveRating(rating) {
        // Logic to save the rating to the database
        handleNewRating({ componentName: this.componentName, page: this.page, question: this.question, vote: rating })
            .then(() => {
                this.saveHasRated(this.componentName); // Save rating status in browser storage
                console.log('Rating saved successfully');
                this._rating = rating;
                //this._displayThankYouMessage = true; // Show thank you message after rating
            })
            .catch((error) => {
                this._isRated = false;
                this.deleteHasRated(this.componentName);
               // this._displayThankYouMessage = false;
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
    }
}
