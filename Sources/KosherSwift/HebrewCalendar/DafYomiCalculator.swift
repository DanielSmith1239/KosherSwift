//
//  DafYomiCalculator.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/21/23.
//

import Foundation

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
