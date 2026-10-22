//
//  ZmanimCalendarTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's ZmanimCalendarTest.java.
//

import XCTest
@testable import KosherSwift

final class ZmanimCalendarTests: XCTestCase {
    private func fixtureCalendar(useElevation: Bool = false) -> ZmanimCalendar {
        ZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 17), shouldUseElevation: useElevation)
    }

    func testAlosAndMisheyakir() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.alosHashachar(), "2017-10-17T09:49:30.219906135Z", "alos16.1")
        assertInstant(calendar.alos72(), "2017-10-17T09:57:51.403184642Z", "alos72")
    }

    func testSofZmanShmaAndTfila() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.latestShemaGra(), "2017-10-17T13:55:53.352746510Z", "sofZmanShmaGRA")
        assertInstant(calendar.latestShemaMga(), "2017-10-17T13:19:53.352746510Z", "sofZmanShmaMGA72")
        assertInstant(calendar.latestTefilaGra(), "2017-10-17T14:51:14.002600466Z", "sofZmanTfilaGRA")
        assertInstant(calendar.latestTefilaMga(), "2017-10-17T14:27:14.002600466Z", "sofZmanTfilaMGA72")
    }

    /// KosherJava's getChatzosHalayla() is KosherSwift's ComplexZmanimCalendar.getSolarMidnight().
    func testChatzos() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.chatzos(), "2017-10-17T16:42:12.781249470Z", "chatzosHayom")
        assertInstant(calendar.chatzosAsHalfDay(), "2017-10-17T16:41:55.302308378Z", "chatzosHayomAsHalfDay")
        let complex = ComplexZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 17))
        assertInstant(complex.getSolarMidnight(), "2017-10-18T04:42:06.833038724Z", "chatzosHalayla")
    }

    func testMinchaAndPlag() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.calculateMinchaGedolah(), "2017-10-17T17:09:35.627235356Z", "minchaGedolaGRA")
        assertInstant(calendar.calculateMinchaKetana(), "2017-10-17T19:55:37.576797224Z", "minchaKetanaGRA")
        assertInstant(calendar.calculatePlagHamincha(), "2017-10-17T21:04:48.389114669Z", "plagHaminchaGRA")
    }

    /// KosherJava's getCandleLighting() is sunset minus 18 minutes on any day, which is KosherSwift's getCandleLighting().
    /// KosherSwift's candleLighting() only returns a time when candles are lit, so it's nil on the Tuesday fixture and
    /// is checked on Friday 20 October 2017 against KosherJava master's getCandleLighting() for that day.
    func testCandleLightingAndTzais() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.getCandleLighting(), "2017-10-17T21:55:59.201432122Z", "candleLighting")
        XCTAssertNil(calendar.candleLighting(), "candleLighting() on a weekday")
        let friday = ZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 20))
        assertInstant(friday.candleLighting(), "2017-10-20T21:51:40.574718940Z", "candleLighting() on Friday")
        assertInstant(calendar.tzeis72(), "2017-10-17T23:25:59.201432122Z", "tzais72")
        assertInstant(calendar.tzeis(), "2017-10-17T22:54:29.772724455Z", "tzaisGeonim8.5")
    }

    func testShaahZmanis() {
        let calendar = fixtureCalendar()
        assertDuration(calendar.shaahZmanisGra(), "PT55M20.649853956S", "shaahZmanisGRA")
        assertDuration(calendar.shaahZmanisMga(), "PT1H7M20.649853956S", "shaahZmanis72")
    }

    /// KosherJava only asserts that toggling elevation changes the result. The elevation-adjusted value is KosherJava
    /// master's getSofZmanShmaGRA() with setUseElevation(true).
    func testElevationToggleAffectsZmanim() {
        let atDefault = fixtureCalendar().latestShemaGra()
        let toggled = fixtureCalendar(useElevation: true).latestShemaGra()
        XCTAssertNotEqual(atDefault, toggled)
        assertInstant(toggled, "2017-10-17T13:55:33.427553374Z", "sofZmanShmaGRA with elevation")
    }
}
