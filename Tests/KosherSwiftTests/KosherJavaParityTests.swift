//
//  KosherJavaParityTests.swift
//  KosherSwiftTests
//
//  Regression tests for logic that diverged from KosherJava. Every expected value here was produced by KosherJava
//  (2.5.0, or master where noted) and is asserted the same way in Tests/KosherJavaParity/KosherJavaParity.java,
//  so both libraries are held to identical answers.
//

import XCTest
@testable import KosherSwift

final class KosherJavaParityTests: XCTestCase {
    private let newYork = GeoLocation(lat: 40.7128, lng: -74.0060, timezone: TimeZone(identifier: "America/New_York")!, elevation: 0, name: "New York")
    private let apia = GeoLocation(lat: -13.8333, lng: -171.7667, timezone: TimeZone(identifier: "Pacific/Apia")!, elevation: 0, name: "Apia")
    private let london = GeoLocation(lat: 51.5074, lng: -0.1278, timezone: TimeZone(identifier: "Europe/London")!, elevation: 0, name: "London")

    /// Midnight of a civil date in the device time zone, the way JewishCalendar(date:) reads its input.
    private func localDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
    
    private func date(_ year: Int, _ month: Int, _ day: Int, in location: GeoLocation) -> Date {
        Date(year: year, month: month, day: day, timezone: location.timezone)
    }

    private func assertInstant(_ actual: Date?, _ expectedMillis: Int64, accuracy: TimeInterval = 1, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        guard let actual else {
            return XCTFail("nil, expected \(Date(milliseconds: expectedMillis)) \(message)", file: file, line: line)
        }
        XCTAssertEqual(actual.timeIntervalSince1970, Double(expectedMillis) / 1000, accuracy: accuracy, message, file: file, line: line)
    }

    // MARK: - Holidays

    /// KosherJava: isErevYomTov() does not include Erev Rosh Chodesh.
    func testErevRoshChodeshIsNotErevYomTov() {
        let cal = JewishCalendar(withJewishYear: 5785, andMonth: .cheshvan, andDay: 29)
        XCTAssertTrue(cal.isErevRoshChodesh)
        XCTAssertFalse(cal.isErevYomTov)
        XCTAssertFalse(cal.isYomTov)
    }

    /// KosherJava: getYomTovIndex() == CHANUKAH and isYomTov() on 29 Kislev, so no Tachanun.
    func testChanukahOnErevRoshChodeshIsYomTov() {
        let cal = JewishCalendar(withJewishYear: 5785, andMonth: .kislev, andDay: 29)
        XCTAssertTrue(cal.isYomTov)
        XCTAssertEqual(cal.getCurrentChag(), .chanukah)
        XCTAssertFalse(TefilaRules(cal).isTachanunRecitedShacharis())
    }

    /// KosherJava: Rosh Chodesh is not in getYomTovIndex(), so isYomTov() is false.
    func testRoshChodeshIsNotYomTov() {
        XCTAssertFalse(JewishCalendar(withJewishYear: 5785, andMonth: .shevat, andDay: 1).isYomTov)
    }

    /// KosherJava: 17 Tammuz on Shabbos is pushed to Sunday. 17 Tammuz 5789 is Shabbos 30 Jun 2029.
    func testSeventeenthOfTammuzOnShabbosIsPostponed() {
        let shabbos = JewishCalendar(withJewishYear: 5789, andMonth: .tammuz, andDay: 17)
        let sunday = JewishCalendar(withJewishYear: 5789, andMonth: .tammuz, andDay: 18)
        XCTAssertEqual(shabbos.dow, .saturday)
        XCTAssertFalse(shabbos.isSeventeenthOfTammuz)
        XCTAssertFalse(shabbos.isTaanis)
        XCTAssertTrue(sunday.isSeventeenthOfTammuz)
        XCTAssertTrue(sunday.isTaanis)
    }

    /// KosherJava: when 5 Iyar is Monday, Yom HaZikaron is Monday and Yom Ha'atzmaut Tuesday (5784: 13/14 May 2024).
    func testYomHazikaronWhenFiveIyarIsMonday() {
        let monday = JewishCalendar(withJewishYear: 5784, andMonth: .iyar, andDay: 5)
        let tuesday = JewishCalendar(withJewishYear: 5784, andMonth: .iyar, andDay: 6)
        XCTAssertEqual(monday.dow, .monday)
        XCTAssertTrue(monday.isYomHazikaron)
        XCTAssertFalse(tuesday.isYomHazikaron)
        XCTAssertTrue(tuesday.isYomHaatzmaut)
    }

    /// KosherJava: ISRU_CHAG after Pesach and Succos too.
    func testIsruChag() {
        XCTAssertTrue(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 23).isIsruChag)
        XCTAssertTrue(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 22, isInIsrael: true).isIsruChag)
        XCTAssertTrue(JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 24).isIsruChag)
        XCTAssertTrue(JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 23, isInIsrael: true).isIsruChag)
        XCTAssertFalse(JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 23).isIsruChag)
    }

    /// KosherJava: isCholHamoedSuccos() includes Hoshana Rabba; getYomTovIndex() == HOSHANA_RABBA.
    func testHoshanaRabba() {
        let cal = JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 21)
        XCTAssertTrue(cal.isCholHamoedSuccos)
        XCTAssertEqual(cal.getCurrentChag(), .hoshanaRabba)
        XCTAssertTrue(cal.isYomTov)
    }

    /// KosherJava: getYomTovIndex() == CHANUKAH on 30 Kislev; formatYomTov() == "Chanukah 6".
    /// Run several times since the old Dictionary-based lookup changed answer between launches.
    func testChanukahOnRoshChodeshIsDeterministic() throws {
        let cal = JewishCalendar(withJewishYear: 5785, andMonth: .kislev, andDay: 30)
        for _ in 0..<20 {
            XCTAssertEqual(cal.getCurrentChag(), .chanukah)
        }
        XCTAssertEqual(try HebrewDateFormatter().formatYomTov(cal), "Chanukah 6")
    }

    /// KosherJava: getSpecialShabbos() returns HAGADOL, SHIRA, CHAZON, NACHAMU, SHUVA.
    func testSpecialShabbosos() {
        XCTAssertEqual(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 14).getSpecialShabbos(), .hagadol)
        XCTAssertEqual(JewishCalendar(date: localDate(2025, 2, 8)).getSpecialShabbos(), .shira)
        XCTAssertEqual(JewishCalendar(date: localDate(2025, 8, 2)).getSpecialShabbos(), .chazon)
        XCTAssertEqual(JewishCalendar(date: localDate(2025, 8, 9)).getSpecialShabbos(), .nachamu)
        XCTAssertEqual(JewishCalendar(date: localDate(2024, 10, 5)).getSpecialShabbos(), .shuva)
        XCTAssertEqual(HebrewDateFormatter().formatSpecialParsha(jewishCalendar: JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 14)), "Hagadol")
    }

    // MARK: - Molad and Kiddush Levana

    /// KosherJava: new JewishCalendar(5784, TEVES, 1).getMoladAsDate().getTime() == 1702402813504
    /// (Tuesday 12 Dec 2023, 20:01 and 3 chalakim, Jerusalem). The same instant whatever the device time zone.
    func testMoladTeves5784() {
        let savedTimeZone = NSTimeZone.default
        defer { NSTimeZone.default = savedTimeZone }
        for identifier in ["America/New_York", "Asia/Jerusalem", "America/Los_Angeles", "UTC", "Asia/Tokyo"] {
            NSTimeZone.default = TimeZone(identifier: identifier)!
            let cal = JewishCalendar(withJewishYear: 5784, andMonth: .teves, andDay: 1)
            XCTAssertEqual(cal.moladDate?.molad.hours, 20, identifier)
            XCTAssertEqual(cal.moladDate?.molad.minutes, 1, identifier)
            XCTAssertEqual(cal.moladDate?.molad.chalakim, 3, identifier)
            assertInstant(cal.moladDate?.gregDate, 1702402813504, identifier)
        }
    }

    /// KosherJava: getTchilasZmanKidushLevana3Days() == molad + 72 h, getSofZmanKidushLevanaBetweenMoldos() == 1703678535170.
    func testKiddushLevana() {
        let cal = JewishCalendar(withJewishYear: 5784, andMonth: .teves, andDay: 1)
        assertInstant(cal.earliestKiddushLevana3Days, 1702662013504)
        assertInstant(cal.latestZmanKidushLevanaBetweenMoldos, 1703678535170)
    }

    // MARK: - Tefila rules

    /// KosherJava TefilaRules.isHallelRecited(): 15 Nissan everywhere; 23 Tishrei only outside Israel.
    func testHallel() {
        XCTAssertTrue(TefilaRules(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 15)).isHallelRecited())
        XCTAssertTrue(TefilaRules(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 15, isInIsrael: true)).isHallelRecited())
        XCTAssertTrue(TefilaRules(JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 23)).isHallelRecited())
        XCTAssertFalse(TefilaRules(JewishCalendar(withJewishYear: 5785, andMonth: .tishrei, andDay: 23, isInIsrael: true)).isHallelRecited())
        XCTAssertTrue(TefilaRules(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 15)).isHallelShalemRecited())
    }

    /// KosherJava TefilaRules.isVeseinTalUmatarStartDate(): in 5781 day 47 is Shabbos 5 Dec 2020, so the start is Sunday 6 Dec.
    func testVeseinTalUmatarStartDateAfterShabbos() {
        XCTAssertFalse(TefilaRules(JewishCalendar(date: localDate(2020, 12, 5))).isVeseinTalUmatarStartDate())
        XCTAssertTrue(TefilaRules(JewishCalendar(date: localDate(2020, 12, 6))).isVeseinTalUmatarStartDate())
        // 5786: day 47 is Friday 5 Dec 2025, which is the start date
        XCTAssertTrue(TefilaRules(JewishCalendar(date: localDate(2025, 12, 5))).isVeseinTalUmatarStartDate())
    }

    // MARK: - Formatting

    /// KosherJava HebrewDateFormatter (Hebrew): formatMonth(Nissan) == "ניסן", formatMonth(Adar, non-leap) == "אדר".
    func testHebrewMonthNames() {
        let formatter = HebrewDateFormatter(hebrewFormat: true)
        XCTAssertEqual(formatter.formatMonth(JewishDate(withJewishYear: 5785, andMonth: .nissan, andDay: 1)), "ניסן")
        XCTAssertEqual(formatter.formatMonth(JewishDate(withJewishYear: 5785, andMonth: .adar, andDay: 1)), "אדר")
        XCTAssertEqual(formatter.formatMonth(JewishDate(withJewishYear: 5784, andMonth: .adar, andDay: 1)), "אדר א׳")
        XCTAssertEqual(formatter.formatMonth(JewishDate(withJewishYear: 5784, andMonth: .adar2, andDay: 1)), "אדר ב׳")
        XCTAssertEqual(formatter.formatRoshChodesh(JewishCalendar(withJewishYear: 5785, andMonth: .nissan, andDay: 1)), "ראש חודש ניסן")
    }

    // MARK: - Zmanim

    /// KosherJava GeoLocation("Apia", -13.8333, -171.7667, Pacific/Apia).getAntimeridianAdjustment() == -1,
    /// getSeaLevelSunrise() on 15 Jun 2025 == 1749923284242 (06:48 local), getSeaLevelSunset() == 1749964017721.
    func testAntimeridianLocation() {
        XCTAssertEqual(apia.antimeridianAdjustment, -1)
        XCTAssertEqual(apia.localMeanTimeOffset, -88024008, accuracy: 1)
        let cal = ZmanimCalendar(location: apia, date: date(2025, 6, 15, in: apia))
        assertInstant(cal.seaLevelSunrise, 1749923284242)
        assertInstant(cal.seaLevelSunset, 1749964017721)
    }

    /// KosherJava ComplexZmanimCalendar.getFixedLocalChatzos() on 15 Jun 2025 (New York 1750006561440, Apia 1749943624008),
    /// with getSeaLevelSunrise() in New York as a control (1749979456066).
    func testFixedLocalChatzos() {
        let ny = ComplexZmanimCalendar(location: newYork, date: date(2025, 6, 15, in: newYork))
        assertInstant(ny.getFixedLocalChatzos(), 1750006561440)
        assertInstant(ny.seaLevelSunrise, 1749979456066)
        let samoa = ComplexZmanimCalendar(location: apia, date: date(2025, 6, 15, in: apia))
        assertInstant(samoa.getFixedLocalChatzos(), 1749943624008)
    }

    /// KosherJava: getPlagHamincha16Point1Degrees() etc. are null in London on 21 Jun 2025 because the sun never reaches
    /// 16.1° below the horizon; the GRA getPlagHamincha() is 1750531057068.
    func testDegreeBasedZmanimAreNilWhenAlosDoesNotOccur() {
        let cal = ComplexZmanimCalendar(location: london, date: date(2025, 6, 21, in: london))
        XCTAssertNil(cal.alos16Point1Degrees())
        XCTAssertNil(cal.plagHamincha16Point1Degrees())
        XCTAssertNil(cal.minchaGedola16Point1Degrees())
        XCTAssertNil(cal.minchaKetana16Point1Degrees())
        assertInstant(cal.calculatePlagHamincha(), 1750531057068)
    }

    /// Second night of Rosh Hashana 5785 (Thu 3 Oct 2024): candle lighting is 13.5 minutes before 7.083° tzeis,
    /// i.e. KosherJava getBainHashmashosRT13Point5MinutesBefore7Point083Degrees() == 1727996002341.
    func testCandleLightingSecondNightRoshHashana() {
        let cal = ZmanimCalendar(location: newYork, date: date(2024, 10, 3, in: newYork))
        assertInstant(cal.candleLighting(), 1727996002341)
        XCTAssertGreaterThan(cal.candleLighting()!, cal.seaLevelSunset!)
    }

    /// Weekday Erev Rosh Chodesh has no candle lighting (KosherJava hasCandleLighting() == false).
    func testNoCandleLightingOnErevRoshChodesh() {
        // 29 Cheshvan 5785 = Sat 30 Nov 2024 is Shabbos; use 29 Teves 5785 = Wed 29 Jan 2025
        XCTAssertTrue(JewishCalendar(withJewishYear: 5785, andMonth: .teves, andDay: 29).isErevRoshChodesh)
        let cal = ZmanimCalendar(location: newYork, date: date(2025, 1, 29, in: newYork))
        XCTAssertNil(cal.candleLighting())
    }

    /// Tisha B'Av 5785 (Sun 3 Aug 2025) starts at sunset on Shabbos 2 Aug: KosherJava getSeaLevelSunset() == 1754179798622.
    func testTishaBeavStartsTheEveningBefore() {
        let cal = ComplexZmanimCalendar(location: newYork, date: date(2025, 8, 1, in: newYork))
        assertInstant(cal.getTaanisStartTime(), 1754179798622)
    }

    // MARK: - Daf Yomi Yerushalmi (KosherJava master YerushalmiYomiCalculator)

    func testDafYomiYerushalmi() {
        let cases: [(Int, Int, Int, Int, Int)] = [
            // year, month, day, masechta number, daf
            (2022, 1, 15, 29, 42),
            (2022, 7, 15, 35, 7), // summer: DST must not cost a day
            (2022, 8, 5, 35, 28),
            (2022, 8, 8, 35, 30), // 9 Av 5782 was Shabbos, so 10 Av (7 Aug) had no daf
            (2022, 12, 1, 0, 18),
            (2023, 7, 1, 5, 16),
            (2025, 7, 15, 24, 19),
        ]
        for (year, month, day, masechta, daf) in cases {
            let result = JewishCalendar(date: Date(year: year, month: month, day: day)).dafYomiYerushalmi
            XCTAssertEqual(result?.masechtaNumber, masechta, "\(year)-\(month)-\(day)")
            XCTAssertEqual(result?.daf, daf, "\(year)-\(month)-\(day)")
        }
        XCTAssertNil(JewishCalendar(date: localDate(2022, 8, 7)).dafYomiYerushalmi)
    }
}
