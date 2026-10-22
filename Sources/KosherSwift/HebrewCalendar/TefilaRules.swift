//
//  File.swift
//
//
//  Created by Daniel Smith on 12/29/23.
//

import Foundation

/// Tefila Rules is a utility class that covers the various *halachos* and *minhagim* regarding changes to daily
/// *tefila* / prayers, based on the Jewish calendar. This is mostly useful for use in developing *siddur* type
/// applications, but it is also valuable for *shul* calendars that set *tefila* times based on if
/// [*tachanun*](https://en.wikipedia.org/wiki/Tachanun) is recited that day. There are many settings in this class to
/// cover the vast majority of *minhagim*, but there are likely some not covered here. The source for many of the
/// *chasidishe minhagim* can be found in the [Minhag Yisrael
/// Torah](https://www.nli.org.il/he/books/NNL_ALEPH001141272/NLI) on Orach Chaim 131. Dates used in specific
/// communities such as specific *yahrzeits* or a holidays like Purim Mezhbizh (Medzhybizh) celebrated on 11 *Teves* or
/// [Purim Saragossa](https://en.wikipedia.org/wiki/Second_Purim#Purim_Saragossa_(18_Shevat)) celebrated on the (17th
/// or) 18th of *Shevat* are not (and likely will not be) supported by this class.
///
/// Sample code:
///
/// ```swift
/// let hdf = HebrewDateFormatter()
/// let roshHashana = JewishCalendar(withJewishYear: 5783, andMonth: .tishrei, andDay: 1)
/// print(try hdf.formatDate(roshHashana) + ": \(TefilaRules(roshHashana).isTachanunRecitedShacharis())")
/// let adar17 = JewishCalendar(withJewishYear: 5783, andMonth: .adar, andDay: 17)
/// print(try hdf.formatDate(adar17) + ": \(TefilaRules(adar17).isTachanunRecitedShacharis())")
/// let rules = TefilaRules(adar17, tachanunRecitedWeekOfPurim: false)
/// print(try hdf.formatDate(adar17) + ": \(rules.isTachanunRecitedShacharis())")
/// ```
///
/// - ToDo: The following items may be added at a future date. - *Lamnatzaiach* - *Mizmor Lesoda* - *Behab* - *Selichos*
///   - ...
public class TefilaRules {
    let cal: JewishCalendar
    
    /// The default value is `true`.
    public let tachanunRecitedEndOfTishrei: Bool

    /// The default value is `false`.
    public let tachanunRecitedWeekAfterShavuos: Bool

    /// The default value is `true`.
    public let tachanunRecited13SivanOutOfIsrael: Bool

    /// The default value is `false`.
    public let tachanunRecitedPesachSheni: Bool

    /// The default value is `true`.
    public let tachanunRecited15IyarOutOfIsrael: Bool

    /// The default value is `false`.
    public let tachanunRecitedMinchaErevLagBaomer: Bool

    /// The default value is `true`.
    public let tachanunRecitedShivasYemeiHamiluim: Bool

    /// The default value is `true`.
    public let tachanunRecitedWeekOfHod: Bool

    /// The default value is `true`.
    public let tachanunRecitedWeekOfPurim: Bool

    /// The default value is `true`.
    public let tachanunRecitedFridays: Bool

    /// The default value is `true`.
    public let tachanunRecitedSundays: Bool

    /// The default value is `true`.
    public let tachanunRecitedMinchaAllYear: Bool

    /// The default value is `false`.
    ///
    /// - SeeAlso: `isMizmorLesodaRecited()`
    public let mizmorLesodaRecitedErevYomKippurAndPesach: Bool
    
    private let mashivHaruachStart: Date
    private let mashivHaruachEnd: Date
    
    public init(_ cal: JewishCalendar, tachanunRecitedEndOfTishrei: Bool = true, tachanunRecitedWeekAfterShavuos: Bool = false, tachanunRecited13SivanOutOfIsrael: Bool = true, tachanunRecitedPesachSheni: Bool = false, tachanunRecited15IyarOutOfIsrael: Bool = true, tachanunRecitedMinchaErevLagBaomer: Bool = false, tachanunRecitedShivasYemeiHamiluim: Bool = true, tachanunRecitedWeekOfHod: Bool = true, tachanunRecitedWeekOfPurim: Bool = true, tachanunRecitedFridays: Bool = true, tachanunRecitedSundays: Bool = true, tachanunRecitedMinchaAllYear: Bool = true, mizmorLesodaRecitedErevYomKippurAndPesach: Bool = false) {
        self.cal = cal
        
        self.tachanunRecitedEndOfTishrei = tachanunRecitedEndOfTishrei
        self.tachanunRecitedWeekAfterShavuos = tachanunRecitedWeekAfterShavuos
        self.tachanunRecited13SivanOutOfIsrael = tachanunRecited13SivanOutOfIsrael
        self.tachanunRecitedPesachSheni = tachanunRecitedPesachSheni
        self.tachanunRecited15IyarOutOfIsrael = tachanunRecited15IyarOutOfIsrael
        self.tachanunRecitedMinchaErevLagBaomer = tachanunRecitedMinchaErevLagBaomer
        self.tachanunRecitedShivasYemeiHamiluim = tachanunRecitedShivasYemeiHamiluim
        self.tachanunRecitedWeekOfHod = tachanunRecitedWeekOfHod
        self.tachanunRecitedWeekOfPurim = tachanunRecitedWeekOfPurim
        self.tachanunRecitedFridays = tachanunRecitedFridays
        self.tachanunRecitedSundays = tachanunRecitedSundays
        self.tachanunRecitedMinchaAllYear = tachanunRecitedMinchaAllYear
        self.mizmorLesodaRecitedErevYomKippurAndPesach = mizmorLesodaRecitedErevYomKippurAndPesach
        
        self.mashivHaruachStart = JewishDate(withJewishYear: cal.year, andMonth: .tishrei, andDay: 22).gregDate
        self.mashivHaruachEnd = JewishDate(withJewishYear: cal.year, andMonth: .nissan, andDay: 15).gregDate
    }
    
    /// Returns if *tachanun* is recited during *shacharis* on the day in question. See the many *minhag* based settings
    /// that are available in this class.
    ///
    /// - Returns: if *tachanun* is recited during *shacharis*.
    /// - SeeAlso: `isTachanunRecitedMincha()`
    public func isTachanunRecitedShacharis() -> Bool {
        TefilaRules.isTachanunRecitedShacharis(cal: cal, rules: self)
    }
    
    public func copy(withCal cal: JewishCalendar) -> TefilaRules {
        TefilaRules(cal, tachanunRecitedEndOfTishrei: tachanunRecitedEndOfTishrei, tachanunRecitedWeekAfterShavuos: tachanunRecitedWeekAfterShavuos, tachanunRecited13SivanOutOfIsrael: tachanunRecited13SivanOutOfIsrael, tachanunRecitedPesachSheni: tachanunRecitedPesachSheni, tachanunRecited15IyarOutOfIsrael: tachanunRecited15IyarOutOfIsrael, tachanunRecitedMinchaErevLagBaomer: tachanunRecitedMinchaErevLagBaomer, tachanunRecitedShivasYemeiHamiluim: tachanunRecitedShivasYemeiHamiluim, tachanunRecitedWeekOfHod: tachanunRecitedWeekOfHod, tachanunRecitedWeekOfPurim: tachanunRecitedWeekOfPurim, tachanunRecitedFridays: tachanunRecitedFridays, tachanunRecitedSundays: tachanunRecitedSundays, tachanunRecitedMinchaAllYear: tachanunRecitedMinchaAllYear, mizmorLesodaRecitedErevYomKippurAndPesach: mizmorLesodaRecitedErevYomKippurAndPesach)
    }
    
    private static func isTachanunRecitedShacharis(cal: JewishCalendar, rules: TefilaRules) -> Bool {
        let day = cal.day
        let month = cal.month
        let dow = cal.dow
        
        let notRecited = dow == .saturday
        || (!rules.tachanunRecitedSundays && dow == .sunday)
        || (!rules.tachanunRecitedFridays && dow == .friday)
        || month == .nissan
        || (month == .tishrei && ((!rules.tachanunRecitedEndOfTishrei && day > 8) || (rules.tachanunRecitedEndOfTishrei && day > 8 && day < 22)))
        || (month == .sivan && ((rules.tachanunRecitedWeekAfterShavuos && day < 7) || (!rules.tachanunRecitedWeekAfterShavuos && day < (!cal.isInIsrael && !rules.tachanunRecited13SivanOutOfIsrael ? 14 : 13))))
        || (cal.isYomTov && (!cal.isTaanis || (!rules.tachanunRecitedPesachSheni && cal.isPesachSheni)))
        || (!cal.isInIsrael && !rules.tachanunRecitedPesachSheni && !rules.tachanunRecited15IyarOutOfIsrael && month == .iyar && day == 15)
        || cal.isTishaBeav
        || cal.isIsruChag
        || cal.isRoshChodesh
        || (!rules.tachanunRecitedShivasYemeiHamiluim && ((!cal.isJewishLeapYear && month == .adar) || (cal.isJewishLeapYear && month == .adar2)) && day > 22)
        || (!rules.tachanunRecitedWeekOfPurim && ((!cal.isJewishLeapYear && month == .adar) || (cal.isJewishLeapYear && month == .adar2)) && day > 10 && day < 18)
        || (cal.isYomHaatzmaut || cal.isYomYerushalaim)
        || (!rules.tachanunRecitedWeekOfHod && month == .iyar && day > 13 && day < 21)
        
        return !notRecited
    }
    
    /// Returns if *tachanun* is recited during *mincha* on the day in question.
    ///
    /// - Returns: if *tachanun* is recited during *mincha*.
    /// - SeeAlso: `isTachanunRecitedShacharis()`
    public func isTachanunRecitedMincha() -> Bool {
        let tomorrow = JewishCalendar(date: cal.gregDate.withAdded(days: 1)!, isInIsrael: cal.isInIsrael)
        
        let notRecited = !tachanunRecitedMinchaAllYear
        || cal.dow == .friday
        || !isTachanunRecitedShacharis()
        || (!TefilaRules.isTachanunRecitedShacharis(cal: tomorrow, rules: self) && !tomorrow.isErevRoshHashana && !tomorrow.isErevYomKippur && !tomorrow.isPesachSheni)
        || (!tachanunRecitedMinchaErevLagBaomer && tomorrow.isLagBaomer)
        
        return !notRecited
    }
    
    /// Returns if it is the Jewish day (starting the evening before) to start reciting *Vesein Tal Umatar Livracha*
    /// (*Sheailas Geshamim*). In Israel this is the 7th day of *Marcheshvan*. Outside Israel recitation starts on the
    /// evening of December 4th (or 5th if it is the year before a civil leap year) in the 21st century and shifts a day
    /// forward every century not evenly divisible by 400. This method will return true if *vesein tal umatar* on the
    /// current Jewish date that starts on the previous night, so Dec 5/6 will be returned by this method in the 21st
    /// century. *vesein tal umatar* is not recited on *Shabbos* and the start date will be delayed a day when the start
    /// day is on a *Shabbos* (this can only occur out of Israel).
    ///
    /// - Returns: true if it is the first Jewish day (starting the prior evening of reciting *Vesein Tal Umatar
    ///   Livracha* (*Sheailas Geshamim*).
    /// - SeeAlso: `isVeseinTalUmatarStartingTonight()`, `isVeseinTalUmatarRecited`
    public func isVeseinTalUmatarStartDate() -> Bool {
        if cal.isInIsrael {
            return cal.month == .cheshvan && cal.day == 7
        } else {
            if cal.dow == .saturday { // not started on Friday night, so Shabbos can't be the start date
                return false
            }
            
            let elapsed = cal.tekufasTishreiElapsedDays
            if cal.dow == .sunday {
                return elapsed == 48 || elapsed == 47
            } else {
                return elapsed == 47
            }
        }
    }
    
    /// Returns if true if tonight is the first night to start reciting *Vesein Tal Umatar Livracha* ( *Sheailas
    /// Geshamim*). In Israel this is the 7th day of *Marcheshvan* (so the 6th will return true). Outside Israel
    /// recitation starts on the evening of December 4th (or 5th if it is the year before a civil leap year) in the 21st
    /// century and shifts a day forward every century not evenly divisible by 400. *Vesein tal umatar* is not recited
    /// on *Shabbos* and the start date will be delayed a day when the start day is on a *Shabbos* (this can only occur
    /// out of Israel).
    ///
    /// - Returns: true if it is the first Jewish day (starting the prior evening of reciting *Vesein Tal Umatar
    ///   Livracha* (*Sheailas Geshamim*).
    /// - SeeAlso: `isVeseinTalUmatarStartDate()`, `isVeseinTalUmatarRecited`
    public func isVeseinTalUmatarStartingTonight() -> Bool {
        if cal.isInIsrael {
            return cal.month == .cheshvan && cal.day == 6
        } else {
            if cal.dow == .friday {
                return false
            }
            
            let elapsed = cal.tekufasTishreiElapsedDays
            if cal.dow == .saturday {
                return elapsed == 47 || elapsed == 46
            } else {
                return elapsed == 46
            }
        }
    }
    
    /// Returns if *Vesein Beracha* is recited. It is recited from 15 *Nissan* to the point that *vesein tal umatar* is
    /// recited.
    ///
    /// - Returns: true if *Vesein Beracha* is recited.
    /// - SeeAlso: `isVeseinTalUmatarRecited`
    public func isVeseinBerachaRecited() -> Bool {
        !isVeseinTalUmatarRecited()
    }
    
    /// Returns if *Vesein Tal Umatar Livracha* (*Sheailas Geshamim*) is recited. This will return true for the entire
    /// season, even on *Shabbos* when it is not recited.
    ///
    /// - Returns: true if *Vesein Tal Umatar Livracha* (*Sheailas Geshamim*) is recited.
    /// - SeeAlso: `isVeseinTalUmatarStartDate()`, `isVeseinTalUmatarStartingTonight()`
    public func isVeseinTalUmatarRecited() -> Bool {
        if cal.month == .nissan && cal.day < 15 {
            return true
        } else if cal.month.rawValue < JewishMonth.cheshvan.rawValue {
            return false
        } else if cal.isInIsrael {
            return cal.month != .cheshvan || cal.day >= 7
        }
        
        return cal.tekufasTishreiElapsedDays >= 47
    }
    
    /// Returns if *Mashiv Haruach Umorid Hageshem* is recited. This period starts on 22 *Tishrei* and ends on the 15th
    /// day of *Nissan*.
    ///
    /// - Returns: true if *Mashiv Haruach Umorid Hageshem* is recited.
    /// - SeeAlso: `isMashivHaruachStartDate`, `isMashivHaruachEndDate`
    public func isMashivHaruachRecited() -> Bool {
        return cal.gregDate.isBetween(start: mashivHaruachStart, end: mashivHaruachEnd)
    }
    
    /// Returns if *Morid Hatal* (or the lack of reciting *Mashiv Haruach* following *nussach Ashkenaz*) is recited.
    /// This period starts on the 15th day of *Nissan* and ends on 22 *Tishrei*.
    ///
    /// - Returns: true if *Morid Hatal* (or the lack of reciting *Mashiv Haruach* following *nussach Ashkenaz*) is
    ///   recited.
    public func isMoridHatalRecited() -> Bool {
        return !isMashivHaruachRecited() || cal.gregDate.dateEquals(mashivHaruachStart) || cal.gregDate.dateEquals(mashivHaruachEnd)
    }
    
    /// Returns if *Hallel* is recited on the day in question. This will return true for both *Hallel shalem* and
    /// *Chatzi Hallel*. See `isHallelShalemRecited()` to know if the complete *Hallel* is recited.
    ///
    /// - Returns: if *Hallel* is recited.
    /// - SeeAlso: `isHallelShalemRecited()`
    public func isHallelRecited() -> Bool {
        cal.isRoshChodesh || cal.isChanukah
        || (cal.month == .nissan && (cal.day >= 15 && ((cal.isInIsrael && cal.day <= 21) || (!cal.isInIsrael && cal.day <= 22))))
        || cal.isYomHaatzmaut
        || cal.isYomYerushalaim
        || (cal.month == .sivan && (cal.day == 6 || (!cal.isInIsrael && cal.day == 7)))
        || (cal.month == .tishrei && (cal.day >= 15 && (cal.day <= 22 || (!cal.isInIsrael && cal.day <= 23))))
    }
    
    /// Returns if *hallel shalem* is recited on the day in question. This will always return false if
    /// `isHallelRecited()` returns false.
    ///
    /// - Returns: if *hallel shalem* is recited.
    /// - SeeAlso: `isHallelRecited()`
    public func isHallelShalemRecited() -> Bool {
        if !isHallelRecited() {
            return false
        }
        
        let notRecited = (cal.isRoshChodesh && !cal.isChanukah)
        || (cal.month == .nissan && ((cal.isInIsrael && cal.day > 15) || (!cal.isInIsrael && cal.day > 16)))
        
        return !notRecited
    }
    
    /// Returns if [*Al HaNissim*](https://en.wikipedia.org/wiki/Al_HaNissim) is recited on the day in question.
    ///
    /// - Returns: if *al hanissim* is recited.
    /// - SeeAlso: `isChanukah`
    public func isAlHanissimRecited() -> Bool {
        cal.isPurim || cal.isChanukah
    }
    
    /// Returns if *Yaaleh Veyavo* is recited on the day in question.
    ///
    /// - Returns: if *Yaaleh Veyavo* is recited.
    /// - SeeAlso: `isPesach`, `isShavuos`, `isRoshHashana`, `isYomKippur`, `isSuccos`, `isSimchasTorah`,
    ///   `isRoshChodesh`
    public func isYaalehVeyavoRecited() -> Bool {
        cal.isPesach || cal.isShavuos || cal.isRoshHashana || cal.isYomKippur || cal.isSuccos || cal.isSheminiAtzeres || cal.isSimchasTorah || cal.isRoshChodesh
    }
    
    /// Returns if Is *Mizmor Lesoda* is recited on the day in question.
    ///
    /// - Returns: if *Mizmor Lesoda* is recited.
    public func isMizmorLesodaRecited() -> Bool {
        if cal.isAssurBemelacha {
            return false
        }
        
        let notRecited = !mizmorLesodaRecitedErevYomKippurAndPesach
        && (cal.isErevYomKippur || cal.isErevPesach || cal.isCholHamoedPesach)
        
        return !notRecited
    }
}
