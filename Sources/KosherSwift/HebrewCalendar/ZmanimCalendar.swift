//
//  ZmanimCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/20/23.
//

import Foundation

typealias ZmanCalculator = () -> Date?

public class ZmanimCalendar: AstronomicalCalendar {
    let shouldUseElevation: Bool
    public let candleLightingOffset: Double
    
    public init(location: GeoLocation, date: Date, astronomicalCalculator: AstronomicalCalculator = NOAACalculator(), shouldUseElevation: Bool = false, candleLightingOffset: Double = 18) {
        self.shouldUseElevation = shouldUseElevation
        self.candleLightingOffset = candleLightingOffset
        super.init(location: location, date: date, astronomicalCalculator: astronomicalCalculator)
    }
    
    var elevationAdjustedSunrise: Date? { shouldUseElevation ? sunrise : seaLevelSunrise }
    var elevationAdjustedSunset: Date? { shouldUseElevation ? sunset : seaLevelSunset }
    
    // Zmanim
    public func tzeis() -> Date? { getSunsetOffsetByDegrees(offsetZenith: Zenith.z8_5) }
    public func alosHashachar() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_1) }
    public func alos72() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -72 * ZmanimCalendar.minuteMillis) }
    public func chatzos() -> Date? { getSunTransit() }
    public func latestShemaGra() -> Date? { calculateLatestZmanShema(elevationAdjustedSunrise, elevationAdjustedSunset) }
    public func latestShemaMga() -> Date? { calculateLatestZmanShema(alos72(), tzeis72()) }
    public func tzeis72() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 72 * AstronomicalCalendar.minuteMillis) }
    
    public func candleLighting() -> Date? {
        let todayCal = JewishCalendar(date: date)
        let yesterdayCal = JewishCalendar(date: date.withAdded(days: -1)!)
        if (todayCal.dow == .saturday && todayCal.isErevYomTov)
            || (todayCal.isRoshHashana && yesterdayCal.isErevYomTov)
            || (todayCal.isChanukah && todayCal.dow != .friday) {
            let offsetDate = getSunsetOffsetByDegrees(offsetZenith: .z7_083)
            return AstronomicalCalendar.getTimeOffset(time: offsetDate, offset: -13.5 * AstronomicalCalendar.hourMillis)
        } else if todayCal.dow == .friday || todayCal.isErevYomTov || todayCal.tomorrow.isAssurBemelacha {
            return AstronomicalCalendar.getTimeOffset(time: seaLevelSunset, offset: -candleLightingOffset * AstronomicalCalendar.minuteMillis)
        }
        
        return nil
    }
    
    public func latestTefilaGra() -> Date? { calculateLatestTefila(elevationAdjustedSunrise, elevationAdjustedSunset) }
    public func latestTefilaMga() -> Date? { calculateLatestTefila(alos72(), tzeis72()) }
    public func shaahZmanisGra() -> Double? { getTemporalHour(dayStart: elevationAdjustedSunrise, dayEnd: elevationAdjustedSunset) }
    public func shaahZmanisMga() -> Double? { getTemporalHour(dayStart: alos72(), dayEnd: tzeis72()) }
    
    // Helpers
    public func calculateLatestTefila(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let shaahZmanis = getTemporalHour(dayStart: dayStart ?? seaLevelSunrise!, dayEnd: dayEnd ?? seaLevelSunset!) else {
            return nil
        }
        return AstronomicalCalendar.getTimeOffset(time: dayStart, offset: shaahZmanis * 4)
    }
    
    public func calculateLatestZmanShema(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else {
            return calculateLatestZmanShema(seaLevelSunrise, seaLevelSunset)
        }
        return shaahZmanisBasedZman(dayStart, dayEnd, 3)
    }
    
    public func calculateMinchaKetana(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else {
            return calculateMinchaKetana(seaLevelSunrise, seaLevelSunset)
        }
        return shaahZmanisBasedZman(dayStart, dayEnd, 9.5)
    }
    
    public func calculatePlagHamincha(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else {
            return calculatePlagHamincha(seaLevelSunrise, seaLevelSunset)
        }
        return shaahZmanisBasedZman(dayStart, dayEnd, 10.75)
    }
    
    public func calculateMinchaGedolah(_ dayStart: Date? = nil, _ dayEnd: Date? = nil) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else {
            return calculateMinchaGedolah(seaLevelSunrise, seaLevelSunset)
        }
        return shaahZmanisBasedZman(dayStart, dayEnd, 6.5)
    }
    
    public func shaahZmanisBasedZman(_ startOfDay: Date, _ endOfDay: Date, _ hours: Double) -> Date? {
        guard let shaahZmanis = getTemporalHour(dayStart: startOfDay, dayEnd: endOfDay) else {
            return nil
        }
        return AstronomicalCalendar.getTimeOffset(time: startOfDay, offset: shaahZmanis * hours)
    }
    
    public func getHalfDayBasedZman(startOfHalfDay:Date?, endOfHalfDay:Date?, hours:Double) -> Date? {
        if (startOfHalfDay == nil || endOfHalfDay == nil) {
            return nil;
        }
        
        let shaahZmanis = getHalfDayBasedShaahZmanis(startOfHalfDay: startOfHalfDay, endOfHalfDay: endOfHalfDay)
        if (shaahZmanis == Int64.min) { //defensive, should not be needed
            return nil;
        }
        
        if hours >= 0 { // forward from start a day
            return ZmanimCalendar.getTimeOffset(time: startOfHalfDay, offset: (Double(shaahZmanis) * hours) * 1000)
        } else { // subtract from end of day
            return ZmanimCalendar.getTimeOffset(time: endOfHalfDay, offset: (Double(shaahZmanis) * hours) * 1000)
        }
    }
    
    public func getHalfDayBasedShaahZmanis(startOfHalfDay:Date?, endOfHalfDay:Date?) -> Int64 {
        if (startOfHalfDay == nil || endOfHalfDay == nil) {
            return Int64.min;
        }
        return Int64((endOfHalfDay!.timeIntervalSince1970 - startOfHalfDay!.timeIntervalSince1970) / 6)
    }
}
