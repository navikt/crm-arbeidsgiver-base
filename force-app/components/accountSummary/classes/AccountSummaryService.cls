public with sharing class AccountSummaryService {
    private static final Integer ROW_QUERY_LIMIT = 500;
    private static final Integer TABLE_QUERY_LIMIT = 200;
    private static final Integer DEADLINE_WARNING_DAYS = 7;
    private static final Integer MAX_DETAIL_GROUPS = 3;
    private static final List<String> MONTH_ABBREVIATIONS = new List<String>{
        'jan',
        'feb',
        'mar',
        'apr',
        'mai',
        'jun',
        'jul',
        'aug',
        'sep',
        'okt',
        'nov',
        'des'
    };
    private static final List<String> MONTH_NAMES = new List<String>{
        'januar',
        'februar',
        'mars',
        'april',
        'mai',
        'juni',
        'juli',
        'august',
        'september',
        'oktober',
        'november',
        'desember'
    };
    @TestVisible
    private static final String COORDINATION_NOTICE = 'Det er pågående aktivitet med denne arbeidsgiveren. Anbefalt å koordinere før du tar kontakt.';

    /* CONTEXT */

    public class Context {
        public Id accountId;
        public String accountName;
        public Id excludeInquiryId;
        public Boolean isInquiry = false;
    }

    public static Context resolveContext(Id recordId) {
        if (recordId == null) {
            return null;
        }
        Context ctx = new Context();
        Schema.SObjectType recordType = recordId.getSObjectType();
        if (recordType == Account.SObjectType) {
            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :recordId WITH USER_MODE LIMIT 1];
            if (accounts.isEmpty()) {
                return null;
            }
            ctx.accountId = accounts[0].Id;
            ctx.accountName = accounts[0].Name;
        } else if (recordType == EmployerInquiry__c.SObjectType) {
            List<EmployerInquiry__c> inquiries = [
                SELECT Id, TAG_Account__c, TAG_Account__r.Name
                FROM EmployerInquiry__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ];
            if (inquiries.isEmpty() || inquiries[0].TAG_Account__c == null) {
                return null;
            }
            ctx.accountId = inquiries[0].TAG_Account__c;
            ctx.accountName = inquiries[0].TAG_Account__r?.Name;
            ctx.excludeInquiryId = recordId;
            ctx.isInquiry = true;
        } else {
            return null;
        }
        return ctx;
    }

    /* SUMMARY */

    public static Summary buildSummary(Id recordId, Integer months) {
        Integer period = months == 12 ? 12 : 6;
        Summary summary = new Summary();
        summary.months = period;
        Context ctx = resolveContext(recordId);
        if (ctx == null) {
            summary.hasAccount = false;
            return summary;
        }
        summary.hasAccount = true;
        summary.accountId = ctx.accountId;
        summary.accountName = ctx.accountName;
        summary.isInquiryContext = ctx.isInquiry;

        Map<String, OngoingRow> rowsByKey = new Map<String, OngoingRow>();
        for (String key : AccountSummaryConfig.ONGOING_QUERY_KEYS) {
            OngoingRow row = buildQueryRow(key, ctx);
            rowsByKey.put(key, row);
            summary.ongoing.add(row);
        }
        PlannedResult planned = queryPlanned(ctx);
        OngoingRow plannedRow = buildPlannedRow(planned);
        rowsByKey.put(AccountSummaryConfig.PLANLAGT, plannedRow);
        summary.ongoing.add(plannedRow);
        summary.navContact = buildNavContact(ctx);

        HistoryCollector history = collectHistory(ctx, period);
        summary.history = history.getMonths();
        summary.historyTotals = history.getTotals();
        summary.historyTotal = history.total;

        for (OngoingRow row : summary.ongoing) {
            if (row.isAccessible && row.count > 0) {
                summary.hasOngoingActivity = true;
            }
        }
        summary.coordinationNotice = summary.hasOngoingActivity ? COORDINATION_NOTICE : null;
        summary.summaryParts = buildSummaryText(ctx, rowsByKey, planned, history, period);
        return summary;
    }

    /* ONGOING ROWS */

    private static OngoingRow buildQueryRow(String key, Context ctx) {
        Map<String, String> config = AccountSummaryConfig.getConfig(key);
        OngoingRow row = new OngoingRow(key, config);
        try {
            String query =
                buildOngoingQuery(config, ctx, 'Id, ' + config.get('detailFields')) +
                ' ORDER BY ' +
                config.get('orderBy') +
                ' LIMIT ' +
                ROW_QUERY_LIMIT;
            List<SObject> records = Database.queryWithBinds(query, buildBinds(config, ctx), AccessLevel.USER_MODE);
            row.count = records.size() < ROW_QUERY_LIMIT
                ? records.size()
                : Database.countQueryWithBinds(
                      buildOngoingQuery(config, ctx, 'COUNT()'),
                      buildBinds(config, ctx),
                      AccessLevel.USER_MODE
                  );
            describeRecords(key, records, row);
        } catch (Exception e) {
            row.isAccessible = false;
            row.count = 0;
        }
        return row;
    }

    private static String buildOngoingQuery(Map<String, String> config, Context ctx, String fields) {
        String query =
            'SELECT ' +
            fields +
            ' FROM ' +
            config.get('objectApiName') +
            ' WHERE ' +
            config.get('lookupField') +
            ' = :accountId';
        if (String.isNotBlank(config.get('queryFilter'))) {
            query += ' AND (' + config.get('queryFilter') + ')';
        }
        if (excludesCurrentRecord(config, ctx)) {
            query += ' AND Id != :excludeId';
        }
        return query;
    }

    private static Map<String, Object> buildBinds(Map<String, String> config, Context ctx) {
        Map<String, Object> binds = new Map<String, Object>{ 'accountId' => ctx.accountId };
        if (excludesCurrentRecord(config, ctx)) {
            binds.put('excludeId', ctx.excludeInquiryId);
        }
        return binds;
    }

    private static Boolean excludesCurrentRecord(Map<String, String> config, Context ctx) {
        return ctx.excludeInquiryId != null && config.get('objectApiName') == 'EmployerInquiry__c';
    }

    private static void describeRecords(String key, List<SObject> records, OngoingRow row) {
        if (records.isEmpty()) {
            return;
        }
        List<String> labels = new List<String>();
        switch on key {
            when 'avtale' {
                for (SObject rec : records) {
                    Contract__c contract = (Contract__c) rec;
                    Boolean isStrategic =
                        contract.TAG_Type_Partner__c == 'Strategisk Partner' ||
                        contract.TAG_Category__c == 'Strategisk partneravtale';
                    labels.add(
                        isStrategic
                            ? 'Strategisk partner'
                            : picklistLabel(Contract__c.TAG_Category__c, contract.TAG_Category__c)
                    );
                }
                Contract__c first = (Contract__c) records[0];
                row.details = records.size() == 1
                    ? labels[0] + ' · gyldig til ' + formatDate(first.TAG_EndDate__c, true)
                    : groupLabels(labels);
            }
            when 'stilling' {
                JobPosting__c first = (JobPosting__c) records[0];
                String title = String.isNotBlank(first.Title__c) ? first.Title__c : 'Uten tittel';
                if (records.size() > 1) {
                    title += ' (+' + (records.size() - 1) + ' flere)';
                }
                row.details = title;
                if (first.Expires__c != null) {
                    Date expires = first.Expires__c.date();
                    if (expires <= Date.today().addDays(DEADLINE_WARNING_DAYS)) {
                        row.pill = 'frist ' + formatDate(expires, false);
                    } else {
                        row.details += ' · frist ' + formatDate(expires, false);
                    }
                }
            }
            when 'tiltak' {
                for (SObject rec : records) {
                    labels.add(picklistLabel(Workfare__c.Type__c, (String) rec.get('Type__c')));
                }
                row.details = groupLabels(labels);
            }
            when 'ia' {
                for (SObject rec : records) {
                    String type = (String) rec.get('Type_IA_Cooperation__c');
                    if (String.isNotBlank(type)) {
                        labels.add(type);
                    }
                }
                IACooperation__c first = (IACooperation__c) records[0];
                row.details = !labels.isEmpty()
                    ? groupLabels(labels)
                    : (first.StartDate__c != null ? 'Startet ' + formatDate(first.StartDate__c, true) : null);
            }
            when 'mulighet' {
                for (SObject rec : records) {
                    labels.add(
                        picklistLabel(CustomOpportunity__c.InquiryCategory__c, (String) rec.get('InquiryCategory__c'))
                    );
                }
                row.details = groupLabels(labels);
            }
            when 'henvendelse' {
                for (SObject rec : records) {
                    labels.add(picklistLabel(EmployerInquiry__c.TAG_Status__c, (String) rec.get('TAG_Status__c')));
                }
                row.details = groupLabels(labels);
                row.latestDate = ((Datetime) records[0].get('CreatedDate')).date();
            }
        }
    }

    /* PLANNED ACTIVITIES */

    private class PlannedItem implements Comparable {
        public Id recordId;
        public String objectApiName;
        public String typeLabel;
        public String subject;
        public Datetime startsAt;
        public Date startsOn;
        public String ownerName;

        public Integer compareTo(Object other) {
            Datetime mine = sortValue();
            Datetime theirs = ((PlannedItem) other).sortValue();
            return mine == theirs ? 0 : (mine < theirs ? -1 : 1);
        }

        private Datetime sortValue() {
            return startsAt != null ? startsAt : Datetime.newInstance(startsOn, Time.newInstance(23, 59, 0, 0));
        }

        public Date getDate() {
            return startsAt != null ? startsAt.date() : startsOn;
        }
    }

    private class PlannedResult {
        public List<PlannedItem> items = new List<PlannedItem>();
        public Boolean isAccessible = false;
    }

    private static PlannedResult queryPlanned(Context ctx) {
        PlannedResult result = new PlannedResult();
        Id accountId = ctx.accountId;
        Datetime now = Datetime.now();
        try {
            for (Task t : [
                SELECT Id, Subject, ActivityDate, Owner.Name
                FROM Task
                WHERE RelatedToAccount__c = :accountId AND IsClosed = FALSE AND ActivityDate >= TODAY
                WITH USER_MODE
                ORDER BY ActivityDate ASC
                LIMIT :TABLE_QUERY_LIMIT
            ]) {
                PlannedItem item = new PlannedItem();
                item.recordId = t.Id;
                item.objectApiName = 'Task';
                item.typeLabel = 'Oppgave';
                item.subject = t.Subject;
                item.startsOn = t.ActivityDate;
                item.ownerName = t.Owner?.Name;
                result.items.add(item);
            }
            result.isAccessible = true;
        } catch (Exception e) {
            logDebug('Task', e);
        }
        try {
            for (Event ev : [
                SELECT Id, Subject, StartDateTime, ActivityDate, IsAllDayEvent, Owner.Name
                FROM Event
                WHERE RelatedToAccount__c = :accountId AND StartDateTime >= :now
                WITH USER_MODE
                ORDER BY StartDateTime ASC
                LIMIT :TABLE_QUERY_LIMIT
            ]) {
                PlannedItem item = new PlannedItem();
                item.recordId = ev.Id;
                item.objectApiName = 'Event';
                item.typeLabel = 'Møte';
                item.subject = ev.Subject;
                item.startsAt = ev.StartDateTime;
                item.ownerName = ev.Owner?.Name;
                result.items.add(item);
            }
            result.isAccessible = true;
        } catch (Exception e) {
            logDebug('Event', e);
        }
        result.items.sort();
        return result;
    }

    private static OngoingRow buildPlannedRow(PlannedResult planned) {
        OngoingRow row = new OngoingRow(
            AccountSummaryConfig.PLANLAGT,
            AccountSummaryConfig.getConfig(AccountSummaryConfig.PLANLAGT)
        );
        row.isAccessible = planned.isAccessible;
        row.count = planned.items.size();
        if (!planned.items.isEmpty()) {
            PlannedItem next = planned.items[0];
            row.details =
                (planned.items.size() > 1 ? 'Neste: ' : '') +
                next.typeLabel +
                ' ' +
                formatDate(next.getDate(), false);
            if (String.isNotBlank(next.subject) && next.subject != next.typeLabel) {
                row.details += ' · ' + next.subject;
            }
            if (planned.items.size() > 1) {
                Integer meetings = 0;
                Integer tasks = 0;
                for (PlannedItem item : planned.items) {
                    if (item.objectApiName == 'Event') {
                        meetings++;
                    } else {
                        tasks++;
                    }
                }
                List<String> totals = new List<String>();
                if (meetings > 0) {
                    totals.add(meetings + ' ' + plural(meetings, 'møte', 'møter'));
                }
                if (tasks > 0) {
                    totals.add(tasks + ' ' + plural(tasks, 'oppgave', 'oppgaver'));
                }
                row.secondaryDetails = String.join(totals, ' · ') + ' totalt';
            }
            row.latestDate = next.getDate();
            row.latestTypeLabel = next.typeLabel;
        }
        return row;
    }

    /* NAV CONTACTS */

    private static List<AccountTeamMember> queryTeamMembers(Id accountId) {
        return [
            SELECT Id, UserId, User.Name, User.CompanyName, User.MobilePhone, TeamMemberRole
            FROM AccountTeamMember
            WHERE AccountId = :accountId
            WITH USER_MODE
            ORDER BY CreatedDate ASC
            LIMIT :TABLE_QUERY_LIMIT
        ];
    }

    private static NavContact buildNavContact(Context ctx) {
        try {
            List<AccountTeamMember> members = queryTeamMembers(ctx.accountId);
            if (members.isEmpty()) {
                return null;
            }
            NavContact contact = new NavContact();
            contact.name = members[0].User?.Name;
            contact.unit = members[0].User?.CompanyName;
            contact.initials = initials(contact.name);
            contact.count = members.size();
            contact.additionalCount = members.size() - 1;
            contact.helpText = AccountSummaryConfig.getConfig(AccountSummaryConfig.NAVKONTAKT).get('helpText');
            return contact;
        } catch (Exception e) {
            logDebug('AccountTeamMember', e);
            return null;
        }
    }

    /* RECORD LISTS (POPOVER) */

    public static List<BadgeService.RecordWrapper> getRecords(Id recordId, String key) {
        Context ctx = resolveContext(recordId);
        if (ctx == null) {
            return new List<BadgeService.RecordWrapper>();
        }
        if (key == AccountSummaryConfig.PLANLAGT) {
            return wrapPlanned(queryPlanned(ctx).items);
        }
        if (key == AccountSummaryConfig.NAVKONTAKT) {
            return wrapTeamMembers(queryTeamMembers(ctx.accountId));
        }
        Map<String, String> config = AccountSummaryConfig.getConfig(key);
        String query =
            buildOngoingQuery(config, ctx, 'Id, ' + config.get('columns')) +
            ' ORDER BY ' +
            config.get('orderBy') +
            ' LIMIT ' +
            TABLE_QUERY_LIMIT;
        List<SObject> records = Database.queryWithBinds(query, buildBinds(config, ctx), AccessLevel.USER_MODE);
        return BadgeService.convertToWrappedRecords(records, config);
    }

    private static List<BadgeService.RecordWrapper> wrapPlanned(List<PlannedItem> items) {
        String icon = AccountSummaryConfig.getConfig(AccountSummaryConfig.PLANLAGT).get('icon');
        List<BadgeService.RecordWrapper> wrappers = new List<BadgeService.RecordWrapper>();
        for (PlannedItem item : items) {
            String name = String.isNotBlank(item.subject) ? item.subject : item.typeLabel;
            BadgeService.RecordWrapper wrapper = createWrapper(item.recordId, item.objectApiName, name, icon);
            wrapper.fields.add(createField('Emne', 'text', name));
            wrapper.fields.add(createField('Type', 'text', item.typeLabel));
            wrapper.fields.add(
                createField('Dato', 'date', item.startsAt != null ? (Object) item.startsAt : (Object) item.startsOn)
            );
            wrapper.fields.add(createField('Eier', 'text', item.ownerName));
            wrappers.add(wrapper);
        }
        return wrappers;
    }

    private static List<BadgeService.RecordWrapper> wrapTeamMembers(List<AccountTeamMember> members) {
        String icon = AccountSummaryConfig.getConfig(AccountSummaryConfig.NAVKONTAKT).get('icon');
        List<BadgeService.RecordWrapper> wrappers = new List<BadgeService.RecordWrapper>();
        for (AccountTeamMember member : members) {
            BadgeService.RecordWrapper wrapper = createWrapper(member.UserId, 'User', member.User?.Name, icon);
            wrapper.fields.add(createField('Navn', 'text', member.User?.Name));
            wrapper.fields.add(
                createField('Rolle', 'text', picklistLabel(AccountTeamMember.TeamMemberRole, member.TeamMemberRole))
            );
            wrapper.fields.add(createField('Nav-kontor', 'text', member.User?.CompanyName));
            wrapper.fields.add(createField('Telefon', 'phone', member.User?.MobilePhone));
            wrappers.add(wrapper);
        }
        return wrappers;
    }

    private static BadgeService.RecordWrapper createWrapper(
        Id recordId,
        String objectApiName,
        String name,
        String icon
    ) {
        BadgeService.RecordWrapper wrapper = new BadgeService.RecordWrapper();
        wrapper.id = recordId;
        wrapper.name = name;
        wrapper.icon = icon;
        wrapper.link = '/lightning/r/' + objectApiName + '/' + recordId + '/view';
        wrapper.fields = new List<BadgeService.Field>();
        return wrapper;
    }

    private static BadgeService.Field createField(String label, String type, Object value) {
        BadgeService.Field field = new BadgeService.Field();
        field.label = label;
        field.fieldName = label;
        field.type = type;
        field.value = value;
        return field;
    }

    /* HISTORY */

    @TestVisible
    private class HistoryCollector {
        public Date startDate;
        public Date endDate = Date.today();
        public Integer months;
        public Integer total = 0;
        public Integer placements = 0;
        public Date lastContactDate;
        public String lastContactType;
        private Map<String, Map<String, Integer>> countsByMonth = new Map<String, Map<String, Integer>>();
        private Map<String, Integer> totals = new Map<String, Integer>();

        public HistoryCollector(Integer months) {
            this.months = months;
            this.startDate = Date.today().toStartOfMonth().addMonths(-(months - 1));
        }

        public Datetime startDateTime() {
            return Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        }

        public Boolean add(String key, Date activityDate) {
            if (activityDate == null || activityDate < startDate || activityDate > endDate) {
                return false;
            }
            String monthKey = monthKey(activityDate);
            if (!countsByMonth.containsKey(monthKey)) {
                countsByMonth.put(monthKey, new Map<String, Integer>());
            }
            Map<String, Integer> monthCounts = countsByMonth.get(monthKey);
            monthCounts.put(key, (monthCounts.containsKey(key) ? monthCounts.get(key) : 0) + 1);
            totals.put(key, (totals.containsKey(key) ? totals.get(key) : 0) + 1);
            total++;
            return true;
        }

        public void registerContact(Date contactDate, String typeLabel) {
            if (contactDate == null || contactDate > endDate) {
                return;
            }
            if (lastContactDate == null || contactDate > lastContactDate) {
                lastContactDate = contactDate;
                lastContactType = typeLabel;
            }
        }

        public List<HistoryMonth> getMonths() {
            List<HistoryMonth> result = new List<HistoryMonth>();
            for (Integer i = 0; i < months; i++) {
                Date monthStart = startDate.addMonths(i);
                HistoryMonth month = new HistoryMonth();
                month.key = monthKey(monthStart);
                month.label = MONTH_ABBREVIATIONS[monthStart.month() - 1];
                month.fullLabel = MONTH_NAMES[monthStart.month() - 1] + ' ' + monthStart.year();
                month.segments = new List<HistorySegment>();
                month.total = 0;
                Map<String, Integer> monthCounts = countsByMonth.get(month.key);
                if (monthCounts != null) {
                    for (String key : AccountSummaryConfig.HISTORY_KEYS) {
                        if (monthCounts.containsKey(key)) {
                            HistorySegment segment = new HistorySegment();
                            segment.key = key;
                            segment.label = AccountSummaryConfig.HISTORY_LABELS.get(key);
                            segment.count = monthCounts.get(key);
                            month.segments.add(segment);
                            month.total += segment.count;
                        }
                    }
                }
                result.add(month);
            }
            return result;
        }

        public List<HistoryTotal> getTotals() {
            List<HistoryTotal> result = new List<HistoryTotal>();
            for (String key : AccountSummaryConfig.HISTORY_KEYS) {
                if (totals.containsKey(key)) {
                    HistoryTotal item = new HistoryTotal();
                    item.key = key;
                    item.label = AccountSummaryConfig.HISTORY_LABELS.get(key);
                    item.count = totals.get(key);
                    result.add(item);
                }
            }
            return result;
        }

        public Integer getCount(String key) {
            return totals.containsKey(key) ? totals.get(key) : 0;
        }
    }

    @TestVisible
    private static HistoryCollector collectHistory(Context ctx, Integer months) {
        HistoryCollector collector = new HistoryCollector(months);
        Id accountId = ctx.accountId;
        Date startDate = collector.startDate;
        Datetime startDateTime = collector.startDateTime();
        Datetime now = Datetime.now();

        try {
            for (Contract__c contract : [
                SELECT TAG_EndDate__c
                FROM Contract__c
                WHERE
                    TAG_Account__c = :accountId
                    AND RecordType.DeveloperName = 'EmployerAgreement'
                    AND TAG_Category__c != 'IA-avtale'
                    AND TAG_EndDate__c >= :startDate
                    AND TAG_EndDate__c <= TODAY
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(AccountSummaryConfig.AVTALE, contract.TAG_EndDate__c);
            }
        } catch (Exception e) {
            logDebug('Contract__c history', e);
        }

        try {
            for (JobPosting__c posting : [
                SELECT Expires__c, LastUpdated__c
                FROM JobPosting__c
                WHERE
                    Account__c = :accountId
                    AND Source__c = 'DIR'
                    AND Status__c != 'ACTIVE'
                    AND (Expires__c >= :startDateTime
                    OR LastUpdated__c >= :startDateTime)
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                Datetime closed = posting.Expires__c != null &&
                    posting.Expires__c <= now
                    ? posting.Expires__c
                    : posting.LastUpdated__c;
                collector.add(AccountSummaryConfig.STILLING, closed?.date());
            }
        } catch (Exception e) {
            logDebug('JobPosting__c history', e);
        }

        try {
            for (Workfare__c workfare : [
                SELECT EndDate__c
                FROM Workfare__c
                WHERE
                    Account__c = :accountId
                    AND Status__c = 'AVSLUTTET'
                    AND EndDate__c >= :startDate
                    AND EndDate__c <= TODAY
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(AccountSummaryConfig.TILTAK, workfare.EndDate__c);
            }
        } catch (Exception e) {
            logDebug('Workfare__c history', e);
        }

        try {
            for (IACooperation__c cooperation : [
                SELECT EndDate__c, LastModifiedDate
                FROM IACooperation__c
                WHERE
                    Account__c = :accountId
                    AND Status__c IN ('FULLFØRT', 'AVBRUTT')
                    AND (EndDate__c >= :startDate
                    OR (EndDate__c = NULL
                    AND LastModifiedDate >= :startDateTime))
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(
                    AccountSummaryConfig.IA,
                    cooperation.EndDate__c != null ? cooperation.EndDate__c : cooperation.LastModifiedDate.date()
                );
            }
        } catch (Exception e) {
            logDebug('IACooperation__c history', e);
        }

        try {
            for (CustomOpportunity__c opportunity : [
                SELECT ClosingDate__c
                FROM CustomOpportunity__c
                WHERE Account__c = :accountId AND InclusionStage__c = 'Avsluttet' AND ClosingDate__c >= :startDateTime
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(AccountSummaryConfig.MULIGHET, opportunity.ClosingDate__c.date());
            }
        } catch (Exception e) {
            logDebug('CustomOpportunity__c history', e);
        }

        try {
            for (EmployerInquiry__c inquiry : [
                SELECT TAG_ResolvedDate__c
                FROM EmployerInquiry__c
                WHERE
                    TAG_Account__c = :accountId
                    AND TAG_Status__c = 'Fullført'
                    AND TAG_ResolvedDate__c >= :startDateTime
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(AccountSummaryConfig.HENVENDELSE, inquiry.TAG_ResolvedDate__c.date());
            }
        } catch (Exception e) {
            logDebug('EmployerInquiry__c history', e);
        }

        try {
            for (Event ev : [
                SELECT EndDateTime
                FROM Event
                WHERE RelatedToAccount__c = :accountId AND EndDateTime >= :startDateTime AND EndDateTime <= :now
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                if (collector.add(AccountSummaryConfig.MOTE, ev.EndDateTime.date())) {
                    collector.registerContact(ev.EndDateTime.date(), 'møte');
                }
            }
        } catch (Exception e) {
            logDebug('Event history', e);
        }

        try {
            for (DialogueMeeting__c meeting : [
                SELECT MeetingTime__c
                FROM DialogueMeeting__c
                WHERE
                    Account__c = :accountId
                    AND Status__c != 'AVLYST'
                    AND MeetingTime__c >= :startDateTime
                    AND MeetingTime__c <= :now
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                if (collector.add(AccountSummaryConfig.MOTE, meeting.MeetingTime__c.date())) {
                    collector.registerContact(meeting.MeetingTime__c.date(), 'dialogmøte');
                }
            }
        } catch (Exception e) {
            logDebug('DialogueMeeting__c history', e);
        }

        try {
            for (Task t : [
                SELECT Type, ActivityDate, CompletedDateTime, CreatedDate, IsClosed
                FROM Task
                WHERE
                    RelatedToAccount__c = :accountId
                    AND ((IsClosed = TRUE
                    AND CompletedDateTime >= :startDateTime)
                    OR (Type IN :AccountSummaryConfig.COMMUNICATION_TASK_TYPES
                    AND (ActivityDate >= :startDate
                    OR (ActivityDate = NULL
                    AND CreatedDate >= :startDateTime))))
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                if (t.Type != null && AccountSummaryConfig.COMMUNICATION_TASK_TYPES.contains(t.Type)) {
                    Date contactDate = t.ActivityDate != null ? t.ActivityDate : t.CreatedDate.date();
                    if (collector.add(AccountSummaryConfig.KOMMUNIKASJON, contactDate)) {
                        collector.registerContact(
                            contactDate,
                            AccountSummaryConfig.COMMUNICATION_TYPE_LABELS.get(t.Type)
                        );
                    }
                } else if (t.IsClosed && t.CompletedDateTime != null) {
                    collector.add(AccountSummaryConfig.MOTE, t.CompletedDateTime.date());
                }
            }
        } catch (Exception e) {
            logDebug('Task history', e);
        }

        try {
            for (CandidateOutcome__c outcome : [
                SELECT Result__c, TimeRegistered__c, CreatedDate
                FROM CandidateOutcome__c
                WHERE
                    (Account__c = :accountId
                    OR Account2__c = :accountId)
                    AND (TimeRegistered__c >= :startDateTime
                    OR (TimeRegistered__c = NULL
                    AND CreatedDate >= :startDateTime))
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                Datetime registered = outcome.TimeRegistered__c != null
                    ? outcome.TimeRegistered__c
                    : outcome.CreatedDate;
                if (
                    collector.add(AccountSummaryConfig.FORMIDLING, registered.date()) &&
                    outcome.Result__c == 'FATT_JOBBEN'
                ) {
                    collector.placements++;
                }
            }
        } catch (Exception e) {
            logDebug('CandidateOutcome__c history', e);
        }

        try {
            for (CustomCampaignMember__c member : [
                SELECT LastModifiedDate
                FROM CustomCampaignMember__c
                WHERE
                    Account__c = :accountId
                    AND Status__c IN :AccountSummaryConfig.CAMPAIGN_MEMBER_ACTIVITY_STATUSES
                    AND LastModifiedDate >= :startDateTime
                WITH USER_MODE
                LIMIT :ROW_QUERY_LIMIT
            ]) {
                collector.add(AccountSummaryConfig.FORMIDLING, member.LastModifiedDate.date());
            }
        } catch (Exception e) {
            logDebug('CustomCampaignMember__c history', e);
        }

        return collector;
    }

    /* WRITTEN SUMMARY */

    private static List<TextPart> buildSummaryText(
        Context ctx,
        Map<String, OngoingRow> rows,
        PlannedResult planned,
        HistoryCollector history,
        Integer months
    ) {
        List<TextPart> parts = new List<TextPart>();
        List<String> items = new List<String>();
        addCountItem(items, rows.get(AccountSummaryConfig.MULIGHET), 'åpen mulighet', 'åpne muligheter');
        addCountItem(
            items,
            rows.get(AccountSummaryConfig.HENVENDELSE),
            ctx.isInquiry ? 'annen åpen henvendelse' : 'åpen henvendelse',
            ctx.isInquiry ? 'andre åpne henvendelser' : 'åpne henvendelser'
        );
        addCountItem(
            items,
            rows.get(AccountSummaryConfig.STILLING),
            'aktiv direktemeldt stilling',
            'aktive direktemeldte stillinger'
        );
        addCountItem(items, rows.get(AccountSummaryConfig.TILTAK), 'aktivt tiltak', 'aktive tiltak');
        addCountItem(items, rows.get(AccountSummaryConfig.IA), 'pågående IA-samarbeid', 'pågående IA-samarbeid');
        addCountItem(items, rows.get(AccountSummaryConfig.AVTALE), 'aktiv avtale', 'aktive avtaler');
        OngoingRow plannedRow = rows.get(AccountSummaryConfig.PLANLAGT);
        if (plannedRow.count == 1) {
            items.add(
                '1 planlagt ' +
                    plannedRow.latestTypeLabel.toLowerCase() +
                    ' ' +
                    formatDate(plannedRow.latestDate, false)
            );
        } else if (plannedRow.count > 1) {
            items.add(
                plannedRow.count + ' planlagte møter/oppgaver (neste ' + formatDate(plannedRow.latestDate, false) + ')'
            );
        }

        Boolean useName = ctx.isInquiry && String.isNotBlank(ctx.accountName);
        parts.add(new TextPart(useName ? ctx.accountName : 'Bedriften', useName));
        if (items.isEmpty()) {
            parts.add(new TextPart(' har ingen pågående aktivitet registrert.', false));
        } else {
            parts.add(new TextPart(' har ', false));
            for (Integer i = 0; i < items.size(); i++) {
                if (i > 0) {
                    parts.add(new TextPart(i == items.size() - 1 ? ' og ' : ', ', false));
                }
                parts.add(new TextPart(items[i], true));
            }
            parts.add(new TextPart('.', false));
        }

        if (history.total > 0) {
            parts.add(
                new TextPart(
                    ' Siste ' +
                        months +
                        ' mnd er det registrert ' +
                        history.total +
                        ' ' +
                        plural(history.total, 'aktivitet', 'aktiviteter'),
                    false
                )
            );
            if (history.placements > 0) {
                parts.add(new TextPart(', blant annet ', false));
                parts.add(
                    new TextPart(
                        history.placements + ' ' + plural(history.placements, 'formidling', 'formidlinger'),
                        true
                    )
                );
            }
            parts.add(new TextPart('.', false));
        } else {
            parts.add(new TextPart(' Det er ikke registrert aktivitet siste ' + months + ' mnd.', false));
        }

        if (history.lastContactDate != null) {
            parts.add(
                new TextPart(
                    ' Siste kontakt var ' +
                        history.lastContactType +
                        ' ' +
                        formatDate(history.lastContactDate, false) +
                        '.',
                    false
                )
            );
        }

        OngoingRow inquiryRow = rows.get(AccountSummaryConfig.HENVENDELSE);
        if (ctx.isInquiry && inquiryRow.isAccessible && inquiryRow.count > 0) {
            parts.add(new TextPart(' Merk:', true));
            String warning = inquiryRow.count == 1
                ? ' det finnes 1 annen åpen henvendelse fra samme arbeidsgiver'
                : ' det finnes ' + inquiryRow.count + ' andre åpne henvendelser fra samme arbeidsgiver';
            if (inquiryRow.latestDate != null) {
                warning += ' (siste fra ' + formatDate(inquiryRow.latestDate, false) + ')';
            }
            parts.add(new TextPart(warning + '.', false));
        }
        return parts;
    }

    private static void addCountItem(List<String> items, OngoingRow row, String singular, String pluralForm) {
        if (row != null && row.isAccessible && row.count > 0) {
            items.add(row.count + ' ' + plural(row.count, singular, pluralForm));
        }
    }

    /* HELPERS */

    private static String plural(Integer count, String singular, String pluralForm) {
        return count == 1 ? singular : pluralForm;
    }

    @TestVisible
    private static String groupLabels(List<String> labels) {
        Map<String, Integer> counts = new Map<String, Integer>();
        List<String> order = new List<String>();
        for (String label : labels) {
            String key = String.isBlank(label) ? 'Ukjent' : label;
            if (!counts.containsKey(key)) {
                counts.put(key, 0);
                order.add(key);
            }
            counts.put(key, counts.get(key) + 1);
        }
        if (order.size() == 1 && counts.get(order[0]) == 1) {
            return order[0];
        }
        List<String> formatted = new List<String>();
        for (Integer i = 0; i < order.size() && i < MAX_DETAIL_GROUPS; i++) {
            formatted.add(order[i] + ' ×' + counts.get(order[i]));
        }
        if (order.size() > MAX_DETAIL_GROUPS) {
            formatted.add('…');
        }
        return String.join(formatted, ' · ');
    }

    @TestVisible
    private static String formatDate(Date value, Boolean includeYear) {
        if (value == null) {
            return '';
        }
        String result =
            String.valueOf(value.day()).leftPad(2, '0') +
            '.' +
            String.valueOf(value.month()).leftPad(2, '0');
        return includeYear ? result + '.' + value.year() : result;
    }

    private static String monthKey(Date value) {
        return value.year() + '-' + String.valueOf(value.month()).leftPad(2, '0');
    }

    @TestVisible
    private static String initials(String name) {
        if (String.isBlank(name)) {
            return '';
        }
        List<String> words = name.trim().split('\\s+');
        String result = words[0].left(1);
        if (words.size() > 1) {
            result += words[words.size() - 1].left(1);
        }
        return result.toUpperCase();
    }

    private static String picklistLabel(Schema.SObjectField field, String value) {
        if (String.isBlank(value)) {
            return value;
        }
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.getValue() == value) {
                return entry.getLabel();
            }
        }
        return value;
    }

    private static void logDebug(String source, Exception e) {
        System.debug(LoggingLevel.WARN, 'AccountSummary: could not read ' + source + ': ' + e.getMessage());
    }

    /* WRAPPERS */

    public class Summary {
        @AuraEnabled
        public Boolean hasAccount = false;
        @AuraEnabled
        public Id accountId;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public Boolean isInquiryContext = false;
        @AuraEnabled
        public Boolean hasOngoingActivity = false;
        @AuraEnabled
        public String coordinationNotice;
        @AuraEnabled
        public List<TextPart> summaryParts = new List<TextPart>();
        @AuraEnabled
        public List<OngoingRow> ongoing = new List<OngoingRow>();
        @AuraEnabled
        public NavContact navContact;
        @AuraEnabled
        public Integer months;
        @AuraEnabled
        public Integer historyTotal = 0;
        @AuraEnabled
        public List<HistoryMonth> history = new List<HistoryMonth>();
        @AuraEnabled
        public List<HistoryTotal> historyTotals = new List<HistoryTotal>();
    }

    public class OngoingRow {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String helpText;
        @AuraEnabled
        public Integer count = 0;
        @AuraEnabled
        public String details;
        @AuraEnabled
        public String pill;
        @AuraEnabled
        public String secondaryDetails;
        @AuraEnabled
        public Boolean isAccessible = true;
        public Date latestDate;
        public String latestTypeLabel;

        public OngoingRow(String key, Map<String, String> config) {
            this.key = key;
            this.label = config.get('label');
            this.icon = config.get('icon');
            this.helpText = config.get('helpText');
        }
    }

    public class NavContact {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String unit;
        @AuraEnabled
        public String initials;
        @AuraEnabled
        public String helpText;
        @AuraEnabled
        public Integer count;
        @AuraEnabled
        public Integer additionalCount;
    }

    public class HistoryMonth {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fullLabel;
        @AuraEnabled
        public Integer total;
        @AuraEnabled
        public List<HistorySegment> segments;
    }

    public class HistorySegment {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Integer count;
    }

    public class HistoryTotal {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Integer count;
    }

    public class TextPart {
        @AuraEnabled
        public String text;
        @AuraEnabled
        public Boolean bold;

        public TextPart(String text, Boolean bold) {
            this.text = text;
            this.bold = bold;
        }
    }
}
