/**
 * BookingTriggerHandler
 * Handles all trigger logic for Booking__c object using bulkified pattern
 */
public class BookingTriggerHandler {
    
    /**
     * Handle after update trigger events
     */
    public static void handleAfterUpdate(List<Booking__c> newBookings, Map<Id, Booking__c> oldBookingsMap) {
        List<Booking__c> confirmedBookings = new List<Booking__c>();
        
        // Find bookings where Status changed to 'Confirmed'
        for (Booking__c booking : newBookings) {
            Booking__c oldBooking = oldBookingsMap.get(booking.Id);
            if (oldBooking.Status__c != 'Confirmed' && booking.Status__c == 'Confirmed') {
                confirmedBookings.add(booking);
            }
        }
        
        // Process confirmed bookings in bulk
        if (!confirmedBookings.isEmpty()) {
            createInvoiceAndItinerary(confirmedBookings);
        }
    }
    
    /**
     * Create Invoice and Itinerary records for confirmed bookings
     * Bulkified method that handles multiple bookings at once
     * Enqueues email notifications for created invoices
     */
    public static void createInvoiceAndItinerary(List<Booking__c> confirmedBookings) {
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        List<Itinerary__c> itinerariesToInsert = new List<Itinerary__c>();
        
        // Create Invoice and Itinerary records for each booking
        for (Booking__c booking : confirmedBookings) {
            // Create Invoice with Total Cost
            Invoice__c invoice = new Invoice__c(
                Name = 'INV-' + booking.Id.to15(),
                Booking__c = booking.Id,
                Amount__c = booking.Total_Cost__c
            );
            invoicesToInsert.add(invoice);
            
            // Create initial Itinerary record
            Itinerary__c itinerary = new Itinerary__c(
                Name = 'ITN-' + booking.Id.to15(),
                Booking__c = booking.Id,
                Day_Number__c = 1,
                Activity__c = 'Trip Start - Package: ' + booking.Package__c
            );
            itinerariesToInsert.add(itinerary);
        }
        
        // Bulk insert records with partial success handling
        List<Id> createdInvoiceIds = new List<Id>();
        
        if (!invoicesToInsert.isEmpty()) {
            List<Database.SaveResult> invoiceResults = Database.insert(invoicesToInsert, false);
            handleInsertResults(invoiceResults, confirmedBookings, 'Invoice');
            
            // Collect successfully created invoice IDs for email notification
            for (Database.SaveResult result : invoiceResults) {
                if (result.isSuccess()) {
                    createdInvoiceIds.add(result.getId());
                }
            }
        }
        
        if (!itinerariesToInsert.isEmpty()) {
            List<Database.SaveResult> itineraryResults = Database.insert(itinerariesToInsert, false);
            handleInsertResults(itineraryResults, confirmedBookings, 'Itinerary');
        }
        
        // Enqueue email notifications for created invoices
        if (!createdInvoiceIds.isEmpty()) {
            System.enqueueJob(new InvoiceEmailQueueable(createdInvoiceIds));
        }
    }
    
    /**
     * Handle database insert results and log any failures
     */
    private static void handleInsertResults(
        List<Database.SaveResult> results, 
        List<Booking__c> bookings,
        String recordType
    ) {
        List<Booking_Error_Log__c> errorLogs = new List<Booking_Error_Log__c>();
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            
            if (!result.isSuccess()) {
                String errorMessage = '';
                for (Database.Error error : result.getErrors()) {
                    errorMessage += error.getStatusCode() + ': ' + error.getMessage() + '\n';
                }
                
                Booking_Error_Log__c errorLog = new Booking_Error_Log__c(
                    Name = 'Error-' + recordType + '-' + System.now().getTime(),
                    Booking__c = bookings[i].Id,
                    Error_Message__c = errorMessage,
                    Related_Record_Type__c = recordType,
                    Error_Timestamp__c = System.now()
                );
                errorLogs.add(errorLog);
            }
        }
        
        // Insert error logs
        if (!errorLogs.isEmpty()) {
            Database.insert(errorLogs, false);
        }
    }
}
