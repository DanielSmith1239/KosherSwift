//
//  CalculatorSelectionTests.swift
//  KosherSwiftTests
//
//  Checks that each calculator ported from KosherJava works when plugged into ComplexZmanimCalendar, the way
//  KosherJava's setAstronomicalCalculator is used. Expected values are each calculator's own UTC hours from the ported
//  KosherJava tests (Lakewood's neighbour Woodcliff Lake, NJ on 17 October 2017), so they're checked to the second.
//

import XCTest
@testable import KosherSwift

final class CalculatorSelectionTests: XCTestCase {
    private func calendar(_ calculator: AstronomicalCalculator) -> ComplexZmanimCalendar {
        ComplexZmanimCalendar(location: TestLocations.nj(TestLocations.newYork), date: TestLocations.date(2017, 10, 17), astronomicalCalculator: calculator)
    }

    private func utc(_ hours: Double) -> Date {
        TestLocations.date(2017, 10, 17, in: TestLocations.utc).addingTimeInterval(hours * 3600)
    }

    func testSunriseUsesTheSelectedCalculator() {
        // getUTCSunrise(..., adjustForElevation: true) values from the ported tests
        let cases: [(AstronomicalCalculator, Double)] = [
            (SPACalculator(), 11.13593689),
            (MeeusCalculator(), 11.13565507),
            (SunTimesCalculator(), 11.12643745),
        ]
        for (calculator, hours) in cases {
            guard let sunrise = calendar(calculator).sunrise else { return XCTFail("\(type(of: calculator)) sunrise is nil") }
            XCTAssertEqual(sunrise.timeIntervalSince1970, utc(hours).timeIntervalSince1970, accuracy: 1, "\(type(of: calculator)) sunrise")
        }
    }

    func testZmanimWorkWithEachCalculator() {
        let noaa = calendar(NOAACalculator())
        for calculator: AstronomicalCalculator in [SPACalculator(), MeeusCalculator(), SunTimesCalculator()] {
            let czc = calendar(calculator)
            // The algorithms agree to well under two minutes at mid latitudes
            for (name, zman, reference) in [
                ("alos 16.1", czc.alos16Point1Degrees(), noaa.alos16Point1Degrees()),
                ("sof zman shma GRA", czc.latestShemaGra(), noaa.latestShemaGra()),
                ("tzais 8.5", czc.tzeisGeonim8Point5Degrees(), noaa.tzeisGeonim8Point5Degrees()),
            ] {
                guard let zman, let reference else { return XCTFail("\(type(of: calculator)) \(name) is nil") }
                XCTAssertEqual(zman.timeIntervalSince1970, reference.timeIntervalSince1970, accuracy: 120, "\(type(of: calculator)) \(name)")
            }
        }
    }
}
