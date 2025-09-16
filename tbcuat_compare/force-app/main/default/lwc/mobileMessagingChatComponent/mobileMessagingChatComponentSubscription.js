import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { showToast } from './mobileMessagingChatComponentUtils';
import { updateMessageMap } from './mobileMessagingChatComponentMessageProcessor';

// Subscribes to a streaming topic for real-time notifications
const subscribeToPushTopic = function() {
    const messageCallback = (response) => {
        try {
            updateMessageMap.call(this, response.data.event.createdDate, response.data.sobject);
        } catch (error) {
            // Handle error: For production, consider sending error to an error logging service instead
        }
    };

    return subscribe('/topic/MobileMessage_SMS_Changes', -1, messageCallback)
        .then(subscription => {
            // Subscription is successful
            // You can also perform other actions here if needed
            console.log("🚀 ~ file: MobileMessagingChatComponentSubscription.js:23 ~ subscribeToPushTopic ~ subscription:", subscription);
            return subscription; // You can return this if you need to use the subscription elsewhere
        })
        .catch(error => {
            showToast.call(this, 'Error subscribing to the topic: ' + error, 'error');
            // Handle or throw the error as needed
        });
};


// Unsubscribes from the streaming topic
const unsubscribeFromPushTopic = function(subscription) {
    if (subscription) {
        console.log("🚀 ~ file: MobileMessagingChatComponentSubscription.js:29 ~ unsubscribeFromPushTopic ~ unsubscription requested 04:")
        
        unsubscribe(subscription)
            .catch(error => {
                showToast.call(this, 'Error unsubscribing from the topic: ' +  error);
            });
    }
};

// Registers a global error listener for the EMP API
const registerErrorListener = function() {
    onError(error => {
        // Handle only specific global errors
        // Add conditions here to filter global errors if necessary
       // showToast.call(this, 'Received global error: ' + error.body.message, 'error');
       console.log('Listener Got Trapped');
    });
};

export { subscribeToPushTopic, unsubscribeFromPushTopic, registerErrorListener };