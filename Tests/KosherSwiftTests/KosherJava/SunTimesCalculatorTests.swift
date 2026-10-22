//
//  SunTimesCalculatorTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's util/SunTimesCalculatorTest.java, asserted to the same 1e-8 hours.
//  The three UnsupportedOperationException tests aren't ported: the Swift class simply doesn't have those methods.
//

import XCTest
@testable import KosherSwift

final class SunTimesCalculatorTests: XCTestCase {
    private func calculator() -> SunTimesCalculator { SunTimesCalculator() }
    private let zenith = 90.0 // AstronomicalCalculator.GEOMETRIC_ZENITH
    private let noEvent = Double.nan
    private let delta = 1e-8 // KosherJava's DELTA, in hours

    private func geo(_ location: String) -> GeoLocation {
        switch location {
        case "NJ": return TestLocations.nj(TestLocations.utc)
        case "LA": return TestLocations.la(TestLocations.utc)
        case "JERUSALEM": return TestLocations.jerusalem(TestLocations.utc)
        case "NORWAY": return TestLocations.norway(TestLocations.utc)
        case "SYDNEY": return TestLocations.sydney(TestLocations.utc)
        case "MACAPA": return TestLocations.macapa(TestLocations.utc)
        case "SUVA": return TestLocations.suva(TestLocations.utc)
        case "USHUAIA": return TestLocations.ushuaia(TestLocations.utc)
        default: fatalError("Unknown location: \(location)")
        }
    }

    private func date(_ iso: String) -> Date {
        let parts = iso.split(separator: "-").map { Int($0)! }
        return TestLocations.date(parts[0], parts[1], parts[2], in: TestLocations.utc)
    }

    /// KosherJava's `LocalDateTime.parse("yyyy-MM-dd HH:mm:ss").toInstant(ZoneOffset.UTC)`.
    private func instant(_ dateTime: String) -> Date {
        TestLocations.instant(dateTime.replacingOccurrences(of: " ", with: "T") + "Z")
    }

    private func assertUtcHour(_ label: String, _ expected: Double, _ actual: Double, line: UInt = #line) {
        if expected.isNaN {
            XCTAssertTrue(actual.isNaN, "\(label) should have no event (NaN)", line: line)
        } else {
            XCTAssertEqual(actual, expected, accuracy: delta, label, line: line)
        }
    }

    func testGetUTCSunrise() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 11.12643745),
            ("LA Standard Date", "2017-10-17", "LA", 14.00076197),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 4.11037446),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 19.68724563),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 9.39464043),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 18.60351329),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 12.95527929),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 9.43972880),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCSunset() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 22.25383390),
            ("LA Standard Date", "2017-10-17", "LA", 1.32889810),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 15.65101844),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 8.56114598),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 21.53593703),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 5.65641338),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 20.20896383),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 0.57971462),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunset(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCNoon() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 16.69011947),
            ("LA Standard Date", "2017-10-17", "LA", 19.66482200),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 9.88071908),
            ("Norway Polar No Noon", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 2.12420286),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 15.46529012),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 0.12996327),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 16.58212152),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 17.00973685),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCNoon(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetUTCMidnight() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 4.69011947),
            ("LA Standard Date", "2017-10-17", "LA", 7.66482200),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 21.88071908),
            ("Norway Polar No Midnight", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 14.12420286),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 3.46529012),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 12.12996327),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 4.58212152),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 5.00973685),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCMidnight(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetUTCSunriseAtZenith() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ Civil", "2017-10-17", "NJ", 96.0, 10.70056986),
            ("NJ Nautical", "2017-10-17", "NJ", 102.0, 10.16784691),
            ("NJ Astronomical", "2017-10-17", "NJ", 108.0, 9.63665090),
            ("Sydney Civil", "2020-02-29", "SYDNEY", 96.0, 19.28346936),
        ]
        for c in cases {
            assertUtcHour(c.0, c.4, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: c.3, adjustForElevation: true))
        }
    }

    func testGetUTCSunriseWithoutElevationAdjustment() {
        let cases: [(String, String, String, Double)] = [
            ("NJ No Elev Adj", "2017-10-17", "NJ", 11.16388056),
            ("Jerusalem No Elev Adj", "1955-02-26", "JERUSALEM", 4.18050398),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: false))
        }
    }

    func testGetCalculatorName() {
        XCTAssertEqual(calculator().calculatorName, "US Naval Almanac Algorithm")
    }
}
