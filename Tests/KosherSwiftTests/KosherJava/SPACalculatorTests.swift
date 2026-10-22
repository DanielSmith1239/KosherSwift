//
//  SPACalculatorTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's util/SPACalculatorTest.java, asserted to the same 1e-8 hours.
//  getTimeAtAzimuthRejectsUnsupportedAzimuth isn't ported: Swift traps on the precondition instead of throwing.
//

import XCTest
@testable import KosherSwift

final class SPACalculatorTests: XCTestCase {
    private func calculator() -> SPACalculator { SPACalculator() }
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
            ("NJ Standard Date", "2017-10-17", "NJ", 11.13593689),
            ("LA Standard Date", "2017-10-17", "LA", 14.00756754),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 4.11873932),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 19.68293143),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 9.38998685),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 18.60534965),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 12.95741199),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 9.44912615),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCSunset() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 22.24099415),
            ("LA Standard Date", "2017-10-17", "LA", 1.31843857),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 15.64512300),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", noEvent),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 8.56367402),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 21.53102552),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 5.65791427),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 20.21191830),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 0.58028674),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunset(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    func testGetUTCNoon() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 16.69350885),
            ("LA Standard Date", "2017-10-17", "LA", 19.66696009),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 9.87817106),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", 11.42056214),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 2.12799525),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 15.46051831),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 0.13165740),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 16.58459266),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 17.01689317),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCNoon(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetUTCMidnight() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Standard Date", "2017-10-17", "NJ", 4.69189152),
            ("LA Standard Date", "2017-10-17", "LA", 7.66535335),
            ("Jerusalem Hist. Date", "1955-02-26", "JERUSALEM", 21.87680310),
            ("Norway Polar Solstice", "2017-06-21", "NORWAY", 23.42238534),
            ("Sydney Leap Day", "2020-02-29", "SYDNEY", 14.12642351),
            ("Macapa Equator New Year", "2000-01-01", "MACAPA", 3.46446119),
            ("Suva Fiji Solstice", "2023-06-21", "SUVA", 12.13348552),
            ("Ushuaia Southern Winter", "2017-06-21", "USHUAIA", 4.58641480),
            ("NJ Future DeltaT", "2100-07-04", "NJ", 5.01835716),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUTCMidnight(date: date(c.1), geoLocation: geo(c.2)))
        }
    }

    func testGetTimeAtAzimuth() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ East", "2017-10-17", "NJ", 90.0, 9.96630382),
            ("NJ West", "2017-10-17", "NJ", 270.0, 23.43696229),
            ("LA East", "2017-10-17", "LA", 90.0, 12.71802376),
            ("LA West", "2017-10-17", "LA", 270.0, 2.63792595),
            ("Sydney East", "2020-02-29", "SYDNEY", 90.0, 20.92601636),
            ("Sydney West", "2020-02-29", "SYDNEY", 270.0, 7.34685680),
            ("Macapa East No Cross", "2000-01-01", "MACAPA", 90.0, noEvent),
            ("Polar East", "2017-06-21", "NORWAY", 90.0, 6.01986373),
        ]
        for c in cases {
            assertUtcHour(c.0, c.4, calculator().getTimeAtAzimuth(date: date(c.1), geoLocation: geo(c.2), azimuth: c.3))
        }
    }

    func testGetSolarElevation() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Noon", "2017-10-17 12:00:00", "NJ", 8.24142367),
            ("NJ Evening", "2017-10-17 18:30:00", "NJ", 33.57165658),
            ("LA Evening", "2017-10-17 20:00:00", "LA", 46.19391692),
            ("Polar Midnight", "2017-06-21 00:00:00", "NORWAY", 3.98549481),
            ("Sydney Morning", "2020-02-29 20:00:00", "SYDNEY", 2.89087872),
            ("Macapa Local Noon", "2000-01-01 15:00:00", "MACAPA", 65.99118480),
            ("Suva Afternoon", "2023-06-21 02:00:00", "SUVA", 40.24649656),
        ]
        for c in cases {
            XCTAssertEqual(calculator().getSolarElevation(instant: instant(c.1), geoLocation: geo(c.2)), c.3, accuracy: delta, c.0)
        }
    }

    func testGetSolarAzimuth() {
        let cases: [(String, String, String, Double)] = [
            ("NJ Noon", "2017-10-17 12:00:00", "NJ", 110.13757333),
            ("NJ Evening", "2017-10-17 18:30:00", "NJ", 212.62157928),
            ("LA Evening", "2017-10-17 20:00:00", "LA", 187.12533185),
            ("Polar Midnight", "2017-06-21 00:00:00", "NORWAY", 8.01127958),
            ("Sydney Morning", "2020-02-29 20:00:00", "SYDNEY", 97.32308776),
            ("Macapa Local Noon", "2000-01-01 15:00:00", "MACAPA", 164.22300003),
            ("Suva Afternoon", "2023-06-21 02:00:00", "SUVA", 325.62786587),
        ]
        for c in cases {
            XCTAssertEqual(calculator().getSolarAzimuth(instant: instant(c.1), geoLocation: geo(c.2)), c.3, accuracy: delta, c.0)
        }
    }

    func testGetUTCSunriseAtZenith() {
        let cases: [(String, String, String, Double, Double)] = [
            ("NJ Civil", "2017-10-17", "NJ", 96.0, 10.70943974),
            ("NJ Nautical", "2017-10-17", "NJ", 102.0, 10.17613961),
            ("NJ Astronomical", "2017-10-17", "NJ", 108.0, 9.64457480),
            ("Sydney Civil", "2020-02-29", "SYDNEY", 96.0, 19.27874463),
        ]
        for c in cases {
            assertUtcHour(c.0, c.4, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: c.3, adjustForElevation: true))
        }
    }

    func testGetUTCSunriseWithoutElevationAdjustment() {
        let cases: [(String, String, String, Double)] = [
            ("NJ No Elev Adj", "2017-10-17", "NJ", 11.17344334),
            ("Jerusalem No Elev Adj", "1955-02-26", "JERUSALEM", 4.18885558),
        ]
        for c in cases {
            assertUtcHour(c.0, c.3, calculator().getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: false))
        }
    }

    func testGetUTCSunriseWithDeltaTDisabled() {
        let cases: [(String, String, String, Double)] = [
            ("NJ dT off", "2017-10-17", "NJ", 11.13586818),
            ("Jerusalem dT off", "1955-02-26", "JERUSALEM", 4.11871824),
        ]
        for c in cases {
            let calc = calculator()
            calc.applyDeltaT = false
            assertUtcHour(c.0, c.3, calc.getUtcSunrise(date: date(c.1), location: geo(c.2), zenith: zenith, adjustForElevation: true))
        }
    }

    // Independently verifiable reference: the published NREL SPA example (Reda & Andreas, NREL/TP-560-34302).
    // 2003-10-17 19:30:30 UTC, lat 39.742476, lng -105.1786, elevation 1830.14 m, 820 mb, 11 C, delta-T 67 s.
    private func nrelCalculator() -> SPACalculator {
        let calc = SPACalculator()
        calc.deltaTOverride = 67.0
        calc.pressure = 820
        calc.temperature = 11
        return calc
    }

    private let nrelLocation = GeoLocation(lat: 39.742476, lng: -105.1786, timezone: TestLocations.utc, elevation: 1830.14, name: "NREL Reference")

    func testGetSolarElevationNrelReference() {
        XCTAssertEqual(nrelCalculator().getSolarElevation(instant: instant("2003-10-17 19:30:30"), geoLocation: nrelLocation), 39.888378, accuracy: 0.001, "NREL published topocentric elevation")
    }

    func testGetSolarAzimuthNrelReference() {
        XCTAssertEqual(nrelCalculator().getSolarAzimuth(instant: instant("2003-10-17 19:30:30"), geoLocation: nrelLocation), 194.340241, accuracy: 0.001, "NREL published topocentric azimuth")
    }

    func testDefaultsAndSetters() {
        let calc = SPACalculator()
        XCTAssertTrue(calc.applyDeltaT)
        XCTAssertNil(calc.deltaTOverride)
        XCTAssertEqual(calc.pressure, 1013.25)
        XCTAssertEqual(calc.temperature, 10.0)
        calc.deltaTOverride = 67.0
        calc.pressure = 820
        calc.temperature = 11
        calc.applyDeltaT = false
        XCTAssertEqual(calc.deltaTOverride, 67.0)
        XCTAssertEqual(calc.pressure, 820.0)
        XCTAssertEqual(calc.temperature, 11.0)
        XCTAssertFalse(calc.applyDeltaT)
    }

    func testGetCalculatorName() {
        XCTAssertEqual(calculator().calculatorName, "NREL Solar Position Algorithm")
    }
}
