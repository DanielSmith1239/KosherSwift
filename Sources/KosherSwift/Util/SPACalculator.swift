//
//  SPACalculator.swift
//  KosherSwift
//

import Foundation

/// Port of KosherJava master's `SPACalculator`: NREL's Solar Position Algorithm (Reda & Andreas, NREL/TP-560-34302)
/// with the abridged VSOP87 series. Sunrise and sunset are solved against the topocentric (observer-based) position
/// of the sun, and refraction uses the configured ``pressure`` and ``temperature``.
public final class SPACalculator: HorizonAdjustingCalculator, AstronomicalCalculator {
    /// Returns the name of the algorithm.
    ///
    /// - Returns: the descriptive name of the algorithm.
    public var calculatorName: String { "NREL Solar Position Algorithm" }

    /// Whether to convert UT to Terrestrial Time with Delta T. KosherJava default: true.
    public var applyDeltaT = true
    /// A fixed Delta T in seconds to use instead of the estimate, or nil to estimate it.
    public var deltaTOverride: Double? = nil
    /// Atmospheric pressure in millibars, used for refraction of solar elevation. KosherJava default: 1013.25.
    public var pressure = 1013.25
    /// Temperature in °C, used for refraction of solar elevation. KosherJava default: 10.
    public var temperature = 10.0

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
        let riseSet = solveRiseSet(Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day), location, adjustedZenith, solarEvent)
        if riseSet.isNaN {
            return .nan
        }
        return Self.normalizeHours(riseSet / 60)
    }

    private func solveRiseSet(_ jdDay: Double, _ location: GeoLocation, _ adjustedZenith: Double, _ solarEvent: SolarEvent) -> Double {
        let lonWest = -location.lng
        let lat = location.lat
        let elevation = location.elevation ?? 0
        // Closed-form first guess using the geocentric declination at local apparent noon
        let noonMin = solveNoonMidnight(jdDay, lonWest, .noon)
        let declNoon = solarCoords(jdDay + noonMin / 1440.0).delta
        let eot = equationOfTime(jdDay + noonMin / 1440.0)
        let cosH0 = (cosDegrees(adjustedZenith) - sinDegrees(lat) * sinDegrees(declNoon)) / (cosDegrees(lat) * cosDegrees(declNoon))
        if cosH0 < -1.0 || cosH0 > 1.0 {
            return .nan // sun never reaches this zenith (polar day / night)
        }
        let h0 = acosDegrees(cosH0)
        let signed = solarEvent == .sunrise ? h0 : -h0
        let guess = 720 + 4 * (lonWest - signed) - eot // minutes
        // Secant refinement on f(t) = topocentricTrueZenith(t) - adjustedZenith
        var t0 = guess
        var t1 = guess + 0.5
        var f0 = topocentricTrueZenith(jdDay + t0 / 1440.0, lat, location.lng, elevation) - adjustedZenith
        var f1 = topocentricTrueZenith(jdDay + t1 / 1440.0, lat, location.lng, elevation) - adjustedZenith
        var i = 0
        while i < 12 && abs(f1) > 1e-9 {
            let denom = f1 - f0
            if denom == 0 {
                break
            }
            let t2 = t1 - f1 * (t1 - t0) / denom
            t0 = t1
            f0 = f1
            t1 = t2
            f1 = topocentricTrueZenith(jdDay + t1 / 1440.0, lat, location.lng, elevation) - adjustedZenith
            i += 1
        }
        return t1
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
        let noon = solveNoonMidnight(Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day), -geoLocation.lng, .noon) / 60
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
        let midnight = solveNoonMidnight(Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day), -geoLocation.lng, .midnight) / 60
        return Self.normalizeHours(midnight)
    }

    /// Finds the UT at which the sun's apparent hour angle is 0 (noon) or 180 (midnight), in minutes after 0:00 UTC.
    private func solveNoonMidnight(_ julianDay: Double, _ lonWest: Double, _ solarEvent: SolarEvent) -> Double {
        let lonEast = -lonWest
        let targetHourAngle = solarEvent == .noon ? 0.0 : 180.0
        var dayFraction = (solarEvent == .noon ? 0.5 : 1.0) - lonEast / 360.0
        for _ in 0..<3 {
            let sc = solarCoords(julianDay + dayFraction)
            let hourAngle = ((sc.nu + lonEast - sc.alpha - targetHourAngle).truncatingRemainder(dividingBy: 360) + 540).truncatingRemainder(dividingBy: 360) - 180
            dayFraction -= hourAngle / 360.0
        }
        return dayFraction * 1440.0
    }

    /// UTC hour at which the sun is due east (90) or due west (270), or NaN if it never is that day.
    /// Only 90 and 270 are supported; KosherJava throws `IllegalArgumentException` for anything else.
    public func getTimeAtAzimuth(date: Date, geoLocation: GeoLocation, azimuth targetAzimuth: Double) -> Double {
        precondition(targetAzimuth == 90.0 || targetAzimuth == 270.0, "The targetAzimuth must be 90 or 270. Other azimuth values are not supported")
        let localDate = Self.localDate(date, geoLocation)
        let julianDay = Self.julianDay(year: localDate.year, month: localDate.month, day: localDate.day)
        let solarNoonBase = 0.5 - (geoLocation.lng / 360.0)
        var dateTime = solarNoonBase + (targetAzimuth == 90.0 ? 0.25 : 0.75)
        for _ in 0..<4 {
            let jd = julianDay + dateTime
            let decl = solarCoords(jd).delta
            let ratio = tanDegrees(decl) / tanDegrees(geoLocation.lat)
            if ratio.isNaN || ratio > 1.0 || ratio < -1.0 {
                return .nan
            }
            let offset = (targetAzimuth == 90.0 ? -1.0 : 1.0) * (acosDegrees(ratio) / 360.0)
            dateTime = solarNoonBase + offset - (equationOfTime(jd) / 1440.0)
        }
        return Self.normalizeHours(dateTime * 24.0)
    }

    /// Observed (refraction-corrected) topocentric elevation of the sun in degrees at `instant`.
    public func getSolarElevation(instant: Date, geoLocation: GeoLocation) -> Double {
        topocentric(Self.julianDay(instant), geoLocation.lat, geoLocation.lng, geoLocation.elevation ?? 0).elevation
    }

    /// Topocentric azimuth of the sun in degrees, eastward from north, at `instant`.
    public func getSolarAzimuth(instant: Date, geoLocation: GeoLocation) -> Double {
        topocentric(Self.julianDay(instant), geoLocation.lat, geoLocation.lng, geoLocation.elevation ?? 0).azimuth
    }

    private func deltaTSeconds(_ julianDayUT: Double) -> Double {
        applyDeltaT ? (deltaTOverride ?? Self.deltaT(julianDayUT)) : 0.0
    }

    /// Geocentric apparent right ascension (alpha), declination (delta), true obliquity (epsilon), apparent sidereal
    /// time at Greenwich (nu), all in degrees, and the earth-sun distance in AU.
    private func solarCoords(_ julianDayUT: Double) -> (alpha: Double, delta: Double, epsilon: Double, nu: Double, radius: Double) {
        let jde = julianDayUT + deltaTSeconds(julianDayUT) / 86400.0
        let jce = (jde - Self.julianDayJan12000) / Self.julianDaysPerCentury
        let jc = (julianDayUT - Self.julianDayJan12000) / Self.julianDaysPerCentury
        let jme = jce / 10.0
        let earthL = toDegrees(VSOP87Earth.sumSeries(VSOP87Earth.l, jme))
        let earthB = toDegrees(VSOP87Earth.sumSeries(VSOP87Earth.b, jme))
        let radius = VSOP87Earth.sumSeries(VSOP87Earth.r, jme)
        let theta = (earthL + 180.0).truncatingRemainder(dividingBy: 360.0)
        let beta = -earthB
        let nut = Self.nutation(jce)
        let epsilon = Self.meanObliquity(jme) + nut.deltaEpsilon
        let aberration = -20.4898 / (3600.0 * radius)
        let lambda = theta + nut.deltaPsi + aberration
        var nu0 = 280.46061837 + 360.98564736629 * (julianDayUT - Self.julianDayJan12000)
            + 0.000387933 * jc * jc - jc * jc * jc / 38710000.0
        nu0 = Self.normalizeDegrees(nu0)
        let nu = nu0 + nut.deltaPsi * cosDegrees(epsilon)
        let alpha = Self.normalizeDegrees(toDegrees(atan2(
            sinDegrees(lambda) * cosDegrees(epsilon) - tanDegrees(beta) * sinDegrees(epsilon),
            cosDegrees(lambda))))
        let delta = asinDegrees(sinDegrees(beta) * cosDegrees(epsilon) + cosDegrees(beta) * sinDegrees(epsilon) * sinDegrees(lambda))
        return (alpha, delta, epsilon, nu, radius)
    }

    /// True topocentric elevation (no refraction), observed elevation and azimuth, in degrees.
    private func topocentric(_ julianDayUT: Double, _ latitude: Double, _ longitude: Double, _ elevationMeters: Double) -> (trueElevation: Double, elevation: Double, azimuth: Double) {
        let sc = solarCoords(julianDayUT)
        let h = Self.normalizeDegrees((sc.nu + longitude - sc.alpha).truncatingRemainder(dividingBy: 360.0))
        // equatorial horizontal parallax of the sun
        let xi = 8.794 / (3600.0 * sc.radius)
        let u = atan(0.99664719 * tanDegrees(latitude))
        let x = cos(u) + (elevationMeters / 6378140.0) * cosDegrees(latitude)
        let y = 0.99664719 * sin(u) + (elevationMeters / 6378140.0) * sinDegrees(latitude)
        let deltaAlpha = toDegrees(atan2(-x * sinDegrees(xi) * sinDegrees(h), cosDegrees(sc.delta) - x * sinDegrees(xi) * cosDegrees(h)))
        let deltaPrime = toDegrees(atan2((sinDegrees(sc.delta) - y * sinDegrees(xi)) * cosDegrees(deltaAlpha),
                                         cosDegrees(sc.delta) - x * sinDegrees(xi) * cosDegrees(h)))
        let hPrime = h - deltaAlpha
        let e0 = asinDegrees(sinDegrees(latitude) * sinDegrees(deltaPrime) + cosDegrees(latitude) * cosDegrees(deltaPrime) * cosDegrees(hPrime))
        let e = e0 + refractionCorrection(e0)
        let gamma = toDegrees(atan2(sinDegrees(hPrime), cosDegrees(hPrime) * sinDegrees(latitude) - tanDegrees(deltaPrime) * cosDegrees(latitude)))
        let azimuth = Self.normalizeDegrees((gamma + 180.0).truncatingRemainder(dividingBy: 360.0))
        return (e0, e, azimuth)
    }

    private func topocentricTrueZenith(_ julianDayUT: Double, _ latitude: Double, _ longitude: Double, _ elevationMeters: Double) -> Double {
        90.0 - topocentric(julianDayUT, latitude, longitude, elevationMeters).trueElevation
    }

    private func refractionCorrection(_ trueElevation: Double) -> Double {
        // KosherJava uses the fixed solar radius here, only as a below-horizon cutoff
        if trueElevation < -1.0 * (solarRadius + refraction) {
            return 0.0
        }
        return (pressure / 1010.0) * (283.0 / (273.0 + temperature)) * 1.02 / (60.0 * tanDegrees(trueElevation + 10.3 / (trueElevation + 5.11)))
    }

    /// Equation of time in minutes.
    private func equationOfTime(_ julianDayUT: Double) -> Double {
        let sc = solarCoords(julianDayUT)
        let jde = julianDayUT + deltaTSeconds(julianDayUT) / 86400.0
        let jme = (jde - Self.julianDayJan12000) / Self.julianDaysPerCentury / 10.0
        var l0 = 280.4664567 + jme * (360007.6982779 + jme * (0.03032028
            + jme * (1.0 / 49931.0 - jme * (1.0 / 15300.0 + jme / 2000000.0))))
        l0 = Self.normalizeDegrees(l0)
        let deltaPsi = Self.nutation((jde - Self.julianDayJan12000) / Self.julianDaysPerCentury).deltaPsi
        var e = l0 - 0.0057183 - sc.alpha + deltaPsi * cosDegrees(sc.epsilon)
        e = Self.normalizeDegrees(e + 180) - 180
        return e * 4.0
    }

    private static func meanObliquity(_ jme: Double) -> Double {
        let u = jme / 10.0
        let seconds = 84381.448 - 4680.93 * u - 1.55 * u * u + 1999.25 * pow(u, 3) - 51.38 * pow(u, 4)
            - 249.67 * pow(u, 5) - 39.05 * pow(u, 6) + 7.12 * pow(u, 7) + 27.87 * pow(u, 8)
            + 5.79 * pow(u, 9) + 2.45 * pow(u, 10)
        return seconds / 3600.0
    }

    /// Nutation in longitude and obliquity, in degrees.
    private static func nutation(_ t: Double) -> (deltaPsi: Double, deltaEpsilon: Double) {
        let omega = 125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000.0
        let lSun = 280.4665 + 36000.7698 * t
        let lMoon = 218.3165 + 481267.8813 * t
        let deltaPsiArcsec = -17.20 * sinDegrees(omega) - 1.32 * sinDegrees(2 * lSun) - 0.23 * sinDegrees(2 * lMoon) + 0.21 * sinDegrees(2 * omega)
        let deltaEpsArcsec = 9.20 * cosDegrees(omega) + 0.57 * cosDegrees(2 * lSun) + 0.10 * cosDegrees(2 * lMoon) - 0.09 * cosDegrees(2 * omega)
        return (deltaPsiArcsec / 3600.0, deltaEpsArcsec / 3600.0)
    }
}
