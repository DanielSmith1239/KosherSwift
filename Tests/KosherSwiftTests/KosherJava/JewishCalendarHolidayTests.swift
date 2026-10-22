//
//  JewishCalendarHolidayTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava's hebrewcalendar/JewishCalendarHolidayTest.java (KosherJava master).
//

import XCTest
@testable import KosherSwift

final class JewishCalendarHolidayTests: XCTestCase {
    func testRoshHashanaAndTzomGedaliah() {
        var date = JewishCalendar(date: TestLocations.localDate(2023, 9, 16))
        XCTAssertTrue(date.isRoshHashana)

        date = date.tomorrow
        XCTAssertTrue(date.isRoshHashana)

        date = date.tomorrow // Tzom Gedaliah (3 Tishrei)
        XCTAssertFalse(date.isRoshHashana)
        XCTAssertTrue(date.isTaanis)
    }

    func testParshah() {
        let formatter = HebrewDateFormatter()
        XCTAssertEqual("Bereshis", formatter.formatParsha(JewishCalendar(date: TestLocations.localDate(2023, 10, 14)).getParsha()))

        let hebrew = HebrewDateFormatter(hebrewFormat: true)
        XCTAssertEqual("בראשית", hebrew.formatParsha(JewishCalendar(date: TestLocations.localDate(2023, 10, 14)).getParsha()))

        XCTAssertEqual("Terumah", formatter.formatParsha(JewishCalendar(date: TestLocations.localDate(2024, 2, 17)).getParsha()))
    }

    func testPurimAndShushanPurim() {
        // 14 Adar in a non-leap year: Purim in unwalled cities, but Shushan Purim (15th) in walled cities.
        let date = JewishCalendar(withJewishYear: 5783, andMonth: .adar, andDay: 14)
        XCTAssertTrue(date.isPurim)
        date.isMukafChoma = true
        XCTAssertFalse(date.isPurim)

        // 15 Adar: Shushan Purim, observed as Purim in walled cities.
        let shushanPurim = date.tomorrow
        XCTAssertTrue(shushanPurim.isPurim)
        shushanPurim.isMukafChoma = false
        XCTAssertFalse(shushanPurim.isPurim)

        // In a leap year Purim falls in Adar II, so Adar (I) 14 is not Purim.
        XCTAssertFalse(JewishCalendar(withJewishYear: 5784, andMonth: .adar, andDay: 14).isPurim)
    }

    func testAssurBemelacha() {
        // Yom Kippur (10 Tishrei) is assur bemelacha.
        XCTAssertTrue(JewishCalendar(withJewishYear: 5784, andMonth: .tishrei, andDay: 10).isAssurBemelacha)

        // An ordinary weekday is not.
        XCTAssertFalse(JewishCalendar(withJewishYear: 5784, andMonth: .cheshvan, andDay: 5).isAssurBemelacha)
    }
}
