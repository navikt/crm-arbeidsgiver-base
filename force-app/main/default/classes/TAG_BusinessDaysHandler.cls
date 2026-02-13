public without sharing class TAG_BusinessDaysHandler {

    @InvocableMethod(label='Calculate Due DateTime' description='Returns a Due DateTime by adding business days (skipping weekends/holidays)')
    public static List<Datetime> calculateDueDate(List<DueDateWrapper> requests) {
        List<Datetime> dueDates = new List<Datetime>();
        
        Set<Date> holidayDates = getHolidayDates();

        for (DueDateWrapper req : requests) {
            Datetime currentDt = req.startDateTime;
            Integer daysToAdd = req.daysToAdd;
            
            Integer daysAdded = 0;
            
            while (daysAdded < daysToAdd) {
                currentDt = currentDt.addDays(1);
                
                // Extract just the Date part to check against Holidays/Weekends
                Date dateToCheck = currentDt.date();

                // Check if this new day is a Weekend or a Holiday
                if (!isWeekend(dateToCheck) && !holidayDates.contains(dateToCheck)) {
                    daysAdded++;
                }
            }
            dueDates.add(currentDt);
        }
        return dueDates;
    }

    // Determine if a date is Sat or Sun
    private static Boolean isWeekend(Date d) {
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        String dayName = dt.format('E'); 
        return (dayName == 'Sat' || dayName == 'Sun');
    }

    private static Set<Date> getHolidayDates() {
        Set<Date> dates = new Set<Date>();
        for (Holiday h : [SELECT ActivityDate, RecurrenceType, RecurrenceMonthOfYear, RecurrenceDayOfMonth, RecurrenceStartDate FROM Holiday]) {
            if (h.RecurrenceType == 'RecursYearly') {
                // Add this year's occurrence
                Date thisYear = Date.newInstance(System.today().year(), h.ActivityDate.month(), h.ActivityDate.day());
                dates.add(thisYear);
                // Add next year's occurrence (in case the due date calculation spans into next year)
                dates.add(thisYear.addYears(1));
            } else {
                dates.add(h.ActivityDate);
            }
        }
        return dates;
    }

    public class DueDateWrapper {
        @InvocableVariable(label='Start DateTime' required=true)
        public Datetime startDateTime;
        
        @InvocableVariable(label='Business Days to Add' required=true)
        public Integer daysToAdd;
    }
}
