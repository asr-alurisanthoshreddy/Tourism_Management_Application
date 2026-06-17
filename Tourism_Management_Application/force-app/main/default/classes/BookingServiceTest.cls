/**
 * BookingServiceTest
 * Test class for BookingService utility methods
 * Tests SOQL relationship queries and calculation logic
 */
@isTest
public class BookingServiceTest {
    
    /**
     * Test Setup - Create test data including bookings with expense items
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
        
        // Create Booking
        Booking__c booking = new Booking__c(
            Name = 'Test Booking',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 0
        );
        insert booking;
        
        // Create Expense Items
        List<Expense_Item__c> expenseItems = new List<Expense_Item__c>();
        expenseItems.add(new Expense_Item__c(
            Name = 'Hotel Cost',
            Booking__c = booking.Id,
            Amount__c = 2000.00
        ));
        expenseItems.add(new Expense_Item__c(
            Name = 'Transport Cost',
            Booking__c = booking.Id,
            Amount__c = 1500.00
        ));
        expenseItems.add(new Expense_Item__c(
            Name = 'Food Cost',
            Booking__c = booking.Id,
            Amount__c = 500.00
        ));
        insert expenseItems;
    }
    
    /**
     * POSITIVE TEST: Verify correct calculation of total cost from expense items
     */
    @isTest
    static void testCalculateTotalCost_PositiveCase() {
        // Arrange
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        List<Id> bookingIds = new List<Id>{booking.Id};
        
        Decimal expectedTotalCost = 2000.00 + 1500.00 + 500.00; // 4000.00
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(bookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, totalCosts.size(), 'Should return one entry');
        System.assertEquals(expectedTotalCost, totalCosts.get(booking.Id), 'Should correctly sum all expense items');
    }
    
    /**
     * BULK TEST: Verify calculation works with multiple bookings
     */
    @isTest
    static void testCalculateTotalCost_MultipleBo okings() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        // Create second booking with different expense amounts
        Booking__c booking2 = new Booking__c(
            Name = 'Second Booking',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 0
        );
        insert booking2;
        
        // Add expense items to second booking
        List<Expense_Item__c> expenseItems = new List<Expense_Item__c>();
        expenseItems.add(new Expense_Item__c(
            Name = 'Booking2 Expense1',
            Booking__c = booking2.Id,
            Amount__c = 3000.00
        ));
        expenseItems.add(new Expense_Item__c(
            Name = 'Booking2 Expense2',
            Booking__c = booking2.Id,
            Amount__c = 2000.00
        ));
        insert expenseItems;
        
        // Get original booking
        Booking__c booking1 = [SELECT Id FROM Booking__c WHERE Name = 'Test Booking'];
        List<Id> bookingIds = new List<Id>{booking1.Id, booking2.Id};
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(bookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, totalCosts.size(), 'Should return entries for both bookings');
        System.assertEquals(4000.00, totalCosts.get(booking1.Id), 'First booking total should be 4000');
        System.assertEquals(5000.00, totalCosts.get(booking2.Id), 'Second booking total should be 5000');
    }
    
    /**
     * EDGE CASE TEST: Verify handling of bookings with no expense items
     */
    @isTest
    static void testCalculateTotalCost_BookingWithNoExpenseItems() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        // Create booking without expense items
        Booking__c bookingNoExpense = new Booking__c(
            Name = 'Booking No Expenses',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 0
        );
        insert bookingNoExpense;
        
        List<Id> bookingIds = new List<Id>{bookingNoExpense.Id};
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(bookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, totalCosts.size(), 'Should return entry for booking');
        System.assertEquals(0, totalCosts.get(bookingNoExpense.Id), 'Total should be zero when no expense items');
    }
    
    /**
     * EDGE CASE TEST: Verify handling of empty booking list
     */
    @isTest
    static void testCalculateTotalCost_EmptyList() {
        // Arrange
        List<Id> emptyBookingIds = new List<Id>();
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(emptyBookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, totalCosts.size(), 'Should return empty map for empty input');
    }
    
    /**
     * TEST: Verify null handling in expense items
     */
    @isTest
    static void testCalculateTotalCost_NullAmountInExpenseItem() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        Booking__c booking = new Booking__c(
            Name = 'Booking with Null Amount',
            Tourist__c = tourist.Id,
            Package__c = package1.Id,
            Status__c = 'New',
            Total_Cost__c = 0
        );
        insert booking;
        
        // Create expense item with null amount
        Expense_Item__c expenseWithNull = new Expense_Item__c(
            Name = 'Null Amount Expense',
            Booking__c = booking.Id,
            Amount__c = null
        );
        insert expenseWithNull;
        
        // Also add a valid expense item
        Expense_Item__c validExpense = new Expense_Item__c(
            Name = 'Valid Expense',
            Booking__c = booking.Id,
            Amount__c = 1000.00
        );
        insert validExpense;
        
        List<Id> bookingIds = new List<Id>{booking.Id};
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(bookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, totalCosts.size(), 'Should handle null amounts gracefully');
        System.assertEquals(1000.00, totalCosts.get(booking.Id), 'Should only sum non-null amounts');
    }
    
    /**
     * BULK TEST: Calculate costs for 100 bookings efficiently
     */
    @isTest
    static void testCalculateTotalCost_LargeScale() {
        // Arrange
        Tourist__c tourist = [SELECT Id FROM Tourist__c LIMIT 1];
        Package__c package1 = [SELECT Id FROM Package__c LIMIT 1];
        
        // Create 100 bookings
        List<Booking__c> bookings = new List<Booking__c>();
        for (Integer i = 0; i < 100; i++) {
            bookings.add(new Booking__c(
                Name = 'Scale Test Booking ' + i,
                Tourist__c = tourist.Id,
                Package__c = package1.Id,
                Status__c = 'New',
                Total_Cost__c = 0
            ));
        }
        insert bookings;
        
        // Create expense items for each booking
        List<Expense_Item__c> allExpenses = new List<Expense_Item__c>();
        for (Booking__c booking : bookings) {
            allExpenses.add(new Expense_Item__c(
                Name = 'Expense for ' + booking.Name,
                Booking__c = booking.Id,
                Amount__c = 1000.00 + bookings.indexOf(booking)
            ));
        }
        insert allExpenses;
        
        // Get all booking IDs
        List<Id> bookingIds = new List<Id>();
        for (Booking__c booking : bookings) {
            bookingIds.add(booking.Id);
        }
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(bookingIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(100, totalCosts.size(), 'Should return 100 entries');
        
        // Verify correctness for a few entries
        for (Integer i = 0; i < 5; i++) {
            Decimal expectedCost = 1000.00 + i;
            System.assertEquals(expectedCost, totalCosts.get(bookings[i].Id), 
                'Booking ' + i + ' total cost should match expected amount');
        }
    }
    
    /**
     * TEST: Verify relationship query works correctly with SOQL
     */
    @isTest
    static void testCalculateTotalCost_VerifySOQLRelationshipQuery() {
        // Arrange
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Name = 'Test Booking' LIMIT 1];
        
        // Manually verify the relationship exists
        Booking__c bookingWithRelationship = [
            SELECT Id, (SELECT Amount__c FROM Expense_Items__r) 
            FROM Booking__c 
            WHERE Id = :booking.Id
        ];
        
        System.assertEquals(3, bookingWithRelationship.Expense_Items__r.size(), 
            'Should have 3 expense items in relationship');
        
        // Act
        Test.startTest();
        Map<Id, Decimal> totalCosts = BookingService.calculateTotalCost(new List<Id>{booking.Id});
        Test.stopTest();
        
        // Assert
        System.assertEquals(4000.00, totalCosts.get(booking.Id), 
            'Service method should match manual relationship query calculation');
    }
}
