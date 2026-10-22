//
//  SunTimesCalculator.swift
//  KosherSwift
//

import Foundation

/// Port of KosherJava master's `SunTimesCalculator`: the US Naval Almanac "Almanac for Computers" sunrise/sunset
/// algorithm. Less accurate than ``NOAACalculator``; KosherJava keeps it (deprecated) for compatibility.
public final class SunTimesCalculator: HorizonAdjustingCalculator, AstronomicalCalculator {
    /// - SeeAlso: `calculatorName`
    public var calculatorName: String { "US Naval Almanac Algorithm" }

    public required init() { super.init() }

    /// - SeeAlso: `getUtcSunrise()`
    public func getUtcSunrise(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        let localDate = Self.localDate(date, location)
        let elevation = adjustForElevation ? (location.elevation ?? 0) : 0
        let adjustedZenith = adjustZenith(zenith, elevation: elevation, year: localDate.year, month: localDate.month, day: localDate.day)
        return Self.getTimeUTC(localDate, location, adjustedZenith, isSunrise: true)
    }

    /// - SeeAlso: `getUtcSunset()`
    public func getUtcSunset(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        let localDate = Self.localDate(date, location)
        let elevation = adjustForElevation ? (location.elevation ?? 0) : 0
        let adjustedZenith = adjustZenith(zenith, elevation: elevation, year: localDate.year, month: localDate.month, day: localDate.day)
        return Self.getTimeUTC(localDate, location, adjustedZenith, isSunrise: false)
    }

    /// Halfway between sunrise and sunset (zenith 90°, no elevation), as in KosherJava.
    public func getUTCNoon(date: Date, geoLocation: GeoLocation) -> Double {
        let sunrise = getUtcSunrise(date: date, location: geoLocation, zenith: 90, adjustForElevation: false)
        let sunset = getUtcSunset(date: date, location: geoLocation, zenith: 90, adjustForElevation: false)
        var noon = sunrise + ((sunset - sunrise) / 2)
        if noon < sunrise {
            noon -= 12
        }
        return Self.normalizeHours(noon)
    }

    /// Return the [Universal Coordinated Time](https://en.wikipedia.org/wiki/Universal_Coordinated_Time) (UTC) of
    /// [solar midnight](https://en.wikipedia.org/wiki/Midnight) (UTC) for the given day at the given location. The
    /// `NOAACalculator`, the default calculator implementation calculates true solar midnight, something that can be
    /// calculated even in the Arctic / Antarctic where there may be no sunrise or sunset, while the
    /// `SunTimesCalculator` approximates it, calculating the time as 12 hours after halfway between sunrise and sunset,
    /// something that can't be calculated in Polar regions where there is no sunrise or sunset for part of the year.
    /// See [The Definition of *Chatzos*](https://kosherjava.com/2020/07/02/definition-of-chatzos/) for details on solar
    /// noon / midnight calculations.
    ///
    /// - Parameters:
    ///   - date: The `LocalDate` representing the date to calculate midnight for. The calculation will be for midnight
    ///     at the end of the day passed in.
    ///   - geoLocation: The location information used for astronomical calculation of solar times.
    /// - Returns: The UTC time of solar midnight in a 24-hour `double` format. 1:45:00 AM will return 1.75. If an error
    ///   was encountered in the calculation (expected behavior for the `SunTimesCalculator` at times of the
    ///   year in Polar regions), `Double.nan` will be returned.
    /// - SeeAlso: `getUTCNoon()`
    public func getUTCMidnight(date: Date, geoLocation: GeoLocation) -> Double {
        (getUTCNoon(date: date, geoLocation: geoLocation) + 12).truncatingRemainder(dividingBy: 24)
    }

    private static let degPerHour = 360.0 / 24.0

    private static func getHoursFromMeridian(_ longitude: Double) -> Double {
        longitude / degPerHour
    }

    private static func getApproxTimeDays(_ dayOfYear: Int, _ hoursFromMeridian: Double, isSunrise: Bool) -> Double {
        Double(dayOfYear) + ((isSunrise ? 6.0 : 18.0) - hoursFromMeridian) / 24
    }

    private static func getMeanAnomaly(_ dayOfYear: Int, _ longitude: Double, isSunrise: Bool) -> Double {
        (0.9856 * getApproxTimeDays(dayOfYear, getHoursFromMeridian(longitude), isSunrise: isSunrise)) - 3.289
    }

    private static func getSunTrueLongitude(_ sunMeanAnomaly: Double) -> Double {
        let l = sunMeanAnomaly + (1.916 * sinDegrees(sunMeanAnomaly)) + (0.020 * sinDegrees(2 * sunMeanAnomaly)) + 282.634
        return normalizeDegrees(l)
    }

    private static func getSunRightAscensionHours(_ sunTrueLongitude: Double) -> Double {
        let a = 0.91764 * tanDegrees(sunTrueLongitude)
        var ra = 360.0 / (2.0 * Double.pi) * atan(a)
        let lQuadrant = floor(sunTrueLongitude / 90.0) * 90.0
        let raQuadrant = floor(ra / 90.0) * 90.0
        ra = ra + (lQuadrant - raQuadrant)
        return ra / degPerHour
    }

    private static func getCosLocalHourAngle(_ sunTrueLongitude: Double, _ latitude: Double, _ zenith: Double) -> Double {
        let sinDec = 0.39782 * sinDegrees(sunTrueLongitude)
        let cosDec = cosDegrees(asinDegrees(sinDec))
        return (cosDegrees(zenith) - (sinDec * sinDegrees(latitude))) / (cosDec * cosDegrees(latitude))
    }

    private static func getLocalMeanTime(_ localHour: Double, _ sunRightAscensionHours: Double, _ approxTimeDays: Double) -> Double {
        localHour + sunRightAscensionHours - (0.06571 * approxTimeDays) - 6.622
    }

    private static func getTimeUTC(_ localDate: (year: Int, month: Int, day: Int), _ location: GeoLocation, _ zenith: Double, isSunrise: Bool) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: calendar.date(from: DateComponents(year: localDate.year, month: localDate.month, day: localDate.day))!)!
        let sunMeanAnomaly = getMeanAnomaly(dayOfYear, location.lng, isSunrise: isSunrise)
        let sunTrueLong = getSunTrueLongitude(sunMeanAnomaly)
        let sunRightAscensionHours = getSunRightAscensionHours(sunTrueLong)
        let cosLocalHourAngle = getCosLocalHourAngle(sunTrueLong, location.lat, zenith)
        // acos of a value outside [-1, 1] is NaN: no sunrise/sunset that day, as in KosherJava
        let localHourAngle = isSunrise ? 360.0 - acosDegrees(cosLocalHourAngle) : acosDegrees(cosLocalHourAngle)
        let localHour = localHourAngle / degPerHour
        let localMeanTime = getLocalMeanTime(localHour, sunRightAscensionHours,
                                             getApproxTimeDays(dayOfYear, getHoursFromMeridian(location.lng), isSunrise: isSunrise))
        let processedTime = localMeanTime - getHoursFromMeridian(location.lng)
        return normalizeHours(processedTime)
    }
}
