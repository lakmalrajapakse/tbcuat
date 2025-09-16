import { ShowToastEvent } from 'lightning/platformShowToastEvent';

function showToast(cmp, message, variant = 'info', mode = 'pester') {
    let title = '';
    if (variant == 'success')
        title = 'Success';
    else if (variant == 'warning')
        title = 'Warning';
    else if (variant == 'error')
        title = 'Error';
    else if (variant == 'info')
        title = 'Info';

    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    });
    cmp.dispatchEvent(event);
}

export { showToast }