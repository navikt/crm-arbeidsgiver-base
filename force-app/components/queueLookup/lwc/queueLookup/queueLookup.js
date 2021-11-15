import { LightningElement, track, api } from 'lwc';
import search from '@salesforce/apex/QueueLookupController.search';

const SEARCH_DELAY = 300;
const MIN_SEARCH_LENGTH = 3;
const REGEX_SOSL_RESERVED = /(\?|&|\||!|\{|\}|\[|\]|\(|\)|\^|~|\*|:|"|\+|-|\\)/g;

export default class QueueLookup extends LightningElement {
  @track searchResults = [];
  @api availableForSObjectType;
  loading = false;
  hasFocus = false;
  minSearchTermLength = MIN_SEARCH_LENGTH;

  _searchTerm = '';
  _focusedIndex = null;
  _currentSelection = null;
  _cleanSearchTerm;
  _searchThrottlingTimeout;

  handleInputChange(event) {
    this.updateSearchTerm(event.target.value);
  }

  handleResultClick(event) {
    const recordId = event.currentTarget.dataset.recordid;
    const selectedItem = this.searchResults.find((result) => result.id === recordId);

    if (selectedItem) {
      this._currentSelection = selectedItem;
      this._searchTerm = '';
      this.searchResults = [];
      this.template.querySelector('input').focus();
    }
  }

  removeSelection() {
    this._currentSelection = null;
    this.template.querySelector('input').focus();
  }

  handleFocus() {
    this.hasFocus = true;
  }

  handleBlur(event) {
    const dropdown = this.template.querySelector('.search-results');
    const clickDropdown = dropdown.contains(event.relatedTarget);
    if (!clickDropdown) {
      this._searchTerm = '';
      this.searchResults = [];
      this.hasFocus = false;
      this._focusedIndex = null;
    }
  }

  updateSearchTerm(newSearchTerm) {
    this._searchTerm = newSearchTerm;

    const newCleanSearchTerm = newSearchTerm.trim().replace(REGEX_SOSL_RESERVED, '?').toLowerCase();
    if (this._cleanSearchTerm === newCleanSearchTerm) {
      return;
    }

    this._cleanSearchTerm = newCleanSearchTerm;
    this.searchResults = [];

    if (this._searchThrottlingTimeout) {
      clearTimeout(this._searchThrottlingTimeout);
    }

    this._searchThrottlingTimeout = setTimeout(() => {
      if (this._cleanSearchTerm.length >= this.minSearchTermLength) {
        this.loading = true;

        search({ searchTerm: this._cleanSearchTerm, SObjectType: this.availableForSObjectType })
          .then((results) => {
            this.loading = false;
            this.searchResults = results;
          })
          .catch((error) => {
            console.error('Lookup error', error);
          });
      }
      this._searchThrottlingTimeout = null;
    }, SEARCH_DELAY);
  }

  handleKeyDown(event) {
    if (this._focusedIndex === null) {
      this._focusedIndex = -1;
    }
    switch (event.key) {
      case 'ArrowDown':
        if (this._focusedIndex < this.searchResults.length - 1) {
          this._focusedIndex++;
          this.focusItem(this._focusedIndex);
          event.preventDefault();
        } else {
          this._focusedIndex = 0;
          this.focusItem(this._focusedIndex);
          event.preventDefault();
        }
        break;
      case 'ArrowUp':
        if (this._focusedIndex > 0) {
          this._focusedIndex--;
          this.focusItem(this._focusedIndex);
          event.preventDefault();
        } else if (this._focusedIndex === 0) {
          this._focusedIndex = this.searchResults.length - 1;
          this.focusItem(this._focusedIndex);
          event.preventDefault();
        }
        break;
      case 'Enter':
        const id = this.searchResults[this._focusedIndex].id;
        this.template.querySelector(`[data-id="${id}"]`).click();
        break;
      default:
        return;
    }
  }

  focusItem(index) {
    const id = this.searchResults[index].id;
    this.template.querySelector(`[data-id="${id}"]`).focus();
  }

  @api
  validate() {
    if (this.selectedItem !== null) {
      return { isValid: true };
    } else {
      return {
        isValid: false,
        errorMessage: 'Dette feltet er obligatorisk.'
      };
    }
  }

  @api
  get selectedRecordId() {
    return this._currentSelection ? this._currentSelection.id : null;
  }

  get searchTerm() {
    return this._searchTerm;
  }

  get selectedItem() {
    return this._currentSelection;
  }

  get getInputValue() {
    return this._currentSelection ? this._currentSelection.title : this._searchTerm;
  }

  get containerClass() {
    return this._currentSelection ? 'slds-combobox_container slds-has-selection' : 'slds-combobox_container';
  }

  get inputClass() {
    return this._currentSelection
      ? 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right'
      : 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
  }

  get dropdownClass() {
    return this.hasFocus
      ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
      : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
  }
}
