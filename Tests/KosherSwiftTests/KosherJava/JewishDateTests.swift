//
//  JewishDateTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava's hebrewcalendar/UT_DaysInJewishMonth.java, UT_JewishLeapYear.java, UT_JewishDateNavigation.java,
//  UT_GregorianDateNavigation.java (KosherJava master) and UT_DaysInGregorianMonth.java (KosherJava 2.5.0).
//
//  KosherJava's plusDays(1)/minusDays(1) are KosherSwift's tomorrow/yesterday. JewishMonth raw values are KosherJava's
//  month constants (NISSAN = 1 ... ADAR_II = 13), so month assertions compare rawValue to KosherJava's numbers.
//

import XCTest
@testable import KosherSwift

final class JewishDateTests: XCTestCase {
    private func jewishDate(year: Int) -> JewishDate {
        JewishDate(withJewishYear: year, andMonth: .tishrei, andDay: 1)
    }

    // MARK: UT_DaysInJewishMonth

    func testDaysInMonthsInHaserYear() {
        assertHaser(5773)
        assertHaser(5777)
        assertHaser(5781)
        assertHaserLeap(5784)
        assertHaserLeap(5790)
        assertHaserLeap(5793)
    }

    func testDaysInMonthsInQesidrahYear() {
        assertQesidrah(5769)
        assertQesidrah(5772)
        assertQesidrah(5778)
        assertQesidrah(5786)
        assertQesidrah(5789)
        assertQesidrah(5792)
        assertQesidrahLeap(5782)
    }

    func testDaysInMonthsInShalemYear() {
        assertShalem(5770)
        assertShalem(5780)
        assertShalem(5783)
        assertShalem(5785)
        assertShalem(5788)
        assertShalem(5791)
        assertShalem(5794)
        assertShalemLeap(5771)
        assertShalemLeap(5774)
        assertShalemLeap(5776)
        assertShalemLeap(5779)
        assertShalemLeap(5787)
        assertShalemLeap(5795)
    }

    private func assertHaser(_ year: Int, line: UInt = #line) {
        XCTAssertFalse(jewishDate(year: year).isCheshvanLong, "\(year)", line: line)
        XCTAssertTrue(jewishDate(year: year).isKislevShort, "\(year)", line: line)
    }

    private func assertHaserLeap(_ year: Int, line: UInt = #line) {
        assertHaser(year, line: line)
        XCTAssertTrue(JewishDate.isJewishLeapYear(year), "\(year)", line: line)
    }

    private func assertQesidrah(_ year: Int, line: UInt = #line) {
        XCTAssertFalse(jewishDate(year: year).isCheshvanLong, "\(year)", line: line)
        XCTAssertFalse(jewishDate(year: year).isKislevShort, "\(year)", line: line)
    }

    private func assertQesidrahLeap(_ year: Int, line: UInt = #line) {
        assertQesidrah(year, line: line)
        XCTAssertTrue(JewishDate.isJewishLeapYear(year), "\(year)", line: line)
    }

    private func assertShalem(_ year: Int, line: UInt = #line) {
        XCTAssertTrue(jewishDate(year: year).isCheshvanLong, "\(year)", line: line)
        XCTAssertFalse(jewishDate(year: year).isKislevShort, "\(year)", line: line)
    }

    private func assertShalemLeap(_ year: Int, line: UInt = #line) {
        assertShalem(year, line: line)
        XCTAssertTrue(JewishDate.isJewishLeapYear(year), "\(year)", line: line)
    }

    // MARK: UT_JewishLeapYear

    func testIsLeapYear() {
        for year in [5160, 5771, 5774, 5776, 5779, 5782, 5784, 5787, 5790, 5793, 5795] {
            XCTAssertTrue(JewishDate.isJewishLeapYear(year), "\(year)")
        }
        for year in [5536, 5770, 5772, 5773, 5775, 5777, 5778, 5780, 5781, 5783, 5785, 5786, 5788, 5789, 5791, 5792, 5794] {
            XCTAssertFalse(JewishDate.isJewishLeapYear(year), "\(year)")
        }
    }

    // MARK: UT_JewishDateNavigation

    func testJewishForwardMonthToMonth() {
        let date = JewishDate(withJewishYear: 5771, andMonth: .nissan, andDay: 1).gregDate
        XCTAssertEqual(5, date.day)
        XCTAssertEqual(4, date.month)
        XCTAssertEqual(2011, date.year)
    }

    func testComputeRoshHashana5771() {
        // At one point, this test was failing as the JewishDate class spun through a never-ending loop...
        let date = JewishDate(withJewishYear: 5771, andMonth: .tishrei, andDay: 1).gregDate
        XCTAssertEqual(9, date.day)
        XCTAssertEqual(9, date.month)
        XCTAssertEqual(2010, date.year)
    }

    // KosherJava master's addYearsUsesConfiguredAdarMonthWhenMovingToLeapYear tests plusYears(_, useAdarAlephForLeapYear),
    // which KosherSwift doesn't have.

    // MARK: UT_GregorianDateNavigation

    /// (gregorian date, expected next day, expected Jewish month/day of the next day), from gregorianForwardMonthToMonth.
    func testGregorianForwardMonthToMonth() {
        var hebrewDate = JewishCalendar(date: TestLocations.localDate(2011, 1, 31))
        XCTAssertEqual(5771, hebrewDate.year)
        XCTAssertEqual(11, hebrewDate.month.rawValue)
        XCTAssertEqual(26, hebrewDate.day)
        hebrewDate = hebrewDate.tomorrow
        assertDate(hebrewDate, 2011, 2, 1, 11, 27)

        hebrewDate = JewishCalendar(date: TestLocations.localDate(2011, 2, 28))
        assertDate(hebrewDate, 2011, 2, 28, 12, 24)
        assertDate(hebrewDate.tomorrow, 2011, 3, 1, 12, 25)

        let cases: [((Int, Int, Int), (Int, Int, Int), (Int, Int))] = [
            ((2011, 3, 31), (2011, 4, 1), (13, 26)),
            ((2011, 4, 30), (2011, 5, 1), (1, 27)),
            ((2011, 5, 31), (2011, 6, 1), (2, 28)),
            ((2011, 6, 30), (2011, 7, 1), (3, 29)),
            ((2011, 7, 31), (2011, 8, 1), (5, 1)),
            ((2011, 8, 31), (2011, 9, 1), (6, 2)),
            ((2011, 9, 30), (2011, 10, 1), (7, 3)),
            ((2011, 10, 31), (2011, 11, 1), (8, 4)),
            ((2011, 11, 30), (2011, 12, 1), (9, 5)),
            ((2011, 12, 31), (2012, 1, 1), (10, 6)),
        ]
        for (start, next, jewish) in cases {
            let tomorrow = JewishCalendar(date: TestLocations.localDate(start.0, start.1, start.2)).tomorrow
            assertDate(tomorrow, next.0, next.1, next.2, jewish.0, jewish.1)
        }
        XCTAssertEqual(5772, JewishCalendar(date: TestLocations.localDate(2011, 10, 31)).tomorrow.year)
    }

    func testGregorianBackwardMonthToMonth() {
        let cases: [((Int, Int, Int), (Int, Int, Int), (Int, Int))] = [
            ((2011, 1, 1), (2010, 12, 31), (10, 24)),
            ((2010, 12, 1), (2010, 11, 30), (9, 23)),
            ((2010, 11, 1), (2010, 10, 31), (8, 23)),
            ((2010, 10, 1), (2010, 9, 30), (7, 22)),
            ((2010, 9, 1), (2010, 8, 31), (6, 21)),
            ((2010, 8, 1), (2010, 7, 31), (5, 20)),
            ((2010, 7, 1), (2010, 6, 30), (4, 18)),
            ((2010, 6, 1), (2010, 5, 31), (3, 18)),
            ((2010, 5, 1), (2010, 4, 30), (2, 16)),
            ((2010, 4, 1), (2010, 3, 31), (1, 16)),
            ((2010, 3, 1), (2010, 2, 28), (12, 14)),
            ((2010, 2, 1), (2010, 1, 31), (11, 16)),
        ]
        for (start, previous, jewish) in cases {
            let yesterday = JewishCalendar(date: TestLocations.localDate(start.0, start.1, start.2)).yesterday
            assertDate(yesterday, previous.0, previous.1, previous.2, jewish.0, jewish.1)
        }
        XCTAssertEqual(5770, JewishCalendar(date: TestLocations.localDate(2010, 9, 1)).yesterday.year)
    }

    private func assertDate(_ date: JewishCalendar, _ year: Int, _ month: Int, _ day: Int, _ jewishMonth: Int, _ jewishDay: Int, line: UInt = #line) {
        XCTAssertEqual(year, date.gregDate.year, "gregorian year", line: line)
        XCTAssertEqual(month, date.gregDate.month, "gregorian month", line: line)
        XCTAssertEqual(day, date.gregDate.day, "gregorian day", line: line)
        XCTAssertEqual(jewishMonth, date.month.rawValue, "jewish month", line: line)
        XCTAssertEqual(jewishDay, date.day, "jewish day", line: line)
    }

    // MARK: UT_DaysInGregorianMonth (KosherJava 2.5.0)

    func testDaysInMonth() { assertDaysInMonth(febIsLeap: false, year: 2011) }
    func testDaysInMonthLeapYear() { assertDaysInMonth(febIsLeap: true, year: 2012) }
    func testDaysInMonth100Year() { assertDaysInMonth(febIsLeap: false, year: 2100) }
    func testDaysInMonth400Year() { assertDaysInMonth(febIsLeap: true, year: 2000) }

    private func assertDaysInMonth(febIsLeap: Bool, year: Int, line: UInt = #line) {
        let expected = [31, febIsLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        for (index, days) in expected.enumerated() {
            XCTAssertEqual(days, JewishDate.getLastDayOfGregorianMonth(month: index + 1, year: year), "\(year)-\(index + 1)", line: line)
        }
    }
}
