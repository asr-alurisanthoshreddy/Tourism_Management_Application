/**
 * BookingService
 * Service class for booking-related calculations and operations
 */
public class BookingService {
    
    /**
     * Calculate total cost for bookings based on related expense items
     * Uses relationship query to fetch all expense items and sum their amounts
     * 
     * @param bookingIds List of Booking IDs to calculate costs for
     * @return Map of Booking ID to total calculated cost (Decimal)
     */
    public static Map<Id, Decimal> calculateTotalCost(List<Id> bookingIds) {
        Map<Id, Decimal> totalCostMap = new Map<Id, Decimal>();
        
        // Query bookings with related expense items
        List<Booking__c> bookings = [
            SELECT Id, (SELECT Amount__c FROM Expense_Items__r) 
            FROM Booking__c 
            WHERE Id IN :bookingIds
        ];
        
        // Calculate total cost for each booking
        for (Booking__c booking : bookings) {
            Decimal totalCost = 0;
            
            // Sum all expense item amounts for this booking
            if (booking.Expense_Items__r != null && !booking.Expense_Items__r.isEmpty()) {
                for (Expense_Item__c expenseItem : booking.Expense_Items__r) {
                    if (expenseItem.Amount__c != null) {
                        totalCost += expenseItem.Amount__c;
                    }
                }
            }
            
            totalCostMap.put(booking.Id, totalCost);
        }
        
        return totalCostMap;
    }
}
