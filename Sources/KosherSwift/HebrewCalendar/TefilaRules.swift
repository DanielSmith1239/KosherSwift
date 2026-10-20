//
//  File.swift
//
//
//  Created by Daniel Smith on 12/29/23.
//

import Foundation

public class TefilaRules {
    let cal: JewishCalendar
    
    public let tachanunRecitedEndOfTishrei: Bool
    public let tachanunRecitedWeekAfterShavuos: Bool
    public let tachanunRecited13SivanOutOfIsrael: Bool
    public let tachanunRecitedPesachSheni: Bool
    public let tachanunRecited15IyarOutOfIsrael: Bool
    public let tachanunRecitedMinchaErevLagBaomer: Bool
    public let tachanunRecitedShivasYemeiHamiluim: Bool
    public let tachanunRecitedWeekOfHod: Bool
    public let tachanunRecitedWeekOfPurim: Bool
    public let tachanunRecitedFridays: Bool
    public let tachanunRecitedSundays: Bool
    public let tachanunRecitedMinchaAllYear: Bool
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
    
    public func isTachanunRecitedMincha() -> Bool {
        let tomorrow = JewishCalendar(date: cal.gregDate.withAdded(days: 1)!, isInIsrael: cal.isInIsrael)
        
        let notRecited = !tachanunRecitedMinchaAllYear
        || cal.dow == .friday
        || !isTachanunRecitedShacharis()
        || (!TefilaRules.isTachanunRecitedShacharis(cal: tomorrow, rules: self) && !tomorrow.isErevRoshHashana && !tomorrow.isErevYomKippur && !tomorrow.isPesachSheni)
        || (!tachanunRecitedMinchaErevLagBaomer && tomorrow.isLagBaomer)
        
        return !notRecited
    }
    
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
    
    public func isVeseinBerachaRecited() -> Bool {
        !isVeseinTalUmatarRecited()
    }
    
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
    
    public func isMashivHaruachRecited() -> Bool {
        return cal.gregDate.isBetween(start: mashivHaruachStart, end: mashivHaruachEnd)
    }
    
    public func isMoridHatalRecited() -> Bool {
        return !isMashivHaruachRecited() || cal.gregDate.dateEquals(mashivHaruachStart) || cal.gregDate.dateEquals(mashivHaruachEnd)
    }
    
    public func isHallelRecited() -> Bool {
        cal.isRoshChodesh || cal.isChanukah
        || (cal.month == .nissan && (cal.day >= 15 && ((cal.isInIsrael && cal.day <= 21) || (!cal.isInIsrael && cal.day <= 22))))
        || cal.isYomHaatzmaut
        || cal.isYomYerushalaim
        || (cal.month == .sivan && (cal.day == 6 || (!cal.isInIsrael && cal.day == 7)))
        || (cal.month == .tishrei && (cal.day >= 15 && (cal.day <= 22 || (!cal.isInIsrael && cal.day <= 23))))
    }
    
    public func isHallelShalemRecited() -> Bool {
        if !isHallelRecited() {
            return false
        }
        
        let notRecited = (cal.isRoshChodesh && !cal.isChanukah)
        || (cal.month == .nissan && ((cal.isInIsrael && cal.day > 15) || (!cal.isInIsrael && cal.day > 16)))
        
        return !notRecited
    }
    
    public func isAlHanissimRecited() -> Bool {
        cal.isPurim || cal.isChanukah
    }
    
    public func isYaalehVeyavoRecited() -> Bool {
        cal.isPesach || cal.isShavuos || cal.isRoshHashana || cal.isYomKippur || cal.isSuccos || cal.isSheminiAtzeres || cal.isSimchasTorah || cal.isRoshChodesh
    }
    
    public func isMizmorLesodaRecited() -> Bool {
        if cal.isAssurBemelacha {
            return false
        }
        
        let notRecited = !mizmorLesodaRecitedErevYomKippurAndPesach
        && (cal.isErevYomKippur || cal.isErevPesach || cal.isCholHamoedPesach)
        
        return !notRecited
    }
}
