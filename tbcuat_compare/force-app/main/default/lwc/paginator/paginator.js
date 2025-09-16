/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   05-13-2021   James Ridge   Initial Version
**/
import { LightningElement, api, track } from 'lwc';
import { debug } from 'c/debug';

export default class Paginator extends LightningElement {
    //Usually the first page (for future implementation)
    MIN_ALLOWED_PAGE = 1;   
    //How many page numbers to be displayed
    @track MAX_SET_SIZE = 3;       
    //How many Items per page do we show? Default to the first item of the list of options
    @api pageSize = this.pageSizeOptions[0].value;
    //Total number of records - we get this through an aggregate query. By default
    //it is set to zero on load of the component
    @track TOTAL_RECORDS_SIZE = 0;   
    //The maximum page number (total pages to paginate)
    get MAX_ALLOWED_PAGE(){ 
        return Math.ceil(this.TOTAL_RECORDS_SIZE / this.pageSize);
    }

    label = {
        Next: 'Next',
        Previous: 'Prev',
        First: 'First',
        Last: 'Last',
        Title_PageSizeSelector: 'Set the number of items displayed per page'
    }

    get pageSizeOptions() {
        return [
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '75', value: 75 },
            { label: '100', value: 100 },
            { label: '250', value: 250 },
            { label: 'All', value: 999999 },
        ];
    }
    @track currentPage = 1;
    @track pagesList = [];

    /**
     * API Variable
     */
    @api get totalRecords(){
        return this.TOTAL_RECORDS_SIZE;
    }
    set totalRecords(val){
        this.TOTAL_RECORDS_SIZE = parseInt(val, 10);
        this.renderPagesList();
    }
    @api get visiblePages(){
        return this.MAX_SET_SIZE;
    }
    set visiblePages(val){
        this.MAX_SET_SIZE = parseInt(val, 10);
        this.renderPagesList();
    }
    @api get itemsPerPage(){
        return this.pageSize;
    }
    set itemsPerPage(val){
        this.pageSize = parseInt(val, 10);
        this.renderPagesList();
    }
    
    connectedCallback(){
        //Report to parent that the component has initialized
        //this is necessary, so the parent can set the correct itemsPerPage
        this.reportToParent();
    }

    handlePageSizeChange(event){
        this.pageSize = parseInt(event.detail.value, 10);
        //When we have changed the number of items per page setting,
        //report to the parent and set the current page to the first/min page
        this.currentPage = this.MIN_ALLOWED_PAGE;
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    } 

    handleNavigationClick(event){
        let type = event.currentTarget.dataset.type;
        if(type === 'jump-first'){
            this.handleJumpFirst();
        }else if(type === 'jump-last'){
            this.handleJumpLast();
        }else if(type === 'load-previous'){
            this.handleLoadPrevious();
        }else if(type === 'load-next'){
            this.handleLoadNext();
        }else if(type === 'jump-index'){
            this.handleJumpAtIndex(event.currentTarget.dataset.index);
        }
    }

    handleJumpAtIndex(index){
        //Jump at a particular page index
        this.currentPage =  parseInt(index, 10);
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    }

    handleJumpFirst(){
        this.currentPage = this.MIN_ALLOWED_PAGE;
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    }
    handleJumpLast(){
        this.currentPage = this.MAX_ALLOWED_PAGE;
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    }
    handleLoadPrevious(){
        if(this.currentPage === this.MIN_ALLOWED_PAGE)
            return;
        --this.currentPage;        
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    }
    handleLoadNext(){
        if(this.currentPage === this.MAX_ALLOWED_PAGE)
            return;

        ++this.currentPage;
        this.renderPagesList().then((value) => {
            this.reportToParent();
        });
    }

    async renderPagesList(){
        //Create a list of page objects that contain the page number and 
        //an indicator whether the page is the current page - needed so 
        //we can highlight that page to the user in the UI
        let pageItems = [];
        for(let pageNumber = 1; pageNumber <= this.MAX_ALLOWED_PAGE; pageNumber++){
            pageItems.push({pageNumber: pageNumber, isCurrent: (pageNumber === this.currentPage)});
        }        

        //Find the middle of the provided Maximum Set Size in order
        //to determine how many pages before/after we are rendering and
        //allowing the user to jump to
        let mid = Math.floor(this.MAX_SET_SIZE / 2) + 1;
        if (this.currentPage > mid) {
            this.pagesList = pageItems.slice(this.currentPage - mid, this.currentPage + mid - 1);
        } else {
            this.pagesList = pageItems.slice(0, this.MAX_SET_SIZE);
        }

    }

    reportToParent(){
        this.dispatchEvent(new CustomEvent('pagechange',
            {
                detail: {
                    totalRecords: this.TOTAL_RECORDS_SIZE,
                    itemsPerPage: this.pageSize,
                    currentPage: this.currentPage
                }
            }
        ));
    }
    
    get showLoadPrevious() {
        return this.currentPage > this.MIN_ALLOWED_PAGE;
    }
    
    get showLoadNext() {
        return this.currentPage < this.MAX_ALLOWED_PAGE;
    }

    get showEllipsisFirst(){
        //Ensure that the list of pages don't contain the first/min allowed page number
        if (this.pagesList.some(e => e.pageNumber === this.MIN_ALLOWED_PAGE)) {
            return false;
        }
        return this.currentPage > this.MIN_ALLOWED_PAGE + 1;
    }

    get showEllipsisLast(){
        //Ensure that the list of pages don't contain the last/max allowed page number
        if (this.pagesList.some(e => e.pageNumber === this.MAX_ALLOWED_PAGE)) {
            return false;
        }
        return this.currentPage < this.MAX_ALLOWED_PAGE - 1;
    }

    get showPageSizeSelector(){
        return this.pagesList && this.pagesList.length > 0;
    }
}