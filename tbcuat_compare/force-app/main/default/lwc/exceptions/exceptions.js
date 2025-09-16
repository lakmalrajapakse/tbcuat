import { showToast } from 'c/toasts';

function standartizeError(err) {
    let errorObj = {
        type: 'Unknown',
        message: '',
        stack: 'N/A',
        isApex: false
    };
    
    if(!err){
        errorObj.type = 'Unknown';
        errorObj.message = '-';
    }else if(typeof err === 'string' || err instanceof String){
        //Handle throw "error";
        errorObj.type = typeof err;
        errorObj.message = err;
    }else if(err.body){
        //Handle Apex Errors
        errorObj.isApex = true;

        if(err.body.exceptionType){
            errorObj.type = err.body.exceptionType;
        }
        if(err.body.message){
            errorObj.message = err.body.message;
        }  
        if(err.body.stackTrace){
           errorObj.stack = err.body.stackTrace;
        }
    } else {
        //Handle JS Error Object
        errorObj.isApex = false;
        if(err.name){
            errorObj.type = err.name;
        }
        if(err.message){
            errorObj.message =  err.message;
        }   
        if(err.stack){
            errorObj.stack = err.stack;
        }
    }
    return errorObj;
}

function handleException(cmp, err = {}, errorToast = true) {
    let cmpName = (cmp && cmp.template && cmp.template.host)  ? cmp.template.host.localName : 'unknown-component';

    let errorObj = standartizeError(err);
    console.error(`--- Handled Exception @ ${cmpName} ---`, errorObj);
    
    if(errorToast){
        showToast(cmp, errorObj.message, 'error');
    }
}

export { handleException }