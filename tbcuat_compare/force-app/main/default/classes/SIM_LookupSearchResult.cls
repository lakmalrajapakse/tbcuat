/*
Generic LWC - https://github.com/pozil/sfdc-ui-lookup-lwc/blob/master/src/main/default/lwc/lookup/lookup.js
*/

/**
 * Class used to serialize a single Lookup search result item
 * The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
 */
public class SIM_LookupSearchResult implements Comparable {
    private Id id;
    private String sObjectType;
    private String icon;
    private String title;
    private String subtitle;

    public SIM_LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }

    @AuraEnabled
    public Id getId() {
        return id;
    }

    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

    @AuraEnabled
    public String getIcon() {
        return icon;
    }

    @AuraEnabled
    public String getTitle() {
        return title;
    }

    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }

    /**
     * Allow to sort search results based on title
     */
    public Integer compareTo(Object compareTo) {
        SIM_LookupSearchResult other = (SIM_LookupSearchResult) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }
}