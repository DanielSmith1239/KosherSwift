//
//  AstronomicalCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/20/23.
//

import Foundation

/// A Java calendar that calculates astronomical times such as sunrise, sunset and twilight times. This class contains a
/// Calendar and can therefore use the standard Calendar functionality to change dates etc. The calculation engine used
/// to calculate the astronomical times can be changed to a different implementation by implementing the abstract
/// `AstronomicalCalculator` and setting it with the `astronomicalCalculator`. A number of different calculation engine
/// implementations are included in the util package. **Note:** There are times when the algorithms can't calculate
/// proper values for sunrise, sunset and twilight. This is usually caused by trying to calculate times for areas either
/// very far North or South, where sunrise / sunset never happen on that date. This is common when calculating twilight
/// with a deep dip below the horizon for locations as far south of the North Pole as London, in the northern
/// hemisphere. The sun never reaches this dip at certain times of the year. When the calculations encounter this
/// condition nil will be returned when a ``Date`` is expected and `MIN_VALUE` when a `long` is expected. The reason
/// that `Exception`s are not thrown in these cases is because the lack of a rise/set or twilight is not an exception,
/// but an expected condition in many parts of the world. Here is a simple example of how to use the API to calculate
/// sunrise. First create the calendar for the location and date you would like to calculate sunrise or sunset times for:
///
/// ```swift
/// let location = GeoLocation(lat: 40.0828, lng: -74.2094, // Lakewood, NJ
///                            timezone: TimeZone(identifier: "America/New_York")!,
///                            elevation: 20, // optional elevation correction in meters
///                            name: "Lakewood, NJ")
/// var calendar = Calendar(identifier: .gregorian)
/// calendar.timeZone = location.timezone
/// let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 8))!
/// let ac = AstronomicalCalendar(location: location, date: date)
/// ```
///
/// To get the time of sunrise, first set the date you want (if not set, the date will default to today):
///
/// ```swift
/// let sunrise = ac.sunrise
/// ```
public class AstronomicalCalendar {
    /// A method that returns the currently set `GeoLocation` which contains location information used for the
    /// astronomical calculations.
    ///
    /// - Returns: Returns the geoLocation.
    public let location: GeoLocation

    /// returns the Calendar object encapsulated in this class.
    ///
    /// - Returns: Returns the calendar.
    public let date: Date

    /// A method that returns the currently set AstronomicalCalculator.
    ///
    /// - Returns: Returns the astronomicalCalculator.
    /// - SeeAlso: `astronomicalCalculator`
    public let astronomicalCalculator: AstronomicalCalculator
    
    public init(location: GeoLocation, date: Date, astronomicalCalculator: AstronomicalCalculator = NOAACalculator()) {
        self.location = location
        self.date = date
        self.astronomicalCalculator = astronomicalCalculator
    }
    
    /// The getSunrise method Returns a `Date` representing the elevation adjusted sunrise time. The zenith used for the
    /// calculation uses geometric zenith of 90° plus `getElevationAdjustment()`. This is adjusted by the
    /// `AstronomicalCalculator` to add approximately 50/60 of a degree to account for 34 archminutes of refraction and
    /// 16 archminutes for the sun's radius for a total of 90.83333°. See documentation for the specific implementation
    /// of the `AstronomicalCalculator` that you are using.
    ///
    /// - Returns: the `Date` representing the exact sunrise time. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `adjustZenith()`, `seaLevelSunrise`, `getUtcSunrise()`
    public var sunrise: Date? {
        let ret = getUtcSunrise(zenith: Zenith.geometric.rawValue)
        
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    /// A method that returns the sunrise without elevation adjustment. Non-sunrise and sunset calculations such as dawn
    /// and dusk, depend on the amount of visible light, something that is not affected by elevation. This method
    /// returns sunrise calculated at sea level. This forms the base for dawn calculations that are calculated as a dip
    /// below the horizon before sunrise.
    ///
    /// - Returns: the `Date` representing the exact sea-level sunrise time. If the calculation can't be computed such
    ///   as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
    ///   where it does not set, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `sunrise`, `seaLevelSunset`
    public var seaLevelSunrise: Date? {
        let ret = getUtcSeaLevelSunrise(zenith: Zenith.geometric)
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    /// A method that returns the beginning of [civil twilight](https://en.wikipedia.org/wiki/Twilight#Civil_twilight)
    /// (dawn) using a zenith of 96°.
    ///
    /// - Returns: The `Date` of the beginning of civil twilight using a zenith of 96°. If the calculation can't be
    ///   computed, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.civil`
    public var civilTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.civil.rawValue)
    }
    
    /// A method that returns the beginning of [nautical
    /// twilight](https://en.wikipedia.org/wiki/Twilight#Nautical_twilight) using a zenith of 102°.
    ///
    /// - Returns: The `Date` of the beginning of nautical twilight using a zenith of 102°. If the calculation can't be
    ///   computed nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.nautical`
    public var nauticalTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.nautical.rawValue)
    }
    
    /// A method that returns the beginning of [astronomical
    /// twilight](https://en.wikipedia.org/wiki/Twilight#Astronomical_twilight) using a zenith of 108°.
    ///
    /// - Returns: The `Date` of the beginning of astronomical twilight using a zenith of 108°. If the calculation can't
    ///   be computed, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.astronomical`
    public var astronomicalTwilightStart: Date? {
        getSunriseOffsetByDegrees(offset: Zenith.astronomical.rawValue)
    }
    
    /// The getSunset method Returns a `Date` representing the elevation adjusted sunset time. The zenith used for the
    /// calculation uses geometric zenith of 90° plus `getElevationAdjustment()`. This is adjusted by the
    /// `AstronomicalCalculator` to add approximately 50/60 of a degree to account for 34 archminutes of refraction and
    /// 16 archminutes for the sun's radius for a total of 90.83333°. See documentation for the specific implementation
    /// of the `AstronomicalCalculator` that you are using. Note: In certain cases the calculates sunset will occur
    /// before sunrise. This will typically happen when a timezone other than the local timezone is used (calculating
    /// Los Angeles sunset using a GMT timezone for example). In this case the sunset date will be incremented to the
    /// following date.
    ///
    /// - Returns: the `Date` representing the exact sunset time. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `adjustZenith()`, `seaLevelSunset`, `getUtcSunset()`
    public var sunset: Date? {
        let ret = getUtcSunset(zenith: Zenith.geometric.rawValue)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    /// A method that returns the sunset without elevation adjustment. Non-sunrise and sunset calculations such as dawn
    /// and dusk, depend on the amount of visible light, something that is not affected by elevation. This method
    /// returns sunset calculated at sea level. This forms the base for dusk calculations that are calculated as a dip
    /// below the horizon after sunset.
    ///
    /// - Returns: the `Date` representing the exact sea-level sunset time. If the calculation can't be computed such as
    ///   in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
    ///   where it does not set, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `sunset`
    public var seaLevelSunset: Date? {
        let ret = getUtcSeaLevelSunset(zenith: .geometric)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    /// A method that returns the end of [civil twilight](https://en.wikipedia.org/wiki/Twilight#Civil_twilight) using a
    /// zenith of 96°.
    ///
    /// - Returns: The `Date` of the end of civil twilight using a zenith of 96°. If the calculation can't be computed,
    ///   nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.civil`
    public var civilTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.civil.rawValue)
    }
    
    /// A method that returns the end of nautical twilight using a zenith of 102°.
    ///
    /// - Returns: The `Date` of the end of nautical twilight using a zenith of 102° . If the calculation can't be
    ///   computed, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.nautical`
    public var nauticalTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.nautical.rawValue)
    }
    
    /// A method that returns the end of astronomical twilight using a zenith of 108°.
    ///
    /// - Returns: the `Date` of the end of astronomical twilight using a zenith of 108°. If the calculation can't be
    ///   computed, nil will be returned. See detailed explanation on top of the page.
    /// - SeeAlso: `Zenith.astronomical`
    public var astronomicalTwilightEnd: Date? {
        getSunsetOffsetByDegrees(offset: Zenith.astronomical.rawValue)
    }
    
    /// A utility method that returns the time of an offset by degrees below or above the horizon of sunrise. Note that
    /// the degree offset is from the vertical, so for a calculation of 14° before sunrise, an offset of 14 +
    /// `Zenith.geometric` = 104 would have to be passed as a parameter.
    ///
    /// - Parameter offset: the degrees before `sunrise` to use in the calculation. For time after sunrise use negative
    ///   numbers. Note that the degree offset is from the vertical, so for a calculation of 14°
    ///   before sunrise, an offset of 14 + `Zenith.geometric` = 104 would have to be passed as a
    ///   parameter.
    /// - Returns: The `Date` of the offset after (or before) `sunrise`. If the calculation can't be computed such as in
    ///   the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
    ///   it does not set, nil will be returned. See detailed explanation on top of the page.
    public func getSunriseOffsetByDegrees(offset: Double) -> Date? {
        let ret = getUtcSunrise(zenith: offset)
		return getDateFromTime(time: ret, solarEvent: .sunrise)
    }
    
    /// A utility method that returns the time of an offset by degrees below or above the horizon of sunrise. Note that
    /// the degree offset is from the vertical, so for a calculation of 14° before sunrise, an offset of 14 +
    /// `Zenith.geometric` = 104 would have to be passed as a parameter.
    ///
    /// - Parameter offsetZenith: the degrees before `sunrise` to use in the calculation. For time after sunrise use
    ///   negative numbers. Note that the degree offset is from the vertical, so for a
    ///   calculation of 14° before sunrise, an offset of 14 + `Zenith.geometric` = 104 would
    ///   have to be passed as a parameter.
    /// - Returns: The `Date` of the offset after (or before) `sunrise`. If the calculation can't be computed such as in
    ///   the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
    ///   it does not set, nil will be returned. See detailed explanation on top of the page.
    public func getSunriseOffsetByDegrees(offsetZenith: Zenith) -> Date? {
        getSunriseOffsetByDegrees(offset: offsetZenith.rawValue)
    }
    
    /// A utility method that returns the time of an offset by degrees below or above the horizon of sunset. Note that
    /// the degree offset is from the vertical, so for a calculation of 14° after sunset, an offset of 14 +
    /// `Zenith.geometric` = 104 would have to be passed as a parameter.
    ///
    /// - Parameter offset: the degrees after `sunset` to use in the calculation. For time before sunset use negative
    ///   numbers. Note that the degree offset is from the vertical, so for a calculation of 14° after
    ///   sunset, an offset of 14 + `Zenith.geometric` = 104 would have to be passed as a parameter.
    /// - Returns: The `Date`of the offset after (or before) `sunset`. If the calculation can't be computed such as in
    ///   the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
    ///   it does not set, nil will be returned. See detailed explanation on top of the page.
    public func getSunsetOffsetByDegrees(offset: Double) -> Date? {
        let ret = getUtcSunset(zenith: offset)
		return getDateFromTime(time: ret, solarEvent: .sunset)
    }
    
    /// A utility method that returns the time of an offset by degrees below or above the horizon of sunset. Note that
    /// the degree offset is from the vertical, so for a calculation of 14° after sunset, an offset of 14 +
    /// `Zenith.geometric` = 104 would have to be passed as a parameter.
    ///
    /// - Parameter offsetZenith: the degrees after `sunset` to use in the calculation. For time before sunset use
    ///   negative numbers. Note that the degree offset is from the vertical, so for a
    ///   calculation of 14° after sunset, an offset of 14 + `Zenith.geometric` = 104 would have
    ///   to be passed as a parameter.
    /// - Returns: The `Date`of the offset after (or before) `sunset`. If the calculation can't be computed such as in
    ///   the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
    ///   it does not set, nil will be returned. See detailed explanation on top of the page.
    public func getSunsetOffsetByDegrees(offsetZenith: Zenith) -> Date? {
        getSunsetOffsetByDegrees(offset: offsetZenith.rawValue)
    }
    
    /// Adjusts the `Calendar` to deal with edge cases where the location crosses the antimeridian.
    ///
    /// - Returns: the adjusted Calendar
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
    public func getTemporalHour(dayStart: Date? = nil, dayEnd: Date? = nil) -> Double? {
        let start = dayStart
        let end = dayEnd
        
        guard let start = start, let end = end else { return nil }
        
        return Double((end.millisecondsSince1970 - start.millisecondsSince1970) / 12)
    }
	
	///A method that calculates a temporal (solar) hour based on ``seaLevelSunrise`` and ``seaLevelSunset``.
	/// 
	///- Returns: the millisecond length of a temporal hour. If the calculation can't be computed, `nil` will be returned. See details on ``AstronomicalCalendar`` for more information.
	public func getTemporalHour() -> Double? {
		getTemporalHour(dayStart: seaLevelSunrise, dayEnd: seaLevelSunset)
	}
	
	/// A method that returns sundial or solar noon. It occurs when the Sun is
	/// [transiting](https://en.wikipedia.org/wiki/Transit_%28astronomy%29) the [celestial
	/// meridian](https://en.wikipedia.org/wiki/Meridian_%28astronomy%29). The calculations used by this class depend on
	/// the `AstronomicalCalculator` used. If this calendar instance is set to use the `NOAACalculator` (the default) it
	/// will calculate astronomical noon. If the calendar instance is to use the `SunTimesCalculator`, that does not
	/// have code to calculate astronomical noon, the sun transit is calculated as halfway between sea level sunrise and
	/// sea level sunset, which can be slightly off the real transit time due to changes in declination (the lengthening
	/// or shortening day). See [The Definition of Chatzos](https://kosherjava.com/2020/07/02/definition-of-chatzos/)
	/// for details on the proper definition of solar noon / midday.
	///
	/// - Returns: the `Date` representing Sun's transit. If the calculation can't be computed such as in the Arctic
	///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
	///   set, nil will be returned. See detailed explanation on top of the page.
	/// - SeeAlso: `getSunTransit()`, `getTemporalHour()`
	public func getSunTransit() -> Date? {
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
    public func getSunTransit(start: Date, end: Date) -> Date? {
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
    
    /// A method that returns [local mean time (LMT)](https://en.wikipedia.org/wiki/Local_mean_time) for a `LocalTime`
    /// passed to this method. This time is adjusted from standard time to account for the local latitude. The 360° of
    /// the globe divided by 24 calculates to 15° per hour with 4 minutes per degree, so at a longitude of 0 , 15, 30
    /// etc... noon is at exactly 12:00 PM. Lakewood, NJ, with a longitude of -74.222, is 0.7906 away from the closest
    /// multiple of 15 at -75°. This is multiplied by 4 clock minutes (per degree) to yield 3 minutes and 7 seconds for
    /// a noon time of 11:56:53 AM. This method is not tied to the theoretical 15° time zones, but will adjust to the
    /// actual time zone and [Daylight saving time](https://en.wikipedia.org/wiki/Daylight_saving_time) to return LMT.
    ///
    /// - Parameter hours: the local wall-clock time (such as 12:00 for noon and 00:00 for midnight) to calculate as
    ///   LMT.
    /// - Returns: the `Instant` representing the local mean time (LMT) for the time passed in. In Lakewood, NJ, passing
    ///   noon will return 11:56:50 AM.
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
    
    /// A utility method that returns a date offset by the offset time passed in as a parameter. This method casts the
    /// offset as a `long` and calls `getTimeOffset()`.
    ///
    /// - Parameters:
    ///   - time: the start time
    ///   - offset: the offset in milliseconds to add to the time
    /// - Returns: the `Date`with the offset added to it
    public static func getTimeOffset(time: Date?, offset: Double?) -> Date? {
//        guard let time = time, let offset = offset, offset != Double.leastNormalMagnitude else {
//            return nil
//        }
//        
//        return time + Double(offset) / 1000
        guard let time = time, let offset = offset else { return nil }
        return Date(timeInterval: TimeInterval(offset / 1000), since: time)
    }
    
}
