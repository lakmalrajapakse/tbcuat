// MobileMessagingChatComponentService.js
import getPastMessages from '@salesforce/apex/MobileMessagingChatComponentController.getPastMessages';
import createNewMessage from '@salesforce/apex/MobileMessagingChatComponentController.createNewMessage';
import USER_ID from '@salesforce/user/Id';


const fetchPastMessages = async ({ contactId, pageNumber, pageSize }) => {
      try {
        // Call the Apex method and handle the promise
  
        const response = await getPastMessages({ contactId});
        
        return response; // This could be a list of messages
    } catch (error) {
        console.error("fetchPastMessages - error:", error);
        // Re-throw the error for further handling, or handle it as needed
        throw error;
    }
};


const sendNewMessage = async (contactId, newMessageContent, newMessageType) => {
    try {
        // Create an object with keys that match the Apex method's parameter names
        const messageParams = {
            contactId: contactId,
            messageBody: newMessageContent, // Ensure that this key matches the parameter name in Apex
            newMessageType: newMessageType
        
        };
        // Call the Apex method with the parameters object
        const response = await createNewMessage(messageParams);
        return response;
    } catch (error) {
        console.error("ChatComponentService: Error sending new message:", error);
        throw error;
    }
};

export { fetchPastMessages, sendNewMessage };