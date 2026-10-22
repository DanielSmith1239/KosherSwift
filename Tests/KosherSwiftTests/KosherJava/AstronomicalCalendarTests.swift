//
//  AstronomicalCalendarTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's AstronomicalCalendarTest.java. KosherJava's swappingCalculatorChangesResult isn't
//  ported because NOAA is KosherSwift's only calculator.
//

import XCTest
@testable import KosherSwift

final class AstronomicalCalendarTests: XCTestCase {
    private func fixtureCalendar() -> AstronomicalCalendar {
        AstronomicalCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 17))
    }

    func testSunriseAndSunset() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.sunrise, "2017-10-17T11:09:11.571783718Z", "sunrise")
        assertInstant(calendar.sunset, "2017-10-17T22:14:38.994862349Z", "sunset")
        assertInstant(calendar.seaLevelSunrise, "2017-10-17T11:09:51.403184642Z", "seaLevelSunrise")
        assertInstant(calendar.seaLevelSunset, "2017-10-17T22:13:59.201432122Z", "seaLevelSunset")
    }

    /// KosherSwift's getSolarMidnight() is on ComplexZmanimCalendar rather than AstronomicalCalendar.
    func testTransitAndSolarMidnight() {
        assertInstant(fixtureCalendar().getSunTransit(), "2017-10-17T16:42:12.781249470Z", "sunTransit")
        let complex = ComplexZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 17))
        assertInstant(complex.getSolarMidnight(), "2017-10-18T04:42:06.833038724Z", "solarMidnight")
    }

    func testTwilights() {
        let calendar = fixtureCalendar()
        assertInstant(calendar.civilTwilightStart, "2017-10-17T10:42:27.439221886Z", "beginCivil")
        assertInstant(calendar.nauticalTwilightStart, "2017-10-17T10:10:57.242471901Z", "beginNautical")
        assertInstant(calendar.astronomicalTwilightStart, "2017-10-17T09:39:33.523030241Z", "beginAstronomical")
        assertInstant(calendar.civilTwilightEnd, "2017-10-17T22:41:21.435143220Z", "endCivil")
        assertInstant(calendar.nauticalTwilightEnd, "2017-10-17T23:12:49.151356447Z", "endNautical")
        assertInstant(calendar.astronomicalTwilightEnd, "2017-10-17T23:44:09.707296295Z", "endAstronomical")
    }

    func testTemporalHour() {
        assertDuration(fixtureCalendar().getTemporalHour(), "PT55M20.649853956S", "temporalHour")
    }

    func testOffsetByDegreesMatchesNamedTwilight() {
        let calendar = fixtureCalendar()
        XCTAssertEqual(calendar.civilTwilightStart, calendar.getSunriseOffsetByDegrees(offset: 96.0))
        XCTAssertEqual(calendar.civilTwilightEnd, calendar.getSunsetOffsetByDegrees(offset: 96.0))
    }

    func testPolarNoEventReturnsNil() {
        let calendar = AstronomicalCalendar(location: TestLocations.norway(TestLocations.utc), date: TestLocations.date(2017, 6, 21, in: TestLocations.utc))
        XCTAssertNil(calendar.sunrise, "polar sunrise")
        XCTAssertNil(calendar.sunset, "polar sunset")
    }
}
