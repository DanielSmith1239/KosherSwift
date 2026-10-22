//
//  MeeusCalculator.swift
//  KosherSwift
//

import Foundation

/// Port of KosherJava master's `MeeusCalculator`: Jean Meeus's higher-accuracy solar position (Astronomical Algorithms
/// chapters 22, 25 and 28, with the abridged VSOP87 Earth series) and Delta T.
public final class MeeusCalculator: HorizonAdjustingCalculator, AstronomicalCalculator {
    /// Returns the name of the algorithm.
    ///
    /// - Returns: the descriptive name of the algorithm.
    public var calculatorName: String { "Jean Meeus Higher-Accuracy (VSOP87) Algorithm" }

    /// Whether to convert UT to Terrestrial Time with Delta T before computing the sun's position. KosherJava default: true.
    public var applyDeltaT = true

    private static let julianDayJan12000 = 2451545.0
    private static let julianDaysPerCentury = 36525.0

    private enum SolarEvent { case sunrise, sunset, noon, midnight }

    public required init() { super.init() }

    /// A method that calculates UTC sunrise as well as any time based on an angle above or below sunrise. This abstract
    /// method is implemented by the classes that extend this class.
    ///
    /// - Parameters:
    ///   - date: Used to calculate day of year.
    ///   - location: The location information used for astronomical calculating sun times.
    ///   - zenith: the azimuth below the vertical zenith of 90 degrees. for sunrise typically the zenith used for the
    ///     calculation uses geometric zenith of 90° and adjusts this slightly to account for solar refraction
    ///     and the sun's radius. Another example would be `nauticalTwilightStart` that passes `Zenith.nautical`
    ///     to this method.
    ///   - adjustForElevation: Should the time be adjusted for elevation
    /// - Returns: The UTC time of sunrise in 24 hour format. 5:45:00 AM will return 5.75.0. If an error was encountered
    ///   in the calculation (expected behavior for some locations such as near the poles, `Double.nan` will be
    ///   returned.
    /// - SeeAlso: `getElevationAdjustment()`
    public func getUtcSunrise(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        getUTCSunRiseSet(date, location, zenith, adjustForElevation, .sunrise)
    }

    /// A method that calculates UTC sunset as well as any time based on an angle above or below sunset. This abstract
    /// method is implemented by the classes that extend this class.
    ///
    /// - Parameters:
    ///   - date: Used to calculate day of year.
    ///   - location: The location information used for astronomical calculating sun times.
    ///   - zenith: the azimuth below the vertical zenith of 90°. For sunset typically the zenith used for the
    ///     calculation uses geometric zenith of 90° and adjusts this slightly to account for solar refraction
    ///     and the sun's radius. Another example would be `nauticalTwilightEnd` that passes `Zenith.nautical`
    ///     to this method.
    ///   - adjustForElevation: Should the time be adjusted for elevation
    /// - Returns: The UTC time of sunset in 24 hour format. 5:45:00 AM will return 5.75.0. If an error was encountered
    ///   in the calculation (expected behavior for some locations such as near the poles, `Double.nan` will be
    ///   returned.
    /// - SeeAlso: `getElevationAdjustment()`
    public func getUtcSunset(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        getUTCSunRiseSet(date, location, zenith, adjustForElevation, .sunset)
    }

    private func getUTCSunRiseSet(_ date: Date, _ location: GeoLocation, _ zenith: Double, _ adjustForElevation: Bool, _ solarEvent: SolarEvent) -> Double {
        let localDate = Self.localDate(date, location)
        let elevation = adjustForElevation ? (location.elevation ?? 0) : 0
        let adjustedZenith = adjustZenith(zenith, elevation: elevation, year: localDate.year, month: localDate.month, day: localDate.day)
        let julianDay = Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day)
        let riseSet = getSunRiseSetUTC(julianDay, location.lat, -location.lng, adjustedZenith, solarEvent) / 60
        return Self.normalizeHours(riseSet)
    }

    /// Return [solar noon](https://en.wikipedia.org/wiki/Noon#Solar_noon) (UTC) for the given day at the given location
    /// on earth. The the `NOAACalculator` implementation calculates true solar noon, while the `SunTimesCalculator`
    /// approximates it, calculating the time as halfway between sunrise and sunset.
    ///
    /// - Parameters:
    ///   - date: Used to calculate day of year.
    ///   - geoLocation: The location information used for astronomical calculating sun times.
    /// - Returns: the time in minutes from zero UTC
    public func getUTCNoon(date: Date, geoLocation: GeoLocation) -> Double {
        let localDate = Self.localDate(date, geoLocation)
        let noon = getSolarNoonMidnightUTC(Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day), -geoLocation.lng, .noon) / 60
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
        let localDate = Self.localDate(date, geoLocation)
        let midnight = getSolarNoonMidnightUTC(Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day), -geoLocation.lng, .midnight) / 60
        return Self.normalizeHours(midnight)
    }

    private func getSolarNoonMidnightUTC(_ julianDay: Double, _ longitude: Double, _ solarEvent: SolarEvent) -> Double {
        let base = solarEvent == .noon ? 720.0 : 1440.0
        let tnoon = getJulianCenturiesFromJulianDay(julianDay + longitude / 360.0)
        var equationOfTime = Self.getEquationOfTime(tnoon)
        var solNoonUTC = base + (longitude * 4) - equationOfTime // minutes
        for _ in 0..<3 {
            let newt = getJulianCenturiesFromJulianDay(julianDay + solNoonUTC / 1440.0)
            equationOfTime = Self.getEquationOfTime(newt)
            solNoonUTC = base + (longitude * 4) - equationOfTime
        }
        return solNoonUTC
    }

    private func getSunRiseSetUTC(_ julianDay: Double, _ latitude: Double, _ longitude: Double, _ zenith: Double, _ solarEvent: SolarEvent) -> Double {
        let noonmin = getSolarNoonMidnightUTC(julianDay, longitude, .noon)
        let tnoon = getJulianCenturiesFromJulianDay(julianDay + noonmin / 1440.0)
        var equationOfTime = Self.getEquationOfTime(tnoon)
        var solarDeclination = Self.getSunDeclination(tnoon)
        var hourAngle = Self.getSunHourAngle(latitude, solarDeclination, zenith, solarEvent)
        var delta = longitude - toDegrees(hourAngle)
        var timeUTC = 720 + (4 * delta) - equationOfTime
        for _ in 0..<2 {
            let newt = getJulianCenturiesFromJulianDay(julianDay + timeUTC / 1440.0)
            equationOfTime = Self.getEquationOfTime(newt)
            solarDeclination = Self.getSunDeclination(newt)
            hourAngle = Self.getSunHourAngle(latitude, solarDeclination, zenith, solarEvent)
            if hourAngle.isNaN {
                return .nan
            }
            delta = longitude - toDegrees(hourAngle)
            timeUTC = 720 + (4 * delta) - equationOfTime
        }
        return timeUTC
    }

    /// UTC hour at which the sun is due east (90) or due west (270), or NaN if it never is that day.
    /// Only 90 and 270 are supported; KosherJava throws `IllegalArgumentException` for anything else.
    public func getTimeAtAzimuth(date: Date, geoLocation: GeoLocation, azimuth targetAzimuth: Double) -> Double {
        precondition(targetAzimuth == 90.0 || targetAzimuth == 270.0, "The targetAzimuth must be 90 or 270. Other azimuth values are not supported")
        let localDate = Self.localDate(date, geoLocation)
        let julianDay = Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day)
        let solarNoonBase = 0.5 - (geoLocation.lng / 360.0)
        var dateTime = solarNoonBase + (targetAzimuth == 90.0 ? 0.25 : 0.75)
        for _ in 0..<3 {
            let julianCenturies = getJulianCenturiesFromJulianDay(julianDay + dateTime)
            let ratio = tanDegrees(Self.getSunDeclination(julianCenturies)) / tanDegrees(geoLocation.lat)
            if ratio.isNaN || ratio > 1.0 || ratio < -1.0 {
                return .nan
            }
            let offset = (targetAzimuth == 90.0 ? -1.0 : 1.0) * (acosDegrees(ratio) / 360.0)
            dateTime = solarNoonBase + offset - (Self.getEquationOfTime(julianCenturies) / 1440.0)
        }
        return Self.normalizeHours(dateTime * 24.0)
    }

    /// Refraction-corrected elevation of the sun in degrees at `instant`.
    public func getSolarElevation(instant: Date, geoLocation: GeoLocation) -> Double {
        getSolarElevationAzimuth(instant, geoLocation, isAzimuth: false)
    }

    /// Azimuth of the sun in degrees, eastward from north, at `instant`.
    public func getSolarAzimuth(instant: Date, geoLocation: GeoLocation) -> Double {
        getSolarElevationAzimuth(instant, geoLocation, isAzimuth: true)
    }

    private func getSolarElevationAzimuth(_ instant: Date, _ geoLocation: GeoLocation, isAzimuth: Bool) -> Double {
        let lat = geoLocation.lat
        let lon = geoLocation.lng
        let (julianDay, fractionalDay) = Self.julianDayAndFraction(instant)
        let jc = getJulianCenturiesFromJulianDay(julianDay + fractionalDay)
        let decl = Self.getSunDeclination(jc)
        let eot = Self.getEquationOfTime(jc)
        let trueSolarTime = ((fractionalDay + eot / 1440.0 + lon / 360.0) + 2).truncatingRemainder(dividingBy: 1)
        let hourAngle = trueSolarTime * 2 * Double.pi - Double.pi
        let cosZenith = sinDegrees(lat) * sinDegrees(decl) + cosDegrees(lat) * cosDegrees(decl) * cos(hourAngle)
        let zenithDeg = acosDegrees(max(-1, min(1, cosZenith)))
        let elevation = (90.0 - zenithDeg) + Self.adjustElevationForRefraction(90.0 - zenithDeg)
        let azimuth: Double
        let azDenom = cosDegrees(lat) * sinDegrees(zenithDeg)
        if abs(azDenom) > 0.001 {
            let az = (sinDegrees(lat) * cosDegrees(zenithDeg) - sinDegrees(decl)) / azDenom
            azimuth = 180 - acosDegrees(max(-1, min(1, az))) * (hourAngle > 0 ? -1 : 1)
        } else {
            azimuth = lat > 0 ? 180 : 0
        }
        return isAzimuth ? (azimuth + 360).truncatingRemainder(dividingBy: 360) : elevation
    }

    private static func adjustElevationForRefraction(_ elevation: Double) -> Double {
        if elevation > 85.0 {
            return 0.0
        }
        let te = tanDegrees(elevation)
        let correction: Double
        if elevation > 5.0 {
            correction = 58.1 / te - 0.07 / pow(te, 3) + 0.000086 / pow(te, 5)
        } else if elevation > -0.575 {
            correction = 1735.0 + elevation * (-518.2 + elevation * (103.4 + elevation * (-12.79 + 0.711 * elevation)))
        } else {
            correction = -20.774 / te
        }
        return correction / 3600.0
    }

    private static func getSunHourAngle(_ latitude: Double, _ solarDeclination: Double, _ zenith: Double, _ solarEvent: SolarEvent) -> Double {
        let ratio = cosDegrees(zenith) / (cosDegrees(latitude) * cosDegrees(solarDeclination))
            - tanDegrees(latitude) * tanDegrees(solarDeclination)
        if ratio < -1.0 || ratio > 1.0 {
            return .nan // the sun never reaches this zenith (polar day / night)
        }
        let hourAngle = acos(ratio)
        return solarEvent == .sunset ? -hourAngle : hourAngle
    }

    private func getJulianCenturiesFromJulianDay(_ julianDayUT: Double) -> Double {
        var jde = julianDayUT
        if applyDeltaT {
            jde += Self.deltaT(julianDayUT) / 86400.0
        }
        return (jde - Self.julianDayJan12000) / Self.julianDaysPerCentury
    }

    private static func getSunDeclination(_ julianCenturies: Double) -> Double {
        let (lambda, beta) = getSunApparentEclipticCoordinates(julianCenturies)
        let epsilon = getTrueObliquity(julianCenturies)
        return asinDegrees(sinDegrees(beta) * cosDegrees(epsilon) + cosDegrees(beta) * sinDegrees(epsilon) * sinDegrees(lambda))
    }

    private static func getSunRightAscension(_ julianCenturies: Double) -> Double {
        let (lambda, beta) = getSunApparentEclipticCoordinates(julianCenturies)
        let epsilon = getTrueObliquity(julianCenturies)
        let y = sinDegrees(lambda) * cosDegrees(epsilon) - tanDegrees(beta) * sinDegrees(epsilon)
        let x = cosDegrees(lambda)
        return normalizeDegrees(toDegrees(atan2(y, x)))
    }

    private static func getSunApparentEclipticCoordinates(_ julianCenturies: Double) -> (lambda: Double, beta: Double) {
        let tau = julianCenturies / 10.0
        let earthL = toDegrees(VSOP87Earth.sumSeries(VSOP87Earth.l, tau))
        let earthB = toDegrees(VSOP87Earth.sumSeries(VSOP87Earth.b, tau))
        let earthR = VSOP87Earth.sumSeries(VSOP87Earth.r, tau)
        var theta = earthL + 180.0
        var beta = -earthB
        // FK5 frame correction (Meeus 25.9)
        let lambdaPrime = theta - 1.397 * julianCenturies - 0.00031 * julianCenturies * julianCenturies
        let deltaLongFK5 = -0.09033 + 0.03916 * (cosDegrees(lambdaPrime) + sinDegrees(lambdaPrime)) * tanDegrees(beta)
        let deltaLatFK5 = 0.03916 * (cosDegrees(lambdaPrime) - sinDegrees(lambdaPrime))
        theta += deltaLongFK5 / 3600.0
        beta += deltaLatFK5 / 3600.0
        let nutation = getNutation(julianCenturies)
        let aberration = -20.4898 / earthR // arc-seconds
        let lambda = theta + nutation.deltaPsi / 3600.0 + aberration / 3600.0
        return (normalizeDegrees(lambda), beta)
    }

    private static func getTrueObliquity(_ julianCenturies: Double) -> Double {
        let seconds = 21.448 - julianCenturies * (46.8150 + julianCenturies * (0.00059 - julianCenturies * 0.001813))
        let epsilon0 = 23.0 + (26.0 + (seconds / 60.0)) / 60.0
        return epsilon0 + getNutation(julianCenturies).deltaEpsilon / 3600.0
    }

    /// Nutation in longitude and obliquity, in arc-seconds.
    private static func getNutation(_ t: Double) -> (deltaPsi: Double, deltaEpsilon: Double) {
        let omega = 125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000.0
        let lSun = 280.4665 + 36000.7698 * t
        let lMoon = 218.3165 + 481267.8813 * t
        let deltaPsi = -17.20 * sinDegrees(omega) - 1.32 * sinDegrees(2 * lSun) - 0.23 * sinDegrees(2 * lMoon) + 0.21 * sinDegrees(2 * omega)
        let deltaEpsilon = 9.20 * cosDegrees(omega) + 0.57 * cosDegrees(2 * lSun) + 0.10 * cosDegrees(2 * lMoon) - 0.09 * cosDegrees(2 * omega)
        return (deltaPsi, deltaEpsilon)
    }

    /// Equation of time in minutes.
    private static func getEquationOfTime(_ julianCenturies: Double) -> Double {
        let tau = julianCenturies / 10.0
        var l0 = 280.4664567 + tau * (360007.6982779 + tau * (0.03032028
            + tau * (1.0 / 49931.0 - tau * (1.0 / 15300.0 + tau / 2000000.0))))
        l0 = normalizeDegrees(l0)
        let alpha = getSunRightAscension(julianCenturies)
        let nutation = getNutation(julianCenturies)
        let epsilon = getTrueObliquity(julianCenturies)
        var e = l0 - 0.0057183 - alpha + (nutation.deltaPsi / 3600.0) * cosDegrees(epsilon)
        e = normalizeDegrees(e + 180) - 180
        return e * 4.0
    }
}
