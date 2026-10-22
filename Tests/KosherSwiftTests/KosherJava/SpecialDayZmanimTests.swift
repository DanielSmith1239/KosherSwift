//
//  SpecialDayZmanimTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's SpecialDayZmanimTest.java. KosherSwift has no MGA 72 minutes zmanis chametz times and
//  no polar zmanim, so those assertions and polarZmanimDuringPolarDay / polarZmanimAreNullWhereSunRisesAndSets aren't
//  ported. KosherJava's ComprehensiveZmanimCalendar returns molad and kiddush levana times only on the day they fall;
//  KosherSwift has them on JewishCalendar for the whole month, so kidushLevanaIsNullOutsideItsWindow isn't ported and
//  the instants are checked from JewishCalendar instead.
//

import XCTest
@testable import KosherSwift

final class SpecialDayZmanimTests: XCTestCase {
    private func calendarFor(_ year: Int, _ month: Int, _ day: Int) -> ComplexZmanimCalendar {
        ComplexZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(year, month, day))
    }

    func testChametzTimesOnErevPesach() {
        let calendar = calendarFor(2017, 4, 10)
        XCTAssertNotNil(calendar.latestAchilasChametzGRA())
        XCTAssertNotNil(calendar.latestAchilasChametzMGA72Minutes())
        XCTAssertNotNil(calendar.latestAchilasChametzMGA16Point1Degrees())
        XCTAssertNotNil(calendar.latestAchilasChametzBaalHatanya())
        XCTAssertNotNil(calendar.latestBiurChametzGRA())
        XCTAssertNotNil(calendar.latestBiurChametzMGA72Minutes())
        XCTAssertNotNil(calendar.latestBiurChametzMGA16Point1Degrees())
        XCTAssertNotNil(calendar.latestBiurChametzBaalHatanya())
        // Biur (end of the 5th hour) is one shaah zmanis after achilas (end of the 4th).
        assertInstant(calendar.latestAchilasChametzGRA(), "2017-04-10T14:47:45.675920561Z", "achilasGRA")
        assertInstant(calendar.latestBiurChametzGRA(), "2017-04-10T15:53:07.762314340Z", "biurGRA")
    }

    func testChametzTimesAreNilOnAnOrdinaryDay() {
        let calendar = calendarFor(2017, 10, 17)
        XCTAssertNil(calendar.latestAchilasChametzGRA())
        XCTAssertNil(calendar.latestBiurChametzGRA())
        XCTAssertNil(calendar.latestBiurChametzMGA16Point1Degrees())
    }

    func testZmanMoladAndTchilasKidushLevana() {
        // The molad of Cheshvan 5778 (the moment itself falls on 2017-10-20).
        let cheshvan = JewishCalendar(withJewishYear: 5778, andMonth: .cheshvan, andDay: 1)
        assertInstant(cheshvan.moladDate?.gregDate, "2017-10-20T09:52:00.170666666Z", "zmanMolad")
        // Earliest Kidush Levana: 3 days and 7 days after the molad.
        assertInstant(cheshvan.earliestKiddushLevana3Days, "2017-10-23T09:52:00.170666666Z", "tchilas3Days")
        assertInstant(cheshvan.earliestKiddushLevana7Days, "2017-10-27T09:52:00.170666666Z", "tchilas7Days")
    }

    func testSofZmanKidushLevana() {
        // Latest Kidush Levana for the month whose molad was in late September 2017 (sayable through 2017-10-05).
        let tishrei = JewishCalendar(withJewishYear: 5778, andMonth: .tishrei, andDay: 15)
        assertInstant(tishrei.latestKiddushLevana15Days, "2017-10-05T21:07:56.837333333Z", "sof15Days")
        assertInstant(tishrei.latestZmanKidushLevanaBetweenMoldos, "2017-10-05T15:29:58.503333333Z", "sofBetweenMoldos")
    }
}
