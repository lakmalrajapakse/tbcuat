/**
 * Response Classes
 * This file contains an abstract base class and its subclasses for handling API responses in Salesforce Apex.
 * The Response class is the parent class that provides common attributes and constructors.
 * SuccessResponse and ErrorResponse are subclasses that represent successful and error outcomes respectively.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Creation Date: [Specify Creation Date Here]
 * Last Modified: 14 Jan 2024
 */

/**
 * Response
 * An abstract base class for standardizing API responses.
 */
public abstract class Response {
    public Integer statusCode;
    public Boolean success;
    public String message;
    public Object responseObject;

    /**
     * Constructor for the Response class.
     *
     * @param statusCode The HTTP status code of the response.
     * @param success The success flag indicating if the operation was successful.
     */
    public Response(Integer statusCode, Boolean success) {
        this.statusCode = statusCode;
        this.success = success;
    }

    /**
     * SuccessResponse
     * A subclass of Response for successful API outcomes.
     */
    public class SuccessResponse extends Response {

        /**
         * Default constructor for a success response with a 200 status code.
         */
        public SuccessResponse() {
            super(200, true);
        }

        /**
         * Constructor for a success response with a payload and custom message.
         *
         * @param responseObject The payload associated with the success response.
         * @param message A custom message detailing the success.
         */
        public SuccessResponse(Object responseObject, String message) {
            this();
            this.responseObject = responseObject;
            this.message = message;
        }

        /**
         * Constructor for a success response with only a payload.
         *
         * @param responseObject The payload associated with the success response.
         */
        public SuccessResponse(Object responseObject) {
            this();
            this.responseObject = responseObject;
        }

        /**
         * Constructor for a success response with only a custom message.
         *
         * @param message A custom message detailing the success.
         */
        public SuccessResponse(String message) {
            this();
            this.message = message;
        }
    }

    /**
     * ErrorResponse
     * A subclass of Response for error API outcomes.
     */
    public class ErrorResponse extends Response {

        /**
         * Constructor for an error response with a custom message and a 400 status code.
         *
         * @param message A custom message detailing the error.
         */
        public ErrorResponse(String message) {
            super(400, false);
            this.message = message;
        }

        /**
         * Constructor for an error response with a payload, custom message, and a 400 status code.
         *
         * @param responseObject The payload associated with the error response.
         * @param message A custom message detailing the error.
         */
        public ErrorResponse(Object responseObject, String message) {
            super(400, false);
            this.responseObject = responseObject;
            this.message = message;
        }

        /**
         * Constructor for an error response with only a payload and a 400 status code.
         *
         * @param responseObject The payload associated with the error response.
         */
        public ErrorResponse(Object responseObject) {
            super(400, false);
            this.responseObject = responseObject;
        }
    }
}