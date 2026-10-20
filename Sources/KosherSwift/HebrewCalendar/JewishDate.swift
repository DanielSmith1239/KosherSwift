//
//  JewishMonth.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

public class JewishDate: Comparable {
    public let gregDate: Date

    public let month: JewishMonth
    public let day: Int
    public let year: Int
    public let dow: DayOfWeek

    public let isJewishLeapYear: Bool
    
    init(date: Date, includeTime: Bool = false) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Calendar.current.timeZone
        let components = DateComponents(year: date.year, month: date.month, day: date.day, hour: includeTime ? date.hour : 0, minute: includeTime ? date.minute : 0, second: includeTime ? date.second : 0)
        self.gregDate = cal.date(from: components)!
                
        var hebCal = Calendar(identifier: .hebrew)
        hebCal.timeZone = Calendar.current.timeZone
        
        self.year = hebCal.component(.year, from: gregDate)
        self.isJewishLeapYear = JewishDate.isJewishLeapYear(year)
        self.month = JewishMonth.fromSwiftCalMonth(month: hebCal.component(.month, from: gregDate), isLeapYear: self.isJewishLeapYear)

        self.day = hebCal.component(.day, from: gregDate)
        self.dow = DayOfWeek(rawValue: Calendar.current.dateComponents([.weekday], from: gregDate).weekday!)!
    }
    
    public convenience init(withJewishYear year: Int, andMonth month: JewishMonth, andDay day: Int) {
        var hebCal = Calendar(identifier: .hebrew)
        hebCal.timeZone = Calendar.current.timeZone
        
        let gregDate = hebCal.date(from: DateComponents(year: year, month: month.toSwiftCalMonth(JewishDate.isJewishLeapYear(year)), day: day))!
        self.init(date: gregDate)
    }
    
    public static func == (lhs: JewishDate, rhs: JewishDate) -> Bool {
        return lhs.gregDate == rhs.gregDate
    }
    
    public static func < (lhs: JewishDate, rhs: JewishDate) -> Bool {
        return lhs.gregDate < rhs.gregDate
    }
}

extension JewishDate {
    static func moladToAbsDate(chalakim: Double) -> Int {
      return Int((chalakim / Double(chalakimPerDay)) + Double(jewishEpoch))
    }

    static func getLastDayOfGregorianMonth(month: Int, year: Int) -> Int {
        switch (month) {
          case 2:
            if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
              return 29;
            } else {
              return 28;
            }
          case 4, 6, 9, 11:
            return 30;
          default:
            return 31;
        }
      }

    private static func jewishDateToAbsDate(jewishDate: JewishDate) -> Int{
        let elapsed = getDaysSinceStartOfJewishYear(jewishDate: jewishDate)
        // add elapsed days this year + Days in prior years + Days elapsed before absolute year 1
        let jewCalElapsed = getJewishCalendarElapsedDays(year: jewishDate.year)
        let ret = elapsed + jewCalElapsed + jewishEpoch;
        return ret
      }
    
    static func gregorianDateToAbsDate(year: Int, month: Int, day: Int) -> Int {
       var absDate = day
        for m in stride(from: month - 1, to: 0, by: -1) {
            absDate += getLastDayOfGregorianMonth(month: m, year: year)
        }
        
       let ret = absDate // days this year
           +
       365 * (year - 1) // days in previous years ignoring leap days
           +
           ((year - 1) ~/ 4) // Julian leap days before this year
           -
           ((year - 1) ~/ 100) // minus prior century years
           +
          ((year - 1) ~/ 400) // plus prior years divisible by 400
        
        return ret
     }
    
     static func gregorianDateToAbsDate(date: Date) -> Int {
        let comp = Calendar.current.dateComponents([.year, .month, .day], from: date)
        
         return gregorianDateToAbsDate(year: comp.year!, month: comp.month!, day: comp.day!)
      }
    
    static func absDateToDate(absDate: Int) -> Date {
        let (year, month, day) = absDateToGregorian(absDate: absDate)
        return Date(year: year, month: month, day: day)
    }
    
    static func absDateToGregorian(absDate: Int) -> (year: Int, month: Int, day: Int) {
        var year = absDate ~/ 366 // Search forward year by year from approximate year
        while absDate >= gregorianDateToAbsDate(year: year + 1, month: 1, day: 1) {
          year += 1
        }

        var month = 1 // Search forward month by month from January
        while absDate > gregorianDateToAbsDate(year: year, month: month, day: getLastDayOfGregorianMonth(month: month, year: year)) {
          month += 1
        }

//        let dayOfMonth = absDate - gregorianDateToAbsDate(date: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!) + 1
        let toSub = gregorianDateToAbsDate(year: year, month: month, day: 1)
        let day = absDate - toSub + 1
        return (year, month, day)
      }
    
    static func isJewishLeapYear(_ year: Int) -> Bool {
        ((7 * year) + 1) % 19 < 7
    }

    
    private static func getLastMonthOfJewishYear(_ year: Int) -> JewishMonth {
        isJewishLeapYear(year) ? .adar2 : .adar
    }
    
    var lastMonthOfJewishYear: JewishMonth { JewishDate.getLastMonthOfJewishYear(year) }


    private static func getDaysInJewishYear(_ year: Int) -> Int {
        getJewishCalendarElapsedDays(year: year + 1) -
        getJewishCalendarElapsedDays(year: year);
    }
    
    var daysInJewishYear: Int { JewishDate.getDaysInJewishYear(year) }

    private static func isCheshvanLong(year: Int) -> Bool {
        return getDaysInJewishYear(year) % 10 == 5
    }
    
    var isCheshvanLong: Bool { JewishDate.isCheshvanLong(year: year) }
    
    private static func isKislevShort(year: Int) -> Bool {
        return getDaysInJewishYear(year) % 10 == 3
    }
    
    var isKislevShort: Bool { JewishDate.isKislevShort(year: year) }

    private static func getJewishCalendarElapsedDays(year: Int) -> Int {
        let chalakimSince = getChalakimSinceMoladTohu(year: year, month: .tishrei);
        let moladDay = chalakimSince ~/ chalakimPerDay
        let moladParts = Int(chalakimSince - Double(moladDay) * Double(chalakimPerDay))
        return addDechiyos(year: year, moladDay: moladDay, moladParts: moladParts);
    }
    
    var jewishCalendarElapsedDays: Int { JewishDate.getJewishCalendarElapsedDays(year: year) }
    
    private static func addDechiyos(year: Int, moladDay: Int, moladParts: Int) -> Int {
        var roshHashanaDay = moladDay // if no dechiyos
        // delay Rosh Hashana for the dechiyos of the Molad - new moon 1 - Molad Zaken, 2- GaTRaD 3- BeTuTaKFoT
        if moladParts >= 19440 || ((moladDay % 7) == 2 && moladParts >= 9924 && !isJewishLeapYear(year)) || ((moladDay % 7) == 1 && moladParts >= 16789 && isJewishLeapYear(year - 1)) {
            // in a year following a leap year - end Dechiya of BeTuTaKFoT
            roshHashanaDay += 1 // Then postpone Rosh HaShanah one day
        }
        // start 4th Dechiya - Lo ADU Rosh - Rosh Hashana can't occur on A- sunday, D- Wednesday, U - Friday
        if (roshHashanaDay % 7) == 0 || (roshHashanaDay % 7) == 3 || (roshHashanaDay % 7) == 5 {
            // or Friday - end 4th Dechiya - Lo ADU Rosh
            roshHashanaDay = roshHashanaDay + 1 // Then postpone it one (more) day
        }
        return roshHashanaDay
    }

    private static func getJewishMonthOfYear(year: Int, month: JewishMonth) -> Int {
        let isLeapYear = isJewishLeapYear(year);
        return (month.rawValue + (isLeapYear ? 6 : 5)) % (isLeapYear ? 13 : 12) + 1
      }
    
    static func getChalakimSinceMoladTohu(year: Int, month: JewishMonth) -> Double {
        // Jewish lunar month = 29 days, 12 hours and 793 chalakim
        // chalakim since Molad Tohu BeHaRaD - 1 day, 5 hours and 204 chalakim
        let monthOfYear = getJewishMonthOfYear(year: year, month: month)
        let monthsElapsed = (
            (235 * ((year - 1) ~/ 19)) // Months in complete 19 year lunar (Metonic) cycles so far
            +
            (12 * ((year - 1) % 19)) // Regular months in this cycle
            +
            ((7 * ((year - 1) % 19) + 1) ~/ 19) // Leap months this cycle
            +
            (monthOfYear -
                1)) // add elapsed months till the start of the molad of the month
        // return chalakim prior to BeHaRaD + number of chalakim since
        return Double(chalakimMoladTohu) + (chalakimPerMonth * Double(monthsElapsed))
      }
    
    private static func getDaysSinceStartOfJewishYear(jewishDate: JewishDate) -> Int {
        var elapsedDays = jewishDate.day
        
        // Before Tishrei (from Nissan to Tishrei), add days in prior months
        if jewishDate.month.rawValue < JewishMonth.tishrei.rawValue {
            // this year before and after Nisan.
            
            for m in JewishMonth.tishrei.rawValue...getLastMonthOfJewishYear(jewishDate.year).rawValue {
                elapsedDays += JewishDate.getDaysInJewishMonth(month: JewishMonth(rawValue: m)!, year: jewishDate.year)
            }
            for m in JewishMonth.nissan.rawValue..<jewishDate.month.rawValue {
                elapsedDays += JewishDate.getDaysInJewishMonth(month: JewishMonth(rawValue: m)!, year: jewishDate.year)
            }
        } else {
            // Add days in prior months this year
            for m in JewishMonth.tishrei.rawValue..<jewishDate.month.rawValue {
                elapsedDays += JewishDate.getDaysInJewishMonth(month: JewishMonth(rawValue: m)!, year: jewishDate.year)
            }
        }
        
        return elapsedDays
    }
    
    var daysSinceStartOfJewishYear: Int { JewishDate.getDaysSinceStartOfJewishYear(jewishDate: self) }

    static func getDaysInJewishMonth(month: JewishMonth, year: Int) -> Int {
        let is29 = [.iyar, .tammuz, .elul, .teves, .adar2].contains(month)
            || (month == .cheshvan && !JewishDate.isCheshvanLong(year: year))
            || (month == .kislev && JewishDate.isKislevShort(year: year))
            || (month == .adar && !JewishDate.isJewishLeapYear(year))
        
        return is29 ? 29 : 30
      }
    
    public func getDaysInJewishMonth(month: JewishMonth) -> Int { JewishDate.getDaysInJewishMonth(month: month, year: year) }
}
