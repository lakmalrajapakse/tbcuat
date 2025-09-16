export default class Utils {

    static convertShifts(records = [], siteTimezones, shiftSignatures = {}, CustomExternalIDForShiftRecords, DefaultTimeZone) {
        console.log('opened function');
        let results = [];
        console.log('convert Shifts now');
        console.log('custom field for matching: ' + CustomExternalIDForShiftRecords);

        console.log('Default Time Zone =' + DefaultTimeZone);
        if (DefaultTimeZone === null || DefaultTimeZone == '') DefaultTimeZone = 'Europe/London';
        console.log('Default Time Zone After Check=' + DefaultTimeZone);

        for (let record of records) {
            console.log('converting a record now');
            // results.push(new Shift(record));
            let hasScheduledStart = record?.sirenum__Scheduled_Start_Time__c !== undefined;
            let hasScheduledEnd = record?.sirenum__Scheduled_End_Time__c !== undefined;
            let hasApprovedStart = record?.sirenum__Billable_Start_Time__c !== undefined;
            let hasApprovedEnd = record?.sirenum__Billable_End_Time__c !== undefined;
            let hasActualStart = record?.sirenum__Actual_Start_Time__c !== undefined;
            let hasActualEnd = record?.sirenum__Actual_End_Time__c !== undefined;
            let ExternalIDValue = '';
            let ExternalIDForShiftRecords = CustomExternalIDForShiftRecords;
            console.log('ExternalIDForShiftRecords=' + ExternalIDForShiftRecords);
            console.log('ExternalIDForShiftRecords=' + ExternalIDForShiftRecords + '=' + ExternalIDValue);
            if (record.hasOwnProperty(ExternalIDForShiftRecords)) {
                ExternalIDValue = record[ExternalIDForShiftRecords];
            }
            console.log('ExternalIDForShiftRecords=' + ExternalIDForShiftRecords);
            console.log('ExternalIDForShiftRecords=' + ExternalIDForShiftRecords + '=' + ExternalIDValue);

            let shift = {
                Id: record.Id,
                shift: record,
                // schedTimezone: moment(record?.sirenum__Scheduled_Start_Time__c).tz('Australia/Perth').format(),
                shiftDate: Utils.formatDate(record.sirenum__Shift_Date__c),
                schedStart: record?.sirenum__Scheduled_Start_Time__c !== undefined ? new Date(record?.sirenum__Scheduled_Start_Time__c) : undefined,
                schedEnd: record?.sirenum__Scheduled_End_Time__c !== undefined ? new Date(record?.sirenum__Scheduled_End_Time__c) : undefined,
                appStart: record?.sirenum__Billable_Start_Time__c !== undefined ? new Date(record?.sirenum__Billable_Start_Time__c) : undefined,
                appEnd: record?.sirenum__Billable_End_Time__c !== undefined ? new Date(record?.sirenum__Billable_End_Time__c) : undefined,
                actStart: record?.sirenum__Actual_Start_Time__c !== undefined ? new Date(record?.sirenum__Actual_Start_Time__c) : undefined,
                actEnd: record?.sirenum__Actual_End_Time__c !== undefined ? new Date(record?.sirenum__Actual_End_Time__c) : undefined,
                scheduledStartTime: Utils.formatDate(record?.sirenum__Scheduled_Start_Time__c),
                scheduledEndTime: Utils.formatDate(record?.sirenum__Scheduled_End_Time__c),
                scheduledStartDate: hasScheduledStart ? Utils.convertDateFormat(new Date(record?.sirenum__Scheduled_Start_Time__c)) : '',
                scheduledEndDate: hasScheduledEnd ? Utils.convertDateFormat(new Date(record?.sirenum__Scheduled_End_Time__c)) : '',
                scheduledStartTime: hasScheduledStart ? Utils.convertTimeFormat(new Date(record?.sirenum__Scheduled_Start_Time__c)) : '',
                scheduledEndTime: hasScheduledEnd ? Utils.convertTimeFormat(new Date(record?.sirenum__Scheduled_End_Time__c)) : '',
                approvedStartDate: hasApprovedStart ? Utils.convertDateFormat(new Date(record?.sirenum__Billable_Start_Time__c)) : '',
                approvedEndDate: hasApprovedEnd ? Utils.convertDateFormat(new Date(record?.sirenum__Billable_End_Time__c)) : '',
                approvedStartTime: hasApprovedStart ? Utils.convertTimeFormat(new Date(record?.sirenum__Billable_Start_Time__c)) : '',
                approvedEndTime: hasApprovedEnd ? Utils.convertTimeFormat(new Date(record?.sirenum__Billable_End_Time__c)) : '',
                actualStartTime: Utils.formatDate(record?.sirenum__Actual_Start_Time__c),
                actualEndTime: Utils.formatDate(record?.sirenum__Actual_End_Time__c),
                // billStartDate: record?.sirenum__Billable_Local_Start_Date__c !== undefined ? new Date(record?.sirenum__Billable_Local_Start_Date__c) : undefined,
                // billStartTime: record?.sirenum__Billable_Local_Start_Time__c !== undefined ? new Date(record?.sirenum__Billable_Local_Start_Time__c) : 'undefined',
                // billEndDate: record?.sirenum__Billable_Local_End_Date__c !== undefined ? new Date(record?.sirenum__Billable_Local_End_Date__c) : undefined,
                // billEndTime: record?.sirenum__Billable_Local_End_Time__c !== undefined ? new Date(record?.sirenum__Billable_Local_End_Time__c) : 'undefined',
                approvedStart: hasApprovedStart ? record?.sirenum__Billable_Start_Time__c : (record?.sirenum__Scheduled_Start_Time__c),
                approvedEnd: hasApprovedEnd ? record?.sirenum__Billable_End_Time__c : (record?.sirenum__Scheduled_End_Time__c),
                wfmId: record?.WFM_External_Reference_ID__c ?? '',
                timezone: siteTimezones[record?.sirenum__Site__c] ?? DefaultTimeZone,
                poNumber: record?.PO_Number__c ?? '',
                feedback: record?.SK_Feedback__c ?? '-',
                noFeedback: record?.SK_Feedback__c === undefined || record?.SK_Feedback__c === null || record?.SK_Feedback__c === '',
                poorFeedback: record?.SK_Feedback__c === 'Poor',
                lowFeedback: record?.SK_Feedback__c === 'OK',
                goodFeedback: record?.SK_Feedback__c === 'Good' || record?.SK_Feedback__c === 'Great',
                // client rating field matches the sirenum ranking obj for the shift
                // client rating field is used for filtering 
                //NOTE uses client rating field
                // hasRatings: record?.Client_Rating__c !== undefined || record?.Client_Rating__c !== null || record?.Client_Rating__c !== '',
                // clientRating: record?.Client_Rating__c !== undefined || record?.Client_Rating__c !== null || record?.Client_Rating__c !== '' || record?.Client_Rating__c !== 'None' ? record?.Client_Rating__c : '-',
                // isLowRank: record?.Client_Rating__c === 'Unsuitable' || record?.Client_Rating__c === 'Bad',
                // hasGoodRating: record?.Client_Rating__c === 'Excellent' || record?.Client_Rating__c === 'Good',
                // hasAvgRating: record?.Client_Rating__c === 'Average',
                // hasPoorRating: record?.Client_Rating__c === 'Unsuitable' || record?.Client_Rating__c === 'Bad',
                // hasNoClientRating: record?.Client_Rating__c === undefined || record?.Client_Rating__c === null || record?.Client_Rating__c === '' || record?.Client_Rating__c !== 'None',
                //hasSignature: shiftSignatures[record?.Id] != undefined ,
                // hasSignature: shiftSignatures && shiftSignatures[record?.Id] !== undefined,
                // signatureLink: shiftSignatures && shiftSignatures[record?.Id] !== undefined ? `/servlet/servlet.FileDownload?file=${shiftSignatures[record?.Id]?.Id}` : '',
                // signatureLinkId: shiftSignatures && shiftSignatures[record?.Id] !== undefined ? shiftSignatures[record?.Id]?.Id : '',
                signatureLink: record?.Attachments?.records?.[0] !== undefined ? '/servlet/servlet.FileDownload?file=' + record?.Attachments?.records?.[0]?.Id : '',
                signatureLinkId: record?.Attachments?.records?.[0]?.Id !== undefined ? record?.Attachments?.records?.[0]?.Id : '',
                hasSignature: record?.Attachments?.records?.length > 0,
                // NOTE uses ranking obj
                hasRatings: record?.Ratings__r?.records?.length > 0,
                clientRating: record?.Ratings__r?.records[0].sirenum__Rank__c ?? '-',
                ratingPlaceholder: '-',
                isLowRank: record?.Ratings__r?.records[0].sirenum__Rank__c === 'Unsuitable' || record?.Ratings__r?.records[0].sirenum__Rank__c === 'Bad',
                hasGoodRating: record?.Ratings__r?.records[0].sirenum__Rank__c === 'Excellent' || record?.Ratings__r?.records[0].sirenum__Rank__c === 'Good',
                hasAvgRating: record?.Ratings__r?.records[0].sirenum__Rank__c === 'Average',
                hasPoorRating: record?.Ratings__r?.records[0].sirenum__Rank__c === 'Unsuitable' || record?.Ratings__r?.records[0].sirenum__Rank__c === 'Bad',
                hasNoClientRating: record?.Ratings__r?.records.length === 0,

                ratings: record?.Ratings__r?.records,
                rating: record?.Ratings__r?.records[0],
                rank: record?.Ratings__r?.records[0].sirenum__Rank__c ?? '-',
                // isLowRank: record?.Ratings__r?.records[0].sirenum__Rank__c === 'Unsuitable' || record?.Ratings__r?.records[0].sirenum__Rank__c === 'Bad',
                // hasGoodRating: record?.Ratings__r?.records?.length && (record?.Ratings__r?.records[0].sirenum__Rank__c !== 'Unsuitable' || record?.Ratings__r?.records[0].sirenum__Rank__c !== 'Bad'),
                // hasPoorRating: record?.Ratings__r?.records?.length && (record?.Ratings__r?.records[0].sirenum__Rank__c === 'Unsuitable' || record?.Ratings__r?.records[0].sirenum__Rank__c === 'Bad')

                hasPayOrCharge: record?.Pay__c != 0 || record?.Charge__c != 0,
                isAdhoc: !record?.sirenum__Scheduled_End_Time__c,
                hasBreaks: record?.sirenum__Shift_Breaks__r?.records?.length > 0,
                breaks: record?.sirenum__Shift_Breaks__r?.records,
                hasExpenses: record?.ShiftExpenses__r?.records?.length > 0,
                // expenses: record?.ShiftExpenses__r?.records,
                expenses: Utils.convertExpenses(record?.ShiftExpenses__r?.records),
                timesheetSummary: Utils.convertTimesheetSummary(record?.sirenum__Timesheet_summaries__r),
                timesheets: Utils.convertTimesheets(record?.sirenum__Timesheet_Lines__r?.records),
                hasTimesheet: !!record?.sirenum__Timesheet_summaries__r,
                isAdhoc: record?.sirenum__AdHoc__c == 'Ad-Hoc',
                // TODO add hasSignature
                // NOTE not sure if we need check for portalHoursEntry
                // portalHoursEntry : record.Time_Type__c == 'Hours'
                portalHoursEntry: record?.Time_Type__c == 'Hours' || record?.Time_Type__c === undefined ? true : false,
                lengthMinusBreaks: record?.sirenum__Absolute_Shift_Length__c ? record?.sirenum__Absolute_Shift_Length__c :
                    Utils.calculateShiftLength(record?.sirenum__Absolute_End_Time__c, record?.sirenum__Absolute_Start_Time__c),
                site: record?.sirenum__Site__c,
                siteName: record?.Site_Value_for_Import_Export__c,
                account: record?.sirenum__Site__r?.sirenum__Operating_Company__c,
                accountName: record?.sirenum__Site__r?.sirenum__Operating_Company__r?.Name,
                hasQuery: record?.Queried__c,
                query: record?.Query__c ?? '',
                shiftName: record?.Name ?? '',
                shiftRota: record?.Rota_Value_for_Import_Export__c ?? '',
                jobRole: record?.Job_Role_Value_for_Import_Export__c ?? '',
                comments: record?.sirenum__Scheduling_Comments__c ?? '',
                //
                externalIDOrIDOfShift: ExternalIDValue,
                workerName: record?.sirenum__Contact__r?.Name ?? '',
                isApproved: record?.sirenum__Allow_pay__c && record?.sirenum__Allow_charge__c,
                //isApproved: record?.Approved__c ?? '',
                isConsultantApproved: record?.Is_Approved__c,
                isCancelled: record?.sirenum__Cancelled__c,
                shiftLocation: record?.Location_Value_for_Import_Export__c ?? '',
                cancellationReason: record?.sirenum__CancellationReason__c ?? '',
                date: record?.sirenum__Shift_Date__c ?? '',
                date_Reversed: record?.sirenum__Shift_Date__c !== undefined ? Utils.convertDateFormat_Reverse(new Date(record?.sirenum__Shift_Date__c)) : '',
                contract: record?.sirenum__Team__r?.sirenum__Account__c,
                // contractName: record?.sirenum__Team__r?.sirenum__Account__r?.Name,
            };

            let totalBreakHours = 0;
            let totalBreakMins = 0;

            if (shift.hasBreaks) {
                for (let sbreak of shift.breaks) {
                    //  let [breakLengthDeci, breakLengthHourMin] = this.calculateLength(sbreak.sirenum__Start_Time__c, sbreak.sirenum__End_Time__c);
                    let { hoursDecimal, hours, minutes, formattedString } = this.calculateLength(sbreak.sirenum__Start_Time__c, sbreak.sirenum__End_Time__c, sbreak);
                    sbreak.BreakHourMinuteLength = formattedString;
                    sbreak.PaidUnPaid = ((sbreak.sirenum__Paid_Break__c) ? '(Paid)' : '');
                    sbreak.BreakDecimalLength = hoursDecimal;
                    sbreak.Hours = hours;
                    sbreak.Minutes = minutes;

                    if (!sbreak.sirenum__Paid_Break__c) {
                        totalBreakHours += Number(hours);
                        totalBreakMins += Number(minutes);
                    }
                }

                // add total hours and min of break to shift obj
                shift.TotalBreakHours = totalBreakHours;
                shift.TotalBreakMinutes = totalBreakMins;
            }

            if (shift.portalHoursEntry) {
                let defaultStart = record?.sirenum__Scheduled_Start_Time__c !== undefined ? record?.sirenum__Scheduled_Start_Time__c : record?.sirenum__Absolute_Start_Time__c;
                let defaultEnd = record?.sirenum__Scheduled_End_Time__c !== undefined ? record?.sirenum__Scheduled_End_Time__c : record?.sirenum__Absolute_End_Time__c;
                let startTime = record?.sirenum__Billable_Start_Time__c;
                let endTime = record?.sirenum__Billable_End_Time__c;

                if (startTime == null || endTime == null) {
                    startTime = defaultStart;
                    endTime = defaultEnd;
                }
                const durrationData = this.calculateLength(startTime, endTime, shift);
                shift.shiftTotalColumn = durrationData.formattedString;
                shift.decimalLength = durrationData.hoursDecimal;
                shift.Hours = durrationData.hours;
                shift.Minutes = durrationData.minutes;
                shift.totalApprovedTime = durrationData.formattedString;
            } else {
                shift.shiftTotalColumn = '-';
            }

            switch (record?.sirenum__Contract__r?.Approval_Hours_Entry_Type__c) {
                case 'Start + End Time':
                    shift.crStartEndEntry = true;
                    break;
                case 'Hours':
                    shift.crHoursOnlyEntry = true;
                    break;
                case 'Daily':
                    shift.crDailyEntry = true;
                    break;
                default:
                    //Default to Start/End Entry  
                    shift.crStartEndEntry = true;
            }

            switch (record?.sirenum__Contract__r?.Actual_Hours_Entry_Type__c) {
                case 'Start + End Time':
                    shift.ahStartEndEntry = true;
                    break;
                case 'Hours':
                    shift.ahHoursOnlyEntry = true;
                    break;
                case 'Daily':
                    shift.ahDailyEntry = true;
                    break;
                default:
                    //Default to Start/End Entry  
                    shift.ahStartEndEntry = true;
            }

            switch (record?.sirenum__Contract__r?.Billable_Hours_Entry_Type__c) {
                case 'Start + End Time':
                    shift.pbStartEndEntry = true;
                    break;
                case 'Hours':
                    shift.pbHoursOnlyEntry = true;
                    break;
                case 'Daily':
                    shift.pbDailyEntry = true;
                    break;
                default:
                    //Default to Start/End Entry  
                    shift.pbStartEndEntry = true;
            }
            console.log('adding shift to sorted results ' + shift.Id);
            results.push(shift);
        }
        console.log('Sorted Results size', results.length);
        console.log('Sorted Results', results);
        return results;
    }

    static getLocalTime(dtArg, timezone) {
        let locTime = '';
        if (dtArg !== undefined) {
            let dt = moment.tz(dtArg, timezone);
            // return time in 12hr format with am/pm
            locTime = dt.format('HH:mm');
        }
        return locTime;
    }

    static getLocalDate(dtArg, timezone) {
        let locDate = '';
        if (dtArg !== undefined) {
            let dt = moment.tz(dtArg, timezone);
            locDate = dt.format('DD/MM/YYYY');
        }
        return locDate;
    }

    static getLocalDate_Reversed(dtArg, timezone) {
        let locDate = '';
        if (dtArg !== undefined) {
            let dt = moment.tz(dtArg, timezone);
            locDate = dt.format('YYYY-MM-DD');
        }
        return locDate;
    }

    static calculateLength(startTime, endTime, obj) {
        let start = moment(startTime);
        let end = moment(endTime);
        if (obj?.hasBreaks) {
            end = end.subtract(obj.TotalBreakHours, 'hours').subtract(obj.TotalBreakMinutes, 'minutes');
        }
        let duration = moment.duration(end.diff(start));
        let decimalHours = duration.asHours();
        let length = moment.utc(decimalHours * 36000 * 100).format('HH:mm');
        let hours = this.parseTimeFromString(length, false, 'HH');
        let mins = this.parseTimeFromString(length, false, 'mm');
        // remove leading 0 if any
        hours = hours[0] === '0' ? hours.substring(1) : hours;
        mins = mins[0] === '0' ? mins.substring(1) : mins;

        // return [decimalHours, `${hours} hours ${mins} mins`];
        return {
            hoursDecimal: decimalHours,
            hours: hours,
            minutes: mins,
            formattedString: `${hours} hours ${mins} mins`
        }
    }

    static sortRecords(records = []) {
        Utils.sortByDate(records);
        Utils.sortByContact(records);

        // Utils.sortByNotApproved(records);
    }

    static convertDateFormat(date) {
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();

        day = day < 10 ? '0' + day : day;
        month = month < 10 ? '0' + month : month;
        return `${month}/${day}/${year}`;
    }

    static convertDateFormat_Reverse(date) {
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();

        day = day < 10 ? '0' + day : day;
        month = month < 10 ? '0' + month : month;
        return `${year}-${month}-${day}`;
    }

    static convertTimeFormat(date) {
        let minutes = date.getDate();
        minutes = minutes < 10 ? '0' + minutes : minutes;
        return `${date.getHours()}:${minutes}`;
    }

    static calculateShiftLength(endTime, startTime) {
        let shiftEnd = new Date(endTime);
        let shiftStart = new Date(startTime);
        return (shiftEnd - shiftStart) * 24;
    }

    static sortByContact(records = []) {
        records.sort((a, b) => {
            if (a.shift.sirenum__Contact__r?.Name < b.shift?.sirenum__Contact__r?.Name) {
                return -1;
            }
            if (a.shift?.sirenum__Contact__r?.Name > b.shift?.sirenum__Contact__r?.Name) {
                return 1;
            }
            // a must be equal to b
            return 0;
        });
    }

    static sortByDate(records = []) {
        records.sort((a, b) => {
            if (new Date(a.shift.sirenum__Absolute_Start_Time__c) < new Date(b.shift.sirenum__Absolute_Start_Time__c)) {
                return -1;
            }
            if (new Date(a.shift.sirenum__Absolute_Start_Time__c) > new Date(b.shift.sirenum__Absolute_Start_Time__c)) {
                return 1;
            }
            // a must be equal to b
            return 0;
        });
    }

    static sortByNotApproved(records = []) {
        records.sort((a, b) => {
            if (a.shift.sirenum__Allow_charge__c < b.shift.sirenum__Allow_charge__c) {
                return -1;
            }
            if (a.shift.sirenum__Allow_charge__c > b.shift.sirenum__Allow_charge__c) {
                return 1;
            }
            return 0;
        })
    }

    static formatDate(d) {
        if (!d) return 'N/A';
        return new Date(d).toLocaleDateString('en-GB');
    }
    static formatTime(d) {
        if (!d) return 'N/A';
        return new Date(d).toLocaleTimeString('en-GB');
    }

    static convertExpenses(expenses = []) {
        let results = [];
        for (let expense of expenses) {
            let newExpense = {
                'Id': expense?.Id,
                'Name': expense?.sirenum__Expense_Type__r?.Name,
                'Timesheet': expense?.sirenum__Timesheet__c,
                'Shift': expense?.Shift__c,
                // 'ShiftDate': expense?.Shift_Date__c,
                'ExpenseTypeId': expense?.sirenum__Expense_Type__c,
                'ExepnseTypeName': expense?.sirenum__Expense_Type__r?.Name ?? 'Type - N/A',
                'ExpenseTypeValue': expense?.sirenum__Expense_Type__r?.sirenum__Value__c,
                'Amount': expense?.Expense_value__c,
                'Units': expense?.sirenum__Units__c,
                'Approved': expense?.sirenum__Approved__c ?? false,
                'ApprovedForPayment': expense?.sirenum__Approved_for_Payment__c ?? false,
                'IsLocked': expense?.sirenum__Is_Locked__c ?? false
            };
            results.push(newExpense);
        }

        return results;
    }

    static convertTimesheetSummary(summary = {}) {
        return {
            Name: summary?.Name,
            Id: summary?.Id,
            Pay: summary.sirenum__Total_Pay__c,
            Charge: summary.sirenum__Total_Charge__c,
            Hours: summary.sirenum__Total_Hours__c,
            Date: summary.sirenum__Week_Ending__c ? Utils.formatDate(summary.sirenum__Week_Ending__c) : '',
            PONumber: summary.sirenum__PO_Number__c,
            WorkerName: summary.sirenum__Worker__r?.Name + ' (' + summary.sirenum__Worker__r?.InTimeExternalId__c + ')' || '',
            JobRole: summary.sirenum__Team__r?.Name || ''
        };
    }

    static convertTimesheets(timesheets = []) {
        return timesheets.map(x => {
            return {
                Name: x.Name,
                Id: x.Id,
                Pay: x.sirenum__Total_Pay__c,
                Charge: x.sirenum__Total_Charge__c,
                ShiftId: x.sirenum__Shift__c,
                SummaryId: x.sirenum__Timesheet__c,
                Hours: x.sirenum__Hours__c,
                Date: x.sirenum__Date__c ? Utils.formatDate(x.sirenum__Date__c) : ''
            };
        });
    }

    static parseTimeFromString(strTime, isDT, customFormat) {
        const _MAX_HRS = 24;
        const _MIN_HRS = 0;
        //The supported input parsing formats
        const _PARSE_TIME_FORMATS = ['H:m', 'HH:mm', 'hmm', 'Hmm'];
        //The output parsed time format
        const _DISPLAY_TIME_FORMAT = 'HH:mm';

        let parsedTime;
        if (!strTime || strTime === undefined || strTime == null)
            return '';

        let isSuccess = false;
        if (isDT) {
            //Attempt to parse Salesforce DT Format
            parsedTime = moment(strTime);
            if (parsedTime.isValid()) {
                if (parsedTime.seconds() >= 30) {
                    parsedTime.add('30', 'seconds');
                }
                isSuccess = true;
            }
        } else {
            //Attempt to parse TIME only from String
            parsedTime = moment(strTime, _PARSE_TIME_FORMATS);
            if (parsedTime.isValid()) {
                if (parsedTime.seconds() >= 30) {
                    parsedTime.add('30', 'seconds');
                }
                isSuccess = true;
            }

        }

        //Couldn't Parse - return empty string
        if (!isSuccess) {
            return '';
        }

        //Custom format defined
        if (customFormat)
            return parsedTime.format(customFormat);

        return parsedTime.format(_DISPLAY_TIME_FORMAT);
    }
}