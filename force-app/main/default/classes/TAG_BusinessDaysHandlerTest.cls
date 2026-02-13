@isTest
private class TAG_BusinessDaysHandlerTest {

    @testSetup
    static void setup() {
        Holiday testHoliday = new Holiday();
        testHoliday.Name = 'Test Christmas 2023';
        testHoliday.ActivityDate = Date.newInstance(2023, 12, 25); // Monday
        testHoliday.RecurrenceType = null;
        insert testHoliday;
    }

    @isTest
    static void testCalculateDueDateWithHolidayAndWeekend() {
        // Friday, 22 Dec 2023 at 10:00
        Datetime startDt = Datetime.newInstance(2023, 12, 22, 10, 0, 0);

        TAG_BusinessDaysHandler.DueDateWrapper req = new TAG_BusinessDaysHandler.DueDateWrapper();
        req.startDateTime = startDt;
        req.daysToAdd = 2; // Should skip Sat 23, Sun 24, and Mon 25 (Holiday) and set DueDate on Wed 27th

        List<TAG_BusinessDaysHandler.DueDateWrapper> requests = new List<TAG_BusinessDaysHandler.DueDateWrapper>();
        requests.add(req);

        Test.startTest();
        List<Datetime> results = TAG_BusinessDaysHandler.calculateDueDate(requests);
        Test.stopTest();
        
        Datetime expectedDate = Datetime.newInstance(2023, 12, 27, 10, 0, 0);
        
        System.assertEquals(expectedDate, results[0], 
            'Expected Wed Dec 27. The code failed to skip the weekend or the test holiday correctly.');
    }

    @isTest
    static void testBulkOperations() {
        
        List<TAG_BusinessDaysHandler.DueDateWrapper> requests = new List<TAG_BusinessDaysHandler.DueDateWrapper>();
        
        TAG_BusinessDaysHandler.DueDateWrapper req1 = new TAG_BusinessDaysHandler.DueDateWrapper();
        req1.startDateTime = Datetime.newInstance(2023, 12, 22, 09, 0, 0);
        req1.daysToAdd = 2; // Should land on Dec 27th
        requests.add(req1);

        // Starts after the holiday (Tuesday 26th Dec)
        TAG_BusinessDaysHandler.DueDateWrapper req2 = new TAG_BusinessDaysHandler.DueDateWrapper();
        req2.startDateTime = Datetime.newInstance(2023, 12, 26, 09, 0, 0);
        req2.daysToAdd = 1; // Should land on Wednesday Dec 27th
        requests.add(req2);

        Test.startTest();
        List<Datetime> results = TAG_BusinessDaysHandler.calculateDueDate(requests);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return results for both requests');
        System.assertEquals(Datetime.newInstance(2023, 12, 27, 09, 0, 0), results[0], 'Bulk Request 1 Failed');
        System.assertEquals(Datetime.newInstance(2023, 12, 27, 09, 0, 0), results[1], 'Bulk Request 2 Failed');
    }

    @isTest
    static void testCalculateDueDateWithHolidayDuringWeekend() {
        
        Holiday testHoliday1 = new Holiday();
        testHoliday1.Name = 'Test Christmas Sunday 2023';
        testHoliday1.ActivityDate = Date.newInstance(2023, 12, 24); // Sunday
        testHoliday1.RecurrenceType = null;
        insert testHoliday1;
        
        // Friday, 22 Dec 2023 at 10:00
        Datetime startDt = Datetime.newInstance(2023, 12, 22, 10, 0, 0);

        TAG_BusinessDaysHandler.DueDateWrapper req = new TAG_BusinessDaysHandler.DueDateWrapper();
        req.startDateTime = startDt;
        req.daysToAdd = 2; // Should skip Sat 23, Sun 24, and Mon 25 (Holiday) and set DueDate on Wed 27th

        List<TAG_BusinessDaysHandler.DueDateWrapper> requests = new List<TAG_BusinessDaysHandler.DueDateWrapper>();
        requests.add(req);

        Test.startTest();
        List<Datetime> results = TAG_BusinessDaysHandler.calculateDueDate(requests);
        Test.stopTest();
        
        Datetime expectedDate = Datetime.newInstance(2023, 12, 27, 10, 0, 0);
        
        System.assertEquals(expectedDate, results[0], 
            'Expected Wed Dec 27. The code failed to skip the weekend or the test holiday correctly.');
    }
}