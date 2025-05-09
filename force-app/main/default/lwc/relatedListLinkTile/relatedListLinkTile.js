import { LightningElement, api , track} from 'lwc';

export default class RelatedListLinkTile extends LightningElement {
    
    // Variables for UI
    @api iconName;
    @api cardTitle;

    // Parameters to pass to related list page
    _parentRecordId;
    _relatedObjectApiName;
    _size;

    @track relatedRecordsPageUrl = '';
    
    @api
    set parentRecordId(value) {
        this._parentRecordId = value;
        this.generateRelatedRecordsUrl();
    }
    get parentRecordId() {
        return this._parentRecordId;
    }

    @api
    set relatedObjectApiName(value) {
        this._relatedObjectApiName = value;
        this.generateRelatedRecordsUrl();
    }
    get relatedObjectApiName() {
        return this._relatedObjectApiName;
    }

    @api
    set size(value) {
        this._size = value;
        this.generateRelatedRecordsUrl();
    }
    get size() {
        return this._size;
    }


    generateRelatedRecordsUrl() {
        if (!this._parentRecordId || !this._relatedObjectApiName) {
            this.relatedRecordsPageUrl = '';
            return;
        }

        const baseUrl = '/lightning/cmp/c__relatedRecordsPage';
        const params = new URLSearchParams({
            c__configKey: this._relatedObjectApiName,
            c__parentRecordId: this._parentRecordId,
            c__size: this._size || 'small'
        });

        this.relatedRecordsPageUrl = `${baseUrl}?${params.toString()}`;
    }

    get showTile() {
        return this.relatedRecordsPageUrl !== '';
    }

    renderedCallback(){
        console.log('Related List Link Tile renderedCallback');
        console.log('relatedRecordsPageUrl: ' + this.relatedRecordsPageUrl);
        console.log('parentRecordId: ' + this.parentRecordId);
        console.log('relatedObjectApiName: ' + this.relatedObjectApiName);
    }

}
