/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 08-21-2022
 * @last modified by  : James Ridge
**/
@isTest
public with sharing class SIM_LookupSearchController_test {
    @isTest
    static void search(){
        SIM_LookupSearchController.Searchable searchable = new SIM_LookupSearchController.Searchable();
        searchable.searchTerm = UserInfo.getFirstName();
        searchable.objectName = 'User';
        searchable.title = 'Name';
        searchable.subtitle = 'FirstName';
        searchable.iconName = '';
        searchable.maxSearchResults = 100;

        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = UserInfo.getUserId();
        Test.setFixedSearchResults(fixedSearchResults);
        

        //Positive Test search()
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.search(searchable, new List<String>()));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        system.assertEquals(true, ((List<Object>)response.get('responseObject')).size() == fixedSearchResults.size());

        //Negative Test search() - bad object
        searchable.objectName = 'INVALID_OBJECT';
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.search(searchable, new List<String>()));
        system.assertEquals(false, (boolean)response.get('success'));

        //Negative Test search() - invalid searcher
        searchable.objectName = null;
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.search(searchable, new List<String>()));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        system.assertEquals(true, ((List<Object>)response.get('responseObject')).size() == 0);
    }

    @isTest
    static void getRecentlyViewed(){
        SIM_LookupSearchController.Searchable searchable = new SIM_LookupSearchController.Searchable();
        searchable.searchTerm = UserInfo.getFirstName();
        searchable.objectName = 'User';
        searchable.title = 'Name';
        searchable.subtitle = 'FirstName';
        searchable.iconName = '';
        searchable.maxSearchResults = 100;

        //Positive Test getRecentlyViewed()
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getRecentlyViewed(searchable));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        

        //Negative Test getRecentlyViewed() - bad object
        searchable.objectName = 'INVALID_OBJECT';
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getRecentlyViewed(searchable));
        system.assertEquals(false, (boolean)response.get('success'));

        //Negative Test getRecentlyViewed() - invalid searcher
        searchable.objectName = null;
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getRecentlyViewed(searchable));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        system.assertEquals(true, ((List<Object>)response.get('responseObject')).size() == 0);
    }

    @isTest
    static void getSelectedRecords(){
        SIM_LookupSearchController.Searchable searchable = new SIM_LookupSearchController.Searchable();
        searchable.searchTerm = UserInfo.getFirstName();
        searchable.objectName = 'User';
        searchable.title = 'Name';
        searchable.subtitle = 'FirstName';
        searchable.iconName = '';
        searchable.maxSearchResults = 100;


        //Positive Test getSelectedRecords()
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getSelectedRecords(searchable, new List<String>{UserInfo.getUserId()}));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        system.assertEquals(true, ((List<Object>)response.get('responseObject')).size() == 1);

        //Negative Test getSelectedRecords() - bad object
        searchable.objectName = 'INVALID_OBJECT';
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getSelectedRecords(searchable, new List<String>{UserInfo.getUserId()}));
        system.assertEquals(false, (boolean)response.get('success'));

        //Negative Test getSelectedRecords() - invalid searcher
        searchable.objectName = null;
        response = (Map<String, Object>)JSON.deserializeUntyped(SIM_LookupSearchController.getSelectedRecords(searchable, new List<String>{UserInfo.getUserId()}));
        system.assertEquals(true, (boolean)response.get('success'), 'Error: ' + (String)response.get('message'));
        system.assertEquals(true, ((List<Object>)response.get('responseObject')).size() == 0);
    }

    @isTest
    static void codeCoverage(){
        List<SIM_LookupSearchResult> listItems = new List<SIM_LookupSearchResult>();
        listItems.add(new SIM_LookupSearchResult(UserInfo.getUserId(), 'User', '', UserInfo.getUserName(), UserInfo.getUserName()));
        listItems.add(new SIM_LookupSearchResult(UserInfo.getUserId(), 'User', '', UserInfo.getUserName(), UserInfo.getUserName()));
        listItems.sort();
        SIM_LookupSearchResult searchItem = new SIM_LookupSearchResult(UserInfo.getUserId(), 'User', '', UserInfo.getUserName(), UserInfo.getUserName());
        searchItem.getIcon();
        searchItem.getId();
        searchItem.getSObjectType();
        searchItem.getSubtitle();
        searchItem.getTitle();

    }
}