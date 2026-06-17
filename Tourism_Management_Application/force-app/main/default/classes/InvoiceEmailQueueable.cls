/**
 * InvoiceEmailQueueable
 * Queueable job to send email notifications when invoices are created
 * Sends Messaging.SingleEmailMessage to related Tourist__c Email__c address
 * Enqueued from BookingTrigger after Invoice__c insert
 */
public class InvoiceEmailQueueable implements Queueable {
    
    private List<Id> invoiceIds;
    
    /**
     * Constructor
     */
    public InvoiceEmailQueueable(List<Id> invoiceIds) {
        this.invoiceIds = invoiceIds;
    }
    
    /**
     * Execute method - sends email notifications for invoices
     */
    public void execute(QueueableContext context) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            return;
        }
        
        // Query invoices with related booking and tourist information
        List<Invoice__c> invoices = [
            SELECT Id, Name, Amount__c, Tax__c, Booking__c, Booking__r.Tourist__c, 
                   Booking__r.Tourist__r.Email__c, Booking__r.Tourist__r.Name
            FROM Invoice__c
            WHERE Id IN :invoiceIds
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Invoice__c invoice : invoices) {
            if (invoice.Booking__r.Tourist__r.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{invoice.Booking__r.Tourist__r.Email__c});
                email.setSubject('Invoice Created: ' + invoice.Name);
                
                String emailBody = 'Dear ' + invoice.Booking__r.Tourist__r.Name + ',\n\n';
                emailBody += 'Your invoice has been created for your booking.\n\n';
                emailBody += '=== INVOICE DETAILS ===\n';
                emailBody += 'Invoice #: ' + invoice.Name + '\n';
                emailBody += 'Amount: $' + String.valueOf(invoice.Amount__c) + '\n';
                emailBody += 'Tax: $' + String.valueOf(invoice.Tax__c) + '\n';
                emailBody += 'Total: $' + String.valueOf(invoice.Amount__c + invoice.Tax__c) + '\n\n';
                emailBody += 'Please make payment at your earliest convenience to complete your booking confirmation.\n\n';
                emailBody += 'Thank you for choosing our tourism services!\n\n';
                emailBody += 'Best regards,\n';
                emailBody += 'Tourism Management Team';
                
                email.setPlainTextBody(emailBody);
                emails.add(email);
            }
        }
        
        // Send emails with partial success allowed
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
            
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Email send failed: ' + result.getErrors()[0].getMessage());
                }
            }
        }
    }
}
