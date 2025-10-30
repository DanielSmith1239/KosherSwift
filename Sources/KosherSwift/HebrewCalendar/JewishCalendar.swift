//
//  JewishMonth.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

public class JewishCalendar: JewishDate {
    public let isInIsrael: Bool
    public let moladDate: MoladDate?
    
    public convenience init(withJewishYear year: Int, andMonth month: JewishMonth, andDay day: Int, isInIsrael: Bool = false) {
        var hebCal = Calendar(identifier: .hebrew)
        hebCal.timeZone = Calendar.current.timeZone
        
        let newMonth = month.toSwiftCalMonth(JewishDate.isJewishLeapYear(year))
        let gregDate = hebCal.date(from: DateComponents(year: year, month: newMonth, day: day))!
        self.init(date: gregDate, isInIsrael: isInIsrael)
    }
    
    
    public init(date: Date, includeTime: Bool = false, isInIsrael: Bool = false) {
        self.isInIsrael = isInIsrael
        self.moladDate = MoladDate.calculate(forJewishDate: JewishDate(date: date))

        super.init(date: date, includeTime: includeTime)
    }
    
    public func copy(year: Int? = nil, month: JewishMonth? = nil, day: Int? = nil, isInIsrael: Bool? = nil) -> JewishCalendar {
        JewishCalendar(withJewishYear: year ?? self.year, andMonth: (month ?? self.month), andDay: day ?? self.day, isInIsrael: isInIsrael ?? self.isInIsrael)
    }
    
    public var isBirkasHachama: Bool {
        let elapsedDays = jewishCalendarElapsedDays + daysSinceStartOfJewishYear
        
        return elapsedDays % Int(28.0 * 365.25) == 172
    }
    
    public var tekufasTishreiElapsedDays: Int {
        let days = Double(jewishCalendarElapsedDays + (daysSinceStartOfJewishYear - 1)) + 0.5
        let solar = Double(year - 1) * 365.25
        
        return Int((days - solar).rounded(.down))
    }
    
    private func getParshaYearType() -> Int? {
        var rhDow = (jewishCalendarElapsedDays + 1) % 7
        if rhDow == 0 { rhDow = 7 }
        let compDow = DayOfWeek(rawValue: rhDow)!
        
        if isJewishLeapYear {
            switch compDow {
            case .monday:
                if isKislevShort {
                    return isInIsrael ? 14 : 6
                } else if isCheshvanLong {
                    return isInIsrael ? 15 : 7
                }
            case .tuesday:
                return isInIsrael ? 15 : 7
            case .thursday:
                if isKislevShort {
                    return 8
                } else if isCheshvanLong {
                    return 9
                }
            case .saturday:
                if isKislevShort {
                    return 10
                } else if isCheshvanLong {
                    return isInIsrael ? 16 : 11
                }
            default:
                return nil
            }
        } else {
            switch compDow {
            case .monday:
                if isKislevShort {
                    return 0
                } else if isCheshvanLong {
                    return isInIsrael ? 12 : 1
                }
            case .tuesday:
                return isInIsrael ? 12 : 1
            case .thursday:
                if isCheshvanLong {
                    return 3
                } else if !isKislevShort {
                    return isInIsrael ? 13 : 2
                }
            case .saturday:
                if isKislevShort {
                    return 4
                } else if isCheshvanLong {
                    return 5
                }
            default:
                return nil
            }
        }
        
        return nil
    }
    
    public func getParsha() -> Parsha {
        if dow != .saturday {
            return .none
        }
        
        guard let yearType = getParshaYearType() else {
            return .none
        }
        
        let rhDow = jewishCalendarElapsedDays % 7
        let day = rhDow + daysSinceStartOfJewishYear
        
        return Parsha.parshalist[yearType][Int(day / 7)]
    }
    
    public func getWeeklyParsha() -> Parsha {
        if dow == .saturday {
            return getParsha()
        }
        
        var nextShabbos = gregDate.next(.saturday)
        var cal = JewishCalendar(date: nextShabbos, isInIsrael: isInIsrael)
        
        while cal.getParsha() == .none {
            nextShabbos = gregDate.next(.saturday)
            cal = JewishCalendar(date: nextShabbos, isInIsrael: isInIsrael)
        }
        
        return cal.getParsha()
    }
    
    public func getSpecialShabbos() -> Parsha {
        if dow != .saturday {
            return .none
        }
        
        if (month == .shevat && !isJewishLeapYear) || (month == .adar && isJewishLeapYear) {
            if [25, 27, 29].contains(day) {
                return .shkalim
            }
        }
        
        if (month == .adar && !isJewishLeapYear) || month == .adar2 {
            if day == 1 {
                return .shkalim
            } else if [8, 9, 11, 13].contains(day) {
                return .zachor
            } else if [18, 20, 22, 23].contains(day) {
                return .para
            } else if [25, 27, 29].contains(day) {
                return .hachodesh
            }
        }
        
        if month == .nissan && day == 1 {
            return .hachodesh
        }
        
        return .none
    }
    
    // Chagim checkers
    public var isErevRoshChodesh: Bool { day == 29 && month != .elul }
    public var isRoshChodesh: Bool { (day == 1 && month != .tishrei) || day == 30 }
    public var isErevPesach: Bool { month == .nissan && day == 14 }
    public var isPesach: Bool { month == .nissan && (day == 15 || day == 21 || (!isInIsrael && (day == 16 || day == 22))) }
    public var isCholHamoedPesach: Bool { month == .nissan && (day >= 17 && day <= 20 || (day == 16 && isInIsrael)) }
    public var isYomHashoah: Bool { month == .nissan && ((day == 26 && dow == .thursday) || (day == 28 && dow == .monday) || (day == 27 && dow != .sunday && dow != .friday))}
    public var isYomHazikaron: Bool { month == .iyar && ((day == 4 && dow == .tuesday) || ((day == 3 || day == 2) && dow == .wednesday) || (day == 6 && dow == .tuesday)) }
    public var isYomHaatzmaut: Bool { month == .iyar && ((day == 5 && dow == .wednesday) || (day == 6 && dow == .tuesday) || ((day == 4 || day == 3) && dow == .thursday)) }
    public var isPesachSheni: Bool { month == .iyar && day == 14 }
    public var isLagBaomer: Bool { month == .iyar && day == 18 }
    public var isYomYerushalaim: Bool { month == .iyar && day == 28 }
    public var isErevShavuos: Bool { month == .sivan && day == 5 }
    public var isShavuos: Bool { month == .sivan && (day == 6 || (!isInIsrael && day == 7)) }
    public var isSeventeenthOfTammuz: Bool { month == .tammuz && ((day == 17 && dow != .friday) || (day == 18 && dow == .sunday)) }
    public var isTishaBeav: Bool { month == .av && ((day == 10 && dow == .sunday) || (day == 9 && dow != .saturday)) }
    public var isTuBeav: Bool { month == .av && day == 15 }
    public var isErevRoshHashana: Bool { month == .elul && day == 29 }
    public var isRoshHashana: Bool { month == .tishrei && (day == 1 || day == 2) }
    public var isFastOfGedalia: Bool { month == .tishrei && ((day == 3 && dow != .saturday) || (day == 4 && dow == .sunday)) }
    public var isErevYomKippur: Bool { month == .tishrei && day == 9 }
    public var isYomKippur: Bool { month == .tishrei && day == 10 }
    public var isErevSuccos: Bool { month == .tishrei && day == 14 }
    public var isSuccos: Bool { month == .tishrei && (day == 15 || (day == 16 && !isInIsrael)) }
    public var isCholHamoedSuccos: Bool { month == .tishrei && ((day >= 17 && day <= 20) || (day == 16 && isInIsrael)) }
    public var isHoshanaRabba: Bool { month == .tishrei && day == 21 }
    public var isSheminiAtzeres: Bool { month == .tishrei && day == 22 }
    public var isSimchasTorah: Bool { month == .tishrei && day == 23 && !isInIsrael }
    public var isErevChanukah: Bool { month == .kislev && day == 24 } // TODO formatting?
    public var isChanukah: Bool { (month == .kislev && day >= 25) || (month == .teves && ((day == 1 || day == 2) || (day == 3 && isKislevShort)))}
    public var isTenthOfTeves: Bool { month == .teves && day == 10 }
    public var isTuBeshvat: Bool { month == .shevat && day == 15 }
    public var isFastOfEsther: Bool { (!isJewishLeapYear && month == .adar && (((day == 11 || day == 12) && dow == .thursday) || (day == 13 && !(dow == .friday || dow == .saturday)))) || (isJewishLeapYear && month == .adar2 && (((day == 11 || day == 12) && dow == .thursday) || (day == 13 && !(dow == .friday || dow == .saturday)))) }
    public var isPurim: Bool { (!isJewishLeapYear && month == .adar && day == 14) || (isJewishLeapYear && month == .adar2 && day == 14) }
    public var isShushanPurim: Bool { (!isJewishLeapYear && month == .adar && day == 15) || (isJewishLeapYear && month == .adar2 && day == 15) }
    public var isPurimKatan: Bool { isJewishLeapYear && month == .adar && day == 14 }
    public var isShushanPurimKatan: Bool { isJewishLeapYear && month == .adar && day == 15 }
    public var isIsruChag: Bool { month == .sivan && ((day == 7 && isInIsrael) || day == 8 && !isInIsrael) }
    
    private static let chagCheckers: [JewishHoliday: (JewishCalendar) -> Bool] = [
        .erevPesach: { cal in cal.isErevPesach },
        .pesach: { cal in cal.isPesach },
        .cholHamoedPesach: { cal in cal.isCholHamoedPesach },
        .pesachSheni: { cal in cal.isPesachSheni },
        .erevShavuos: { cal in cal.isErevShavuos },
        .shavuos: { cal in cal.isShavuos },
        .seventeenthOfTammuz: { cal in cal.isSeventeenthOfTammuz },
        .tishaBeav: { cal in cal.isTishaBeav },
        .tuBeav: { cal in cal.isTuBeav },
        .erevRoshHashana: { cal in cal.isErevRoshHashana },
        .roshHashana: { cal in cal.isRoshHashana },
        .fastOfGedalia: { cal in cal.isFastOfGedalia },
        .erevYomKippur: { cal in cal.isErevYomKippur },
        .yomKippur: { cal in cal.isYomKippur },
        .erevSuccos: { cal in cal.isErevSuccos },
        .succos: { cal in cal.isSuccos },
        .cholHamoedSuccos: { cal in cal.isCholHamoedSuccos },
        .hoshanaRabba: { cal in cal.isHoshanaRabba },
        .sheminiAtzeres: { cal in cal.isSheminiAtzeres },
        .simchasTorah: { cal in cal.isSimchasTorah },
        .erevChanukah: { cal in cal.isErevChanukah },
        .chanukah: { cal in cal.isChanukah },
        .tenthOfTeves: { cal in cal.isTenthOfTeves },
        .tuBeshvat: { cal in cal.isTuBeshvat },
        .fastOfEsther: { cal in cal.isFastOfEsther },
        .purim: { cal in cal.isPurim },
        .shushanPurim: { cal in cal.isShushanPurim },
        .purimKatan: { cal in cal.isPurimKatan },
        .erevRoshChodesh: { cal in cal.isErevRoshChodesh },
        .roshChodesh: { cal in cal.isRoshChodesh },
        .yomHashoah: { cal in cal.isYomHashoah },
        .yomHazikaron: { cal in cal.isYomHazikaron },
        .yomHaatzmaut: { cal in cal.isYomHaatzmaut },
        .yomYerushalaim: { cal in cal.isYomYerushalaim },
        .lagBaomer: { cal in cal.isLagBaomer },
        .shushanPurimKatan: { cal in cal.isShushanPurimKatan },
        .isruChag: { cal in cal.isIsruChag }
    ]
    
    public func getCurrentChag() -> JewishHoliday? {
        for checker in JewishCalendar.chagCheckers {
            if checker.value(self) {
                return checker.key
            }
        }
        
        return nil
    }
    
    public var isYomTov: Bool {
        guard let _ = getCurrentChag() else {
            return false
        }
        
        let isExcludedChag = (isErevYomTov && !(isHoshanaRabba || isCholHamoedPesach))
            || (isTaanis && !isYomKippur)
            || isIsruChag
        
        return !isExcludedChag
    }
    
    public var isYomTovAssurBemelacha: Bool { isPesach || isShavuos || isSuccos || isSheminiAtzeres || isSimchasTorah || isRoshHashana || isYomKippur }
    
    public var isAssurBemelacha: Bool { dow == .saturday || isYomTovAssurBemelacha }
    
    public var isTomorrowShabbosOrYomTov: Bool { dow == .friday || isErevYomTov || isErevYomTovSheni }
    
    public var isErevYomTovSheni: Bool {
        if month == .tishrei && day == 1 {
            return true
        }
        
        if isInIsrael { return false }
        
        if month == .nissan {
            return day == 15 || day == 21
        } else if month == .tishrei {
            return day == 15 || day == 22
        } else if month == .sivan {
            return day == 6
        }
        
        return false
    }
    
    public var isAseresYemeiTeshuva: Bool { month == .tishrei && day <= 10 }
    
    public var isCholHamoed: Bool { isCholHamoedPesach || isCholHamoedSuccos }
    
    public var isErevYomTov: Bool { isErevRoshChodesh || isErevShavuos || isErevPesach || isErevSuccos || isErevRoshHashana || isErevYomKippur || isErevSuccos || isHoshanaRabba || (isCholHamoedPesach && day == 20) }
    
    public var isTaanis: Bool { isSeventeenthOfTammuz || isTishaBeav || isYomKippur || isFastOfEsther || isFastOfGedalia || isTenthOfTeves }
    
    public var isTaanisBechoros: Bool { month == .nissan && ((day == 14 && dow != .saturday) || (day == 12 && dow == .thursday)) }
    
    public var dayOfChanukah: Int? {
        if !isChanukah { return nil }
        
        if month == .kislev {
            return day - 24
        } else {
            return isKislevShort ? day + 5 : day + 6
        }
    }
    
    public var isMacharChodesh: Bool { dow == .saturday && (day == 30 || day == 29) }
    
    public var isShabbosMevorchim: Bool { dow == .saturday && month != .elul && day >= 23 && day <= 29 }
    
    public var dayOfOmer: Int? {
        if month == .nissan && day >= 16 {
            return day - 15
        } else if month == .iyar {
            return day + 15
        } else if month == .sivan && day < 6 {
            return day + 44
        }
        
        return nil
    }

    public var earliestKiddushLevana3Days: Date? { moladDate?.gregDate.withAdded(days: 3) }
    public var earliestKiddushLevana7Days: Date? { moladDate?.gregDate.withAdded(days: 7) }
    public var latestZmanKidushLevanaBetweenMoldos: Date? { moladDate?.gregDate.withAdded(days: 14, hours: 18, minutes: 22, seconds: 1, milliseconds: 666) }
    public var latestKiddushLevana15Days: Date? { moladDate?.gregDate.withAdded(days: 15) }
    
    public var dafYomiBavli: Daf? { DafYomiCalculator.getDafYomiBavli(cal: self) }
    public var dafYomiYerushalmi: Daf? { DafYomiCalculator.getDafYomiYerushalmi(cal: self) }

    public var isMashivHaruachRecited: Bool {
        let start = JewishDate(withJewishYear: year, andMonth: .tishrei, andDay: 22)
        let end = JewishDate(withJewishYear: year, andMonth: .nissan, andDay: 15)
        
        return gregDate > start.gregDate && gregDate < end.gregDate
    }
    
    public var isVeseinTalUmatarRecited: Bool {
        if month == .nissan && day < 15 {
            return true
        } else if month.rawValue < JewishMonth.cheshvan.rawValue {
            return false
        } else if isInIsrael {
            return month != .cheshvan || day >= 7
        }
        
        return tekufasTishreiElapsedDays >= 47
    }
    
    public var isMashivHaruachStartDate: Bool { return month == .tishrei && day == 22 }
    public var isMashivHaruachEndDate: Bool { return month == .nissan && day == 15 }
    
    public var isVeseinBerachaRecited: Bool { !isVeseinTalUmatarRecited }
    public var isMoridHatalRecited: Bool { !isMashivHaruachRecited || isMashivHaruachStartDate || isMashivHaruachEndDate }
    
    public var tomorrow: JewishCalendar {
        JewishCalendar(date: gregDate.withAdded(days: 1)!, isInIsrael: isInIsrael)
    }
    
    public var yesterday: JewishCalendar {
        JewishCalendar(date: gregDate.withAdded(days: -1)!, isInIsrael: isInIsrael)
    }
    
    public var chagStart: JewishCalendar {
        var temp = JewishCalendar(date: gregDate, isInIsrael: isInIsrael)
        while !temp.isErevYomTov {
            temp = temp.yesterday
        }
        
        return temp
    }
    
    public var chagHavdallahDate: JewishCalendar {
        var temp = chagStart.tomorrow
        while temp.isAssurBemelacha {
            temp = temp.tomorrow
        }
        
        return temp.yesterday
    }
    
    public var cholHamoedDay: Int? {
        if !isCholHamoed {
            return nil
        }
        
        var cur = self.copy()
        var i = 0
        while cur.isCholHamoed {
            i += 1
            cur = cur.yesterday
        }
        
        return i
    }
    
    public var isLedavidSaid: Bool {
        month == .elul || (month == .tishrei && day < 22)
    }
    
    public func getRules(baseRules: TefilaRules) -> TefilaRules {
        baseRules.copy(withCal: self)
    }
    
    public var daysInJewishMonth: Int {
        getDaysInJewishMonth(month: month)
    }
}
