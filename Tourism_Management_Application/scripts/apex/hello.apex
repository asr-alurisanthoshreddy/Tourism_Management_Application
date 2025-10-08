// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Travel Approval Service Class
public class TravelApprovalService {
    
    public static void approveTravel(Id travelId, String comments) {
        Travel_Approval__c ta = [SELECT Id FROM Travel_Approval__c WHERE Id = :travelId];
        ta.Status__c = 'Approved';
        ta.Approval_Comments__c = comments;
        ta.Approved_Date__c = Date.today();
        update ta;
    }
    
    public static void rejectTravel(Id travelId, String reason) {
        Travel_Approval__c ta = [SELECT Id FROM Travel_Approval__c WHERE Id = :travelId];
        ta.Status__c = 'Rejected';
        ta.Rejection_Reason__c = reason;
        update ta;
    }
    
    public static List<Travel_Approval__c> getPendingApprovals(Id deptId) {
        return [SELECT Id, Name, Traveler_Name__c, Destination__c, Total_Cost__c 
                FROM Travel_Approval__c 
                WHERE Department__c = :deptId AND Status__c = 'Pending'];
    }
}
