import { ShowToastEvent } from "lightning/platformShowToastEvent";

function showSuccessToast(title, message) {
    showToast("success", title, message);
}

function showErrorToast(title, message) {
    showToast("error", title, message);
}

function showToast(variant, title, message) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    dispatchEvent(evt);
}

function handleTransactionError(title, error) {
    let message = "Unknown error";
    if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
    } else if (typeof error?.body?.message === "string") {
        message = error.body.message;
    } else if (error instanceof Error) {
        console.log(error.stack);
        message = error.message;
    }
    showErrorToast(title, message);
}

function debounce(fn, timeout) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        timer = setTimeout(() => {
            fn.apply(this, args);
        }, timeout);
    };
}

export { handleTransactionError, showErrorToast, showSuccessToast, debounce };