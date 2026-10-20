//
//  GeoLocation.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

import Foundation

public struct GeoLocation {
    public let lat: Double
    public let lng: Double
    public let timezone: TimeZone
    public let name: String
    
    public let elevation: Double?
    
    public init(lat: Double, lng: Double, timezone: TimeZone = Calendar.current.timeZone, elevation: Double? = nil, name: String = "") {
        self.lat = lat
        self.lng = lng
        self.timezone = timezone
        self.elevation = elevation
        self.name = name
    }
    
    /// The time zone's standard (non-DST) offset in milliseconds, equivalent to Java's `TimeZone.getRawOffset()`.
    var rawOffsetMillis: Double {
        Double(timezone.secondsFromGMT() - Int(timezone.daylightSavingTimeOffset())) * 1000
    }
    
    /// The offset in milliseconds of local mean time at this longitude from standard time in the time zone.
    var localMeanTimeOffset: Double {
        lng * 4 * GeoLocation.minuteMillis - rawOffsetMillis
    }
    
    var localMeanTimeOffsetWithMillis: Double {
        lng * 4 * GeoLocation.minuteMillis - Double(timezone.secondsFromGMT() * 1000)
    }
    
    var antimeridianAdjustment: Int {
        let localHourOffset = localMeanTimeOffset / GeoLocation.hourMillis
        
        if localHourOffset >= 20 {
            return 1
        } else if localHourOffset <= -20 {
            return -1
        }
        
        return 0
    }
}
extension GeoLocation {
    static let minuteMillis: Double = 60 * 1000
    static let hourMillis = minuteMillis * 60
    
    static func radians(_ deg: Double) -> Double {
        deg * .pi / 180
    }
    
    static func degrees(_ rad: Double) -> Double {
        rad * 180.0 / .pi
    }
    
    private static func vincentyFormula(location: GeoLocation, destination: GeoLocation, _ formula: CalculationType) -> Double {
        let a: Double = 6378137
        let b: Double = 6356752.3142
        let f: Double = 1 / 298.257223563 // WGS-84 ellipsiod
        let L: Double = radians(destination.lng - location.lng)
        let u1: Double = atan((1 - f) * tan(radians(location.lat)))
        let u2: Double = atan((1 - f) * tan(radians(destination.lat)))
        let sinU1: Double = sin(u1), cosU1: Double = cos(u1)
        let sinU2: Double = sin(u2), cosU2: Double = cos(u2)
        var lambda: Double = L
        var lambdaP: Double = 2 * Double.pi
        var iterLimit: Double = 20
        var sinLambda: Double = 0
        var cosLambda: Double = 0
        var sinSigma: Double = 0
        var cosSigma: Double = 0
        var sigma: Double = 0
        var sinAlpha: Double = 0
        var cosSqAlpha: Double = 0
        var cos2SigmaM: Double = 0
        var C: Double
        while (abs(lambda - lambdaP) > 1e-12 && iterLimit > 0) {
            sinLambda = sin(lambda)
            cosLambda = cos(lambda)
            sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
                            (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
                            (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
            if (sinSigma == 0) {
                return 0 // co-incident points
            }
            cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
            sigma = atan2(sinSigma, cosSigma)
            sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
            cosSqAlpha = 1 - sinAlpha * sinAlpha
            cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
            if (cos2SigmaM.isNaN) {
                cos2SigmaM = 0
            } // equatorial line: cosSqAlpha=0 (§6)
            C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
            lambdaP = lambda
            lambda = L +
            (1 - C) *
            f *
            sinAlpha *
            (sigma +
             C *
             sinSigma *
             (cos2SigmaM +
              C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
            iterLimit -= 1
        }
        if (iterLimit == 0) {
            return Double.nan // formula failed to converge
        }
        let uSq: Double = cosSqAlpha * (a * a - b * b) / (b * b)
        let A: Double = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
        let B: Double = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
        let deltaSigma: Double = B *
        sinSigma *
        (cos2SigmaM +
         B /
         4 *
         (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
          B /
          6 *
          cos2SigmaM *
          (-3 + 4 * sinSigma * sinSigma) *
          (-3 + 4 * cos2SigmaM * cos2SigmaM)))
        let distance: Double = b * A * (sigma - deltaSigma)
        // initial bearing
        
        let fwdAz: Double = degrees(
            atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
        // final bearing
        let revAz: Double = degrees(
            atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda))
        if (formula == .distance) {
            return distance
        } else if (formula == .initialBearing) {
            return fwdAz
        } else if (formula == .finalBearing) {
            return revAz
        } else {
            // should never happen
            return Double.nan
        }
    }
    
    static func getGeodesicInitialBearing(location: GeoLocation, destination: GeoLocation) -> Double {
        return vincentyFormula(location: location, destination: destination, .initialBearing)
    }
    
    static func getGeodesicFinalBearing(location: GeoLocation, destination: GeoLocation) -> Double {
        return vincentyFormula(location: location, destination: destination, .finalBearing)
    }
    
    static func getGeodesicDistance(location: GeoLocation, destination: GeoLocation) -> Double {
        return vincentyFormula(location: location, destination: destination, .distance)
    }
    
    static func getRhumbLineBearing(location: GeoLocation, destination: GeoLocation) -> Double {
        var dLon = radians(destination.lng - location.lng);
        let dPhi = log(tan(radians(destination.lat) / 2 + .pi / 4) /
                       tan(radians(location.lat) / 2 + .pi / 4))
        if (abs(dLon) > .pi) {
            dLon = dLon > 0 ? -(2 * .pi - dLon) : (2 * .pi + dLon)
        }
        
        return degrees(atan2(dLon, dPhi));
    }
    
    static func getRhumbLineDistance(location: GeoLocation, destination: GeoLocation) -> Double {
        let earthRadius = 6378137.0 // Earth's radius in meters (WGS-84)
        let dLat = radians(location.lat) - radians(destination.lat)
        var dLon = abs(radians(location.lng) - radians(destination.lng))
        let dPhi = log(tan(radians(location.lat) / 2 + .pi / 4) /
                       tan(radians(destination.lat) / 2 + .pi / 4))
        var q = dLat / dPhi
        
        if (!q.isFinite) {
            q = cos(radians(destination.lat))
        }
        // if dLon over 180° take shorter rhumb across 180° meridian:
        if (dLon > .pi) {
            dLon = 2 * .pi - dLon
        }
        let d = sqrt(dLat * dLat + q * q * dLon * dLon)
        return d * earthRadius
    }
}


enum CalculationType {
    case distance, initialBearing, finalBearing
}
