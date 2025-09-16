public with sharing class SyncRateCardsFromJobRoleInvocable {
    @InvocableMethod
    public static void execute(List<Id> jobIds) {
        JobService.syncRateCardsFromRoleByJobId(new Set<Id>(jobIds));
    }
}