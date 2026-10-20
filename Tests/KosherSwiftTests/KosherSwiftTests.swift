//
//  KosherSwiftTests.swift
//  YidKitiOSTests
//
//  Created by Daniel Smith on 12/20/23.
//

import XCTest
import KosherSwift

final class KosherSwiftTests: XCTestCase {
    override func setUpWithError() throws {
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func checkDateEquals(_ a: Date?, _ b: Date?) {
        guard let a = a, let b = b else {
            XCTAssertEqual(false, true)
            return
        }
        
        XCTAssertEqual(a.year, b.year)
        XCTAssertEqual(a.month, b.month)
        XCTAssertEqual(a.day, b.day)
        XCTAssertEqual(a.hour, b.hour)
        XCTAssertEqual(a.minute, b.minute)
        XCTAssertEqual(a.second, b.second)
    }
    
    func checkTimeEquals(_ a: Date?, _ hour: Int, _ minute: Int) {
        guard let a = a else {
            XCTAssertEqual(false, true, "a is nil")
            return
        }
        
        XCTAssertEqual(a.hour, hour, "hour")
        XCTAssertEqual(a.minute, minute, "minute")
    }
    
    func testGregorianDateReflectsHebrew() {
        let jewishCalendar = JewishCalendar(date: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 26))!)
        XCTAssertEqual(jewishCalendar.year, 5784)
        XCTAssertEqual(jewishCalendar.month, .teves)
        XCTAssertEqual(jewishCalendar.day, 14)
    }
    
    func testGregorianDateChange() {
        let jewishCalendar = JewishCalendar(date: Calendar.current.date(from: DateComponents(year: 2023, month: 9, day: 25))!)
        XCTAssertEqual(jewishCalendar.gregDate.year, 2023)
        XCTAssertEqual(jewishCalendar.gregDate.month, 9)
        XCTAssertEqual(jewishCalendar.gregDate.day, 25)
    }
    
    func testGregorianDateChangeWithTimzone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        var comp = DateComponents()
        comp.setValue(2023, for: .year)
        comp.setValue(12, for: .month)
        comp.setValue(24, for: .day)
        let jewishCalendar = JewishCalendar(date: calendar.date(from: comp)!)
        XCTAssertEqual(jewishCalendar.gregDate.year, 2023)
        XCTAssertEqual(jewishCalendar.gregDate.month, 12)
        XCTAssertEqual(jewishCalendar.gregDate.day, 24)
    }
    
    func testHebrewDateChange() {
        let jewishCalendar = JewishCalendar(withJewishYear: 5784, andMonth: .teves, andDay: 5, isInIsrael: false)
        XCTAssertEqual(jewishCalendar.year, 5784)
        XCTAssertEqual(jewishCalendar.month, .teves)
        XCTAssertEqual(jewishCalendar.day, 5)
    }
    
    func testIsErevPesach() {
        let jewishCalendar = JewishCalendar(withJewishYear: 5784, andMonth: .nissan, andDay: 14)
        XCTAssertEqual(jewishCalendar.getCurrentChag(), .erevPesach)
        XCTAssertEqual(jewishCalendar.month, .nissan)
        XCTAssertEqual(jewishCalendar.isErevPesach, true)
    }
    
    func testIsPesach() {
        let jewishCalendar = JewishCalendar(withJewishYear: 5784, andMonth: .nissan, andDay: 15)
        XCTAssertEqual(jewishCalendar.getCurrentChag(), .pesach)
        XCTAssertEqual(jewishCalendar.isPesach, true)
    }
    
    func testMolad() {
        let jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 20))
        XCTAssertEqual(jewishCalendar.moladDate?.molad.hours, 20)
        XCTAssertEqual(jewishCalendar.moladDate?.molad.minutes, 1)
        XCTAssertEqual(jewishCalendar.moladDate?.molad.chalakim, 3)
        
        // KosherJava getMoladAsDate() == 1702402813504; gregDate keeps whole seconds
        let moladFromKosherJava = Date(timeIntervalSince1970: 1702402813.0)
        XCTAssertEqual(jewishCalendar.moladDate?.gregDate, moladFromKosherJava)
    }
    
    
    func testParasha() {
        var jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 20))
        XCTAssertEqual(jewishCalendar.getParsha(), .none)
        
        jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 23))
        XCTAssertEqual(jewishCalendar.getParsha(), .vayigash)
        
        jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 30))
        XCTAssertEqual(jewishCalendar.getParsha(), .vayechi)
    }
    
    func testDateFormat() {
        //leap year
        let jewishCalendar = JewishCalendar(withJewishYear: 5784, andMonth: .tishrei, andDay: 8)
        let formatter = HebrewDateFormatter()
        let res = try! formatter.formatDate(jewishCalendar)
        XCTAssertEqual(res, "8 Tishrei, 5784")
    }
    
    func testParshahString() {
        let jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 23))
        let hebrewDateFormatter = HebrewDateFormatter()
        XCTAssertEqual(hebrewDateFormatter.formatParsha(jewishCalendar.getParsha()), "Vayigash")
    }
    
    func testYomTovString() {
        let jewishCalendar = JewishCalendar(withJewishYear: 5784, andMonth: .nissan, andDay: 15)
        
        let hebrewDateFormatter = HebrewDateFormatter()
        XCTAssertEqual(try! hebrewDateFormatter.formatYomTov(jewishCalendar), "Pesach")
    }
    
    func testDafYomis() {
        let jewishCalendar = JewishCalendar(date: Date(year: 2023, month: 12, day: 21))
        
        let dafYomi = jewishCalendar.dafYomiBavli
        let dafYomiYeru = jewishCalendar.dafYomiYerushalmi
        XCTAssertEqual(dafYomi?.masechta, "בבא קמא")
        XCTAssertEqual(dafYomi?.daf, 49)
        XCTAssertEqual(dafYomiYeru?.masechta, "שבת")
        XCTAssertEqual(dafYomiYeru?.daf, 8)
    }
    
    func testCalculatorSunrise() throws {
        let gregorianCalendar = Calendar(identifier: .gregorian)
        
        let geoLocation = GeoLocation(lat: 40.08213, lng: -74.20970, timezone: TimeZone.current)
        let lakewoodCalculator = NOAACalculator()
        
        var januaryFirst = DateComponents()
        januaryFirst.year = 2023
        januaryFirst.month = 1
        januaryFirst.day = 1
        
        var calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: januaryFirst)!, astronomicalCalculator: lakewoodCalculator)
        
        var sunrise = calendar.sunrise
        
        januaryFirst.hour = 7
        januaryFirst.minute = 18
        januaryFirst.second = 57
        
        var testComp = gregorianCalendar.date(from: januaryFirst)!
        checkDateEquals(sunrise, testComp)
        
        var mayFirst = DateComponents()
        mayFirst.year = 2023
        mayFirst.month = 5
        mayFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: mayFirst)!, astronomicalCalculator: lakewoodCalculator)
        
        sunrise = calendar.sunrise
        
        mayFirst.hour = 5
        mayFirst.minute = 56
        mayFirst.second = 59
        
        testComp = gregorianCalendar.date(from: mayFirst)!
        checkDateEquals(sunrise, testComp)
        
        var augustFirst = DateComponents()
        augustFirst.year = 2023
        augustFirst.month = 8
        augustFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: augustFirst)!, astronomicalCalculator: lakewoodCalculator)
        
        sunrise = calendar.sunrise
        
        augustFirst.hour = 5
        augustFirst.minute = 54
        augustFirst.second = 51
        
        testComp = gregorianCalendar.date(from: augustFirst)!
        checkDateEquals(sunrise, testComp)
        
        var decFirst = DateComponents()
        decFirst.year = 2023
        decFirst.month = 12
        decFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: decFirst)!, astronomicalCalculator: lakewoodCalculator)
        sunrise = calendar.sunrise
        
        decFirst.hour = 6
        decFirst.minute = 59
        decFirst.second = 29
        
        checkDateEquals(sunrise, gregorianCalendar.date(from: decFirst))
    }
    
    func testCalculatorSunset() throws {
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = TimeZone(identifier: "America/New_York")!
        
        let geoLocation = GeoLocation(lat: 40.08213, lng: -74.20970, timezone: TimeZone(identifier: "America/New_York")!)
        let lakewoodCalculator = NOAACalculator()
        
        
        
        var januaryFirst = DateComponents()
        januaryFirst.year = 2023
        januaryFirst.month = 1
        januaryFirst.day = 1
        
        let zmanCal = ComplexZmanimCalendar(location: geoLocation, date: gregorianCalendar.date(from: januaryFirst)!)
        
        
        var calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: januaryFirst)!, astronomicalCalculator: lakewoodCalculator)
        var sunset = calendar.sunset
        
        januaryFirst.hour = 16
        januaryFirst.minute = 41
        januaryFirst.second = 56
        
        checkDateEquals(sunset, gregorianCalendar.date(from: januaryFirst))
        checkDateEquals(zmanCal.sunset, gregorianCalendar.date(from: januaryFirst))
        
        
        var mayFirst = DateComponents()
        mayFirst.year = 2023
        mayFirst.month = 5
        mayFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: mayFirst)!, astronomicalCalculator: lakewoodCalculator)
        
        sunset = calendar.sunset
        
        mayFirst.hour = 19
        mayFirst.minute = 51
        mayFirst.second = 33
        
        checkDateEquals(sunset, gregorianCalendar.date(from: mayFirst))
        
        var augustFirst = DateComponents()
        augustFirst.year = 2023
        augustFirst.month = 8
        augustFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: augustFirst)!, astronomicalCalculator: lakewoodCalculator)
        
        sunset = calendar.sunset
        
        augustFirst.hour = 20
        augustFirst.minute = 10
        augustFirst.second = 57
        
        checkDateEquals(sunset, gregorianCalendar.date(from: augustFirst))
        
        var decFirst = DateComponents()
        decFirst.year = 2023
        decFirst.month = 12
        decFirst.day = 1
        
        calendar = AstronomicalCalendar(location: geoLocation, date: gregorianCalendar.date(from: decFirst)!, astronomicalCalculator: lakewoodCalculator)
        sunset = calendar.sunset
        
        decFirst.hour = 16
        decFirst.minute = 31
        decFirst.second = 56
        
        checkDateEquals(sunset, gregorianCalendar.date(from: decFirst))
    }
    
    func testZmanimCalendar() {
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = TimeZone(identifier: "America/New_York")!
        
        let geoLocation = GeoLocation(lat: 40.08213, lng: -74.20970, timezone: TimeZone(identifier: "America/New_York")!)
        
        var januaryFirst = DateComponents()
        januaryFirst.year = 2023
        januaryFirst.month = 12
        januaryFirst.day = 24
        var lakewoodCalculator = ZmanimCalendar(location: geoLocation, date: gregorianCalendar.date(from: januaryFirst)!)
        
        
        var alot = lakewoodCalculator.alos72()
        let format = DateFormatter()
        format.timeZone = gregorianCalendar.timeZone
        format.timeStyle = .full
        
        januaryFirst.hour = 6
        januaryFirst.minute = 04
        januaryFirst.second = 42
        
        checkDateEquals(alot, gregorianCalendar.date(from: januaryFirst))
        
        var mayFirst = DateComponents()
        mayFirst.year = 2023
        mayFirst.month = 5
        mayFirst.day = 1
        
        lakewoodCalculator = ZmanimCalendar(location: geoLocation, date: gregorianCalendar.date(from: mayFirst)!)
        alot = lakewoodCalculator.alos72()
        
        mayFirst.hour = 4
        mayFirst.minute = 44
        mayFirst.second = 59
        
        checkDateEquals(alot, gregorianCalendar.date(from: mayFirst))
        
        var augustFirst = DateComponents()
        augustFirst.year = 2024
        augustFirst.month = 8
        augustFirst.day = 1
        
        lakewoodCalculator = ZmanimCalendar(location: geoLocation, date: gregorianCalendar.date(from: augustFirst)!)
        alot = lakewoodCalculator.alos72()
        
        augustFirst.hour = 4
        augustFirst.minute = 43
        augustFirst.second = 33
        
        checkDateEquals(alot, gregorianCalendar.date(from: augustFirst))
        
        var decFirst = DateComponents()
        decFirst.year = 2024
        decFirst.month = 12
        decFirst.day = 1
        
        lakewoodCalculator = ZmanimCalendar(location: geoLocation, date: gregorianCalendar.date(from: decFirst)!)
        alot = lakewoodCalculator.alos72()
        
        decFirst.hour = 5
        decFirst.minute = 48
        decFirst.second = 14
        
        checkDateEquals(alot, gregorianCalendar.date(from: decFirst))
    }
    
    func testFixedLocalChatzos() {
        let loc = GeoLocation(lat: 37.32495943, lng: -122.01973712)
        let cal = ComplexZmanimCalendar(location: loc, date: Date(year: 2023, month: 12, day: 28))
        checkTimeEquals(cal.minchaKetanaGRAFixedLocalChatzosToSunset(), 17, 57)
    }
    
    func testTaanisEsther() {
        let cal = JewishCalendar(date: Date(year: 2024, month: 2, day: 22), isInIsrael: false)
        XCTAssertFalse(cal.isFastOfEsther)
        
        let cal2 = JewishCalendar(date: Date(year: 2024, month: 3, day: 21), isInIsrael: false)
        XCTAssertTrue(cal2.isFastOfEsther)
    }
    
    
    func testNextWeekday() {
        let startYear = 2023
        let startMonth = 12
        let startDay = 1
        
        let start = Date(year: startYear, month: startMonth, day: startDay) // DOW = friday
        
        checkDateEquals(start.next(.saturday), Date(year: startYear, month: startMonth, day: startDay + 1))
        checkDateEquals(start.next(.sunday), Date(year: startYear, month: startMonth, day: startDay + 2))
        checkDateEquals(start.next(.monday), Date(year: startYear, month: startMonth, day: startDay + 3))
        checkDateEquals(start.next(.tuesday), Date(year: startYear, month: startMonth, day: startDay + 4))
        checkDateEquals(start.next(.wednesday), Date(year: startYear, month: startMonth, day: startDay + 5))
        checkDateEquals(start.next(.thursday), Date(year: startYear, month: startMonth, day: startDay + 6))
        checkDateEquals(start.next(.friday), Date(year: startYear, month: startMonth, day: startDay + 7))
    }
    
    func testCandleLighting() {
        let loc = GeoLocation(lat: 28.035950, lng: -82.389381)
        var cal = ComplexZmanimCalendar(location: loc, date: Date(year: 2024, month: 1, day: 9).next(.friday))
        checkTimeEquals(cal.candleLighting(), 17, 35)
        
        cal = ComplexZmanimCalendar(location: loc, date: Date(year: 2024, month: 1, day: 16).next(.friday))
        checkTimeEquals(cal.candleLighting(), 17, 40)
    }
    
    func testRoshChodeshAdar() {
        let cal = JewishCalendar(date: Date(year: 2024, month: 3, day: 10))
        let roshChodeshFormatter = HebrewDateFormatter()
//        XCTAssertEqual(.adar, cal.month)
        XCTAssertEqual("Rosh Chodesh Adar II", roshChodeshFormatter.formatRoshChodesh(cal))
        
//        let cal2 = JewishCalendar(date: Date(year: 2024, month: 3, day: 11))
//        XCTAssertEqual(.adar2, cal2.month)
//        XCTAssertEqual("Adar II", roshChodeshFormatter.formatMonth(cal2))
    }
    
    func testFastOfEsther() {
        let cal = JewishCalendar(date: Date(year: 2024, month: 1, day: 23), isInIsrael: false)
        XCTAssert(!cal.isFastOfEsther)
    }
    
    func testParsha() {
        var cal = JewishCalendar(date: Date(year: 2025, month: 10, day: 20), isInIsrael: false)
        XCTAssert(cal.getWeeklyParsha() == .noach)
        
        cal = JewishCalendar(date: Date(year: 2025, month: 8, day: 15), isInIsrael: false)
        XCTAssert(cal.getWeeklyParsha() == .eikev)
    }

    func testLongOmer() throws {
        
        let formatter = HebrewDateFormatter(hebrewFormat: true, longOmerFormat: true)
        let omer1Cal = JewishCalendar(withJewishYear: 5786, andMonth: .nissan, andDay: 16)
        XCTAssert(try formatter.formatOmer(jewishCalendar: omer1Cal) == "הַיּוֹם יוֹם אֶחָד לָעֹמֶר:")
        let omer49Cal = JewishCalendar(withJewishYear: 5786, andMonth: .sivan, andDay: 5)
        XCTAssert(try formatter.formatOmer(jewishCalendar: omer49Cal) == "הַיּוֹם תִּשְׁעָה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁבְעָה שָׁבוּעוֹת:")
    }

    func testPolarDayComplexZmanLogic() {
        let date = Date(year: 2017, month: 6, day: 21)
        let location = GeoLocation(lat: 69.6492, lng: 18.9553, timezone: .init(identifier: "Europe/Oslo")!, elevation: nil, name: "Tromso")
        let cal = ZmanimCalendar(location: location, date: date)
        let shema = cal.latestShemaGra()
        XCTAssert(shema == nil)
    }
}
