//
//  NOAACalculator.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

/// Implementation of sunrise and sunset methods to calculate astronomical times based on the [NOAA](https://noaa.gov)
/// algorithm. This calculator uses the Java algorithm based on the implementation by [NOAA - National Oceanic and
/// Atmospheric Administration](https://noaa.gov)'s [Surface Radiation Research
/// Branch](https://www.srrb.noaa.gov/highlights/sunrise/sunrise.html). NOAA's
/// [implementation](https://www.srrb.noaa.gov/highlights/sunrise/solareqns.PDF) is based on equations from
/// [Astronomical Algorithms](https://www.amazon.com/Astronomical-Table-Sun-Moon-Planets/dp/1942675038/) by [Jean
/// Meeus](https://en.wikipedia.org/wiki/Jean_Meeus). Added to the algorithm is an adjustment of the zenith to account
/// for elevation. The algorithm can be found in the [Wikipedia Sunrise
/// Equation](https://en.wikipedia.org/wiki/Sunrise_equation) article.
public class NOAACalculator: AstronomicalCalculator {
    private static let julianDayJan12000 = 2451545.0
    private static let julianDaaysPerCentury = 36525.0
	
    required public init() { }
        
    /// - SeeAlso: `getUtcSunrise()`
    public func getUtcSunrise(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        let elevation = adjustForElevation ? (location.elevation ?? 0) : 0
        let adjustedZenith = NOAACalculator.adjustZenith(zenith: zenith, elevation: elevation)
        
		var sunrise = getSunriseUTC(julianDay: Self.getJulianDay(dateTime: date, timeZone: location.timezone), latitude: location.lat, longitude: -location.lng, zenith: adjustedZenith)
		
        sunrise = sunrise / 60
        // ensure that the time is >= 0 and < 24
        let normalized = sunrise.truncatingRemainder(dividingBy: 24)  
        return normalized < 0 ? normalized + 24 : normalized 
    }
    
    /// - SeeAlso: `getUtcSunset()`
    public func getUtcSunset(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double {
        let elevation = adjustForElevation ? location.elevation ?? 0 : 0
        let adjustedZenith = NOAACalculator.adjustZenith(zenith: zenith, elevation: elevation)

		var sunset = getSunsetUTC(julianDay: Self.getJulianDay(dateTime: date, timeZone: location.timezone), latitude: location.lat, longitude: -location.lng, zenith: adjustedZenith)
        sunset = sunset / 60
		return sunset > 0 ? sunset.truncatingRemainder(dividingBy: 24) : sunset.truncatingRemainder(dividingBy: 24) + 24
    }
    
    private static func getJulianDayFromJulianCenturies(_ julianCenturies: Double) -> Double {
        return julianCenturies * julianDaaysPerCentury + julianDayJan12000
      }
    
    private static func getSunGeometricMeanLongitude(_ julianCenturies: Double) -> Double {
        let longitude = 280.46646 + julianCenturies * (36000.76983 + 0.0003032 * julianCenturies)

		return longitude > 0
				? longitude.truncatingRemainder(dividingBy: 360)
				: longitude.truncatingRemainder(dividingBy: 360) + 360
    }
    
    private static func getSunGeometricMeanAnomaly(_ julianCenturies: Double) -> Double {
        return 357.52911 +
            julianCenturies *
                (35999.05029 - 0.0001537 * julianCenturies); // in degrees
      }
    
    private static func getEarthOrbitEccentricity(julianCenturies: Double) -> Double {
        return 0.016708634 -
            julianCenturies *
                (0.000042037 + 0.0000001267 * julianCenturies); // unitless
      }
    
    static func getSunEquationOfCenter(julianCenturies: Double) -> Double {
        let m = getSunGeometricMeanAnomaly(julianCenturies);

        let mrad = m.radians;
        let sinm = sin(mrad);
        let sin2m = sin(mrad + mrad);
        let sin3m = sin(mrad + mrad + mrad);

        return sinm *
                (1.914602 -
                    julianCenturies * (0.004817 + 0.000014 * julianCenturies)) +
            sin2m * (0.019993 - 0.000101 * julianCenturies) +
            sin3m * 0.000289; // in degrees
      }
    
    static func getSunTrueLongitude(_ julianCenturies: Double) -> Double {
        let sunLongitude = getSunGeometricMeanLongitude(julianCenturies)
        let center = getSunEquationOfCenter(julianCenturies: julianCenturies)
        return sunLongitude + center // in degrees
    }

    static func getSunApparentLongitude(_ julianCenturies: Double) -> Double {
        let sunTrueLongitude = getSunTrueLongitude(julianCenturies)
        let omega = 125.04 - 1934.136 * julianCenturies
        let lambda = sunTrueLongitude - 0.00569 - 0.00478 * sin(omega.radians)
        return lambda // in degrees
    }

    static func getMeanObliquityOfEcliptic(_ julianCenturies: Double) -> Double {
        let seconds = 21.448 -
            julianCenturies *
            (46.8150 +
                julianCenturies * (0.00059 - julianCenturies * (0.001813)))
        return 23.0 + (26.0 + (seconds / 60.0)) / 60.0 // in degrees
    }

    static func getObliquityCorrection(_ julianCenturies: Double) -> Double {
        let obliquityOfEcliptic = getMeanObliquityOfEcliptic(julianCenturies)
        let omega = 125.04 - 1934.136 * julianCenturies
        return obliquityOfEcliptic + 0.00256 * cos(omega.radians) // in degrees
    }

    func getSunDeclination(_ julianCenturies: Double) -> Double {
        let obliquityCorrection = NOAACalculator.getObliquityCorrection(julianCenturies)
        let lambda = NOAACalculator.getSunApparentLongitude(julianCenturies)
        let sint = sin(obliquityCorrection.radians) * sin(lambda.radians)
        let theta = asin(sint).degrees
        return theta // in degrees
    }

    func getEquationOfTime(_ julianCenturies: Double) -> Double {
        let epsilon = NOAACalculator.getObliquityCorrection(julianCenturies)
        let geomMeanLongSun = NOAACalculator.getSunGeometricMeanLongitude(julianCenturies)
        let eccentricityEarthOrbit = NOAACalculator.getEarthOrbitEccentricity(julianCenturies: julianCenturies)
        let geomMeanAnomalySun = NOAACalculator.getSunGeometricMeanAnomaly(julianCenturies)
        var y = tan(epsilon.radians / 2.0)
        y *= y
        let sin2l0 = sin(2.0 * geomMeanLongSun.radians)
        let sinm = sin(geomMeanAnomalySun.radians)
        let cos2l0 = cos(2.0 * geomMeanLongSun.radians)
        let sin4l0 = sin(4.0 * geomMeanLongSun.radians)
        let sin2m = sin(2.0 * geomMeanAnomalySun.radians)
        let equationOfTime = y * sin2l0 -
            2.0 * eccentricityEarthOrbit * sinm +
            4.0 * eccentricityEarthOrbit * y * sinm * cos2l0 -
            0.5 * y * y * sin4l0 -
            1.25 * eccentricityEarthOrbit * eccentricityEarthOrbit * sin2m
        return equationOfTime.degrees * 4.0 // in minutes of time
    }
	
	func getSunHourAngle(lat: Double, solarDec: Double, zenith: Double, solarEvent: SolarEvent) -> Double {
		let latRad = lat.radians
		let sdRad = solarDec.radians

		var hourAngle = acos(cos(zenith.radians) / (cos(latRad) * cos(sdRad)) - tan(latRad) * tan(sdRad))
		if solarEvent == .sunset {
			hourAngle = -hourAngle
		}
		return hourAngle
	}

	static func getJulianDay(dateTime: Date, timeZone: TimeZone) -> Double {
        var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: dateTime)
        var year = components.year!
		// KosherJava adds 1 to this, but it seems to be due to an effect of java's Calendar implementation
        var month = components.month!
        let day = components.day!
		if month <= 2 {
			year -= 1
			month += 12
		}
		let a = year / 100
		let b = 2 - a + a / 4
		return floor(365.25 * (Double(year) + 4716)) + floor(30.6001 * (Double(month) + 1)) + Double(day) + Double(b) - 1524.5
    }

    func getJulianCenturiesFromJulianDay(julianDay: Double) -> Double {
        return (julianDay - 2451545.0) / 36525.0
    }

    func getEquationOfTime(julianCenturies: Double) -> Double {
        let g = (357.528 + 0.9856003 * julianCenturies).truncatingRemainder(dividingBy: 360.0)
        let c = 1.9148 * sin(g.radians) + 0.0200 * sin((2 * g).radians) + 0.0003 * sin((3 * g).radians)
        let lambda = (280.460 + c).truncatingRemainder(dividingBy: 360.0)
        let e = 23.4393 - 0.0000004 * julianCenturies
        let y = tan(e.radians / 2) * tan(e.radians / 2)
        let equationOfTime = 4 * (y * sin(2 * lambda.radians) - 2 * e * sin(g.radians) + 4 * e * y * sin(g.radians) * cos(2 * lambda.radians) - 0.5 * y * y * sin(4 * lambda.radians) - 1.25 * e * e * sin(2 * g.radians))
        return equationOfTime
    }

    func getSunDeclination(julianCenturies: Double) -> Double {
        let g = (357.528 + 0.9856003 * julianCenturies).truncatingRemainder(dividingBy: 360.0)
        let q = 280.459 + 0.98564736 * julianCenturies
        let l = q + 1.915 * sin(g.radians) + 0.020 * sin((2 * g).radians)
        let r = 23.439 - 0.0000004 * julianCenturies
        let e = asin(sin(r.radians) * sin(l.radians))
        return e
    }
	
    func getSunriseUTC(julianDay: Double, latitude: Double, longitude: Double, zenith: Double) -> Double {
		let noonmin = getSolarNoonMidnightUTC(julianDay: julianDay, longitude: longitude, solarEvent: .noon)
        let tnoon = getJulianCenturiesFromJulianDay(julianDay: julianDay + noonmin / 1440.0)
        var eqTime = getEquationOfTime(tnoon)
        var solarDec = getSunDeclination(tnoon)
        var hourAngle = getSunHourAngle(lat: latitude, solarDec: solarDec, zenith: zenith, solarEvent: .sunrise)
        var delta = longitude - hourAngle.degrees
        var timeDiff = 4 * delta // in minutes of time
        var timeUTC = 720 + timeDiff - eqTime // in minutes
		let newt = getJulianCenturiesFromJulianDay(julianDay: julianDay + timeUTC / 1440.0)
        eqTime = getEquationOfTime(newt)
        solarDec = getSunDeclination(newt)
		hourAngle = getSunHourAngle(lat: latitude, solarDec: solarDec, zenith: zenith, solarEvent: .sunrise)
        delta = longitude - hourAngle.degrees
        timeDiff = 4 * delta
        timeUTC = 720 + timeDiff - eqTime // in minutes
        return timeUTC
    }
	
	/// Return the [Universal Coordinated Time](https://en.wikipedia.org/wiki/Universal_Coordinated_Time) (UTC) of
	/// [solar noon](https://en.wikipedia.org/wiki/Noon#Solar_noon) for the given day at the given location on earth.
	/// This implementation returns true solar noon as opposed to the time halfway between sunrise and sunset. Other
	/// calculators may return a more simplified calculation of halfway between sunrise and sunset. See [The Definition
	/// of *Chatzos*](https://kosherjava.com/2020/07/02/definition-of-chatzos/) for details on solar noon calculations.
	///
	/// - Parameters:
	///   - date: The Calendar representing the date to calculate solar noon for
	///   - geoLocation: The location information used for astronomical calculating sun times. This class uses only
	///     requires the longitude for calculating noon since it is the same time anywhere along the
	///     longitude line.
	/// - Returns: the time in minutes from zero UTC
	/// - SeeAlso: `getUTCNoon()`
	public func getUTCNoon(date: Date, geoLocation: GeoLocation) -> Double {
		let noon = getSolarNoonMidnightUTC(julianDay: Self.getJulianDay(dateTime: date, timeZone: geoLocation.timezone), longitude: -geoLocation.lng, solarEvent: .noon) / 60
		return noon > 0 
            ? noon.truncatingRemainder(dividingBy: 24)
            : noon.truncatingRemainder(dividingBy: 24) + 24
	}
	
	/// Return the [Universal Coordinated Time](https://en.wikipedia.org/wiki/Universal_Coordinated_Time) (UTC) of the current day [solar noon](http://en.wikipedia.org/wiki/Noon#Solar_noon) or the the upcoming midnight (about 12 hours after solar noon) of the given day at the given location on earth.
	/// - Returns: the time in minutes from zero UTC
	/// - Parameters:
	///   - julianDay: The Julian day since [J2000.0](https://en.wikipedia.org/wiki/Epoch_(astronomy)#J2000).
	///   - longitude: The longitude of observer in degrees
	///   - solarEvent: If the calculation is for `noon` or `midnight`
	/// ## See Also
	/// - ``getUTCNoon(date:geoLocation:)``
	func getSolarNoonMidnightUTC(julianDay: Double, longitude: Double, solarEvent: SolarEvent) -> Double {
		let julianDay = (solarEvent == .noon) ? julianDay : julianDay + 0.5
		let tnoon = getJulianCenturiesFromJulianDay(julianDay: julianDay + longitude / 360.0)
		var equationOfTime = getEquationOfTime(tnoon)
		var solNoonUTC = (longitude * 4) - equationOfTime
		
		//second pass
        var newt: Double = 0
        for _ in 0..<2 {
            newt = getJulianCenturiesFromJulianDay(julianDay: julianDay + solNoonUTC / 1440.0)
            equationOfTime = getEquationOfTime(newt)
            solNoonUTC = (solarEvent == .noon ? 720 : 1440) + (longitude * 4) - equationOfTime
        }
		
		return (solarEvent == .noon ? 720 : 1440) + (longitude * 4) - equationOfTime
	}
    
    func getSolarNoonUTC(julianCenturies: Double, longitude: Double) -> Double {
        // First pass uses approximate solar noon to calculate eqtime
        let tnoon = getJulianCenturiesFromJulianDay(
            julianDay: NOAACalculator.getJulianDayFromJulianCenturies(julianCenturies) + longitude / 360.0)
        var eqTime = getEquationOfTime(tnoon)
        let solNoonUTC = 720 + (longitude * 4) - eqTime // min
        let newt = getJulianCenturiesFromJulianDay(
            julianDay: NOAACalculator.getJulianDayFromJulianCenturies(julianCenturies) -
                0.5 +
                solNoonUTC / 1440.0)
        eqTime = getEquationOfTime(newt)
        return 720 + (longitude * 4) - eqTime // min
    }

    func getSunsetUTC(julianDay: Double, latitude: Double, longitude: Double, zenith: Double) -> Double {
        let julianCenturies = getJulianCenturiesFromJulianDay(julianDay: julianDay)
        let noonmin = getSolarNoonUTC(julianCenturies: julianCenturies, longitude: longitude)
        let tnoon = getJulianCenturiesFromJulianDay(julianDay: julianDay + noonmin / 1440.0)
        let eqTime = getEquationOfTime(tnoon)
        let solarDec = getSunDeclination(tnoon)
        let hourAngle = getSunHourAngle(lat: latitude, solarDec: solarDec, zenith: zenith, solarEvent: .sunset)
        let delta = longitude - hourAngle.degrees
        let timeDiff = 4 * delta
        var timeUTC = 720 + timeDiff - eqTime
        let newt = getJulianCenturiesFromJulianDay(julianDay: NOAACalculator.getJulianDayFromJulianCenturies(julianCenturies) + timeUTC / 1440.0)
        let eqTime2 = getEquationOfTime(newt)
        let solarDec2 = getSunDeclination(newt)
		let hourAngle2 = getSunHourAngle(lat: latitude, solarDec: solarDec2, zenith: zenith, solarEvent: .sunset)
        let delta2 = longitude - hourAngle2.degrees
        let timeDiff2 = 4 * delta2
        timeUTC = 720 + timeDiff2 - eqTime2
        return timeUTC
    }
}

extension Double {
    var radians: Double {
		Measurement(value: self, unit: UnitAngle.degrees).converted(to: .radians).value
    }
    
    var degrees: Double {
		Measurement(value: self, unit: UnitAngle.radians).converted(to: .degrees).value
    }
}
