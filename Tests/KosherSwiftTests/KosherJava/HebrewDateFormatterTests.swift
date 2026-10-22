//
//  HebrewDateFormatterTests.swift
//  KosherSwift
//
//  KosherJava has no HebrewDateFormatter unit test. These tests compare KosherSwift's formatter with KosherJava 2.5.0's
//  output, which Tests/KosherJavaParity/HebrewDateFormatterGolden.java writes to HebrewDateFormatterGolden.txt
//  (run.sh checks that the file still matches KosherJava). KosherSwift returns nil where KosherJava returns "", and
//  spells a few Hebrew names in full (plene) spelling; `kosherSwiftSpelling` maps KosherJava's spelling to it.
//

import XCTest
@testable import KosherSwift

final class HebrewDateFormatterTests: XCTestCase {
    private static let golden: [[String]] = {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("HebrewDateFormatterGolden.txt")
        let text = try! String(contentsOf: url, encoding: .utf8)
        return text.split(separator: "\n").map { $0.split(separator: "\t", omittingEmptySubsequences: false).map(String.init) }
    }()

    /// KosherJava spelling -> KosherSwift spelling. These are intentional, not bugs.
    private static let kosherSwiftSpelling = ["חשון": "חשוון", "סיון": "סיוון", "ששי": "שישי", "נצבים": "ניצבים"]

    private static func swiftSpelling(_ s: String) -> String {
        kosherSwiftSpelling.reduce(s) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
    }

    private func rows(_ kind: String) -> [[String]] {
        let rows = Self.golden.filter { $0[0] == kind }
        XCTAssertFalse(rows.isEmpty, "no \(kind) rows in HebrewDateFormatterGolden.txt")
        return rows
    }

    private let hebrew = HebrewDateFormatter(hebrewFormat: true)
    private let hebrewNoGersh = HebrewDateFormatter(hebrewFormat: true, useGershGershayim: false)
    private let hebrewShortWeek = HebrewDateFormatter(hebrewFormat: true, longWeekFormat: false)
    private let transliterated = HebrewDateFormatter()

    func testFormatHebrewNumber() throws {
        for r in rows("number") {
            let formatter = HebrewDateFormatter(hebrewFormat: true, useLongHebrewYears: r[3] == "true",
                                                useGershGershayim: r[2] == "true", useFinalFormLetters: r[4] == "true")
            XCTAssertEqual(try formatter.formatHebrewNumber(Int(r[1])!), r[5], "\(r[1]) gersh \(r[2]) long \(r[3]) final \(r[4])")
        }
    }

    func testFormatHebrewNumberRejectsOutOfRange() {
        XCTAssertThrowsError(try hebrew.formatHebrewNumber(-1))
        XCTAssertThrowsError(try hebrew.formatHebrewNumber(10000))
    }

    func testFormattedKviah() throws {
        for r in rows("kviah") {
            XCTAssertEqual(try transliterated.getFormattedKviah(Int(r[1])!), r[2], r[1])
        }
    }

    func testFormatDafYomi() throws {
        for r in rows("daf") {
            let daf = Daf(masechta: Int(r[1])!, daf: Int(r[2])!, dafType: .bavli)
            XCTAssertEqual(try hebrew.formatDafYomi(daf: daf), r[3])
            XCTAssertEqual(try transliterated.formatDafYomi(daf: daf), r[4])
        }
        for r in rows("dafYerushalmi") {
            let daf = Daf(masechta: Int(r[1])!, daf: Int(r[2])!, dafType: .yerushalmi)
            XCTAssertEqual(try hebrew.formatDafYomi(daf: daf), r[3])
            XCTAssertEqual(try transliterated.formatDafYomi(daf: daf), r[4])
        }
    }

    /// Every day of 5784 (a leap year) and 5785.
    func testFormatEveryDay() throws {
        for r in rows("day") {
            let (year, month, day) = (Int(r[1])!, JewishMonth(rawValue: Int(r[2])!)!, Int(r[3])!)
            let cal = JewishCalendar(withJewishYear: year, andMonth: month, andDay: day)
            let israel = JewishCalendar(withJewishYear: year, andMonth: month, andDay: day, isInIsrael: true)
            let label = "\(year)-\(r[2])-\(day)"
            func check(_ actual: String?, _ column: Int, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
                XCTAssertEqual(actual ?? "", Self.swiftSpelling(r[column]), "\(what) \(label)", file: file, line: line)
            }
            check(try hebrew.format(cal), 4, "format hebrew")
            check(try hebrewNoGersh.format(cal), 5, "format hebrew no geresh")
            check(try transliterated.format(cal), 6, "format")
            check(hebrew.formatMonth(cal), 7, "formatMonth hebrew")
            check(hebrewNoGersh.formatMonth(cal), 8, "formatMonth hebrew no geresh")
            check(transliterated.formatMonth(cal), 9, "formatMonth")
            check(try hebrew.formatDayOfWeek(cal), 10, "formatDayOfWeek hebrew")
            check(try hebrewShortWeek.formatDayOfWeek(cal), 11, "formatDayOfWeek hebrew short")
            check(try transliterated.formatDayOfWeek(cal), 12, "formatDayOfWeek")
            check(try hebrew.formatYomTov(cal), 13, "formatYomTov hebrew")
            check(try transliterated.formatYomTov(cal), 14, "formatYomTov")
            check(try hebrew.formatYomTov(israel), 15, "formatYomTov hebrew Israel")
            check(try transliterated.formatYomTov(israel), 16, "formatYomTov Israel")
            check(hebrew.formatRoshChodesh(cal), 17, "formatRoshChodesh hebrew")
            check(transliterated.formatRoshChodesh(cal), 18, "formatRoshChodesh")
            check(try hebrew.formatOmer(jewishCalendar: cal), 19, "formatOmer hebrew")
            check(try transliterated.formatOmer(jewishCalendar: cal), 20, "formatOmer")
            check(hebrew.formatParsha(cal.getParsha()), 21, "formatParsha hebrew")
            check(transliterated.formatParsha(cal.getParsha()), 22, "formatParsha")
            check(hebrew.formatParsha(israel.getParsha()), 23, "formatParsha hebrew Israel")
            check(transliterated.formatParsha(israel.getParsha()), 24, "formatParsha Israel")
            check(hebrew.formatSpecialParsha(jewishCalendar: cal), 25, "formatSpecialParsha hebrew")
            check(transliterated.formatSpecialParsha(jewishCalendar: cal), 26, "formatSpecialParsha")
        }
    }
}
