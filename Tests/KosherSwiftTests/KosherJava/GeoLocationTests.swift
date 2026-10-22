//
//  GeoLocationTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's util/GeoLocationTest.java. KosherSwift's GeoLocation is an immutable struct that doesn't
//  validate its input, so the constructor, setter, validation, equals/hashCode, clone and toXML tests have no
//  equivalent. KosherJava master comments out its Vincenty and rhumb line tests; they are ported here because
//  KosherSwift has those calculations.
//

import XCTest
@testable import KosherSwift

final class GeoLocationTests: XCTestCase {
    private let ny = TimeZone(identifier: "America/New_York")!
    private let greenwich = GeoLocation(lat: 51.4772, lng: 0, timezone: TimeZone(identifier: "GMT")!, name: "Greenwich, England")

    func testGetLocalMeanTimeOffset() {
        XCTAssertEqual(0, greenwich.localMeanTimeOffset)
        let lakewood = GeoLocation(lat: 40.0828, lng: -74.2094, timezone: ny, elevation: 20, name: "Lakewood, NJ")
        XCTAssertEqual(189744, Int64(lakewood.localMeanTimeOffset))
    }

    func testAntimeridianAdjustment() {
        XCTAssertEqual(0, greenwich.antimeridianAdjustment)
        XCTAssertEqual(0, GeoLocation(lat: 40.0828, lng: -74.2094, timezone: ny, elevation: 20, name: "Lakewood, NJ").antimeridianAdjustment)
        // Apia, Samoa is well east of its longitude-implied zone: roll the date back a day.
        let apia = GeoLocation(lat: -13.8599098, lng: -171.8031745, timezone: TimeZone(identifier: "Pacific/Apia")!, elevation: 1858, name: "Apia, Samoa")
        XCTAssertEqual(-1, apia.antimeridianAdjustment)
        // A location east of the dateline forced onto a UTC-12 zone: roll the date forward a day.
        let westOfLine = GeoLocation(lat: -13.8599098, lng: 179, timezone: TimeZone(identifier: "Etc/GMT+12")!, elevation: 0, name: "GMT +12")
        XCTAssertEqual(1, westOfLine.antimeridianAdjustment)
    }

    func testVincentyFormulae() {
        let gmtPlus12 = TimeZone(identifier: "Etc/GMT+12")!
        let pointA = GeoLocation(lat: 50.06632222222222, lng: -5.71475, timezone: gmtPlus12, name: "A")
        let pointB = GeoLocation(lat: 58.64402222222222, lng: -3.0700944444444445, timezone: gmtPlus12, name: "B")
        XCTAssertEqual(9.14186191, GeoLocation.getGeodesicInitialBearing(location: pointA, destination: pointB), accuracy: 1e-8)
        XCTAssertEqual(11.29720127, GeoLocation.getGeodesicFinalBearing(location: pointA, destination: pointB), accuracy: 1e-8)
        XCTAssertEqual(969954.11445043, GeoLocation.getGeodesicDistance(location: pointA, destination: pointB), accuracy: 1e-5)
    }

    func testGeodesicDistanceForCoincidentPointsIsZero() {
        let point = GeoLocation(lat: 40.0828, lng: -74.2094, timezone: ny, name: "Lakewood, NJ")
        XCTAssertEqual(0.0, GeoLocation.getGeodesicDistance(location: point, destination: point))
    }

    func testRhumbLine() {
        let gmtPlus12 = TimeZone(identifier: "Etc/GMT+12")!
        let pointA = GeoLocation(lat: 50.06638888888889, lng: -5.714722222222222, timezone: gmtPlus12, name: "A")
        let pointB = GeoLocation(lat: 58.64388888888889, lng: -3.07, timezone: gmtPlus12, name: "B")
        XCTAssertEqual(10.14069288, GeoLocation.getRhumbLineBearing(location: pointA, destination: pointB), accuracy: 1e-8)
        XCTAssertEqual(969995.8368008, GeoLocation.getRhumbLineDistance(location: pointA, destination: pointB), accuracy: 1e-5)
    }
}
