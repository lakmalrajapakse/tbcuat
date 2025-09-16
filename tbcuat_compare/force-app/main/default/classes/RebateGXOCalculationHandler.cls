public with sharing class RebateGXOCalculationHandler implements IRebate{
    private Decimal nHours;
    private Decimal nHP_Rate;
    private Decimal nLevy;
    private Decimal nMargin_HGV;
    private Decimal nMargin_Ind;
    private Decimal nNI_Rate;
    private Decimal nPen_Lower;
    private Decimal nPen_Rate;
    private Decimal nST;
    private Set<String> aClients;


    public RebateGXOCalculationHandler(){
        this.nHours = 37.5;
        this.nHP_Rate = 0.1207;
        this.nLevy = 0.005;
        this.nMargin_HGV = 1.45;
        this.nMargin_Ind = 0.60;
        this.nNI_Rate = 0.15;
        this.nPen_Lower = 120;
        this.nPen_Rate = 0.015;
        this.nST = 96;
        this.aClients = new Set<String>();
        this.aClients.add('XPON35');
        this.aClients.add('XPON1123');
    }


    public Map<Id, Decimal> calculateRebate(Set<Id> timesheetIds){
        Decimal lnRebate = 0;
        Decimal lnTotal = 0;

        List<sirenum__Timesheet__c> laTimesheets = getTimesheetLines(timesheetIds);
        Map<Decimal, Decimal> laNormal = new Map<Decimal, Decimal>();
        Map<Decimal, Decimal> laOvertime = new Map<Decimal, Decimal>();
        Map<Id, Decimal> laRebates = new Map<Id, Decimal>();
        
        for (sirenum__Timesheet__c loTimesheet : laTimesheets) {
            lnRebate = 0;
            lnTotal = 0;

            laNormal.clear();
            laOvertime.clear();

            for (sirenum__timesheet_line__c loTimesheetLine : loTimesheet.sirenum__timesheet_lines__r){
                if ((loTimesheetLine.sirenum__charge__c > 0) && (loTimesheetLine.sirenum__hours__c > 0)){
                    if (loTimesheetLine.ratename__c == 'Normal'){
                        if (laNormal.containsKey(loTimesheetLine.sirenum__rate__c)){
                            laNormal.put(loTimesheetLine.sirenum__rate__c, (laNormal.get(loTimesheetLine.sirenum__rate__c) + loTimesheetLine.sirenum__hours__c));
                        } else {
                            laNormal.put(loTimesheetLine.sirenum__rate__c, loTimesheetLine.sirenum__hours__c);
                        }
                    } else {
                        if (laOvertime.containsKey(loTimesheetLine.sirenum__rate__c)){
                            laOvertime.put(loTimesheetLine.sirenum__rate__c, (laOvertime.get(loTimesheetLine.sirenum__rate__c) + loTimesheetLine.sirenum__hours__c));
                        } else {
                            laOvertime.put(loTimesheetLine.sirenum__rate__c, loTimesheetLine.sirenum__hours__c);
                        }
                    }
                }
            }

            for(Decimal lnKey : laNormal.keySet()){
                lnTotal += calculateNormal(loTimesheet.sirenum__client__r.client_code__c, loTimesheet.plan_code__c, laNormal.get(lnKey), lnKey);
            }

            for(Decimal lnKey : laOvertime.keySet()){
                lnTotal += calculateOvertime(loTimesheet.sirenum__client__r.client_code__c, loTimesheet.plan_code__c, laOvertime.get(lnKey), lnKey);
            }

            lnRebate = (loTimesheet.sirenum__total_charge__c - lnTotal);

            if (lnRebate <> 0){
                laRebates.put(loTimesheet.id, lnRebate);
            }
        }

        return laRebates;
    }


    private List<sirenum__Timesheet__c> getTimesheetLines(Set<Id> paTimesheetIds) {
        List<sirenum__timesheet__c> laTimesheets = [Select id, sirenum__total_charge__c, sirenum__total_pay__c,
                                                    sirenum__client__r.client_code__c, plan_code__c,
                                                    (Select id, sirenum__charge__c, sirenum__rate__c,  sirenum__hours__c, ratename__c 
                                                     From sirenum__timesheet_lines__r)
                                                    From sirenum__timesheet__c
                                                    Where (id In :paTimesheetIds)];
    	
        return laTimesheets;
    } 


    private Decimal calculateNormal(String pcCliCode, String pcPlanCode, Decimal pnHours, Decimal pnRate){
        Decimal lnCharge = 0;
        Decimal lnHP = (pnRate * this.nHP_Rate);
        Decimal lnMargin = 0;
        Decimal lnNI = 0;
        Decimal lnPension = 0;
        Decimal lnRate = (pnRate + lnHP);
        Decimal lnLevy = (lnRate * this.nLevy);
        Decimal lnPay = (lnRate * this.nHours);
        
        if ((lnPay - this.nST) > 0){
            lnNI = (((lnPay - this.nST) * this.nNI_Rate) / this.nHours);
        }

        if ((lnPay - this.nPen_Lower) > 0){
            lnPension = (((lnPay - this.nPen_Lower) * this.nPen_Rate) / this.nHours);
        }

        if (this.aClients.contains(pcCliCode)){
            lnMargin = (pcCliCode == 'XPON35') ? 0.75 : 1.30;
        } else {
            lnMargin = (pcPlanCode.substring(2, 3) == 'HGV') ? this.nMargin_HGV : this.nMargin_Ind;
        }

        lnCharge = ((pnRate + lnHP + lnLevy + lnNI + lnPension + lnMargin) * pnHours);

        return lnCharge;
    }


    private Decimal calculateOvertime(String pcCliCode, String pcPlanCode, Decimal pnHours, Decimal pnRate){
        Decimal lnCharge = 0;
        Decimal lnHP = (pnRate * this.nHP_Rate);
        Decimal lnMargin = 0;
        Decimal lnRate = (pnRate + lnHP);
        Decimal lnLevy = (lnRate * this.nLevy);
        Decimal lnNI = (lnRate * this.nNI_Rate);
        Decimal lnPension = (lnRate * this.nPen_Rate);

        if (this.aClients.contains(pcCliCode)){
            lnMargin = (pcCliCode == 'XPON35') ? 0.75 : 1.30;
        } else {
            lnMargin = (pcPlanCode.substring(2, 3) == 'HGV') ? this.nMargin_HGV : this.nMargin_Ind;
        }

        lnCharge = ((pnRate + lnHP + lnLevy + lnNI + lnPension + lnMargin) * pnHours);

        return lnCharge;
    }
}