/**
 * @description       : 
 * @author            : Zach Palmer
 * @group             : 
 * @last modified on  : 01-03-2023
 * @last modified by  : Zach Palmer
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   01-03-2023  Zach Palmer   Initial Version
**/
public with sharing class SIM_FilterComponent {
    @testVisible static Boolean throwException = false;
    /**
     * This function queries metadata to get the 
     * condition criteria, operators and filter options
     * by a target object
     * 
     * targetObject - this is the context object - we will use this for filtering of
     * relevant SIM Filter Conditions
     * filterGroup - additional filter condition to pull only relevant SIM Filter Conditions
     * from context - needed as the component is universal
     */
    @AuraEnabled
    public static String getFilterOptions(String targetObject, String filterGroup) {
        try{
            if (throwException) {
                NoDataFoundException e = new NoDataFoundException();
                e.setMessage('Testing exception handling.');
                throw e;
            }
            Map<String, Object> results = new Map<String, Object>{'userType' => UserInfo.getUserType(),'userName' => UserInfo.getName(),'userId' => UserInfo.getUserId(),'conditionCriteria' => getConditionCriteria(targetObject, filterGroup)};

            return JSON.serialize(new SIM_Response.SuccessResponse(results));
        }catch(Exception e){
            String generalError = String.format(Label.CRM_GeneralApexFailure,new Object[]{e.getMessage(),e.getLineNumber(),e.getStackTraceString()});
            return JSON.serialize(new SIM_Response.ErrorResponse(generalError));
        }
    }

    /**
     * This function retrieves the target object, cross-group operator and the 
     * filter groups and their conditions and queries the server for the IDs of
     * records matching the filter criteria
     */
    @AuraEnabled
    public static String getSOQLFilter(String targetObject, String crossGroupOperator, String groupsJSON){
        try{
            if (throwException) {
                NoDataFoundException e = new NoDataFoundException();
                e.setMessage('Testing exception handling.');
                throw e;
            }
            List<Object> filterGroupsUntyped = (List<Object>)JSON.deserializeUntyped(groupsJSON);

            List<FilterGroup> filterGroups = new List<FilterGroup>();
            for(Object filterGroupUntyped : filterGroupsUntyped){
                filterGroups.add((FilterGroup)JSON.deserialize(JSON.serialize(filterGroupUntyped), FilterGroup.class));
            }

            return JSON.serialize(new SIM_Response.SuccessResponse(buildSOQLFilter(targetObject, crossGroupOperator, filterGroups)));
        }catch(Exception e){
            String generalError = String.format(Label.CRM_GeneralApexFailure,new Object[]{e.getMessage(),e.getLineNumber(),e.getStackTraceString()});
            return JSON.serialize(new SIM_Response.ErrorResponse(generalError));
        }
    }

    public class FilterGroup{
        public String id;public String crossConditionOperator; public List<FilterGroupCondition> conditions;
    }
    public class FilterGroupCondition{
        public String selectedOperator; public String targetField; public String targetValue; public ConditionDTO selectedCriteria;
    }

    /**
     * This function builds String SOQL query based on the 
     * filter groups and cross group operators. 
     * 
     * This function is used by other APEX classes too
     */
    public static String buildSOQLFilter(String targetObject, String crossGroupOperator, List<FilterGroup> filterGroups){
        String stringSOQL = '';
        for(Integer i = 0; i < filterGroups.size(); i++){
            FilterGroup fg = filterGroups[i];
            
            //Group has no conditions
            if(fg.conditions == null || fg.conditions.size() == 0)
                continue;

            stringSOQL += ' (';
            for(Integer j = 0; j < fg.conditions.size(); j++){
                FilterGroupCondition condition = fg.conditions[j];

                // Add left hand expression - [target field] + [operator]
                stringSOQL += getLeftHandExpression(condition.targetField, condition.selectedOperator, condition.targetValue);
                
                /**
                 * Add right hand expression - [value]
                 * 
                 * Note (1): we do not need right hand expression if we are performing a null check
                 * Note (2): we do not need right hand expression for contains/not-contains since it is handled in the left hand expression
                 */
                if(!condition.selectedOperator.contains('null') && !condition.selectedOperator.contains('contains')){

                    if(condition.selectedCriteria.isTextMatch || condition.selectedCriteria.isLookupMatch || condition.selectedCriteria.isPicklistMatch){
                        //Add Text Literal Value
                        String targetValue = condition.targetValue == null ? '' : String.escapeSingleQuotes(condition.targetValue);
                        stringSOQL +=  '\'' + targetValue + '\'';
                    }else if(condition.selectedCriteria.isDateMatch){
                        Date targetDateValue = null;
                        if(condition.targetValue == null){
                            targetDateValue = system.today();
                        }else{
                            try{
                                List<String> dateComps = condition.targetValue.split('-');
                                Date parsedDate = Date.newInstance(Integer.valueOf(dateComps[0]), Integer.valueOf(dateComps[1]), Integer.valueOf(dateComps[2]));
                                targetDateValue = parsedDate;
                            }catch(Exception e){
                                //targetValue = sytem.today();
                                throw new StringException('H:' + e.getMessage());
                            }
                        }
                        stringSOQL += String.valueOf(targetDateValue);
                    }else if(condition.selectedCriteria.isBooleanMatch){
                        Boolean targetBooleanValue = condition.targetValue == null ? false : Boolean.valueOf(condition.targetValue);
                        stringSOQL +=  String.valueOf(targetBooleanValue);
                    }
                }                                    
                
                //Add between cases AND/OR operator
                if(j != fg.conditions.size() - 1) 
                    stringSOQL += ' ' + fg.crossConditionOperator + ' ';
            }

            //Add between groups AND/OR operator
            stringSOQL += ' ) ' + crossGroupOperator;
        }       
        
        return stringSOQL.removeEnd(crossGroupOperator);
    }

    /**
     * Private funtion to get the left hand expression for
     * a string SOQL statement
     */
    private static String getLeftHandExpression(String targetField, String selectedOperator, String targetValue){
        /**
         * equals not-equals null more-equal less-equal more-than less-than contains
         */

         switch on selectedOperator {
            when 'equals' {     
                return targetField + ' = ';
            }   
            when 'not-equals' {     
                return targetField +  ' != ';
            }
            when 'more-equal' { 
                return targetField +  ' >= ';
            }
            when 'less-equal' { 
                return targetField +  ' <= ';
            }
            when 'more-than' {  
                return targetField +  ' > ';
            }
            when 'less-than' {  
                return targetField +  ' < ';
            }
            when 'is-null' {    
                return targetField +  ' = null ';
            }
            when 'not-null' {   
                return targetField +  ' != null ';
            }
            when 'contains' {   
                return ' LIKE \'%' + targetValue + '%\' ';
            }
            when 'not-contains' {   
                return '(NOT ' + targetField +  '  LIKE \'%' + targetValue + '%\' ) ';
            }
            when else {       
                return null;
            }
        }
    }

    /**
     * Gets condtion options, operators and values
     * for a target object
     */
    @testVisible
    private static List<ConditionDTO> getConditionCriteria(String targetObject, String filterGroup){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> matchObjectFieldsMap = schemaMap.get(targetObject).getDescribe().fields.getMap();

        List<ConditionDTO> res = new List<ConditionDTO>();
        for(SIM_Filter_Condition__mdt conditionType : [
            SELECT ID, Search_Icon__c, Type__c, Group__c, Order__c,Condition_Object__r.QualifiedApiName,  Match_Object__r.QualifiedApiName, Match_Object_Field__r.QualifiedApiName, Match_Object_Field__r.DataType, 
            Condition_Object_Title_Field__r.QualifiedApiName, Condition_Object_Subtitle_Field__r.QualifiedApiName
            FROM SIM_Filter_Condition__mdt WHERE Match_Object__r.QualifiedApiName =: targetObject AND Group__c =:filterGroup
            ORDER BY Order__c ASC ]){
                if(conditionType.Type__c == 'Related Object Match'){
                    res.add(new ConditionDTO(conditionType.Match_Object_Field__r.QualifiedApiName, schemaMap.get(conditionType.Condition_Object__r.QualifiedApiName).getDescribe().getLabel(),conditionType.Condition_Object__r.QualifiedApiName,conditionType.Condition_Object_Title_Field__r.QualifiedApiName,conditionType.Search_Icon__c,conditionType.Condition_Object_Subtitle_Field__r.QualifiedApiName
                    ));
                }else if(conditionType.Type__c == 'Text Match' || conditionType.Type__c == 'Date Match' || conditionType.Type__c == 'Boolean Match'){
                    DescribeFieldResult matchObjectFieldDescribe = matchObjectFieldsMap.get(conditionType.Match_Object_Field__r.QualifiedApiName).getDescribe();
                    res.add(new ConditionDTO( conditionType.Type__c, conditionType.Match_Object_Field__r.QualifiedApiName, matchObjectFieldDescribe.getLabel()));

                }else if(conditionType.Type__c == 'Picklist Match'){
                    DescribeFieldResult matchObjectFieldDescribe = matchObjectFieldsMap.get(conditionType.Match_Object_Field__r.QualifiedApiName).getDescribe();
                    res.add(new ConditionDTO(conditionType.Match_Object_Field__r.QualifiedApiName, matchObjectFieldDescribe.getLabel(), matchObjectFieldDescribe.getPicklistValues()));
                }
        }
        return res;
    }

    public class ConditionDTO {
        String value;
        @testvisible
        String label;
        @testvisible
        String targetField;

        @testvisible
        String searchObject;
        @testvisible
        String searchObjectField;
        @testvisible
        String subTitleField;
        @testvisible
        String searchIcon;

        public Boolean isTextMatch = false;
        public Boolean isDateMatch = false;
        public Boolean isBooleanMatch = false;
        public Boolean isLookupMatch = false;
        public Boolean isPicklistMatch = false;

        @testvisible
        List<SIM_Option> options;
        @testvisible
        List<SIM_Option> operators;

        public ConditionDTO(){
        }
        /**
         * Piclist Constructor
         */
        public ConditionDTO(String targetField, String label, List<Schema.PicklistEntry> fieldOptions){
            this.options = new List<SIM_Option>();
            this.isPicklistMatch = true;
            this.targetField = targetField;
            this.label = label;

            for( Schema.PicklistEntry pickListVal : fieldOptions){
                this.options.add(new SIM_Option(pickListVal.getValue(), pickListVal.getLabel()));
            }     

            this.value = null;
            this.createOperators();
        }
        /**
         * TEXT/DATE/BOOLEAN Constructor 
         */
        public ConditionDTO(String conditionType, String targetField, String label){
            this.isTextMatch = conditionType == 'Text Match';
            this.isDateMatch = conditionType == 'Date Match';
            if(conditionType == 'Boolean Match'){
                this.isBooleanMatch = true;
                this.options = new List<SIM_Option>();
                this.options.add(new SIM_Option('true', 'TRUE'));
                this.options.add(new SIM_Option('false', 'FALSE'));
            }
            this.targetField = targetField;
            this.label = label;

            this.value = null;
            this.createOperators();
        }

        /**
         * Related Object Match Constructor 
         */
        public ConditionDTO(String targetField, String label, String searchObject, String searchObjectField, String searchIcon, String subTitleField){
            this.isLookupMatch = true; 

            this.targetField = targetField;                       
            this.label = label;
            this.searchObject = searchObject;

            this.searchObjectField = searchObjectField != null ? searchObjectField : 'Name';
            this.subTitleField = subTitleField;
            this.searchIcon = searchIcon;

            this.value = null;
            this.createOperators();
        }

        public void createOperators(){
            this.operators = new List<SIM_Option>();
            if(this.isTextMatch){
                this.operators.add(new SIM_Option('equals', 'Equals'));
                this.operators.add(new SIM_Option('not-equals', 'Not Equals'));
                this.operators.add(new SIM_Option('contains', 'Contains'));
                this.operators.add(new SIM_Option('not-contains', 'Does Not Contain'));
                this.operators.add(new SIM_Option('is-null', 'Is Empty'));
                this.operators.add(new SIM_Option('not-null', 'Is Not Empty'));
            }else if(this.isDateMatch){
                this.operators.add(new SIM_Option('equals', 'Equals'));
                this.operators.add(new SIM_Option('not-equals', 'Not Equals'));
                this.operators.add(new SIM_Option('less-than', 'Less Than'));
                this.operators.add(new SIM_Option('more-than', 'More Than'));
                this.operators.add(new SIM_Option('less-equal', 'Less or Equal'));
                this.operators.add(new SIM_Option('more-equal', 'More or Equal'));
                this.operators.add(new SIM_Option('is-null', 'Is Empty'));
                this.operators.add(new SIM_Option('not-null', 'Is Not Empty'));
            }else if(this.isBooleanMatch){
                this.operators.add(new SIM_Option('equals', 'Equals'));
                this.operators.add(new SIM_Option('not-equals', 'Not Equals'));
            }else if(this.isLookupMatch || this.isPicklistMatch){
                this.operators.add(new SIM_Option('equals', 'Equals'));
                this.operators.add(new SIM_Option('not-equals', 'Not Equals'));
                this.operators.add(new SIM_Option('is-null', 'Is Empty'));
                this.operators.add(new SIM_Option('not-null', 'Is Not Empty'));
            }
        }     
    }
}