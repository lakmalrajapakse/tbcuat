/**
 * @description       : 
 * @author            : Simon Coles
 * @group             : 
 * @last modified on  : 20-11-2024
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   20-11-2024   Simon Coles   Initial Version
**/
public with sharing class SIM_LookupAuraService {
	public static final Integer MAX_SAERACH_RESULTS = 10;
    @AuraEnabled
	public static String getOneRecordById(Id recordId, String searcherJSON) {
		try{
			Searchable searcher = (Searchable)JSON.deserialize(searcherJSON, Searchable.class);
			List<String> expr = new List<String>();
			expr.add('SELECT ' + String.join(getSearcherFields(searcher), ', '));
			expr.add('FROM ' + String.escapeSingleQuotes(searcher.objectName));
			expr.add('WHERE Id = \'' + recordId + '\'');
			expr.add('LIMIT 1');

			String queryString = String.join(expr, ' ');
			System.debug('query string: ' + queryString);
			return JSON.serialize(new SIM_Response.SuccessResponse(Database.query(queryString)));
		}catch(Exception e){
			return JSON.serialize(new SIM_Response.ErrorResponse(e.getMessage() + ' Code: ' + e.getLineNumber() + ' Stack: ' + e.getStackTraceString()));
		}
	}

	@AuraEnabled(cacheable=false)
	public static String getRecent(String searcherJSON) {
		try{
			
			Searchable searcher = (Searchable)JSON.deserialize(searcherJSON, Searchable.class);
			Set<Id> recentIds = new Set<Id>();
			for(RecentlyViewed rv : queryRecentByType(searcher.objectName)) {
				recentIds.add(rv.Id);
			}

			List<String> expr = new List<String>();
			expr.add('SELECT ' + String.join(getSearcherFields(searcher), ', '));
			expr.add('FROM ' + String.escapeSingleQuotes(searcher.objectName));
			expr.add('WHERE Id IN (\'' + String.join(new List<Id>(recentIds), '\', \'') + '\')');
			return JSON.serialize(new SIM_Response.SuccessResponse(Database.query(String.join(expr, ' '))));
		}catch(Exception e){
			return JSON.serialize(new SIM_Response.ErrorResponse(e.getMessage() + ' Code: ' + e.getLineNumber() + ' Stack: ' + e.getStackTraceString()));
		}
	}
	

	@AuraEnabled(cacheable=true)
	public static String getRecords(String searcherJSON) {
		try{
			Searchable searcher = (Searchable)JSON.deserialize(searcherJSON, Searchable.class);
			String find = 'FIND \'' + String.escapeSingleQuotes(searcher.searchTerm) + '*\' IN ALL FIELDS';
			String returning = 'RETURNING ' + getReturning(searcher.objectName, getSearcherFields(searcher));
			String limitter = 'LIMIT ' + MAX_SAERACH_RESULTS;
			String query = find + ' ' + returning + ' ' + limitter;
			return JSON.serialize(new SIM_Response.SuccessResponse(System.Search.query(query)));
		}catch(Exception e){
			return JSON.serialize(new SIM_Response.ErrorResponse(e.getMessage() + ' Code: ' + e.getLineNumber() + ' Stack: ' + e.getStackTraceString()));
		}
	}

	private static String getReturning(String objectName, List<String> fields) {
		List<String> returning = new List<String>();
		String objectWithFields = objectName + (fields.isEmpty() ? '' : joinReturnFields(fields));
		returning.add(objectWithFields);
		return String.join(returning, ', ');
	}

	private static String joinReturnFields(List<String> fields) {
		return ' (' + String.escapeSingleQuotes(String.join(fields, ', ')) + ')';
	}

	private static List<RecentlyViewed> queryRecentByType(String objectName) {
		return [
			SELECT Id
			FROM RecentlyViewed
			WHERE Type = :objectName
			LIMIT :MAX_SAERACH_RESULTS];
	}

	private static List<String> getSearcherFields(Searchable searcher){
		Set<String> sarchFields = new Set<String>{'Id', 'Name'};
		if(searcher.fields != null && searcher.fields.size() > 0){
			for(String fieldName : searcher.fields)
				if(fieldName != null && fieldName.length() > 0)
					sarchFields.add(fieldName);
		}
		return new List<String>(sarchFields);
	}

	public class Searchable {
		@AuraEnabled
		public String searchTerm {get;set;}
		@AuraEnabled
		public String objectName {get;set;}
		@AuraEnabled
		public List<String> fields {get;set;}
	}
}