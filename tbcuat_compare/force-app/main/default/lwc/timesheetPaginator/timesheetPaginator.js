import { LightningElement, api, track } from 'lwc';

export default class TimesheetPaginator extends LightningElement {

    @api currentPage;
    @api totalNumberOfPages;
    @api startIndex;
    @api endIndex;
    @api totalNumberOfRecords;
    @api pagesList;

    // PRIVATE ATTRIBUTES
    _selectedEntry;
    _numberOfPagesShowInPaginator = 5;

    /**
    * @description Method to rerender the paginator
    **/
    @api
    rerender(currentPage, selectedEntry, totalNumberOfRecords) {
        this.currentPage = currentPage;
        this._selectedEntry = selectedEntry;
        this.totalNumberOfRecords = totalNumberOfRecords;

        this.setTotalPage();
        this.setPagesList();
        this.setEntries();
    }

    /**
    * @description Method to set total page
    **/
    setTotalPage() {
        if (this.totalNumberOfRecords && this._selectedEntry) {
            let totalNumberOfPages = 0;
            // check if selected entry is less than total records 
			if (this._selectedEntry < this.totalNumberOfRecords) {
				this.totalNumberOfPages = Math.ceil(this.totalNumberOfRecords / this._selectedEntry);
			} else this.totalNumberOfPages = 1;
        }
    }

    /**
    * @description Method to set pages list
    **/
    setPagesList() {
        if (this.currentPage && this._selectedEntry) {
            this.pagesList = [];
            // check total pages add it in the list 
			let startIndex = (this.currentPage - 2 <= 1 || this.totalNumberOfPages <= this._numberOfPagesShowInPaginator ? 1 : (this.currentPage + 2 >= this.totalNumberOfPages ? this.totalNumberOfPages - (this._numberOfPagesShowInPaginator-1) : this.currentPage - 2));
			let endIndex = (this.currentPage + 2 >= this.totalNumberOfPages || (this.currentPage + (this._numberOfPagesShowInPaginator - this.currentPage)) >= this.totalNumberOfPages ? this.totalNumberOfPages : (this.currentPage - 2 <= 1 ? this.currentPage + (this._numberOfPagesShowInPaginator - this.currentPage) : this.currentPage+2));
			// set pages 
			for(var i=startIndex;i<=endIndex;i++){
				this.pagesList.push({
                    'pageName' : i,
                    'variant' : i == this.currentPage ? 'brand' : 'neutral'
                });
			}
        }
    }

    /**
    * @description Method to set entries
    **/
    setEntries() {
        if (this.currentPage && this._selectedEntry) {
            this.startIndex = ((this.currentPage - 1) * this._selectedEntry + 1);
			this.endIndex = this.currentPage * this._selectedEntry >= this.totalNumberOfRecords ? this.totalNumberOfRecords : this.currentPage * this._selectedEntry;
        }
    }

    /**
    * @description Method to get isFirstPage
    **/
    get isFirstPage() {
        return this.currentPage == 1;
    }

    /**
    * @description Method to get isLastPage
    **/
    get isLastPage() {
        return this.currentPage == this.totalNumberOfPages;
    }


    /**
    * @description Method to handle first
    **/
    handleFirst() {
        this.firePageChangeEvent(1);
    }

    /**
    * @description Method to handle previous
    **/
    handlePrevious() {
        this.firePageChangeEvent(parseInt(this.currentPage) > 1 ? (parseInt(this.currentPage) - 1) : 1);
    }

    /**
    * @description Method to handle next
    **/
    handleNext() {
        this.firePageChangeEvent((parseInt(this.currentPage) < parseInt(this.totalNumberOfPages) ? (parseInt(this.currentPage) + 1) : parseInt(this.totalNumberOfPages)));
    }

    /**
    * @description Method to handle last
    **/
    handleLast() {
        this.firePageChangeEvent(parseInt(this.totalNumberOfPages));
    }

    /**
    * @description Method to handle page click
    **/
    handlePageClick(event) {
        this.firePageChangeEvent(parseInt(event.currentTarget.value));
    }

    /**
    * @description Method to fire page change event
    **/
    firePageChangeEvent(selectedPage) {
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: selectedPage
        }));
    } 
}