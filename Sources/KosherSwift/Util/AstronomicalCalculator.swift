//
//  AstronomicalCalculator.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

/// An abstract class that all sun time calculating classes extend. This allows the algorithm used to be changed at
/// runtime, easily allowing comparison the results of using different algorithms.
///
/// - ToDo: Consider methods that would allow atmospheric modeling. This can currently be adjusted by setting the
///   refraction.
public protocol AstronomicalCalculator {
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
    func getUtcSunrise(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double

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
    func getUtcSunset(date: Date, location: GeoLocation, zenith: Double, adjustForElevation: Bool) -> Double
    
    init()

	/// Return [solar noon](https://en.wikipedia.org/wiki/Noon#Solar_noon) (UTC) for the given day at the given location
	/// on earth. The the `NOAACalculator` implementation calculates true solar noon, while the `SunTimesCalculator`
	/// approximates it, calculating the time as halfway between sunrise and sunset.
	///
	/// - Parameters:
	///   - date: Used to calculate day of year.
	///   - geoLocation: The location information used for astronomical calculating sun times.
	/// - Returns: the time in minutes from zero UTC
	func getUTCNoon(date: Date, geoLocation: GeoLocation) -> Double
}

extension AstronomicalCalculator {
    /// Method to return the adjustment to the zenith required to account for the elevation. Since a person at a higher
    /// elevation can see farther below the horizon, the calculation for sunrise / sunset is calculated below the
    /// horizon used at sea level. This is only used for sunrise and sunset and not times before or after it such as
    /// nautical twilight since those calculations are based on the level of available light at the given dip below the
    /// horizon, something that is not affected by elevation, the adjustment should only made if the zenith == 90°
    /// adjusted for refraction and solar radius. The algorithm used is
    ///
    /// ```swift
    /// let elevationAdjustment = toDegrees(acos(earthRadiusInMeters / (earthRadiusInMeters + elevationMeters)))
    /// ```
    ///
    /// The source of this algorithm is [Calendrical Calculations](http://www.calendarists.com) by Edward M. Reingold
    /// and Nachum Dershowitz. An alternate algorithm that produces an almost identical (but not accurate) result found
    /// in Ma'aglay Tzedek by Moishe Kosower and other sources is:
    ///
    /// ```swift
    /// let elevationAdjustment = 0.0347 * sqrt(elevationMeters)
    /// ```
    ///
    /// - Parameter elevation: elevation in Meters.
    /// - Returns: the adjusted zenith
    static func getElevationAdjustment(_ elevation: Double) -> Double {
        // double elevationAdjustment = 0.0347 * Math.sqrt(elevation);
        GeoLocation.degrees(acos(AstronomicalCalculatorConstants.earthRadius / (AstronomicalCalculatorConstants.earthRadius + (elevation / 1000))));
      }
    
    /// Adjusts the zenith of astronomical sunrise and sunset to account for solar refraction, solar radius and
    /// elevation. The value for Sun's zenith and true rise/set Zenith (used in this class and subclasses) is the angle
    /// that the center of the Sun makes to a line perpendicular to the Earth's surface. If the Sun were a point and the
    /// Earth were without an atmosphere, true sunset and sunrise would correspond to a 90° zenith. Because the Sun is
    /// not a point, and because the atmosphere refracts light, this 90° zenith does not, in fact, correspond to true
    /// sunset or sunrise, instead the center of the Sun's disk must lie just below the horizon for the upper edge to be
    /// obscured. This means that a zenith of just above 90° must be used. The Sun subtends an angle of 16 minutes of
    /// arc (this can be changed via the `solarRadius` method , and atmospheric refraction accounts for 34 minutes or so
    /// (this can be changed via the `refraction` method), giving a total of 50 arcminutes. The total value for ZENITH
    /// is 90+(5/6) or 90.8333333° for true sunrise/sunset. Since a person at an elevation can see blow the horizon of a
    /// person at sea level, this will also adjust the zenith to account for elevation if available. Note that this will
    /// only adjust the value if the zenith is exactly 90 degrees. For values below and above this no correction is
    /// done. As an example, astronomical twilight is when the sun is 18° below the horizon or 108° below the zenith.
    /// This is traditionally calculated with none of the above mentioned adjustments. The same goes for various *tzais*
    /// and *alos* times such as the 16.1° dip used in `alos16Point1Degrees()`.
    ///
    /// - Parameters:
    ///   - zenith: the azimuth below the vertical zenith of 90°. For sunset typically the zenith used for the
    ///     calculation uses geometric zenith of 90° and adjusts this slightly to account for solar refraction
    ///     and the sun's radius. Another example would be `nauticalTwilightEnd` that passes `Zenith.nautical`
    ///     to this method.
    ///   - elevation: elevation in Meters.
    /// - Returns: The zenith adjusted to include the sun's radius, refraction and elevation adjustment. This will only
    ///   be adjusted for sunrise and sunset (if the zenith == 90°)
    /// - SeeAlso: `getElevationAdjustment()`
    static func adjustZenith(zenith: Double, elevation: Double) -> Double {
        var adjustedZenith = zenith
        if zenith == Zenith.geometric.rawValue {
            // only adjust if it is exactly sunrise or sunset
            adjustedZenith = zenith +
            (AstronomicalCalculatorConstants.solarRadius +
             AstronomicalCalculatorConstants.refraction +
             getElevationAdjustment(elevation));
        }
        return adjustedZenith;
    }
}

public class AstronomicalCalculatorConstants {
    static let refraction = 34 / 60.0
    static let solarRadius = 16 / 60.0
    static let earthRadius = 6356.9
}
