/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 02-16-2021
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   11-26-2020   James Ridge   Initial Version
**/
@isTest
public with sharing class SIM_FilterComponent_test {
    /**
     * 16/02/2021 - Updated test class to use Groups from 
     * custom metadata (Group__c) - this assumes that there already 
     * is a custom setting  with Group__c set to 1
     * 
     */
    static void createTestData(){
        
    }

    /**
     * Positive Test - obtaining user infos
     */
    @isTest
    static void test_getFilterOptions_Pos() {
        createTestData();

        String resultsJSON = SIM_FilterComponent.getFilterOptions('sirenum__Shift__c', '1');
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultsJSON);
        system.assertEquals(true, (Boolean)response.get('success'));

        Map<String, Object> respObjectMap = (Map<String, Object>)response.get('responseObject');

        system.assertEquals(UserInfo.getUserType(), (String)respObjectMap.get('userType'));
        system.assertEquals(UserInfo.getName(), (String)respObjectMap.get('userName'));
        system.assertEquals(UserInfo.getUserId(), (String)respObjectMap.get('userId'));
    }

    @isTest
    static void test_getFilterOptions_exception() {
        SIM_FilterComponent.throwException = true;
        String resultsJSON = SIM_FilterComponent.getFilterOptions('sirenum__Shift__c', '1');
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultsJSON);
        system.assertEquals(false, (Boolean)response.get('success'));
    }

    /** 
     * Negative Test - do not pass object to be described
     */
    @isTest
    static void test_getFilterOptions_Neg() {
        createTestData();

        String resultsJSON = SIM_FilterComponent.getFilterOptions(null, null);    
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultsJSON);
        system.assertEquals(false, (Boolean)response.get('success'));
    }

    /**
     * Positive Test - This test requires that there are custom metadata setting set up to cover
     * all options:
     * Related Object Match
     * Text Match
     * Date Match
     * Boolean Match
     * Picklist Match
     */
 

    /**
     * Positive Test - Test building SOQL filter
     */
     @isTest
     static void test_getSOQLFilter_Pos(){
        String groupsJSON = '[{"id":0,"crossConditionOperator":"and","conditions":[{"id":0,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__Contact__c","subTitleField":"TR1__Candidate_Status__c","searchObjectField":"Name","searchObject":"Contact","searchIcon":"standard:contact","options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Contact","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":true,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__Contact__c","targetFieldLabel":"Contact","targetValue":"0033H000004fyKnQAI","targetValueLabel":"Chew Bacca"},{"id":1,"selectedOperator":"not-null","selectedOperatorLabel":"Is Not Empty","selectedCriteria":{"value":null,"targetField":"sirenum__Shift_Status__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"contains","label":"Contains"},{"value":"not-contains","label":"Does Not Contain"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Shift Status","isTextMatch":true,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__Shift_Status__c","targetFieldLabel":"Shift Status","targetValue":null,"targetValueLabel":null,"disableTargetValue":true},{"id":2,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__CancellationReason__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"Cancelled by Client","label":"Cancelled by Client"},{"value":"Replaced","label":"Replaced"},{"value":"Unavailability","label":"Unavailability"},{"value":"Cancelled by Consultant","label":"Cancelled by Consultant"},{"value":"Filled Externally","label":"Filled Externally"},{"value":"Contract Ended","label":"Contract Ended"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Cancellation Reason","isTextMatch":false,"isPicklistMatch":true,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__CancellationReason__c","targetFieldLabel":"Cancellation Reason","targetValue":"Replaced","targetValueLabel":"Replaced"},{"id":3,"selectedOperator":"more-equal","selectedOperatorLabel":"More or Equal","selectedCriteria":{"value":null,"targetField":"sirenum__Shift_Date__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"less-than","label":"Less Than"},{"value":"more-than","label":"More Than"},{"value":"less-equal","label":"Less or Equal"},{"value":"more-equal","label":"More or Equal"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Shift Date","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":true,"isBooleanMatch":false},"targetField":"sirenum__Shift_Date__c","targetFieldLabel":"Shift Date","targetValue":"2020-11-26","targetValueLabel":"2020-11-26","disableTargetValue":false}]},{"id":1,"crossConditionOperator":"and","conditions":[{"id":0,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__Allow_pay__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"true","label":"TRUE"},{"value":"false","label":"FALSE"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"}],"label":"Allow pay","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":true},"targetField":"sirenum__Allow_pay__c","targetFieldLabel":"Allow pay","targetValue":"true","targetValueLabel":"true"},{"id":1,"selectedOperator":"is-null","selectedOperatorLabel":"Is Empty","selectedCriteria":{"value":null,"targetField":"sirenum__CancellationReason__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"Cancelled by Client","label":"Cancelled by Client"},{"value":"Replaced","label":"Replaced"},{"value":"Unavailability","label":"Unavailability"},{"value":"Cancelled by Consultant","label":"Cancelled by Consultant"},{"value":"Filled Externally","label":"Filled Externally"},{"value":"Contract Ended","label":"Contract Ended"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Cancellation Reason","isTextMatch":false,"isPicklistMatch":true,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__CancellationReason__c","targetFieldLabel":"Cancellation Reason","targetValue":null,"targetValueLabel":null,"disableTargetValue":true}]}]';
        
        String resultsJSON = SIM_FilterComponent.getSOQLFilter('sirenum__Shift__c', 'and', groupsJSON);
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultsJSON);
        system.assertEquals(true, (Boolean)response.get('success'));

        String expectedSOQL = ' (sirenum__Contact__c = \'0033H000004fyKnQAI\' and sirenum__Shift_Status__c != null  and sirenum__CancellationReason__c = \'Replaced\' and sirenum__Shift_Date__c >= 2020-11-26 ) and (sirenum__Allow_pay__c = true and sirenum__CancellationReason__c = null  ) ';
        system.assertEquals(expectedSOQL, (String)response.get('message'));
    }

    @isTest
    static void test_getSOQLFilter_exception() {
        String groupsJSON = '[{"id":0,"crossConditionOperator":"and","conditions":[{"id":0,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__Contact__c","subTitleField":"TR1__Candidate_Status__c","searchObjectField":"Name","searchObject":"Contact","searchIcon":"standard:contact","options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Contact","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":true,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__Contact__c","targetFieldLabel":"Contact","targetValue":"0033H000004fyKnQAI","targetValueLabel":"Chew Bacca"},{"id":1,"selectedOperator":"not-null","selectedOperatorLabel":"Is Not Empty","selectedCriteria":{"value":null,"targetField":"sirenum__Shift_Status__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"contains","label":"Contains"},{"value":"not-contains","label":"Does Not Contain"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Shift Status","isTextMatch":true,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__Shift_Status__c","targetFieldLabel":"Shift Status","targetValue":null,"targetValueLabel":null,"disableTargetValue":true},{"id":2,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__CancellationReason__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"Cancelled by Client","label":"Cancelled by Client"},{"value":"Replaced","label":"Replaced"},{"value":"Unavailability","label":"Unavailability"},{"value":"Cancelled by Consultant","label":"Cancelled by Consultant"},{"value":"Filled Externally","label":"Filled Externally"},{"value":"Contract Ended","label":"Contract Ended"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Cancellation Reason","isTextMatch":false,"isPicklistMatch":true,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__CancellationReason__c","targetFieldLabel":"Cancellation Reason","targetValue":"Replaced","targetValueLabel":"Replaced"},{"id":3,"selectedOperator":"more-equal","selectedOperatorLabel":"More or Equal","selectedCriteria":{"value":null,"targetField":"sirenum__Shift_Date__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":null,"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"less-than","label":"Less Than"},{"value":"more-than","label":"More Than"},{"value":"less-equal","label":"Less or Equal"},{"value":"more-equal","label":"More or Equal"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Shift Date","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":true,"isBooleanMatch":false},"targetField":"sirenum__Shift_Date__c","targetFieldLabel":"Shift Date","targetValue":"2020-11-26","targetValueLabel":"2020-11-26","disableTargetValue":false}]},{"id":1,"crossConditionOperator":"and","conditions":[{"id":0,"selectedOperator":"equals","selectedOperatorLabel":"Equals","selectedCriteria":{"value":null,"targetField":"sirenum__Allow_pay__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"true","label":"TRUE"},{"value":"false","label":"FALSE"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"}],"label":"Allow pay","isTextMatch":false,"isPicklistMatch":false,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":true},"targetField":"sirenum__Allow_pay__c","targetFieldLabel":"Allow pay","targetValue":"true","targetValueLabel":"true"},{"id":1,"selectedOperator":"is-null","selectedOperatorLabel":"Is Empty","selectedCriteria":{"value":null,"targetField":"sirenum__CancellationReason__c","subTitleField":null,"searchObjectField":null,"searchObject":null,"searchIcon":null,"options":[{"value":"Cancelled by Client","label":"Cancelled by Client"},{"value":"Replaced","label":"Replaced"},{"value":"Unavailability","label":"Unavailability"},{"value":"Cancelled by Consultant","label":"Cancelled by Consultant"},{"value":"Filled Externally","label":"Filled Externally"},{"value":"Contract Ended","label":"Contract Ended"}],"operators":[{"value":"equals","label":"Equals"},{"value":"not-equals","label":"Not Equals"},{"value":"is-null","label":"Is Empty"},{"value":"not-null","label":"Is Not Empty"}],"label":"Cancellation Reason","isTextMatch":false,"isPicklistMatch":true,"isLookupMatch":false,"isDateMatch":false,"isBooleanMatch":false},"targetField":"sirenum__CancellationReason__c","targetFieldLabel":"Cancellation Reason","targetValue":null,"targetValueLabel":null,"disableTargetValue":true}]}]';
        SIM_FilterComponent.throwException = true;
        String resultsJSON = SIM_FilterComponent.getSOQLFilter('sirenum__Shift__c', 'and', groupsJSON);
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultsJSON);
        system.assertEquals(false, (Boolean)response.get('success'));
    }

    @isTest
    static void testCreateOperators_TextMatch() {
        // Arrange
        SIM_FilterComponent.ConditionDTO dto = new SIM_FilterComponent.ConditionDTO();
        dto.isTextMatch = true;

        // Act
        dto.createOperators();

        // Assert
        System.assertEquals(6, dto.operators.size(), 'Text Match should have 6 operators.');
        System.assertEquals('equals', dto.operators[0].value);
        System.assertEquals('not-equals', dto.operators[1].value);
        System.assertEquals('contains', dto.operators[2].value);
        System.assertEquals('not-contains', dto.operators[3].value);
        System.assertEquals('is-null', dto.operators[4].value);
        System.assertEquals('not-null', dto.operators[5].value);
    }

    @isTest
    static void testCreateOperators_DateMatch() {
        // Arrange
        SIM_FilterComponent.ConditionDTO dto = new SIM_FilterComponent.ConditionDTO();
        dto.isDateMatch = true;

        // Act
        dto.createOperators();

        // Assert
        System.assertEquals(8, dto.operators.size(), 'Date Match should have 8 operators.');
        System.assertEquals('equals', dto.operators[0].value);
        System.assertEquals('not-equals', dto.operators[1].value);
        System.assertEquals('less-than', dto.operators[2].value);
        System.assertEquals('more-than', dto.operators[3].value);
        System.assertEquals('less-equal', dto.operators[4].value);
        System.assertEquals('more-equal', dto.operators[5].value);
        System.assertEquals('is-null', dto.operators[6].value);
        System.assertEquals('not-null', dto.operators[7].value);
    }

    @isTest
    static void testCreateOperators_BooleanMatch() {
        // Arrange
        SIM_FilterComponent.ConditionDTO dto = new SIM_FilterComponent.ConditionDTO();
        dto.isBooleanMatch = true;

        // Act
        dto.createOperators();

        // Assert
        System.assertEquals(2, dto.operators.size(), 'Boolean Match should have 2 operators.');
        System.assertEquals('equals', dto.operators[0].value);
        System.assertEquals('not-equals', dto.operators[1].value);
    }

    @isTest
    static void testCreateOperators_LookupMatch() {
        // Arrange
        SIM_FilterComponent.ConditionDTO dto = new SIM_FilterComponent.ConditionDTO();
        dto.isLookupMatch = true;

        // Act
        dto.createOperators();

        // Assert
        System.assertEquals(4, dto.operators.size(), 'Lookup Match should have 4 operators.');
        System.assertEquals('equals', dto.operators[0].value);
        System.assertEquals('not-equals', dto.operators[1].value);
        System.assertEquals('is-null', dto.operators[2].value);
        System.assertEquals('not-null', dto.operators[3].value);
    }

    @isTest
    static void testCreateOperators_PicklistMatch() {
        // Arrange
        SIM_FilterComponent.ConditionDTO dto = new SIM_FilterComponent.ConditionDTO();
        dto.isPicklistMatch = true;

        // Act
        dto.createOperators();

        // Assert
        System.assertEquals(4, dto.operators.size(), 'Picklist Match should have 4 operators.');
        System.assertEquals('equals', dto.operators[0].value);
        System.assertEquals('not-equals', dto.operators[1].value);
        System.assertEquals('is-null', dto.operators[2].value);
        System.assertEquals('not-null', dto.operators[3].value);
    }
    
      @IsTest
    static void testConditionDTOTextMatch() {
        // Create a ConditionDTO instance using the TEXT/DATE/BOOLEAN constructor
        String conditionType = 'Text Match';
        String targetField = 'Name';
        String label = 'Account Name';
        
        SIM_FilterComponent.ConditionDTO condition = new SIM_FilterComponent.ConditionDTO(conditionType, targetField, label);
        
        // Verify the properties of the ConditionDTO
        System.assert(condition.isTextMatch);
        System.assertEquals(condition.targetField, 'Name');
        System.assertEquals(condition.label, 'Account Name');
        System.assertNotEquals(null, condition.operators);
    }

    @IsTest
    static void testConditionDTODateMatch() {
        // Create a ConditionDTO instance using the TEXT/DATE/BOOLEAN constructor
        String conditionType = 'Date Match';
        String targetField = 'CreatedDate';
        String label = 'Creation Date';
        
        SIM_FilterComponent.ConditionDTO condition = new SIM_FilterComponent.ConditionDTO(conditionType, targetField, label);
        
        // Verify the properties of the ConditionDTO
        System.assert(condition.isDateMatch);
        System.assertEquals(condition.targetField, 'CreatedDate');
        System.assertEquals(condition.label, 'Creation Date');
        System.assertNotEquals(null, condition.operators);
    }

    @IsTest
    static void testConditionDTOBooleanMatch() {
        // Create a ConditionDTO instance using the TEXT/DATE/BOOLEAN constructor
        String conditionType = 'Boolean Match';
        String targetField = 'IsActive';
        String label = 'Active';
        
        SIM_FilterComponent.ConditionDTO condition = new SIM_FilterComponent.ConditionDTO(conditionType, targetField, label);
        
        // Verify the properties of the ConditionDTO
        System.assert(condition.isBooleanMatch);
        System.assertEquals(condition.targetField, 'IsActive');
        System.assertEquals(condition.label, 'Active');
        System.assertNotEquals(null, condition.operators);
        System.assertEquals(2, condition.options.size());
    }

    
    @IsTest
    static void testConditionDTOLookupMatch() {
        // Create a ConditionDTO instance using the Related Object Match constructor
        String targetField = 'ContactId';
        String label = 'Contact';
        String searchObject = 'Contact';
        String searchObjectField = 'Name';
        String searchIcon = 'standard:contact';
        String subTitleField = 'Email';
        
        SIM_FilterComponent.ConditionDTO condition = new SIM_FilterComponent.ConditionDTO(targetField, label, searchObject, searchObjectField, searchIcon, subTitleField);
        
        // Verify the properties of the ConditionDTO
        System.assert(condition.isLookupMatch);
        System.assertEquals(condition.targetField, 'ContactId');
        System.assertEquals(condition.label, 'Contact');
        System.assertEquals(condition.searchObject, 'Contact');
        System.assertEquals(condition.searchObjectField, 'Name');
        System.assertEquals(condition.searchIcon, 'standard:contact');
        System.assertEquals(condition.subTitleField, 'Email');
        System.assertNotEquals(null, condition.operators);
    }

 

}