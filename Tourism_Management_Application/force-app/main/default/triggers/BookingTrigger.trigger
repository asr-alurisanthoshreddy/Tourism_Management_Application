/**
 * Trigger: BookingTrigger
 * Object: Booking__c
 * Handles automatic creation of invoices and itineraries when booking status changes to 'Confirmed'
 */
trigger BookingTrigger on Booking__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        BookingTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
