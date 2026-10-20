//
//  AstronomicalCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/20/23.
//

import Foundation

public class AstronomicalCalendar {
    public let location: GeoLocation
    public let date: Date
    public let astronomicalCalculator: AstronomicalCalculator
    
    public init(location: GeoLocation, date: Date, astronomicalCalculator: AstronomicalCalculator = NOAACalculator()) {
        self.location = location
        self.date = date
        self.astronomicalCalculator = astronomicalCalculator
    }
    
    public var sunrise: Date? {
        let ret = getUtcSunrise(zenith: Zenith.geometric.rawValue)
        
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    public var seaLevelSunrise: Date? {
        let ret = getUtcSeaLevelSunrise(zenith: Zenith.geometric)
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    public var civilTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.civil.rawValue)
    }
    
    public var nauticalTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.nautical.rawValue)
    }
    
    public var astronomicalTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.astronomical.rawValue)
    }
    
    public var sunset: Date? {
        let ret = getUtcSunset(zenith: Zenith.geometric.rawValue)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    public var seaLevelSunset: Date? {
        let ret = getUtcSeaLevelSunset(zenith: .geometric)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    public var civilTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.civil.rawValue)
    }
    
    public var nauticalTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.nautical.rawValue)
    }
    
    public var astronomicalTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.astronomical.rawValue)
    }
    
    func getSunriseOffsetByDegrees(offset: Double) -> Date? {
        let ret = getUtcSunrise(zenith: offset)
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    func getSunriseOffsetByDegrees(offsetZenith: Zenith) -> Date? {
        getSunriseOffsetByDegrees(offset: offsetZenith.rawValue)
    }
    
    func getSunsetOffsetByDegrees(offset: Double) -> Date? {
        let ret = getUtcSunset(zenith: offset)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    func getSunsetOffsetByDegrees(offsetZenith: Zenith) -> Date? {
        getSunsetOffsetByDegrees(offset: offsetZenith.rawValue)
    }
    
    public var adjustedDate: Date? {
        let offset = location.antimeridianAdjustment
        if offset == 0 {
            return date
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timezone
        return calendar.date(byAdding: .day, value: offset, to: date)
    }
    
    func getUtcSunrise(zenith: Double) -> Double? {
        guard let adjustedDate else { return nil }
        return astronomicalCalculator.getUtcSunrise(date: adjustedDate, location: location, zenith: zenith, adjustForElevation: true)
    }
    
    func getUtcSeaLevelSunrise(zenith: Zenith) -> Double? {
        guard let adjustedDate else { return nil }
        return astronomicalCalculator.getUtcSunrise(date: adjustedDate, location: location, zenith: zenith.rawValue, adjustForElevation: false)
    }
    
    func getUtcSunset(zenith: Double) -> Double? {
        guard let adjustedDate else { return nil }
        return astronomicalCalculator.getUtcSunset(date: adjustedDate, location: location, zenith: zenith, adjustForElevation: true)
    }
    
    func getUtcSeaLevelSunset(zenith: Zenith) -> Double? {
        guard let adjustedDate else { return nil }
        return astronomicalCalculator.getUtcSunset(date: adjustedDate, location: location, zenith: zenith.rawValue, adjustForElevation: false)
    }
    
	/// A method that calculates a temporal (solar) hour based on the sunrise and sunset passed as parameters.
	///
	/// An example of the use of this method would be the calculation of a elevation adjusted temporal hour by passing in sunrise and sunset as parameters.
	/// > Tip: The day from sea-level sunrise to sea-level sunset is split into 12 equal parts with each one being a temporal hour.
	///
	/// - Parameter dayStart: The start of the day.
	/// - Parameter dayEnd: The end of the day.
	/// - Returns: the millisecond length of a temporal hour. If the calculation can't be computed, `nil` will be returned. See details on ``AstronomicalCalendar`` for more information.
    func getTemporalHour(dayStart: Date? = nil, dayEnd: Date? = nil) -> Double? {
        let start = dayStart
        let end = dayEnd
        
        guard let start = start, let end = end else { return nil }
        
        return Double((end.millisecondsSince1970 - start.millisecondsSince1970) / 12)
    }
	
	///A method that calculates a temporal (solar) hour based on ``seaLevelSunrise`` and ``seaLevelSunset``.
	/// 
	///- Returns: the millisecond length of a temporal hour. If the calculation can't be computed, `nil` will be returned. See details on ``AstronomicalCalendar`` for more information.
	func getTemporalHour() -> Double? {
		getTemporalHour(dayStart: seaLevelSunrise, dayEnd: seaLevelSunset)
	}
	
	func getSunTransit() -> Date? {
		guard let adjustedDate else {return nil}
		let noon = astronomicalCalculator.getUTCNoon(date: adjustedDate, geoLocation: location)
		return getDateFromTime(time: noon, solarEvent: .noon)
	}
    
	/// A method that returns sundial or solar noon.
	///
	/// Sundial, or solar noon, occurs when the Sun is [transiting](https://en.wikipedia.org/wiki/Transit_%28astronomy%29) the [celestial meridian](https://en.wikipedia.org/wiki/Meridian_%28astronomy%29).
	/// The calculations used by this class depend on the ``AstronomicalCalculator`` used. If this calendar instance is set to use the ``NOAACalculator`` (the default) it will calculate astronomical noon. See [The Definition of Chatzos](https://kosherjava.com/2020/07/02/definition-of-chatzos/) for details on the proper definition of solar noon / midday.
	///
	/// This time can be slightly off the real transit time due to changes in declination (the lengthening or shortening day).
	///
	/// If no parameters are passed, the method defaults to using ``seaLevelSunrise`` and ``seaLevelSunset``.
	///
	/// - Parameters:
	///   - dayStart: the start of day for calculating the sun's transit. This can be sea level sunrise, visual sunrise (or any arbitrary start of day) passed to this method. Defaults to ``seaLevelSunrise``
	///   - dayEnd: the end of day for calculating the sun's transit. This can be sea level sunset, visual sunset (or any arbitrary end of day) passed to this method. Defaults to ``seaLevelSunset``
	/// - Returns: the Date representing Sun's transit.  If the calculation can't be computed,  `nil` will be returned. See details on ``AstronomicalCalendar`` for more information.
    func getSunTransit(start: Date, end: Date) -> Date? {
        let temporalHour = getTemporalHour(dayStart: start, dayEnd: end)
        guard let temporalHour = temporalHour else { return nil }
        
        return AstronomicalCalendar.getTimeOffset(time: start, offset: temporalHour * 6)
    }
    
	/// A method that returns a Date from the time passed in as a parameter.
	/// 
	/// 
	/// - Parameters:
	///   - time: The time to be set as the time for the Date. time is sunrise and false if it is sunset
	///   - isSunrise: `true` if the date being calculated is relating to Sunrise, `false` if it is not.
	/// - Returns: The Date representation of the time double
	func getDateFromTime(time: Double?, solarEvent: SolarEvent) -> Date? {
		guard let time, let adjustedDate, !time.isNaN else { return nil }
        
        var calculatedTime = time
        
        var gregorianCalendar =  Calendar(identifier: .gregorian)
		// We need to set the calendar to the location's time zone, or the calculations will be determined for the device's current time zone.
		gregorianCalendar.timeZone = location.timezone
		
		let adjustedComponents = gregorianCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: adjustedDate)
		var components = DateComponents(calendar: gregorianCalendar,
										year: adjustedComponents.year,
										month: adjustedComponents.month,
										day: adjustedComponents.day)
        
		components.timeZone = TimeZone(identifier: "GMT")
        let hours = Int(calculatedTime)
        calculatedTime -= Double(hours)
        
        calculatedTime = calculatedTime * 60
        let minutes = Int(calculatedTime)
        calculatedTime -= Double(minutes)
        
        calculatedTime = calculatedTime * 60
        let seconds = Int(calculatedTime)
        calculatedTime -= Double(seconds)

		
		// Check if a date transition has occurred, or is about to occur - this indicates the date of the event is
		// actually not the target date, but the day prior or after
		let localTimeHours = Int(location.lng / 15)
		var daysToAdd = 0
		if solarEvent == .sunrise && localTimeHours + hours > 18 {
			daysToAdd = -1
		} else if solarEvent == .sunset && localTimeHours + hours < 6 {
			daysToAdd = 1
		} else if solarEvent == .midnight && localTimeHours + hours < 12 {
			daysToAdd = 1
		} else if solarEvent == .noon && localTimeHours + hours > 24 {
			daysToAdd = -1
		}
		components.day! += daysToAdd
		components.hour = hours
		components.minute = minutes
		components.second = seconds
        components.nanosecond = Int(calculatedTime * 1000 * 1000000)
		return gregorianCalendar.date(from: components)
    }
    
    func getSunriseSolarDipFromOffset(minutes: Double) -> Double {
        var offsetByDegrees: Date? = seaLevelSunrise
        let offsetByTime = AstronomicalCalendar.getTimeOffset(time: seaLevelSunrise, offset: -(minutes * AstronomicalCalendar.minuteMillis))
        var degrees = 0.0
        let incrementor = 0.0001
        while offsetByDegrees == nil ||
                ((minutes < 0.0 && offsetByDegrees! < offsetByTime!) ||
                 (minutes > 0.0 && offsetByDegrees! > offsetByTime!)) {
            if minutes > 0.0 {
                degrees += incrementor
            } else {
                degrees -= incrementor
            }
            offsetByDegrees = getSunriseOffsetByDegrees(offset: Zenith.geometric.rawValue + degrees)
        }
        
        return degrees
    }
    
    func getSunsetSolarDipFromOffset(minutes: Double) -> Double {
        var offsetByDegrees: Date? = seaLevelSunset
        let offsetByTime = AstronomicalCalendar.getTimeOffset(time: seaLevelSunset, offset: minutes * AstronomicalCalendar.minuteMillis)
        var degrees = 0.0
        let incrementor = 0.001
        while offsetByDegrees == nil ||
                ((minutes > 0.0 && offsetByDegrees! < offsetByTime!) ||
                 (minutes < 0.0 && offsetByDegrees! > offsetByTime!)) {
            if minutes > 0.0 {
                degrees += incrementor
            } else {
                degrees -= incrementor
            }
            offsetByDegrees = getSunsetOffsetByDegrees(offset: Zenith.geometric.rawValue + degrees)
        }
        
        return degrees
    }
    
    public func getLocalMeanTime(hours: Double) -> Date? {
		AstronomicalCalendar.getTimeOffset(time: getDateFromTime(time: hours - location.rawOffsetMillis / AstronomicalCalendar.hourMillis, solarEvent: .sunrise), offset: -location.localMeanTimeOffset)
    }
}

extension AstronomicalCalendar {
    /// The calendar day of ``date`` at this location, as midnight in the device time zone.
    ///
    /// Zmanim read ``date`` in the location's time zone, but `JewishCalendar(date:)` reads its date in the device time zone.
    /// Pass this to `JewishCalendar(date:)` so both agree on the day when the two time zones differ.
    var deviceDate: Date {
        AstronomicalCalendar.sameDay(as: date, from: location.timezone, to: Calendar.current.timeZone)
    }
    
    /// The inverse of ``deviceDate``: a device-time-zone date (such as `JewishCalendar.gregDate`) as midnight of the same day at this location.
    func locationDate(fromDeviceDate deviceDate: Date) -> Date {
        AstronomicalCalendar.sameDay(as: deviceDate, from: Calendar.current.timeZone, to: location.timezone)
    }
    
    /// ``date`` moved by whole calendar days at this location.
    func date(addingDays days: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timezone
        return calendar.date(byAdding: .day, value: days, to: date)!
    }
    
    /// The day of the week of ``date`` at this location.
    var dayOfWeek: DayOfWeek {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timezone
        return DayOfWeek(rawValue: calendar.component(.weekday, from: date))!
    }
    
    private static func sameDay(as date: Date, from source: TimeZone, to destination: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = source
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        calendar.timeZone = destination
        return calendar.date(from: components)!
    }
    
    // Constants
    static let minuteMillis = 60 * 1000.0
    static let hourMillis = minuteMillis * 60
    
    static func getTimeOffset(time: Date?, offset: Double?) -> Date? {
//        guard let time = time, let offset = offset, offset != Double.leastNormalMagnitude else {
//            return nil
//        }
//        
//        return time + Double(offset) / 1000
        guard let time = time, let offset = offset else { return nil }
        return Date(timeInterval: TimeInterval(offset / 1000), since: time)
    }
    
}
