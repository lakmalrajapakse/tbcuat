import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Utility function to show toast notifications
const showToast = function(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title: 'Message', message, variant }));
};

// Utility function to format dates
const formatDate = (date) => {
    return new Date(date).toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        hour12: true,
    });
};

// Utility function to get initials from a name
const getInitialsFromName = (fullName) => {
    return fullName.split(' ').map(name => name[0].toUpperCase()).join('');
};
const computeMessageClass = (direction) => {
    const directionClass = direction === 'inbound' ? 'chat-listitem_inbound' : 'chat-listitem_outbound';
    return directionClass;
};

export { showToast, formatDate, getInitialsFromName, computeMessageClass};