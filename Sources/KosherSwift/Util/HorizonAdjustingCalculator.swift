//
//  HorizonAdjustingCalculator.swift
//  KosherSwift
//

import Foundation

/// Shared base for the calculators ported from KosherJava master (SunTimesCalculator, SPACalculator and
/// MeeusCalculator). It carries KosherJava master's `AstronomicalCalculator` horizon settings, which differ from the
/// KosherJava 2.5.0 constants NOAACalculator uses: the sun's apparent radius varies with the date (instead of a
/// fixed 16′) and the earth radius is the IUGG mean radius, 6371.0088 km (instead of 6356.9 km).
open class HorizonAdjustingCalculator {
    /// Atmospheric refraction at the horizon in degrees. KosherJava default: 34′.
    public var refraction = 34 / 60.0
    /// Fixed solar radius in degrees, used when useApparentSolarRadius is false. Setting it turns useApparentSolarRadius off, as in KosherJava.
    public var solarRadius = 16 / 60.0 {
        didSet { useApparentSolarRadius = false }
    }
    /// Whether sunrise and sunset use the sun's apparent radius for the date instead of solarRadius. KosherJava default: true.
    public var useApparentSolarRadius = true
    /// Earth radius in km, used for the elevation adjustment. KosherJava default: 6371.0088.
    public var earthRadius = 6371.0088
    
    public required init() { }
    
    static let geometricZenith = 90.0
    
    func getElevationAdjustment(_ elevation: Double) -> Double {
        acosDegrees(earthRadius / (earthRadius + (elevation / 1000))) 
    }
    
    /// KosherJava master `adjustZenith(zenith, elevation, localDate)`: only exactly 90° (sunrise/sunset) is adjusted.
    func adjustZenith(_ zenith: Double, elevation: Double, year: Int, month: Int, day: Int) -> Double {
        guard zenith == Self.geometricZenith else { return zenith }
        let radius = useApparentSolarRadius ? Self.apparentSolarRadius(month: month, day: day) : solarRadius
        return zenith + radius + refraction + getElevationAdjustment(elevation)
    }
    
    /// KosherJava master `getApparentSolarRadius(LocalDate)`: the table is indexed by day of year in the non-leap year 2050,
    /// so 29 February uses 28 February's value.
    public static func apparentSolarRadius(month: Int, day: Int) -> Double {
        let daysBeforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        let dayOfYear = daysBeforeMonth[month - 1] + min(day, month == 2 ? 28 : day)
        return solarRadiusByDayOfYear[dayOfYear - 1]
    }
    
    /// The calendar day of `date` in the location's time zone, as KosherJava's `LocalDate`.
    static func localDate(_ date: Date, _ location: GeoLocation) -> (year: Int, month: Int, day: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timezone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year!, c.month!, c.day!)
    }
    
    static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var year = year
        var month = month
        if month <= 2 {
            year -= 1
            month += 12
        }
        let a = year / 100
        let b = 2 - a + a / 4
        return floor(365.25 * Double(year + 4716)) + floor(30.6001 * Double(month + 1)) + Double(day) + Double(b) - 1524.5
    }
    
    /// Julian day of an instant (UTC).
    static func julianDay(_ instant: Date) -> Double {
        let (midnight, fractionalDay) = julianDayAndFraction(instant)
        return midnight + fractionalDay
    }
    
    /// The Julian day of the instant's UTC date and the fraction of the day elapsed, computed as KosherJava does
    /// (`(hour + (minute + (second + nano / 1e9) / 60) / 60) / 24`) so the low bits match.
    static func julianDayAndFraction(_ instant: Date) -> (julianDay: Double, fractionalDay: Double) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: instant)
        let fractionalDay = (Double(c.hour!) + (Double(c.minute!) + (Double(c.second!) + Double(c.nanosecond!) / 1_000_000_000.0) / 60.0) / 60.0) / 24.0
        return (julianDay(year: c.year!, month: c.month!, day: c.day!), fractionalDay)
    }
    
    /// Delta T (TT − UT) in seconds, Espenak & Meeus polynomials, as in KosherJava master.
    static func deltaT(_ julianDay: Double) -> Double {
        let year = 2000.0 + (julianDay - 2451545.0) / 365.25
        if year >= 2005 && year < 2050 {
            let t = year - 2000
            return 62.92 + 0.32217 * t + 0.005589 * t * t
        } else if year >= 1986 && year < 2005 {
            let t = year - 2000
            return 63.86 + 0.3345 * t - 0.060374 * t * t + 0.0017275 * t * t * t
                + 0.000651814 * pow(t, 4) + 0.00002373599 * pow(t, 5)
        } else if year >= 1961 && year < 1986 {
            let t = year - 1975
            return 45.45 + 1.067 * t - t * t / 260.0 - t * t * t / 718.0
        } else if year >= 2050 && year < 2150 {
            return -20 + 32 * pow((year - 1820) / 100.0, 2) - 0.5628 * (2150 - year)
        } else {
            let u = (year - 1820) / 100.0
            return -20 + 32 * u * u
        }
    }
    
    /// Normalizes hours to [0, 24), like Java's `(x % 24 + 24) % 24`.
    static func normalizeHours(_ hours: Double) -> Double {
        (hours.truncatingRemainder(dividingBy: 24) + 24).truncatingRemainder(dividingBy: 24)
    }
    
    static func normalizeDegrees(_ degrees: Double) -> Double {
        (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }
    
    private static let solarRadiusByDayOfYear: [Double] = [
        0.27108024, 0.27108486, 0.27108790, 0.27108930, 0.27108899, 0.27108695, 0.27108316, 0.27107762, 0.27107033,
        0.27106133, 0.27105062, 0.27103826, 0.27102427, 0.27100873, 0.27099168, 0.27097320, 0.27095337, 0.27093228,
        0.27091002, 0.27088667, 0.27086231, 0.27083701, 0.27081079, 0.27078369, 0.27075569, 0.27072676, 0.27069684,
        0.27066588, 0.27063378, 0.27060048, 0.27056589, 0.27052995, 0.27049261, 0.27045383, 0.27041359, 0.27037186,
        0.27032864, 0.27028396, 0.27023782, 0.27019025, 0.27014129, 0.27009098, 0.27003938, 0.26998658, 0.26993264,
        0.26987767, 0.26982177, 0.26976506, 0.26970763, 0.26964958, 0.26959099, 0.26953191, 0.26947239, 0.26941242,
        0.26935200, 0.26929108, 0.26922962, 0.26916755, 0.26910482, 0.26904136, 0.26897712, 0.26891206, 0.26884614,
        0.26877935, 0.26871165, 0.26864306, 0.26857358, 0.26850321, 0.26843197, 0.26835989, 0.26828703, 0.26821343,
        0.26813918, 0.26806437, 0.26798910, 0.26791348, 0.26783763, 0.26776167, 0.26768569, 0.26760979, 0.26753404,
        0.26745846, 0.26738308, 0.26730790, 0.26723289, 0.26715800, 0.26708320, 0.26700842, 0.26693363, 0.26685877,
        0.26678380, 0.26670870, 0.26663342, 0.26655796, 0.26648229, 0.26640640, 0.26633030, 0.26625399, 0.26617748,
        0.26610082, 0.26602406, 0.26594728, 0.26587055, 0.26579398, 0.26571769, 0.26564180, 0.26556641, 0.26549164,
        0.26541756, 0.26534425, 0.26527174, 0.26520006, 0.26512920, 0.26505915, 0.26498987, 0.26492132, 0.26485345,
        0.26478622, 0.26471959, 0.26465351, 0.26458794, 0.26452285, 0.26445820, 0.26439396, 0.26433010, 0.26426661,
        0.26420348, 0.26414070, 0.26407832, 0.26401636, 0.26395489, 0.26389400, 0.26383378, 0.26377435, 0.26371580,
        0.26365825, 0.26360179, 0.26354651, 0.26349247, 0.26343971, 0.26338825, 0.26333807, 0.26328918, 0.26324153,
        0.26319510, 0.26314983, 0.26310568, 0.26306261, 0.26302057, 0.26297951, 0.26293938, 0.26290014, 0.26286173,
        0.26282411, 0.26278725, 0.26275111, 0.26271570, 0.26268102, 0.26264710, 0.26261399, 0.26258177, 0.26255053,
        0.26252037, 0.26249137, 0.26246366, 0.26243731, 0.26241239, 0.26238897, 0.26236707, 0.26234671, 0.26232790,
        0.26231061, 0.26229481, 0.26228048, 0.26226756, 0.26225602, 0.26224581, 0.26223687, 0.26222914, 0.26222257,
        0.26221708, 0.26221262, 0.26220912, 0.26220653, 0.26220480, 0.26220392, 0.26220388, 0.26220470, 0.26220642,
        0.26220910, 0.26221282, 0.26221768, 0.26222375, 0.26223114, 0.26223991, 0.26225014, 0.26226187, 0.26227512,
        0.26228992, 0.26230626, 0.26232413, 0.26234349, 0.26236433, 0.26238659, 0.26241024, 0.26243521, 0.26246145,
        0.26248890, 0.26251746, 0.26254708, 0.26257766, 0.26260913, 0.26264141, 0.26267446, 0.26270823, 0.26274270,
        0.26277789, 0.26281382, 0.26285054, 0.26288813, 0.26292666, 0.26296622, 0.26300686, 0.26304868, 0.26309171,
        0.26313601, 0.26318159, 0.26322848, 0.26327666, 0.26332612, 0.26337685, 0.26342881, 0.26348197, 0.26353627,
        0.26359167, 0.26364809, 0.26370545, 0.26376368, 0.26382267, 0.26388233, 0.26394256, 0.26400328, 0.26406442,
        0.26412593, 0.26418777, 0.26424995, 0.26431249, 0.26437542, 0.26443880, 0.26450270, 0.26456718, 0.26463231,
        0.26469815, 0.26476474, 0.26483213, 0.26490034, 0.26496937, 0.26503922, 0.26510990, 0.26518138, 0.26525364,
        0.26532664, 0.26540034, 0.26547467, 0.26554957, 0.26562495, 0.26570072, 0.26577676, 0.26585296, 0.26592922,
        0.26600544, 0.26608154, 0.26615745, 0.26623314, 0.26630859, 0.26638382, 0.26645884, 0.26653372, 0.26660850,
        0.26668323, 0.26675798, 0.26683280, 0.26690773, 0.26698280, 0.26705803, 0.26713345, 0.26720905, 0.26728485,
        0.26736083, 0.26743698, 0.26751326, 0.26758964, 0.26766606, 0.26774245, 0.26781872, 0.26789476, 0.26797045,
        0.26804569, 0.26812035, 0.26819433, 0.26826755, 0.26833992, 0.26841141, 0.26848200, 0.26855170, 0.26862051,
        0.26868849, 0.26875567, 0.26882211, 0.26888786, 0.26895296, 0.26901746, 0.26908139, 0.26914478, 0.26920767,
        0.26927006, 0.26933199, 0.26939345, 0.26945445, 0.26951496, 0.26957497, 0.26963442, 0.26969325, 0.26975136,
        0.26980865, 0.26986502, 0.26992034, 0.26997450, 0.27002740, 0.27007895, 0.27012907, 0.27017773, 0.27022491,
        0.27027060, 0.27031483, 0.27035764, 0.27039906, 0.27043914, 0.27047794, 0.27051549, 0.27055186, 0.27058709,
        0.27062122, 0.27065430, 0.27068636, 0.27071746, 0.27074761, 0.27077684, 0.27080516, 0.27083256, 0.27085899,
        0.27088442, 0.27090875, 0.27093191, 0.27095379, 0.27097427, 0.27099326, 0.27101067, 0.27102640, 0.27104041,
        0.27105266, 0.27106312, 0.27107182, 0.27107876, 0.27108399]
}

// Same conversion constants as java.lang.Math.toRadians/toDegrees, so results match KosherJava to the last bits
private let degreesToRadians = 0.017453292519943295
private let radiansToDegrees = 57.29577951308232
func toRadians(_ degrees: Double) -> Double { degrees * degreesToRadians }
func toDegrees(_ radians: Double) -> Double { radians * radiansToDegrees }
func sinDegrees(_ angle: Double) -> Double { sin(toRadians(angle)) }
func cosDegrees(_ angle: Double) -> Double { cos(toRadians(angle)) }
func tanDegrees(_ angle: Double) -> Double { tan(toRadians(angle)) }
func acosDegrees(_ value: Double) -> Double { toDegrees(acos(value)) }
func asinDegrees(_ value: Double) -> Double { toDegrees(asin(value)) }
