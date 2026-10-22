//
//  DafYomiCalculator.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/21/23.
//

import Foundation

/// This class calculates the Daf Yomi Bavli page (daf) for a given date. To calculate Daf Yomi Yerushalmi use the
/// `YerushalmiYomiCalculator`. The library may cover Mishna Yomi etc. at some point in the future.
public class DafYomiCalculator {
    private static let dafYomiStart = Calendar.current.date(from: DateComponents(year: 1923, month: 9, day: 11))!
	private static let dafYomiJulianStart = NOAACalculator.getJulianDay(dateTime: dafYomiStart, timeZone: .current)
    private static let shekalimChangeDay = Calendar.current.date(from: DateComponents(year: 1975, month: 6, day: 24))!
	private static let shekalimJulianChangeDay = NOAACalculator.getJulianDay(dateTime: shekalimChangeDay, timeZone: .current)
    
    private static let dafYomiYerushalmiStart = Calendar.current.date(from: DateComponents(year: 1980, month: 2, day: 2))!
    private static let dayMillis = 1000 * 60 * 60 * 24
    private static let wholeShasDafsYerushalmi = 1554
    
    private static let blattPerMasechtaBavli = [ 64, 157, 105, 121, 22, 88, 56, 40, 35, 31, 32, 29, 27, 122, 112, 91, 66, 49, 90, 82, 119, 119, 176, 113, 24, 49, 76, 14, 120, 110, 142, 61, 34, 34, 28, 22, 4, 9, 5, 73]
    
    private static let blattPerMasechtaYerushalmi = [ 68, 37, 34, 44, 31, 59, 26, 33, 28, 20, 13, 92, 65, 71, 22, 22, 42, 26, 26, 33, 34, 22, 19, 85, 72, 47, 40, 47, 54, 48, 44, 37, 34, 44, 9, 57, 37, 19, 13 ]
    
    /// Returns the [Daf Yomi](http://en.wikipedia.org/wiki/Daf_yomi) [Bavli](http://en.wikipedia.org/wiki/Talmud) `Daf`
    /// for a given date. The first Daf Yomi cycle started on Rosh Hashana 5684 (September 11, 1923) and calculations
    /// prior to this date will result in an IllegalArgumentException thrown. For historical calculations (supported by
    /// this method), it is important to note that a change in length of the cycle was instituted starting in the eighth
    /// Daf Yomi cycle beginning on June 24, 1975. The Daf Yomi Bavli cycle has a single masechta of the Talmud
    /// Yerushalmi - Shekalim as part of the cycle. Unlike the Bavli where the number of daf per masechta was
    /// standardized since the original [Bomberg Edition](http://en.wikipedia.org/wiki/Daniel_Bomberg) published from
    /// 1520 - 1523, there is no uniform page length in the Yerushalmi. The early cycles had the Yerushalmi Shekalim
    /// length of 13 days following the
    /// [Slavuta/Zhytomyr](https://he.wikipedia.org/wiki/%D7%93%D7%A4%D7%95%D7%A1_%D7%A1%D7%9C%D7%90%D7%95%D7%95%D7%99%D7%98%D7%90)
    /// Shas used by [Rabbi Meir Shapiro](http://en.wikipedia.org/wiki/Meir_Shapiro). With the start of the eighth Daf
    /// Yomi cycle beginning on June 24, 1975 the length of the Yerushalmi Shekalim was changed from 13 to 22 daf to
    /// follow the [Vilna Shas](https://en.wikipedia.org/wiki/Vilna_Edition_Shas) that is in common use today.
    ///
    /// - Parameter cal: The JewishCalendar date for calculation. TODO: this can be changed to use a regular
    ///   GregorianCalendar since there is nothing specific to the JewishCalendar in this class.
    /// - Returns: the `Daf`.
    public static func getDafYomiBavli(cal: JewishCalendar) -> Daf? {
        /*
         * The number of daf per masechta. Since the number of blatt in Shekalim changed on the 8th Daf Yomi cycle
         * beginning on June 24, 1975 from 13 to 22, the actual calculation for blattPerMasechta[4] will later be
         * adjusted based on the cycle.
         */
        var blattPerMasechta = blattPerMasechtaBavli
        
        let calendar = cal.gregDate
        
		let julianDay = Int(NOAACalculator.getJulianDay(dateTime: calendar, timeZone: .current))
        var cycleNo = 0
        var dafNo = 0
        if (calendar.compare(dafYomiStart) == .orderedAscending) {
            return nil
        }
        if (calendar.compare(shekalimChangeDay) == .orderedSame || calendar.compare(shekalimChangeDay) == .orderedDescending) {
            cycleNo = 8 + ((julianDay - Int(shekalimJulianChangeDay)) ~/ 2711)
            dafNo = (julianDay - Int(shekalimJulianChangeDay)) % 2711
        } else {
            cycleNo = 1 + ((julianDay - Int(dafYomiJulianStart)) ~/ 2702)
            dafNo = (julianDay - Int(dafYomiJulianStart)) % 2702
        }
        
        var total = 0
        var masechta = -1
        var blatt = 0
        
        // Fix Shekalim for old cycles.
        if (cycleNo <= 7) {
            blattPerMasechta[4] = 13
        } else {
            blattPerMasechta[4] = 22 // correct any change that may have been changed from a prior calculation
        }
        
        // Finally find the daf.
        for j in 0..<blattPerMasechta.count {
            masechta += 1
            total = total + blattPerMasechta[j] - 1
            if (dafNo < total) {
                blatt = 1 + blattPerMasechta[j] - (total - dafNo)
                // Fiddle with the weird ones near the end.
                if (masechta == 36) {
                    blatt += 21
                } else if (masechta == 37) {
                    blatt += 24
                } else if (masechta == 38) {
                    blatt += 32
                }
                return Daf(masechta: masechta, daf: blatt, dafType: .bavli)
            }
        }
        
        return nil
    }
    
    /// Returns the [Daf Yomi](https://en.wikipedia.org/wiki/Daf_Yomi)
    /// [Yerusalmi](https://en.wikipedia.org/wiki/Jerusalem_Talmud) page (`Daf`) for a given date. The first Daf Yomi
    /// cycle started on 15 Shevat (Tu Bishvat), 5740 (February, 2, 1980) and calculations prior to this date will
    /// result in an IllegalArgumentException thrown. nil will be returned on Tisha B'Av or Yom Kippur.
    ///
    /// - Parameter cal: the calendar date for calculation
    /// - Returns: the `Daf` or nil if the date is on Tisha B'Av or Yom Kippur.
    public static func getDafYomiYerushalmi(cal: JewishCalendar) -> Daf? {
        var masechta = 0
        
        // There isn't Daf Yomi on Yom Kippur or Tisha B'Av.
        if cal.isYomKippur || cal.isTishaBeav || cal.gregDate < dafYomiYerushalmiStart {
            return nil
        }
        
        var nextCycle = Date(year: 1980, month: 2, day: 2)
        var prevCycle = Date(year: 1900, month: 1, day: 1)

        // Go cycle by cycle, until we get the next cycle
        while nextCycle < cal.gregDate {
            prevCycle = nextCycle
            
            nextCycle = nextCycle.withAdded(days: wholeShasDafsYerushalmi)!
            nextCycle = nextCycle.withAdded(days: getNumSpecialDays(start: prevCycle, end: nextCycle))!
        }
        
        // Get the number of days from cycle start until request.
        // Count calendar days, not 86400-second blocks, so a DST change in between doesn't lose a day
        let dafNo = Calendar.current.dateComponents([.day], from: prevCycle, to: cal.gregDate).day!
                
        // Get the number of special day to subtract
        let specialDays = getNumSpecialDays(start: prevCycle, end: cal.gregDate)
        var total = dafNo - specialDays
        
        // Finally find the daf.
        for len in blattPerMasechtaYerushalmi {
            if total < len {
                return Daf(masechta: masechta, daf: total + 1, dafType: .yerushalmi)
            }
            total -= len
            masechta += 1
        }
        
        return nil
    }
    
    private static func getNumSpecialDays(start: Date, end: Date) -> Int{
        let endYear = JewishDate(date: end).year
        
        var curYear = JewishDate(date: start).year
        var ret = 0
        while curYear <= endYear {
            // Yom Kippur
            if isAfter(start, onOrBefore: end, JewishDate(withJewishYear: curYear, andMonth: .tishrei, andDay: 10).gregDate) {
                ret += 1
            }
            
            // Tisha B'Av, pushed to Sunday when 9 Av is Shabbos
            var tishaBeav = JewishDate(withJewishYear: curYear, andMonth: .av, andDay: 9)
            if tishaBeav.dow == .saturday {
                tishaBeav = JewishDate(withJewishYear: curYear, andMonth: .av, andDay: 10)
            }
            if isAfter(start, onOrBefore: end, tishaBeav.gregDate) {
                ret += 1
            }
            
            curYear += 1
        }
        
        return ret
    }
    
    private static func isAfter(_ start: Date, onOrBefore end: Date, _ date: Date) -> Bool {
        start < date && date <= end
    }
}
