@isTest
public with sharing class ComplianceControllerTest {
    @isTest
    static void getCategories_returnsCorrectData() {
        List<ComplianceController.Category> results = ComplianceController.getCategories();

        System.assertEquals(8, results.size(), 'Should return correct number of picklist values');

        {
            ComplianceController.Category category = results.get(0);
            System.assertEquals('Admin/Office', category.label, 'Should be correct label');
            System.assertEquals('Admin/Office', category.value, 'Should be correct value');
        }
    }
}