/*
Generic LWC - https://github.com/pozil/sfdc-ui-lookup-lwc/blob/master/src/main/default/lwc/lookup/lookup.js
*/

@isTest(isParallel=true)
public class SIM_LookupSearchResult_test {
    @isTest
    static void compareTo_should_work_with_two_null_titles() {
        SIM_LookupSearchResult r1 = getSearchResult(null);
        SIM_LookupSearchResult r2 = getSearchResult(null);

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(0, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_this_null_title() {
        SIM_LookupSearchResult r1 = getSearchResult(null);
        SIM_LookupSearchResult r2 = getSearchResult('a');

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(1, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_other_null_title() {
        SIM_LookupSearchResult r1 = getSearchResult('a');
        SIM_LookupSearchResult r2 = getSearchResult(null);

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(-1, compareResult);
    }

    @isTest
    static void compareTo_should_work_with_non_null_titles() {
        SIM_LookupSearchResult r1 = getSearchResult('a');
        SIM_LookupSearchResult r2 = getSearchResult('b');

        Integer compareResult = r1.compareTo(r2);

        System.assertEquals(-1, compareResult);
    }

    @isTest
    static void getters_should_work() {
        // For the sake of code coverage
        SIM_LookupSearchResult r = new SIM_LookupSearchResult('0010R00000yvEyRQAU', 'type', 'icon', 'title', 'subtitle');

        System.assertEquals('0010R00000yvEyRQAU', r.getId());
        System.assertEquals('type', r.getSObjectType());
        System.assertEquals('icon', r.getIcon());
        System.assertEquals('title', r.getTitle());
        System.assertEquals('subtitle', r.getSubtitle());
    }

    private static SIM_LookupSearchResult getSearchResult(String title) {
        return new SIM_LookupSearchResult(null, null, null, title, null);
    }
}