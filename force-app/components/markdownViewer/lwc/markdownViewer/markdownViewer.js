import { LightningElement, api, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import markedJs from '@salesforce/resourceUrl/marked';
import getData from '@salesforce/apex/MarkdownViewerController.getData';

export default class MarkdownViewer extends LightningElement {

    isRendered = false;

    @api recordId;
    @api objectApiName;
    @api fieldName;

    @track empty = false;

    @track body;

    renderedCallback() {
        console.log(this.objectApiName);
        if (this.isRendered) {
            return;
        }

        this.isRendered = true;

        loadScript(this, markedJs).then(() => {
            this.renderMarkdown();
        });

    }

    @wire(getData, {
        recordId: '$recordId',
        objectApiName: '$objectApiName',
        fieldName: '$fieldName'
    })
    deWire(result) {
        this.body = result.data;
        this.renderMarkdown();
    }


    renderMarkdown() {
        try {
            if (this.body === null) {
                this.empty = true;
            }
            let formattedData = marked(this.body);
            var last = formattedData.substr(formattedData.length - 5);
            if (!last.includes('</p>')) {
                formattedData += '<p></p>';
            }
            this.template.querySelector('div').innerHTML = formattedData;
        }
        catch (error) { }
    }
}