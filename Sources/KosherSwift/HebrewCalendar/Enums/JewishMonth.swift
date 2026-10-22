//
//  JewishMonth.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

public enum JewishMonth: Int {
    /// Value of the month field indicating Nissan, the first numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 7th (or 8th in a leap year) month of the year.
    case nissan = 1

    /// Value of the month field indicating Iyar, the second numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 8th (or 9th in a leap year) month of the year.
    case iyar

    /// Value of the month field indicating Sivan, the third numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 9th (or 10th in a leap year) month of the year.
    case sivan

    /// Value of the month field indicating Tammuz, the fourth numeric month of the year in the Jewish calendar. With
    /// the year starting at `JewishMonth.tishrei`, it would actually be the 10th (or 11th in a leap year) month of the
    /// year.
    case tammuz

    /// Value of the month field indicating Av, the fifth numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 11th (or 12th in a leap year) month of the
    /// year.
    case av

    /// Value of the month field indicating Elul, the sixth numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 12th (or 13th in a leap year) month of the
    /// year.
    case elul

    /// Value of the month field indicating Tishrei, the seventh numeric month of the year in the Jewish calendar. With
    /// the year starting at this month, it would actually be the 1st month of the year.
    case tishrei

    /// Value of the month field indicating Cheshvan/marcheshvan, the eighth numeric month of the year in the Jewish
    /// calendar. With the year starting at `JewishMonth.tishrei`, it would actually be the 2nd month of the year.
    case cheshvan

    /// Value of the month field indicating Kislev, the ninth numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 3rd month of the year.
    case kislev

    /// Value of the month field indicating Teves, the tenth numeric month of the year in the Jewish calendar. With the
    /// year starting at `JewishMonth.tishrei`, it would actually be the 4th month of the year.
    case teves

    /// Value of the month field indicating Shevat, the eleventh numeric month of the year in the Jewish calendar. With
    /// the year starting at `JewishMonth.tishrei`, it would actually be the 5th month of the year.
    case shevat

    /// Value of the month field indicating Adar (or Adar I in a leap year), the twelfth numeric month of the year in
    /// the Jewish calendar. With the year starting at `JewishMonth.tishrei`, it would actually be the 6th month of the
    /// year.
    case adar

    /// Value of the month field indicating Adar II, the leap (intercalary or embolismic) thirteenth (Undecimber)
    /// numeric month of the year added in Jewish leap year). The leap years are years 3, 6, 8, 11, 14, 17 and 19 of a
    /// 19 year cycle. With the year starting at `JewishMonth.tishrei`, it would actually be the 7th month of the year.
    case adar2
    
    private static let monthMap: [Int: JewishMonth] = [
        8: .nissan,
        9: .iyar,
        10: .sivan,
        11: .tammuz,
        12: .av,
        13: .elul,
        1: .tishrei,
        2: .cheshvan,
        3: .kislev,
        4: .teves,
        5: .shevat,
//        6: .adar,
//        7: .adar2
    ]
    
    private static let rMonthMap = monthMap.swapKeyValues()
    
    static func fromSwiftCalMonth(month: Int, isLeapYear: Bool) -> JewishMonth {
        if month == 7 || month == 6 {
            return isLeapYear && month == 7 ? .adar2 : .adar
        }
        
        return monthMap[month]!
    }
    
    func toSwiftCalMonth(_ isJewishLeapYear: Bool) -> Int {
        if self == .adar || self == .adar2 {
            return isJewishLeapYear && self == .adar ? 6 : 7
        }
        
        return JewishMonth.rMonthMap[self]!
    }
}

extension Dictionary where Value : Hashable {
    func swapKeyValues() -> [Value : Key] {
        assert(Set(self.values).count == self.keys.count, "Values must be unique")
        var newDict = [Value : Key]()
        for (key, value) in self {
            newDict[value] = key
        }
        return newDict
    }
}
