//
//  NOAACalculatorTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's util/NOAACalculatorTest.java. Results are UTC hours. KosherJava master asserts them to
//  1e-8 hours against its refined NOAA calculation; KosherSwift matches KosherJava 2.5.0's, so they're compared to the
//  second (1/3600 hour). Where master's refinements move a sunrise or sunset by more than a second (near the equator,
//  far south, and in 2100), the expected value is KosherJava 2.5.0's, with master's value in the comment. KosherSwift has no getUTCMidnight, getTimeAtAzimuth, getSolarElevation, getSolarAzimuth or
//  getCalculatorName, so those tests aren't ported.
//

import XCTest
@testable import KosherSwift

final class NOAACalculatorTests: XCTestCase {
    private let zenith = 90.0 // AstronomicalCalculator.GEOMETRIC_ZENITH
    private let noEvent = Double.nan
    private let oneSecondInHours = 1 / 3600.0

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

    private func assertUtcHour(_ label: String, _ expected: Double, _ actual: Double, line: UInt = #line) {
        if expected.isNaN {
            XCTAssertTrue(actual.isNaN, "\(label) should have no event (NaN)", line: line)
        } else {
            XCTAssertEqual(actual, expected, accuracy: oneSecondInHours, label, line: line)
        }
    }

    func testGetUTCSunrise() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 11.13540831),
            ("LA Standard Date", "2017-10-17", "LA", 14.00704301),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 4.11872483),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 19.68246214),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 9.39039065), // KosherJava 2.5.0; master 9.39008078
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 18.60454635), // KosherJava 2.5.0; master 18.60488873
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 12.95673616), // KosherJava 2.5.0; master 12.95743787
            ("NJ Future DeltaT", "2100-07-04", "NJ", 9.44852313), // KosherJava 2.5.0; master 9.44903860
        ]
        for (label, day, location, expected) in cases {
            assertUtcHour(label, expected, NOAACalculator().getUtcSunrise(date: date(day), location: geo(location), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCSunset() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 22.24081501),
            ("LA Standard Date", "2017-10-17", "LA", 1.31823827),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 15.64544001),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 8.56373515),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 21.53115240), // KosherJava 2.5.0; master 21.53146217
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 5.65815498), // KosherJava 2.5.0; master 5.65781259
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 20.21326791), // KosherJava 2.5.0; master 20.21256620
            ("NJ Future DeltaT", "2100-07-04", "NJ", 0.58117460), // KosherJava 2.5.0; master 0.58065990
        ]
        for (label, day, location, expected) in cases {
            assertUtcHour(label, expected, NOAACalculator().getUtcSunset(date: date(day), location: geo(location), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCNoon() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 16.69315478),
            ("LA Standard Date", "2017-10-17", "LA", 19.66659743),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 9.87832210),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", 11.42090460),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 2.12779094),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 15.46078241),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 0.13137581),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 16.58492880),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 17.01703523),
        ]
        for (label, day, location, expected) in cases {
            assertUtcHour(label, expected, NOAACalculator().getUTCNoon(date: date(day), geoLocation: geo(location)))
        }
    }

    func testGetUTCSunriseAtZenith() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ Civil", "2017-10-17", "NJ", 96.0, 10.70891556),
            ("NJ Nautical", "2017-10-17", "NJ", 102.0, 10.17562194),
            ("NJ Astronomical", "2017-10-17", "NJ", 108.0, 9.64406486),
            ("Sydney Civil", "2020-02-29", "SYDNEY", 96.0, 19.27827196),
        ]
        for (label, day, location, zenith, expected) in cases {
            assertUtcHour(label, expected, NOAACalculator().getUtcSunrise(date: date(day), location: geo(location), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCSunriseWithoutElevationAdjustment() {
        let cases: [(String, String, String, Double)] = [
            ("NJ No Elev Adj", "2017-10-17", "NJ", 11.17291440),
            ("Jerusalem No Elev Adj", "1955-02-26", "JERUSALEM", 4.18884065),
        ]
        for (label, day, location, expected) in cases {
            assertUtcHour(label, expected, NOAACalculator().getUtcSunrise(date: date(day), location: geo(location), zenith: zenith, adjustForElevation: false))
        }
    }
}
