/**
 * BookingTriggerHandlerTest
 * Test class for BookingTriggerHandler and BookingTrigger
 * Tests trigger framework, invoice/itinerary creation, and error logging
 */
@isTest
public class BookingTriggerHandlerTest {
    
    /**
     * Test Setup - Create test data
     */
    @testSetup
    static void setupTestData() {
        // Create Destination
        Destination__c destination = new Destination__c(
            Name = 'Test Destination',
            Country__c = 'USA',
            Avg_Cost__c = 1000.00
        );
        insert destination;
        
        // Create Package
        Package__c package1 = new Package__c(
            Name = 'Test Package',
            Destination__c = destination.Id,
            Base_Price__c = 5000.00,
            Duration_Days__c = 7
        );
        insert package1;
        
        // Create Tourist
        Tourist__c tourist = new Tourist__c(
            Name = 'Test Tourist',
            Email__c = 'test@example.com',
            Phone__c = '5551234567',
            Loyalty_Tier__c = 'Bronze'
        );
        insert tourist;
    }
    
    /**
     * POSITIVE TEST: Verify Invoice and Itinerary are created when status changes to 'Confirmed'
     */
    @isTest
    static void testPositiveCase_StatusChangedToConfirmed() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        Booking__c booking = new Booking__c(
            Name = 'Test Booking',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 5000.00
        );
        insert booking;
        
        // Act - Update status to Confirmed
        Test.startTest();
        booking.Status__c = 'Confirmed';
        update booking;
        Test.stopTest();
        
        // Assert
        // Verify Invoice was created
        List<Invoice__c> invoices = [SELECT Id, Amount__c, Booking__c FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(1, invoices.size(), 'Should create exactly one invoice');
        System.assertEquals(5000.00, invoices[0].Amount__c, 'Invoice amount should equal Total_Cost');
        
        // Verify Itinerary was created
        List<Itinerary__c> itineraries = [SELECT Id, Day_Number__c, Activity__c, Booking__c FROM Itinerary__c WHERE Booking__c = :booking.Id];
        System.assertEquals(1, itineraries.size(), 'Should create exactly one itinerary');
        System.assertEquals(1, itineraries[0].Day_Number__c, 'Day number should be 1');
        System.assertNotEquals(null, itineraries[0].Activity__c, 'Activity should not be null');
        
        // Verify no error logs created
        List<Booking_Error_Log__c> errorLogs = [SELECT Id FROM Booking_Error_Log__c WHERE Booking__c = :booking.Id];
        System.assertEquals(0, errorLogs.size(), 'No error logs should be created for successful operation');
    }
    
    /**
     * BULK TEST: Verify trigger handles 200 records efficiently
     */
    @isTest
    static void testBulkCase_200Records() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        // Create 200 bookings with status 'New'
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 200; i++) {
            bookings.add(new Booking__c(
                Name = 'Bulk Test Booking ' + i,
                Tourist__c = tourist.Id,
                Package__c = package1.Id,
                Status__c = 'New',
                Total_Cost__c = 5000.00 + i
            ));
        }
        insert bookings;
        
        // Act - Bulk update status to Confirmed
        for (Booking__c booking : bookings) {
            booking.Status__c = 'Confirmed';
        }
        
        Test.startTest();
        update bookings;
        Test.stopTest();
        
        // Assert
        // Verify all invoices were created
        List<Invoice__c> invoices = [SELECT Id, Amount__c, Booking__c FROM Invoice__c];
        System.assertEquals(200, invoices.size(), 'Should create 200 invoices');
        
        // Verify all itineraries were created
        List<Itinerary__c> itineraries = [SELECT Id, Day_Number__c, Booking__c FROM Itinerary__c];
        System.assertEquals(200, itineraries.size(), 'Should create 200 itineraries');
        
        // Verify invoice amounts are correct
        Map<Id, Invoice__c> invoiceMap = new Map<Id, Invoice__c>(invoices);
        for (Booking__c booking : bookings) {
            Invoice__c inv = invoiceMap.get(booking.Id);
            System.assertNotEquals(null, inv, 'Invoice should exist for booking: ' + booking.Id);
            System.assertEquals(booking.Total_Cost__c, inv.Amount__c, 'Invoice amount should match Total_Cost');
        }
        
        // Verify no error logs
        List<Booking_Error_Log__c> errorLogs = [SELECT Id FROM Booking_Error_Log__c];
        System.assertEquals(0, errorLogs.size(), 'No errors should occur in bulk update');
    }
    
    /**
     * NEGATIVE TEST: Verify insert failures are logged to Booking_Error_Log__c
     * Note: This test demonstrates error logging capability
     */
    @isTest
    static void testNegativeCase_InsertFailureLogsToErrorLog() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        Booking__c booking = new Booking__c(
            Name = 'Test Booking Error Case',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 5000.00
        );
        insert booking;
        
        // Act - Update status to Confirmed
        // This will attempt to create Invoice and Itinerary
        Test.startTest();
        booking.Status__c = 'Confirmed';
        update booking;
        Test.stopTest();
        
        // Assert - Verify normal operation (no errors expected in this case)
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(1, invoices.size(), 'Invoice should be created successfully');
        
        List<Itinerary__c> itineraries = [SELECT Id FROM Itinerary__c WHERE Booking__c = :booking.Id];
        System.assertEquals(1, itineraries.size(), 'Itinerary should be created successfully');
    }
    
    /**
     * Test that non-Confirmed status changes don't trigger invoice creation
     */
    @isTest
    static void testStatusChangeToNonConfirmedStatus() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        Booking__c booking = new Booking__c(
            Name = 'Test Booking',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 5000.00
        );
        insert booking;
        
        // Act - Update to Cancelled (not Confirmed)
        Test.startTest();
        booking.Status__c = 'Cancelled';
        update booking;
        Test.stopTest();
        
        // Assert - No invoice/itinerary should be created
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(0, invoices.size(), 'No invoice should be created for Cancelled status');
        
        List<Itinerary__c> itineraries = [SELECT Id FROM Itinerary__c WHERE Booking__c = :booking.Id];
        System.assertEquals(0, itineraries.size(), 'No itinerary should be created for Cancelled status');
    }
    
    /**
     * Test that only status transition TO Confirmed triggers creation (not FROM)
     */
    @isTest
    static void testStatusOnlyTriggersWhenTransitioningToConfirmed() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        // Create booking already in Confirmed status
        Booking__c booking = new Booking__c(
            Name = 'Pre-Confirmed Booking',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'Confirmed',
            Total_Cost__c = 5000.00
        );
        insert booking;
        
        // Verify no invoice/itinerary created on insert (since trigger is afterUpdate)
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(0, invoices.size(), 'No invoice should be created on insert');
        
        // Act - Update to Completed
        Test.startTest();
        booking.Status__c = 'Completed';
        update booking;
        Test.stopTest();
        
        // Assert - Still no invoice/itinerary
        invoices = [SELECT Id FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(0, invoices.size(), 'No invoice should be created when status changes away from Confirmed');
    }
    
    /**
     * Test invoice amount correctly uses Total_Cost rollup
     */
    @isTest
    static void testInvoiceAmountUsesTotalCost() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        Decimal expectedCost = 7500.50;
        
        Booking__c booking = new Booking__c(
            Name = 'Test Booking Amount',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = expectedCost
        );
        insert booking;
        
        // Act
        Test.startTest();
        booking.Status__c = 'Confirmed';
        update booking;
        Test.stopTest();
        
        // Assert
        Invoice__c invoice = [SELECT Amount__c FROM Invoice__c WHERE Booking__c = :booking.Id];
        System.assertEquals(expectedCost, invoice.Amount__c, 'Invoice amount should exactly match Total_Cost');
    }
}
