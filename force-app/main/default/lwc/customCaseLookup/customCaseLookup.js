import { LightningElement, api, wire } from 'lwc';
import apexSearch from '@salesforce/apex/LookupController.search';
import getRecentlyViewed from '@salesforce/apex/LookupController.getRecentlyViewed';
import getInitialSelection from '@salesforce/apex/LookupController.getInitialSelection';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class LookupAndDisplay extends LightningElement {
    @api recordId;
    @api selectedCaseId;

    recentlyViewed = [];
    initialSelection;

    handleSearch(event) {
        const lookupElement = event.target;
        apexSearch(event.detail)
            .then(results => {
                lookupElement.setSearchResults(results);
            })
            .catch(error => {
                console.log(error);
            });
    }

    initLookupDefaultResults() {
        // Make sure that the lookup is present and if so, set its default results
        const lookup = this.template.querySelector('c-lookup');
        if (lookup) {
            lookup.setDefaultResults(this.recentlyViewed);
        }
    }

    @wire(getInitialSelection, { recordId: '$idToUse' })
    getInitialSelection({ data }) {
        if (data) {
            // Show the initial selection when the flow starts
            this.initialSelection = data;

            // Change the flow variables to match the initial selection case id
            this.selectedCaseId = data.id;
            
            const selectedIdChangeEvent = new FlowAttributeChangeEvent('selectedCaseId', this.selectedCaseId);
            this.dispatchEvent(selectedIdChangeEvent);
        }
    }

    @wire(getRecentlyViewed)
    getRecentlyViewed({ data }) {
        if (data) {
            this.recentlyViewed = data;
            this.initLookupDefaultResults();
        }
    }

    handleSelectionChange(event) {
        // Get the selection objects with ids, labels, icons...
        const selection = event.target.getSelection();

        if (selection.length === 0) {
            this.selectedCaseId = "-1";
            const selectedIdChangeEvent = new FlowAttributeChangeEvent('selectedCaseId', this.selectedCaseId);
            this.dispatchEvent(selectedIdChangeEvent);
        } else {
            this.selectedCaseId = selection[0].id;
            const selectedIdChangeEvent = new FlowAttributeChangeEvent('selectedCaseId', this.selectedCaseId);
            this.dispatchEvent(selectedIdChangeEvent);
        }
    }

    connectedCallback() {
        if (this.selectedCaseId) {
            this.idToUse = this.selectedCaseId;
        } else {
            this.idToUse = this.recordId;
        }
    }

    renderedCallback() {
        this.initLookupDefaultResults();
    }
}