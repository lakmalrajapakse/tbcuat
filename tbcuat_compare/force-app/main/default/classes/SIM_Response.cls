/**
 * @File Name          : SIM_Response.cls
 * @Description        : 
 * @Author             : James Ridge
 * @Group              : 
 * @Last Modified By   : James Ridge
 * @Last Modified On   : 11-03-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/2/2020   James Ridge     Initial Version
**/
public with sharing class SIM_Response {
    public abstract class Response {
        public Integer statusCode;
        public Boolean success;
        public String message;
        public Object responseObject;

        public Response() {
        }

        public Response(Integer statusCode, Boolean success) {
            this.statusCode = statusCode;
            this.success = success;
        }
    }

    public class SuccessResponse extends Response {

        public SuccessResponse() {
            super(200, true);
            success = true;
        }

        public SuccessResponse(Object responseObject, String message) {
            this();
            super.responseObject = responseObject;
            super.message = message;
            success = true;
        }

        public SuccessResponse(Object responseObject) {
            this();
            super.responseObject = responseObject;
            success = true;
        }
        public SuccessResponse(String message) {
            this();
            super.message = message;
            success = true;
        }
    }

    public class ErrorResponse extends Response {

        public ErrorResponse(String message) {
            super(400, false);
            super.message = message;
            success = false;
        }
        public ErrorResponse(Object responseObject, String message) {
            super(400, false);
            super.responseObject = responseObject;
            super.message = message;
            success = false;
        }
        
        public ErrorResponse(Object responseObject) {
            super(400, false);
            super.responseObject = responseObject;
            success = false;
        }
    }
}