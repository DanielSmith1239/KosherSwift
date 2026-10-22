//
//  JewishMonth.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

/// The JewishCalendar extends the JewishDate class and adds calendar methods. This open source Java code was originally
/// ported by [Avrom Finkelstien](http://www.facebook.com/avromf) from his C++ code. It was refactored to fit the
/// KosherJava Zmanim API with simplification of the code, enhancements and some bug fixing. The class allows setting
/// whether the holiday and *parsha* scheme follows the Israel scheme or outside Israel scheme. The default is the
/// outside Israel scheme. The parsha code was ported by Y. Paritcher from his
/// [libzmanim](https://github.com/yparitcher/libzmanim) code.
///
/// - ToDo: Some do not belong in this class, but here is a partial list of what should still be implemented in some
///   form: - Mishna yomis etc
/// - SeeAlso: `Date`, `Calendar`
public class JewishCalendar: JewishDate {
    /// Gets whether Israel holiday scheme is used or not. The default (if not set) is false.
    ///
    /// - Returns: if the calendar is set to Israel
    public let isInIsrael: Bool

    /// Returns the molad for a given year and month. Returns a JewishDate `Object` set to the date of the molad with
    /// the hours, minutes and chalakim set. In the current implementation, it sets the molad time based on a midnight
    /// date rollover. This means that Rosh Chodesh Adar II, 5771 with a molad of 7 chalakim past midnight on Shabbos 29
    /// Adar I / March 5, 2011 12:00 AM and 7 chalakim, will have the following values: hours: 0, minutes: 0, Chalakim:
    /// 7.
    ///
    /// - Returns: a JewishDate `Object` set to the date of the molad with the hours, minutes and chalakim set.
    public let moladDate: MoladDate?
    /// Whether the city was walled in the time of Yehoshua, so Purim is on the 15th (KosherJava setIsMukafChoma).
    public var isMukafChoma = false
    
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
        let copy = JewishCalendar(withJewishYear: year ?? self.year, andMonth: (month ?? self.month), andDay: day ?? self.day, isInIsrael: isInIsrael ?? self.isInIsrael)
        copy.isMukafChoma = isMukafChoma
        return copy
    }
    
    /// [Birkas Hachamah](https://en.wikipedia.org/wiki/Birkat_Hachama) is recited every 28 years based on *Tekufas
    /// Shmuel* (Julian years) that a year is 365.25 days. The [Rambam](https://en.wikipedia.org/wiki/Maimonides) in
    /// [Hilchos Kiddush Hachodesh 9:3](http://hebrewbooks.org/pdfpager.aspx?req=14278&st=&pgnum=323) states that
    /// *tekufas Nissan* of year 1 was 7 days + 9 hours before *molad Nissan*. This is calculated as every 10,227 days
    /// (28 * 365.25).
    ///
    /// - Returns: true for a day that *Birkas Hachamah* is recited.
    public var isBirkasHachama: Bool {
        let elapsedDays = jewishCalendarElapsedDays + daysSinceStartOfJewishYear
        
        return elapsedDays % Int(28.0 * 365.25) == 172
    }
    
    /// Returns the elapsed days since *Tekufas Tishrei*. This uses *Tekufas Shmuel* (identical to the [Julian
    /// Year](https://en.wikipedia.org/wiki/Julian_year_(astronomy)) with a solar year length of 365.25 days). The
    /// notation used below is D = days, H = hours and C = chalakim. *[Molad](https://en.wikipedia.org/wiki/Molad)
    /// BaHaRad* was 2D,5H,204C or 5H,204C from the start of *Rosh Hashana* year 1. For *molad Nissan* add 177D, 4H and
    /// 438C (6 * 29D, 12H and 793C), or 177D,9H,642C after *Rosh Hashana* year 1. *Tekufas Nissan* was 7D, 9H and 642C
    /// before *molad Nissan* according to the Rambam, or 170D, 0H and 0C after *Rosh Hashana* year 1. *Tekufas Tishrei*
    /// was 182D and 3H (365.25 / 2) before *tekufas Nissan*, or 12D and 15H before *Rosh Hashana* of year 1. Outside of
    /// Israel we start reciting *Tal Umatar* in *Birkas Hashanim* from 60 days after *tekufas Tishrei*. The 60 days
    /// include the day of the *tekufah* and the day we start reciting *Tal Umatar*. 60 days from the tekufah == 47D and
    /// 9H from *Rosh Hashana* year 1.
    ///
    /// - Returns: the number of elapsed days since *tekufas Tishrei*.
    /// - SeeAlso: `isVeseinTalUmatarStartDate()`, `isVeseinTalUmatarStartingTonight()`, `isVeseinTalUmatarRecited`
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
    
    /// Returns this week's *Parsha* if it is *Shabbos*. It returns `NONE` if the date is a weekday or if there is no
    /// *parsha* that week (for example *Yom Tov* that falls on a *Shabbos*).
    ///
    /// - Returns: the current *parsha*.
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
    
    /// Returns the upcoming *Parsha* regardless of if it is the weekday or *Shabbos* (where next Shabbos's *Parsha*
    /// will be returned. This is unlike `getParsha()` that returns `NONE` if the date is not *Shabbos*. If the upcoming
    /// Shabbos is a *Yom Tov* and has no *Parsha*, the following week's *Parsha* will be returned.
    ///
    /// - Returns: the upcoming *parsha*.
    public func getWeeklyParsha() -> Parsha {
        if dow == .saturday {
            return getParsha()
        }
        
        var nextShabbos = gregDate.next(.saturday)
        var cal = JewishCalendar(date: nextShabbos, isInIsrael: isInIsrael)
        
        while cal.getParsha() == .none {
            nextShabbos = nextShabbos.next(.saturday)
            cal = JewishCalendar(date: nextShabbos, isInIsrael: isInIsrael)
        }
        
        return cal.getParsha()
    }
    
    /// Returns a *Parsha* enum if the *Shabbos* is one of the four *parshiyos* of *Shkalim*, *Zachor*, *Para*,
    /// *Hachdesh* or Parsha.NONE for a regular *Shabbos* (or any weekday).
    ///
    /// - Returns: one of the four *parshiyos* of *Shkalim* *Zachor*, *Para*, *Hachdesh* or Parsha.NONE.
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
        
        if month == .nissan {
            if day == 1 {
                return .hachodesh
            } else if day >= 8 && day <= 14 {
                return .hagadol
            }
        }
        
        if month == .av {
            if day >= 4 && day <= 9 {
                return .chazon
            } else if day >= 10 && day <= 16 {
                return .nachamu
            }
        }
        
        if month == .tishrei && day >= 3 && day <= 8 {
            return .shuva
        }
        
        if getParsha() == .beshalach {
            return .shira
        }
        
        return .none
    }
    
    // Chagim checkers
    /// Returns true if the current day is *Erev Rosh Chodesh*. Returns false for *Erev Rosh Hashana*.
    ///
    /// - Returns: true if the current day is *Erev Rosh Chodesh*. Returns false for *Erev Rosh Hashana*.
    /// - SeeAlso: `isRoshChodesh`
    public var isErevRoshChodesh: Bool { day == 29 && month != .elul }

    /// Returns if the day is Rosh Chodesh. Rosh Hashana will return false
    ///
    /// - Returns: true if it is Rosh Chodesh. Rosh Hashana will return false
    public var isRoshChodesh: Bool { (day == 1 && month != .tishrei) || day == 30 }

    /// `true` on the 14th day of Nissan, the day before of Pesach (Passover).
    public var isErevPesach: Bool { month == .nissan && day == 14 }

    /// Returns true if the current day is *Pesach* (either the *Yom Tov* of *Pesach* or *Chol Hamoed Pesach*).
    ///
    /// - Returns: true if the current day is *Pesach* (either the *Yom Tov* of *Pesach* or *Chol Hamoed Pesach*).
    /// - SeeAlso: `isYomTov`, `isCholHamoedPesach`
    public var isPesach: Bool { month == .nissan && (day == 15 || day == 21 || (!isInIsrael && (day == 16 || day == 22))) }

    /// Returns true if the current day is *Chol Hamoed* of *Pesach*.
    ///
    /// - Returns: true if the current day is *Chol Hamoed* of *Pesach*
    /// - SeeAlso: `isYomTov`, `isPesach`
    public var isCholHamoedPesach: Bool { month == .nissan && (day >= 17 && day <= 20 || (day == 16 && isInIsrael)) }

    /// `true` on yom HaShoah, Holocaust Remembrance Day, usually held on the 27th of Nissan. If it falls on a Friday,
    /// it is moved to the 26th, and if it falls on a Sunday it is moved to the 28th. A modern holiday.
    public var isYomHashoah: Bool { month == .nissan && ((day == 26 && dow == .thursday) || (day == 28 && dow == .monday) || (day == 27 && dow != .sunday && dow != .friday))}

    /// `true` on yom HaZikaron, Israeli Memorial Day, held a day before Yom Ha'atzmaut. A modern holiday.
    public var isYomHazikaron: Bool { month == .iyar && ((day == 4 && dow == .tuesday) || ((day == 3 || day == 2) && dow == .wednesday) || (day == 5 && dow == .monday)) }

    /// `true` on yom Ha'atzmaut, Israel Independence Day, the 5th of Iyar, but if it occurs on a Friday or Saturday,
    /// the holiday is moved back to Thursday, the 3rd of 4th of Iyar, and if it falls on a Monday, it is moved forward
    /// to Tuesday the 6th of Iyar. A modern holiday.
    public var isYomHaatzmaut: Bool { month == .iyar && ((day == 5 && dow == .wednesday) || (day == 6 && dow == .tuesday) || ((day == 4 || day == 3) && dow == .thursday)) }

    /// `true` on pesach Sheni, the 14th day of Iyar, a minor holiday.
    public var isPesachSheni: Bool { month == .iyar && day == 14 }

    /// `true` on the 33rd day of the Omer, the 18th of Iyar, a minor holiday.
    public var isLagBaomer: Bool { month == .iyar && day == 18 }

    /// `true` on yom Yerushalayim or Jerusalem Day, on 28 Iyar. A modern holiday.
    public var isYomYerushalaim: Bool { month == .iyar && day == 28 }

    /// `true` on erev Shavuos (the day before Shavuos), the 5th of Sivan
    public var isErevShavuos: Bool { month == .sivan && day == 5 }

    /// Returns true if the current day is *Shavuos*.
    ///
    /// - Returns: true if the current day is *Shavuos*.
    /// - SeeAlso: `isYomTov`
    public var isShavuos: Bool { month == .sivan && (day == 6 || (!isInIsrael && day == 7)) }

    /// `true` on the fast of the 17th day of Tamuz
    public var isSeventeenthOfTammuz: Bool { month == .tammuz && ((day == 17 && dow != .saturday) || (day == 18 && dow == .sunday)) }

    /// `true` on the fast of the 9th of Av
    public var isTishaBeav: Bool { month == .av && ((day == 10 && dow == .sunday) || (day == 9 && dow != .saturday)) }

    /// `true` on the 15th day of Av, a minor holiday
    public var isTuBeav: Bool { month == .av && day == 15 }

    /// `true` on erev Rosh Hashana (the day before Rosh Hashana), the 29th of Elul
    public var isErevRoshHashana: Bool { month == .elul && day == 29 }

    /// Returns true if the current day is *Rosh Hashana*.
    ///
    /// - Returns: true if the current day is *Rosh Hashana*.
    /// - SeeAlso: `isYomTov`
    public var isRoshHashana: Bool { month == .tishrei && (day == 1 || day == 2) }

    /// `true` on the fast of Gedalyah, the 3rd of Tishrei.
    public var isFastOfGedalia: Bool { month == .tishrei && ((day == 3 && dow != .saturday) || (day == 4 && dow == .sunday)) }

    /// `true` on the 9th day of Tishrei, the day before of Yom Kippur.
    public var isErevYomKippur: Bool { month == .tishrei && day == 9 }

    /// Returns true if the current day is *Yom Kippur*.
    ///
    /// - Returns: true if the current day is *Yom Kippur*.
    /// - SeeAlso: `isYomTov`
    public var isYomKippur: Bool { month == .tishrei && day == 10 }

    /// `true` on the 14th day of Tishrei, the day before of Succos/Sukkos (Tabernacles).
    public var isErevSuccos: Bool { month == .tishrei && day == 14 }

    /// Returns true if the current day is *Succos* (either the *Yom Tov* of *Succos* or *Chol Hamoed Succos*). It will
    /// return false for Shmini Atzeres and Simchas Torah.
    ///
    /// - Returns: true if the current day is *Succos* (either the *Yom Tov* of *Succos* or *Chol Hamoed Succos*.
    /// - SeeAlso: `isYomTov`, `isCholHamoedSuccos`, `isHoshanaRabba`
    public var isSuccos: Bool { month == .tishrei && (day == 15 || (day == 16 && !isInIsrael)) }

    /// Returns true if the current day is *Chol Hamoed* of *Succos*.
    ///
    /// - Returns: true if the current day is *Chol Hamoed* of *Succos*
    /// - SeeAlso: `isYomTov`
    public var isCholHamoedSuccos: Bool { month == .tishrei && ((day >= 17 && day <= 21) || (day == 16 && isInIsrael)) }

    /// Returns true if the current day is *Hoshana Rabba*.
    ///
    /// - Returns: true true if the current day is *Hoshana Rabba*.
    /// - SeeAlso: `isYomTov`
    public var isHoshanaRabba: Bool { month == .tishrei && day == 21 }

    /// `true` on shmini Atzeres, the 8th day of Succos/Sukkos is an independent holiday that occurs on the 22nd of
    /// Tishrei.
    public var isSheminiAtzeres: Bool { month == .tishrei && day == 22 }

    /// Returns true if the current day is *Simchas Torah*. This will always return false if in Israel
    ///
    /// - Returns: true if the current day is *Shmini Atzeres*.
    /// - SeeAlso: `isYomTov`
    public var isSimchasTorah: Bool { month == .tishrei && day == 23 && !isInIsrael }
    public var isErevChanukah: Bool { month == .kislev && day == 24 } // TODO formatting?

    /// Returns true if the current day is one of the 8 days of *Chanukah*.
    ///
    /// - Returns: if the current day is one of the 8 days of *Chanukah*.
    /// - SeeAlso: `dayOfChanukah`
    public var isChanukah: Bool { (month == .kislev && day >= 25) || (month == .teves && ((day == 1 || day == 2) || (day == 3 && isKislevShort)))}

    /// `true` on the fast of the 10th day of Teves.
    public var isTenthOfTeves: Bool { month == .teves && day == 10 }

    /// `true` on tu Bishvat on the 15th day of Shevat, a minor holiday.
    public var isTuBeshvat: Bool { month == .shevat && day == 15 }

    /// `true` on the fast of Esther, usually on the 13th day of Adar (or Adar II on leap years). It is earlier on some
    /// years.
    public var isFastOfEsther: Bool { (!isJewishLeapYear && month == .adar && (((day == 11 || day == 12) && dow == .thursday) || (day == 13 && !(dow == .friday || dow == .saturday)))) || (isJewishLeapYear && month == .adar2 && (((day == 11 || day == 12) && dow == .thursday) || (day == 13 && !(dow == .friday || dow == .saturday)))) }
    /// KosherJava isPurim(): the 14th of Adar (Adar II in a leap year), or the 15th when isMukafChoma is set.
    public var isPurim: Bool {
        let purimDay = isMukafChoma ? 15 : 14
        return (!isJewishLeapYear && month == .adar && day == purimDay) || (isJewishLeapYear && month == .adar2 && day == purimDay)
    }

    /// `true` on the holiday of Shushan Purim on the 15th day of Adar (or Adar II on leap years).
    public var isShushanPurim: Bool { (!isJewishLeapYear && month == .adar && day == 15) || (isJewishLeapYear && month == .adar2 && day == 15) }

    /// `true` on the holiday of Purim Katan on the 14th day of Adar I on a leap year when Purim is on Adar II, a minor
    /// holiday.
    public var isPurimKatan: Bool { isJewishLeapYear && month == .adar && day == 14 }

    /// `true` on the holiday of Purim Katan on the 15th day of Adar I on a leap year when Purim is on Adar II, a minor
    /// holiday.
    public var isShushanPurimKatan: Bool { isJewishLeapYear && month == .adar && day == 15 }

    /// Returns true if the current day is *Isru Chag*. The method returns true for the day following *Pesach* *Shavuos*
    /// and *Succos*. It utilizes `isInIsrael` to return the proper date.
    ///
    /// - Returns: true if the current day is *Isru Chag*. The method returns true for the day following *Pesach*
    ///   *Shavuos* and *Succos*. It utilizes `isInIsrael` to return the proper date.
    public var isIsruChag: Bool {
        switch month {
        case .nissan: return (day == 22 && isInIsrael) || (day == 23 && !isInIsrael)
        case .sivan: return (day == 7 && isInIsrael) || (day == 8 && !isInIsrael)
        case .tishrei: return (day == 23 && isInIsrael) || (day == 24 && !isInIsrael)
        default: return false
        }
    }
    
    /// Checked in order, so that on days matching more than one entry the more specific one wins
    /// (Hoshana Rabba over Chol Hamoed, Chanukah over Rosh Chodesh). A `Dictionary` has no stable order.
    private static let chagCheckers: [(JewishHoliday, (JewishCalendar) -> Bool)] = [
        (.erevPesach, { cal in cal.isErevPesach }),
        (.pesach, { cal in cal.isPesach }),
        (.cholHamoedPesach, { cal in cal.isCholHamoedPesach }),
        (.pesachSheni, { cal in cal.isPesachSheni }),
        (.erevShavuos, { cal in cal.isErevShavuos }),
        (.shavuos, { cal in cal.isShavuos }),
        (.seventeenthOfTammuz, { cal in cal.isSeventeenthOfTammuz }),
        (.tishaBeav, { cal in cal.isTishaBeav }),
        (.tuBeav, { cal in cal.isTuBeav }),
        (.erevRoshHashana, { cal in cal.isErevRoshHashana }),
        (.roshHashana, { cal in cal.isRoshHashana }),
        (.fastOfGedalia, { cal in cal.isFastOfGedalia }),
        (.erevYomKippur, { cal in cal.isErevYomKippur }),
        (.yomKippur, { cal in cal.isYomKippur }),
        (.erevSuccos, { cal in cal.isErevSuccos }),
        (.succos, { cal in cal.isSuccos }),
        (.hoshanaRabba, { cal in cal.isHoshanaRabba }),
        (.cholHamoedSuccos, { cal in cal.isCholHamoedSuccos }),
        (.sheminiAtzeres, { cal in cal.isSheminiAtzeres }),
        (.simchasTorah, { cal in cal.isSimchasTorah }),
        (.erevChanukah, { cal in cal.isErevChanukah }),
        (.chanukah, { cal in cal.isChanukah }),
        (.tenthOfTeves, { cal in cal.isTenthOfTeves }),
        (.tuBeshvat, { cal in cal.isTuBeshvat }),
        (.fastOfEsther, { cal in cal.isFastOfEsther }),
        (.purim, { cal in cal.isPurim }),
        (.shushanPurim, { cal in cal.isShushanPurim }),
        (.purimKatan, { cal in cal.isPurimKatan }),
        (.yomHashoah, { cal in cal.isYomHashoah }),
        (.yomHazikaron, { cal in cal.isYomHazikaron }),
        (.yomHaatzmaut, { cal in cal.isYomHaatzmaut }),
        (.yomYerushalaim, { cal in cal.isYomYerushalaim }),
        (.lagBaomer, { cal in cal.isLagBaomer }),
        (.shushanPurimKatan, { cal in cal.isShushanPurimKatan }),
        (.isruChag, { cal in cal.isIsruChag }),
        (.erevRoshChodesh, { cal in cal.isErevRoshChodesh }),
        (.roshChodesh, { cal in cal.isRoshChodesh })
    ]
    
    /// Returns an index of the Jewish holiday or fast day for the current day, or a -1 if there is no holiday for this
    /// day. There are constants in this class representing each *Yom Tov*. Formatting of the *Yomim tovim* is done in
    /// the `formatYomTov()`.
    ///
    /// - ToDo: Consider using enums instead of the constant ints.
    /// - Returns: the index of the holiday such as the constant `isLagBaomer` or `YOM_KIPPUR` or a -1 if it is not a
    ///   holiday.
    /// - SeeAlso: `formatYomTov()`
    public func getCurrentChag() -> JewishHoliday? {
        for (chag, isChag) in JewishCalendar.chagCheckers {
            if isChag(self) {
                return chag
            }
        }
        
        return nil
    }
    
    /// Returns true if the current day is *Yom Tov*. The method returns true even for holidays such as `CHANUKAH` and
    /// minor ones such as `isTuBeav` and `isPesachSheni`. *Erev Yom Tov* (with the exception of `HOSHANA_RABBA`, *erev*
    /// the second days of `PESACH`) returns false, as do fast days besides `YOM_KIPPUR`. Use `isAssurBemelacha` to find
    /// the days that have a prohibition of work.
    ///
    /// - Returns: true if the current day is a Yom Tov
    /// - SeeAlso: `getCurrentChag()`, `isErevYomTov`, `isErevYomTovSheni`, `isTaanis`, `isAssurBemelacha`,
    ///   `isCholHamoed`
    public var isYomTov: Bool {
        // Rosh Chodesh, Erev Rosh Chodesh and Erev Chanukah are not part of KosherJava's getYomTovIndex()
        guard let chag = getCurrentChag(), ![.roshChodesh, .erevRoshChodesh, .erevChanukah].contains(chag) else {
            return false
        }
        
        let isExcludedChag = (isErevYomTov && !isHoshanaRabba)
            || (isTaanis && !isYomKippur)
            || isIsruChag
        
        return !isExcludedChag
    }
    
    /// Returns true if the *Yom Tov* day has a *melacha* (work) prohibition. This method will return false for a
    /// non-*Yom Tov* day, even if it is *Shabbos*.
    ///
    /// - Returns: if the *Yom Tov* day has a *melacha* (work) prohibition.
    public var isYomTovAssurBemelacha: Bool { isPesach || isShavuos || isSuccos || isSheminiAtzeres || isSimchasTorah || isRoshHashana || isYomKippur }
    
    /// Returns true if it is *Shabbos* or if it is a *Yom Tov* day that has a *melacha* (work) prohibition.
    ///
    /// - Returns: if the day is a *Yom Tov* that is *assur bemlacha* or *Shabbos*
    public var isAssurBemelacha: Bool { dow == .saturday || isYomTovAssurBemelacha }
    
    /// Returns true if tomorrow is *Shabbos* or *Yom Tov*. This will return true on *Erev Shabbos*, *Erev Yom Tov*, the
    /// first day of *Rosh Hashana* and *erev* the first days of *Yom Tov* out of Israel. It is identical to calling
    /// KosherJava's `hasCandleLighting()`.
    ///
    /// - Returns: will return if the next day is *Shabbos* or *Yom Tov*.
    public var isTomorrowShabbosOrYomTov: Bool { dow == .friday || isErevYomTov || isErevYomTovSheni }
    
    /// Returns true if the day is the second day of *Yom Tov*. This impacts the second day of *Rosh Hashana* everywhere
    /// and the second days of Yom Tov in *chutz laaretz* (out of Israel).
    ///
    /// - Returns: if the day is the second day of *Yom Tov*.
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
    
    /// Returns true if the current day is *Aseres Yemei Teshuva*.
    ///
    /// - Returns: if the current day is *Aseres Yemei Teshuvah*
    public var isAseresYemeiTeshuva: Bool { month == .tishrei && day <= 10 }
    
    /// Returns true if the current day is *Chol Hamoed* of *Pesach* or *Succos*.
    ///
    /// - Returns: true if the current day is *Chol Hamoed* of *Pesach* or *Succos*
    /// - SeeAlso: `isYomTov`
    public var isCholHamoed: Bool { isCholHamoedPesach || isCholHamoedSuccos }
    
    /// Returns true if the current day is *Erev Yom Tov*. The method returns true for *Erev* - *Pesach* (first and last
    /// days), *Shavuos*, *Rosh Hashana*, *Yom Kippur*, *Succos* and *Hoshana Rabba*.
    ///
    /// - Returns: true if the current day is *Erev* - *Pesach*, *Shavuos*, *Rosh Hashana*, *Yom Kippur*, *Succos* and
    ///   *Hoshana Rabba*.
    /// - SeeAlso: `isYomTov`, `isErevYomTovSheni`
    public var isErevYomTov: Bool { isErevPesach || isErevShavuos || isErevRoshHashana || isErevYomKippur || isErevSuccos || isHoshanaRabba || (isCholHamoedPesach && day == 20) }
    
    /// Return true if the day is a Taanis (fast day). Return true for *17 of Tammuz*, *Tisha B'Av*, *Yom Kippur*, *Fast
    /// of Gedalyah*, *10 of Teves* and the *Fast of Esther*.
    ///
    /// - Returns: true if today is a fast day
    public var isTaanis: Bool { isSeventeenthOfTammuz || isTishaBeav || isYomKippur || isFastOfEsther || isFastOfGedalia || isTenthOfTeves }
    
    /// Return true if the day is *Taanis Bechoros* (on *Erev Pesach*). It will return true for the 14th of *Nissan* if
    /// it is not on *Shabbos*, or if the 12th of *Nissan* occurs on a Thursday.
    ///
    /// - Returns: true if today is *Taanis Bechoros*.
    public var isTaanisBechoros: Bool { month == .nissan && ((day == 14 && dow != .saturday) || (day == 12 && dow == .thursday)) }
    
    /// Returns the day of *Chanukah* or -1 if it is not *Chanukah*.
    ///
    /// - Returns: the day of *Chanukah* or -1 if it is not *Chanukah*.
    /// - SeeAlso: `isChanukah`
    public var dayOfChanukah: Int? {
        if !isChanukah { return nil }
        
        if month == .kislev {
            return day - 24
        } else {
            return isKislevShort ? day + 5 : day + 6
        }
    }
    
    /// Returns if the day is *Shabbos* and Sunday is *Rosh Chodesh* and the *haftorah* of Machar Chodesh is read.
    ///
    /// - ToDo: There is more to tweak in this method (it does not cover all cases and opinions), and it may be removed.
    /// - Returns: true if it is *Shabbos* and Sunday is *Rosh Chodesh* and the *haftorah* of Machar Chodesh is read.
    public var isMacharChodesh: Bool { dow == .saturday && (day == 30 || day == 29) }
    
    /// Returns if the day is *Shabbos Mevorchim*.
    ///
    /// - Returns: true if it is *Shabbos Mevorchim*.
    public var isShabbosMevorchim: Bool { dow == .saturday && month != .elul && day >= 23 && day <= 29 }
    
    /// Returns the int value of the *Omer* day or -1 if the day is not in the *Omer*.
    ///
    /// - Returns: The *Omer* count as an int or -1 if it is not a day of the *Omer*.
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

    // Added as hours, not days, so a DST change between the molad and the zman doesn't move it by an hour
    /// Returns the earliest time of *Kiddush Levana* calculated as 3 days after the molad. This method returns the time
    /// even if it is during the day when *Kiddush Levana* can't be said. Callers of this method should consider
    /// displaying the next *tzais* if the *zman* is between *alos* and *tzais*.
    ///
    /// - Returns: the Date representing the moment 3 days after the molad.
    /// - SeeAlso: `earliestKiddushLevana3Days`
    public var earliestKiddushLevana3Days: Date? { moladDate?.gregDate.withAdded(hours: 72) }

    /// Returns the earliest time of *Kiddush Levana* calculated as 7 days after the *molad* as mentioned by the
    /// [Mechaber](http://en.wikipedia.org/wiki/Yosef_Karo). See the [Bach's](http://en.wikipedia.org/wiki/Yoel_Sirkis)
    /// opinion on this time. This method returns the time even if it is during the day when *Kiddush Levana* can't be
    /// said. Callers of this method should consider displaying the next *tzais* if the *zman* is between *alos* and
    /// *tzais*.
    ///
    /// - Returns: the Date representing the moment 7 days after the molad.
    /// - SeeAlso: `earliestKiddushLevana7Days`
    public var earliestKiddushLevana7Days: Date? { moladDate?.gregDate.withAdded(hours: 168) }

    /// Returns the latest time of Kiddush Levana according to the
    /// [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) opinion that it is calculated as halfway
    /// between *molad* and *molad*. This adds half the 29 days, 12 hours and 793 *chalakim* time between *molad* and
    /// *molad* (14 days, 18 hours, 22 minutes and 666 milliseconds) to the month's *molad*. This method returns the
    /// time even if it is during the day when *Kiddush Levana* can't be recited. Callers of this method should consider
    /// displaying *alos* before this time if the *zman* is between *alos* and *tzais*.
    ///
    /// - Returns: the Date representing the moment halfway between *molad* and *molad*.
    /// - SeeAlso: `latestKiddushLevana15Days`, `latestZmanKidushLevanaBetweenMoldos`
    public var latestZmanKidushLevanaBetweenMoldos: Date? { moladDate?.gregDate.withAdded(hours: 24 * 14 + 18, minutes: 22, seconds: 1, milliseconds: 666) }

    /// Returns the latest time of *Kiddush Levana* calculated as 15 days after the *molad.* This is the opinion brought
    /// down in the Shulchan Aruch (Orach Chaim 426). It should be noted that some opinions hold that the
    /// [Rema](http://en.wikipedia.org/wiki/Moses_Isserles) who brings down the the
    /// [Maharil's](http://en.wikipedia.org/wiki/Yaakov_ben_Moshe_Levi_Moelin) opinion of calculating it as half way
    /// between *molad* and *molad* is of the opinion of the Mechaber as well. Also see the Aruch Hashulchan. For
    /// additional details on the subject, See Rabbi Dovid Heber's very detailed writeup in Siman Daled (chapter 4) of
    /// [Shaarei Zmanim](http://www.worldcat.org/oclc/461326125). This method returns the time even if it is during the
    /// day when *Kiddush Levana* can't be said. Callers of this method should consider displaying *alos* before this
    /// time if the *zman* is between *alos* and *tzais*.
    ///
    /// - Returns: the Date representing the moment 15 days after the *molad*.
    /// - SeeAlso: `latestZmanKidushLevanaBetweenMoldos`, `latestKiddushLevana15Days`
    public var latestKiddushLevana15Days: Date? { moladDate?.gregDate.withAdded(hours: 24 * 15) }
    
    /// Returns the *Daf Yomi (Bavli)* for the date that the calendar is set to. See KosherJava's
    /// `HebrewDateFormatter.formatDafYomiBavli()` for the ability to format the *daf* in Hebrew or transliterated
    /// *masechta* names.
    ///
    /// - Returns: the daf as a `Daf`
    public var dafYomiBavli: Daf? { DafYomiCalculator.getDafYomiBavli(cal: self) }

    /// Returns the *Daf Yomi (Yerushalmi)* for the date that the calendar is set to. See KosherJava's
    /// `HebrewDateFormatter.formatDafYomiYerushalmi()` for the ability to format the *daf* in Hebrew or transliterated
    /// *masechta* names.
    ///
    /// - Returns: the daf as a `Daf`
    public var dafYomiYerushalmi: Daf? { DafYomiCalculator.getDafYomiYerushalmi(cal: self) }

    /// Returns if *Mashiv Haruach Umorid Hageshem* is recited. This period starts on 22 *Tishrei* and ends on the 15th
    /// day of *Nissan*.
    ///
    /// - Important: Deprecated in KosherJava. Use `isMashivHaruachRecited()` instead. This method will be removed in
    ///   the v3.0 release.
    /// - Returns: true if *Mashiv Haruach Umorid Hageshem* is recited.
    /// - SeeAlso: `isMashivHaruachStartDate`, `isMashivHaruachEndDate`
    public var isMashivHaruachRecited: Bool {
        let start = JewishDate(withJewishYear: year, andMonth: .tishrei, andDay: 22)
        let end = JewishDate(withJewishYear: year, andMonth: .nissan, andDay: 15)
        
        return gregDate > start.gregDate && gregDate < end.gregDate
    }
    
    /// Returns if *Vesein Tal Umatar Livracha* (*Sheailas Geshamim*) is recited. This will return true for the entire
    /// season, even on *Shabbos* when it is not recited.
    ///
    /// - Important: Deprecated in KosherJava. Use `isVeseinTalUmatarRecited()` instead. This method will be removed in
    ///   the v3.0 release.
    /// - Returns: true if *Vesein Tal Umatar Livracha* (*Sheailas Geshamim*) is recited.
    /// - SeeAlso: `isVeseinTalUmatarStartDate()`, `isVeseinTalUmatarStartingTonight()`
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
    
    /// Returns if the date is the start date for reciting *Mashiv Haruach Umorid Hageshem*. The date is 22 *Tishrei*.
    ///
    /// - Important: Deprecated in KosherJava. Use `isMashivHaruachStartDate` instead. This method will be removed in
    ///   the v3.0 release.
    /// - Returns: true if the date is the start date for reciting *Mashiv Haruach Umorid Hageshem*.
    /// - SeeAlso: `isMashivHaruachEndDate`, `isMashivHaruachRecited`
    public var isMashivHaruachStartDate: Bool { return month == .tishrei && day == 22 }

    /// Returns if the date is the end date for reciting *Mashiv Haruach Umorid Hageshem*. The date is 15 *Nissan*.
    ///
    /// - Important: Deprecated in KosherJava. Use `isMashivHaruachEndDate` instead. This method will be removed in the
    ///   v3.0 release.
    /// - Returns: true if the date is the end date for reciting *Mashiv Haruach Umorid Hageshem*.
    /// - SeeAlso: `isMashivHaruachStartDate`, `isMashivHaruachRecited`
    public var isMashivHaruachEndDate: Bool { return month == .nissan && day == 15 }
    
    /// Returns if *Vesein Beracha* is recited. It is recited from 15 *Nissan* to the point that *vesein tal umatar* is
    /// recited.
    ///
    /// - Important: Deprecated in KosherJava. Use `isVeseinBerachaRecited()` instead. This method will be removed in
    ///   the v3.0 release.
    /// - Returns: true if *Vesein Beracha* is recited.
    /// - SeeAlso: `isVeseinTalUmatarRecited`
    public var isVeseinBerachaRecited: Bool { !isVeseinTalUmatarRecited }

    /// Returns if *Morid Hatal* (or the lack of reciting *Mashiv Haruach* following *nussach Ashkenaz*) is recited.
    /// This period starts on 22 *Tishrei* and ends on the 15th day of *Nissan*.
    ///
    /// - Important: Deprecated in KosherJava. Use `isMoridHatalRecited()` instead. This method will be removed in the
    ///   v3.0 release.
    /// - Returns: true if *Morid Hatal* (or the lack of reciting *Mashiv Haruach* following *nussach Ashkenaz*) is
    ///   recited.
    public var isMoridHatalRecited: Bool { !isMashivHaruachRecited || isMashivHaruachStartDate || isMashivHaruachEndDate }
    
    public var tomorrow: JewishCalendar {
        let tomorrow = JewishCalendar(date: gregDate.withAdded(days: 1)!, isInIsrael: isInIsrael)
        tomorrow.isMukafChoma = isMukafChoma
        return tomorrow
    }
    
    public var yesterday: JewishCalendar {
        let yesterday = JewishCalendar(date: gregDate.withAdded(days: -1)!, isInIsrael: isInIsrael)
        yesterday.isMukafChoma = isMukafChoma
        return yesterday
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
    
    /// Returns the number of days of a Jewish month for a given month and year.
    ///
    /// - Returns: the number of days for a given Jewish month
    public var daysInJewishMonth: Int {
        getDaysInJewishMonth(month: month)
    }
}
