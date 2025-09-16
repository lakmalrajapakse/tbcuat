/**
 * @description       : 
 * @author            : James Ridge
 * @group             : 
 * @last modified on  : 06-29-2021
 * @last modified by  : James Ridge
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   10-29-2020   James Ridge   Initial Version
**/
public with sharing class SIM_Option {
    public String value;
    public String label;
    public String alternativeText;
    public String iconName;
    public Boolean disabled = false;

    public SIM_Option(String value, String label, Boolean disabled, String alternativeText, String iconName){
        this.value = value;
        this.label = label;
        this.disabled = disabled;
        this.alternativeText = alternativeText;
        this.iconName = iconName;        
    }

    public SIM_Option(String value, String label, Boolean disabled, String alternativeText){
        this.value = value;
        this.label = label;
        this.alternativeText = alternativeText;
        this.disabled = disabled;
    }
    public SIM_Option(String value, String label){ 
        this.value = value;
        this.label = label;
    }
    
    public SIM_Option(String value, String label, Boolean disabled){
        this.value = value;
        this.label = label;
        this.disabled = disabled;
    }
}