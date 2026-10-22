//
//  TestLocations.swift
//  KosherSwiftTests
//
//  Swift port of KosherJava's src/test/java/com/kosherjava/zmanim/TestLocations.java, plus the assertion helpers the
//  ported KosherJava tests share. KosherJava asserts java.time values; these helpers compare the same ISO-8601 strings.
//

import XCTest
@testable import KosherSwift

enum TestLocations {
    static let utc = TimeZone(identifier: "UTC")!
    static let newYork = TimeZone(identifier: "America/New_York")!

    static func nj(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: 41.1181036, lng: -74.0840691, timezone: zone, elevation: 167, name: "Woodcliff Lake, NJ") }
    static func la(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: 34.0201613, lng: -118.6919095, timezone: zone, elevation: 71, name: "Los Angeles, CA") }
    static func jerusalem(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: 31.7962994, lng: 35.1053185, timezone: zone, elevation: 754, name: "Jerusalem, Israel") }
    static func norway(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: 70.1498248, lng: 9.1456867, timezone: zone, elevation: 0, name: "Northern Norway") }
    static func sydney(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: -33.8688, lng: 151.2093, timezone: zone, elevation: 58, name: "Sydney, Australia") }
    static func macapa(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: 0.0349, lng: -51.0694, timezone: zone, elevation: 15, name: "Macapá, Brazil") }
    static func suva(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: -18.1416, lng: 178.4419, timezone: zone, elevation: 6, name: "Suva, Fiji") }
    static func ushuaia(_ zone: TimeZone) -> GeoLocation { GeoLocation(lat: -54.8019, lng: -68.3030, timezone: zone, elevation: 23, name: "Ushuaia, Argentina") }
    static func lakewood() -> GeoLocation { GeoLocation(lat: 40.0721087, lng: -74.2400243, timezone: newYork, elevation: 15, name: "Lakewood, NJ") }

    /// A civil date in the given zone, the Swift equivalent of KosherJava's `setLocalDate(LocalDate.of(y, m, d))`.
    static func date(_ year: Int, _ month: Int, _ day: Int, in zone: TimeZone = newYork) -> Date {
        Date(year: year, month: month, day: day, timezone: zone)
    }

    /// Midnight of a civil date in the device time zone, the way `JewishCalendar(date:)` reads its input.
    static func localDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Parses KosherJava's `Instant.toString()` output, for example `2017-10-17T11:09:11.571783718Z`.
    static func instant(_ iso: String) -> Date {
        let parts = iso.dropLast().split(separator: ".")
        let whole = ISO8601DateFormatter().date(from: parts[0] + "Z")!
        let fraction = parts.count > 1 ? Double("0." + parts[1])! : 0
        return whole.addingTimeInterval(fraction)
    }

    /// Parses KosherJava's `Duration.toString()` output, for example `PT1H7M20.649853956S`, into milliseconds.
    static func durationMillis(_ iso: String) -> Double {
        var millis = 0.0
        var number = ""
        for c in iso.dropFirst(2) {
            switch c {
            case "H": millis += Double(number)! * 3_600_000; number = ""
            case "M": millis += Double(number)! * 60_000; number = ""
            case "S": millis += Double(number)! * 1000; number = ""
            default: number.append(c)
            }
        }
        return millis
    }
}

/// KosherSwift is ported from KosherJava 2.5.0. KosherJava master refined the NOAA calculation (apparent solar radius,
/// refraction and earth radius), which moves its results by up to about a third of a second. Times are therefore
/// compared to the second, the precision any app displays.
let kosherJavaTolerance: TimeInterval = 1

func assertInstant(_ actual: Date?, _ expectedIso: String?, _ label: String = "", accuracy: TimeInterval = kosherJavaTolerance, file: StaticString = #filePath, line: UInt = #line) {
    guard let expectedIso else {
        return XCTAssertNil(actual, "\(label) should be nil", file: file, line: line)
    }
    guard let actual else {
        return XCTFail("\(label) is nil, expected \(expectedIso)", file: file, line: line)
    }
    XCTAssertEqual(actual.timeIntervalSince1970, TestLocations.instant(expectedIso).timeIntervalSince1970, accuracy: accuracy, label, file: file, line: line)
}

func assertDuration(_ actualMillis: Double?, _ expectedIso: String, _ label: String = "", file: StaticString = #filePath, line: UInt = #line) {
    guard let actualMillis else {
        return XCTFail("\(label) is nil, expected \(expectedIso)", file: file, line: line)
    }
    XCTAssertEqual(actualMillis, TestLocations.durationMillis(expectedIso), accuracy: kosherJavaTolerance * 1000, label, file: file, line: line)
}
