//
//  MeeusCalculatorTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's util/MeeusCalculatorTest.java, asserted to the same 1e-8 hours.
//  getTimeAtAzimuthRejectsUnsupportedAzimuth isn't ported: Swift traps on the precondition instead of throwing.
//

import XCTest
@testable import KosherSwift

final class MeeusCalculatorTests: XCTestCase {
    private func calculator() -> MeeusCalculator { MeeusCalculator() }
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
            ("NJ Standard Date", "2017-10-17", "NJ", 11.13565507),
            ("LA Standard Date", "2017-10-17", "LA", 14.00730639),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 4.11849856),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 19.68266925),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 9.38974837),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 18.60510228),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 12.95697826),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 9.44873166),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCSunset() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 22.24115497),
            ("LA Standard Date", "2017-10-17", "LA", 1.31857880),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 15.64527430),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 8.56381339),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 21.53114700),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 5.65803778),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 20.21223110),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 0.58039250),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunset(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCNoon() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 16.69344845),
            ("LA Standard Date", "2017-10-17", "LA", 19.66689969),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 9.87812628),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", 11.42050168),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 2.12793408),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 15.46045983),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 0.13159547),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 16.58453220),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 17.01674900),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCNoon(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetUTCMidnight() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 4.69183111),
            ("LA Standard Date", "2017-10-17", "LA", 7.66529295),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 21.87675832),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", 23.42232487),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 14.12636235),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 3.46440271),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 12.13342359),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 4.58635433),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 5.01821298),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCMidnight(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetTimeAtAzimuth() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ East", "2017-10-17", "NJ", 90.0, 9.96630242),
            ("NJ West", "2017-10-17", "NJ", 270.0, 23.43696025),
            ("LA East", "2017-10-17", "LA", 90.0, 12.71802243),
            ("LA West", "2017-10-17", "LA", 270.0, 2.63792382),
            ("Sydney East", "2020-02-29", "SYDNEY", 90.0, 20.92601400),
            ("Sydney West", "2020-02-29", "SYDNEY", 270.0, 7.34685529),
            ("Macapa East No Cross", "2000-01-01", "MACAPA", 90.0, noEvent),
            ("Polar East", "2017-06-21", "NORWAY", 90.0, 6.01986159),
        ]
        for c in cases {
            assertUtcHour(c.0, c.4, calculator().getTimeAtAzimuth(date: date(c.1), geoLocation: geo(c.2), azimuth: c.3))
        }
    }

    func testGetSolarElevation() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Noon", "2017-10-17 12:00:00", "NJ", 8.24234881),
            ("NJ Evening", "2017-10-17 18:30:00", "NJ", 33.57213757),
            ("LA Evening", "2017-10-17 20:00:00", "LA", 46.19473579),
            ("Polar Midnight", "2017-06-21 00:00:00", "NORWAY", 3.98711013),
            ("Sydney Morning", "2020-02-29 20:00:00", "SYDNEY", 2.89445709),
            ("Macapa Local Noon", "2000-01-01 15:00:00", "MACAPA", 65.99208585),
            ("Suva Afternoon", "2023-06-21 02:00:00", "SUVA", 40.24688524),
        ]
        for c in cases {
            XCTAssertEqual(calculator().getSolarElevation(instant: instant(c.1), geoLocation: geo(c.2)), c.3, accuracy: delta, c.0)
        }
    }

    func testGetSolarAzimuth() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Noon", "2017-10-17 12:00:00", "NJ", 110.13820751),
            ("NJ Evening", "2017-10-17 18:30:00", "NJ", 212.62255322),
            ("LA Evening", "2017-10-17 20:00:00", "LA", 187.12661462),
            ("Polar Midnight", "2017-06-21 00:00:00", "NORWAY", 8.01211355),
            ("Sydney Morning", "2020-02-29 20:00:00", "SYDNEY", 97.32257044),
            ("Macapa Local Noon", "2000-01-01 15:00:00", "MACAPA", 164.22488663),
            ("Suva Afternoon", "2023-06-21 02:00:00", "SUVA", 325.62695543),
        ]
        for c in cases {
            XCTAssertEqual(calculator().getSolarAzimuth(instant: instant(c.1), geoLocation: geo(c.2)), c.3, accuracy: delta, c.0)
        }
    }

    func testGetUTCSunriseAtZenith() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ Civil", "2017-10-17", "NJ", 96.0, 10.70916170),
            ("NJ Nautical", "2017-10-17", "NJ", 102.0, 10.17586674),
            ("NJ Astronomical", "2017-10-17", "NJ", 108.0, 9.64430764),
            ("Sydney Civil", "2020-02-29", "SYDNEY", 96.0, 19.27848095),
        ]
        for c in cases {
            assertUtcHour(c.0, c.4, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: c.3, adjustForElevation: true))
        }
    }

    func testGetUTCSunriseWithoutElevationAdjustment() {
        let cases: [(String, String, String, Double)] = [
            ("NJ No Elev Adj", "2017-10-17", "NJ", 11.17316120),
            ("Jerusalem No Elev Adj", "1955-02-26", "JERUSALEM", 4.18861444),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: false))
        }
    }

    func testGetUTCSunriseWithDeltaTDisabled() {
        let cases: [(String, String, String, Double)] = [
            ("NJ dT off", "2017-10-17", "NJ", 11.13563996),
            ("Jerusalem dT off", "1955-02-26", "JERUSALEM", 4.11850671),
        ]
        for c in cases {
            let calc = calculator()
            calc.applyDeltaT = false
            assertUtcHour(c.0, c.3, calc.getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetCalculatorName() {
        XCTAssertEqual(calculator().calculatorName, "Jean Meeus Higher-Accuracy (VSOP87) Algorithm")
    }
}
