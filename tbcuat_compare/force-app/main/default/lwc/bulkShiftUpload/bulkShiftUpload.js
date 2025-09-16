import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { debug } from 'c/debug';
import {showToast} from 'c/toasts';

import getUploadTemplates from '@salesforce/apex/SIM_ShiftUploadController.getUploadTemplates';
import loadData from '@salesforce/apex/SIM_ShiftUploadController.loadData';
import getBatchProgress from '@salesforce/apex/SIM_ShiftUploadController.getBatchProgress';
import { loadScript } from "lightning/platformResourceLoader";
import xlsx from "@salesforce/resourceUrl/XLSX";

export default class BulkShiftUpload extends NavigationMixin(LightningElement) {
    MAX_FILE_SIZE = 5000000; //Max file size 5.0 MB

    xlsxInitialized = false;
    shiftTemplate = null;
    templateOptions = [];

    file=null;
    filename=null;
    
    batchInitiated = false;
    batchId = null;
    
    progress = 0;
    
    disableFileUpload=true;
    isLoading = true;  
    isSucceeded = false; 
    completed = false;  
    monitorInitiated = false;

    headerRow = 1;
    dataRow = 2;

    renderedCallback() {
        if (this.batchInitiated && !this.monitorInitiated) {
            this.monitorInitiated = true;
            var interval = window.setInterval(() => {
                getBatchProgress({
                    batchId: this.batchId
                }).then(results => {
                    let response = JSON.parse(results);

                    if (response.success) {
                       let respObject = response.responseObject;
                       this.progress = respObject.progress;
                       
                        if (respObject.isCompleted) {                           
                            window.clearInterval(interval);
                            this.batchInitiated=false;
                            this.completed = true;
                            this.isSucceeded = respObject.isLoaded;
                        }
                    } else {
                        window.clearInterval(interval);
                        this.batchInitiated = false;
                        this.progress = 100;
                        showToast(this, 'Unexpeceted error while loading file. Error = ' + response.message, 'error');                                                               
                    }    
                }).catch(err => {
                    window.clearInterval(interval);
                    this.batchInitiated = false;                   
                    this.progress = 100;
                   
                    if (err.body) {
                        let apexErr;
                        if (err.body.message)
                            apexErr = 'Apex Error: ' + err.body.message;
                        else
                            apexErr = 'Unknown Error';
    
                        if (err.body.stackTrace)
                            apexErr += ' Stack:' + err.body.stackTrace;
                        showToast(this, apexErr, 'error');                    
                    } else {
                        let jsErr;
                        if (err && err.message)
                            jsErr = 'Javascript Error: ' + err.message;
                        else if (err)
                            jsErr = '' + err;
                        else
                            jsErr = 'Unknown Error';
    
                        showToast(this, jsErr, 'error');
                    }
                });            
            }, 1000);
        }
    }

    connectedCallback() {
        //load xlsx library
        if (!this.xlsxInitialized) {
            loadScript(this, xlsx + '/jszip.js').then(() => {
                loadScript(this, xlsx + '/xlsx.js').then(() => {
                    this.xlsxInitialized = true;                
                    this.loadTemplateOptions();
                }).catch(error => {
                    showToast(this,  'An error occured while loading the xlsx library.', 'error');
                });                
            }).catch(error => {
                showToast(this, 'An error occured while loading the jszip library.', 'error');                
            });
        }        
    }

    loadTemplateOptions() {
        getUploadTemplates({}).then(results => {                   
            this.templateOptions = JSON.parse(results);
            this.isLoading = false;
        }).catch(err => {
            showToast(this, 'Error loading timesheet templates. Error = ' + err, 'error');
        });
    }

    handleFieldChange(event){
        let apiFieldValue = event.detail.value;
        let type = event.target.dataset.type; 
        switch(type) {
            case "template":
                this.shiftTemplate = apiFieldValue;
                break;                        
            case "hrow":
                this.headerRow = parseInt(apiFieldValue);
                break;
            case "drow":
                this.dataRow = parseInt(apiFieldValue);
                break;
        }

        this.disableFileUpload=true;
        if (this.reportValidity()) {
            this.disableFileUpload=false;
        }
    }

    @api reportValidity(){
        return this.checkValidity();
    }

    @api checkValidity(){
        //Validate inputs
        const allInputsAreValid = [...this.template.querySelectorAll('[data-form-component=true]')]
        .reduce((validSoFar, inputCmp) => {
            //Get Validity Status
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allInputsAreValid;
    }

    handleFileUploaded(event) {        
        this.headerErrorsFound = false;
        this.lineErrorsFound = false;
        this.batchInitiated = false;
        this.batchId = null;
        this.progress = 0;
        this.loadErrors = [];
        
        if (event.target.files.length > 0) {             
            this.file = event.target.files[0];

            if (this.file.size > this.MAX_FILE_SIZE) {
                showToast(this, 'File size is to big - file should be less then 5MB.', 'error');                
            } else {
              this.filename=this.file.name;              
              this.handleUpload();                      
            }
        }
    }

    handleUpload() {  
        var reader=new FileReader();
        var output;

        reader.onload = event => {
            this.isLoading = true;   
            this.completed = false;  
            this.monitorInitiated = false;       

            var data=event.target.result;
           
            var workbook=XLSX.read(data, { type: 'binary', cellText:false, raw:true});
            
            var ws = workbook.Sheets[workbook.SheetNames[0]]; //get the first sheet.
            var hrow = this.headerRow - 1;
            var result = {};
            result[workbook.SheetNames[0]] = XLSX.utils.sheet_to_json(ws, {defval:"", blankrows:true, range:hrow,raw:true});
            
            hrow++;

            //Add the row num to JSON
            for (var i = 0; i < result[workbook.SheetNames[0]].length; i++) {
                hrow++;
                result[workbook.SheetNames[0]][i]["__ROW_NUMBER__"]=hrow;                                
            }
            output = JSON.stringify(result, 2, 2);                           
            console.log(output);
            loadData({
                template: this.shiftTemplate,
                filename: this.filename,
                hrow: this.headerRow,
                drow: this.dataRow,
                jsonString: output
            }).then(results => {
            
                let response = JSON.parse(results);
                console.log('***loadData', response);
                
                if (response.success) {                    
                    this.batchId=response.message;                    
                    this.batchInitiated=true;                    
                } else {
                    console.log(response.messgae);
                    //error - well managed
                    showToast(this, 'Unexpeceted error while loading file. Error = ' + response.message, 'error');                                        
                }
            }).catch(err => {
                console.log('Unmanaged Error ', JSON.stringify(err));
                //error unmanaged - could be a controller exception or javascript exception
                if (err.body) {
                    let apexErr;
                    if (err.body.message)
                        apexErr = 'Apex Error: ' + err.body.message;
                    else
                        apexErr = 'Unknown Error';
    
                    if (err.body.stackTrace)
                        apexErr += ' Stack:' + err.body.stackTrace;
                    showToast(this, apexErr, 'error');                    
                } else {
                    let jsErr;
                    if (err && err.message)
                        jsErr = 'Javascript Error: ' + err.message;
                    else if (err)
                        jsErr = '' + err;
                    else
                        jsErr = 'Unknown Error';
    
                    showToast(this, jsErr, 'error');                                        
                }
            }).finally(fin => {
                this.isLoading = false;
            });            
        };

        reader.onerror = function(ex) {
            showToast(this, 'An error occured while reading. Error = ' + ex.message, 'error');                     
        };

        reader.readAsBinaryString(this.file);
    }
 
    
    /**
     * Handle Record Navigation
    */
    handleNavigateClick(event) {
        let recID = event.currentTarget.dataset.record;
        let objType = event.currentTarget.dataset.object;
        this.navigateToRecordViewPage(recID, objType);
    }

    navigateToRecordViewPage(recID, objType) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recID,
                objectApiName: objType,
                actionName: 'view'
            }
        });
    }
}