/**
 * OverduePaymentBatch
 * Batch job to identify and mark invoices as overdue
 * Queries Invoice__c records where CreatedDate < 30 days ago and related 
 * Booking__c.Status__c != 'Completed', then sets Payment_Overdue__c = true
 */
global class OverduePaymentBatch implements Database.Batchable<sObject> {
    
    /**
     * Start method - returns QueryLocator for batch processing
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime thirtyDaysAgo = System.now().addDays(-30);
        
        String query = 'SELECT Id, Payment_Overdue__c, Booking__c, Booking__r.Status__c ' +
                       'FROM Invoice__c ' +
                       'WHERE CreatedDate < :thirtyDaysAgo ' +
                       'AND Booking__r.Status__c != \'Completed\'';
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Execute method - processes batch of invoices
     * Marks invoices as overdue
     */
    global void execute(Database.BatchableContext bc, List<Invoice__c> invoices) {
        for (Invoice__c invoice : invoices) {
            invoice.Payment_Overdue__c = true;
        }
        
        // Use Database.update with partial success allowed
        List<Database.SaveResult> results = Database.update(invoices, false);
        
        // Log any errors
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug('Error updating invoice ' + invoices[i].Id + ': ' + 
                            results[i].getErrors()[0].getMessage());
            }
        }
    }
    
    /**
     * Finish method - called when batch completes
     */
    global void finish(Database.BatchableContext bc) {
        System.debug('OverduePaymentBatch completed. Processed overdue invoices.');
    }
}
