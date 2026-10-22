//
//  DafYomiTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava's hebrewcalendar/YomiCalculatorTest.java and hebrewcalendar/UT_YerushalmiTest.java
//  (identical in KosherJava 2.5.0 and master).
//

import XCTest
@testable import KosherSwift

final class DafYomiTests: XCTestCase {
    // MARK: YomiCalculatorTest

    func testCorrectDaf1() {
        let daf = JewishCalendar(withJewishYear: 5685, andMonth: .kislev, andDay: 12).dafYomiBavli
        XCTAssertEqual(5, daf?.masechtaNumber)
        XCTAssertEqual(2, daf?.daf)
    }

    func testCorrectDaf2() {
        let daf = JewishCalendar(withJewishYear: 5736, andMonth: .elul, andDay: 26).dafYomiBavli
        XCTAssertEqual(4, daf?.masechtaNumber)
        XCTAssertEqual(14, daf?.daf)
    }

    func testCorrectDaf3() {
        let daf = JewishCalendar(withJewishYear: 5777, andMonth: .elul, andDay: 10).dafYomiBavli
        XCTAssertEqual(23, daf?.masechtaNumber)
        XCTAssertEqual(47, daf?.daf)
    }

    // MARK: UT_YerushalmiTest

    func testYerushalmiCorrectDaf1() {
        let daf = JewishCalendar(withJewishYear: 5777, andMonth: .elul, andDay: 10).dafYomiYerushalmi
        XCTAssertEqual(8, daf?.daf)
        XCTAssertEqual(29, daf?.masechtaNumber)
    }

    func testYerushalmiCorrectDaf2() {
        let daf = JewishCalendar(withJewishYear: 5744, andMonth: .kislev, andDay: 1).dafYomiYerushalmi
        XCTAssertEqual(26, daf?.daf)
        XCTAssertEqual(32, daf?.masechtaNumber)
    }

    func testYerushalmiCorrectDaf3() {
        let daf = JewishCalendar(withJewishYear: 5782, andMonth: .sivan, andDay: 1).dafYomiYerushalmi
        XCTAssertEqual(15, daf?.daf)
        XCTAssertEqual(33, daf?.masechtaNumber)
    }

    func testYerushalmiCorrectSpecialDate() {
        XCTAssertNil(JewishCalendar(withJewishYear: 5775, andMonth: .tishrei, andDay: 10).dafYomiYerushalmi)
        XCTAssertNil(JewishCalendar(withJewishYear: 5783, andMonth: .av, andDay: 9).dafYomiYerushalmi)
        XCTAssertNil(JewishCalendar(withJewishYear: 5775, andMonth: .av, andDay: 10).dafYomiYerushalmi) // 9 Av delayed to Sunday 10 Av
    }
}
