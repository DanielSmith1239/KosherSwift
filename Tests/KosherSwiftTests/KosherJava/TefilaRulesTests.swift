//
//  TefilaRulesTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava's hebrewcalendar/TefilaRulesTest.java (KosherJava master).
//

import XCTest
@testable import KosherSwift

final class TefilaRulesTests: XCTestCase {
    func testOrdinarySummerWeekday() {
        let date = JewishCalendar(date: TestLocations.localDate(2023, 8, 21))
        let rules = TefilaRules(date)

        XCTAssertTrue(rules.isTachanunRecitedShacharis())
        XCTAssertTrue(rules.isTachanunRecitedMincha())
        XCTAssertFalse(rules.isVeseinTalUmatarStartDate())
        XCTAssertFalse(rules.isVeseinTalUmatarStartingTonight())
        XCTAssertFalse(rules.isVeseinTalUmatarRecited())
        XCTAssertTrue(rules.isVeseinBerachaRecited())
        XCTAssertFalse(date.isMashivHaruachStartDate)
        XCTAssertFalse(date.isMashivHaruachEndDate)
        XCTAssertFalse(rules.isMashivHaruachRecited())
        XCTAssertTrue(rules.isMoridHatalRecited())
        XCTAssertFalse(rules.isHallelRecited())
        XCTAssertFalse(rules.isHallelShalemRecited())
        XCTAssertFalse(rules.isAlHanissimRecited())
        XCTAssertFalse(rules.isYaalehVeyavoRecited())
        XCTAssertTrue(rules.isMizmorLesodaRecited())
    }

    func testFirstDayOfSukkos() {
        let date = JewishCalendar(date: TestLocations.localDate(2023, 10, 7))
        let rules = TefilaRules(date)

        XCTAssertFalse(rules.isTachanunRecitedShacharis())
        XCTAssertFalse(rules.isTachanunRecitedMincha())
        XCTAssertFalse(rules.isVeseinTalUmatarStartDate())
        XCTAssertFalse(rules.isVeseinTalUmatarStartingTonight())
        XCTAssertFalse(rules.isVeseinTalUmatarRecited())
        XCTAssertTrue(rules.isVeseinBerachaRecited())
        XCTAssertTrue(date.isMashivHaruachStartDate)
        XCTAssertFalse(date.isMashivHaruachEndDate)
        XCTAssertFalse(rules.isMashivHaruachRecited())
        XCTAssertTrue(rules.isMoridHatalRecited())
        XCTAssertTrue(rules.isHallelRecited())
        XCTAssertTrue(rules.isHallelShalemRecited())
        XCTAssertFalse(rules.isAlHanissimRecited())
        XCTAssertTrue(rules.isYaalehVeyavoRecited())
        XCTAssertFalse(rules.isMizmorLesodaRecited())
    }
}
