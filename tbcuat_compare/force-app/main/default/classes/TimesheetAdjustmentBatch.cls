public with sharing class TimesheetAdjustmentBatch implements Database.Batchable<TimesheetAdjustmentService.AdjustmentRequest>, Database.Stateful {
    private List<TimesheetAdjustmentService.AdjustmentRequest> requests;

    public TimesheetAdjustmentBatch(List<TimesheetAdjustmentService.AdjustmentRequest> requests) {
        this.requests = requests;
    }

    public Iterable<TimesheetAdjustmentService.AdjustmentRequest> start(Database.BatchableContext bc) {
        return this.requests;
    }

    public void execute(Database.BatchableContext bc, List<TimesheetAdjustmentService.AdjustmentRequest> step) {
        TimesheetAdjustmentService.adjust(step);
    }

    public void finish(Database.BatchableContext bc) {
    }
}