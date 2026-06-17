/**
 * ScheduledOverdueCheck
 * Schedulable class to run OverduePaymentBatch daily at 2 AM
 * Usage: System.schedule('Scheduled Overdue Check', '0 0 2 * * ?', new ScheduledOverdueCheck());
 */
global class ScheduledOverdueCheck implements Schedulable {
    
    /**
     * Execute method - runs when scheduled
     * Executes the OverduePaymentBatch in batch mode
     */
    global void execute(SchedulableContext context) {
        // Execute OverduePaymentBatch with batch size 200
        OverduePaymentBatch batch = new OverduePaymentBatch();
        Database.executeBatch(batch, 200);
        
        System.debug('ScheduledOverdueCheck: OverduePaymentBatch scheduled for execution');
    }
}
