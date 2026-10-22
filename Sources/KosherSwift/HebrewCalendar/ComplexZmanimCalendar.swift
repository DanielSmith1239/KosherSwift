//
//  ComplexZmanimCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/21/23.
//

import Foundation

public class ComplexZmanimCalendar: ZmanimCalendar {
    private static let ateretTorahSunsetOffset = 40.0
    
    public func copy(withDate date: Date) -> ComplexZmanimCalendar {
        ComplexZmanimCalendar(location: location, date: date, astronomicalCalculator: astronomicalCalculator, shouldUseElevation: shouldUseElevation, candleLightingOffset: candleLightingOffset)
    }
    
    // TODO
    public func shaahZmanis19Point8Degrees() -> Double? { getTemporalHour(dayStart: alos19Point8Degrees(), dayEnd: tzeis19Point8Degrees()) }
    public func shaahZmanis18Degrees() -> Double? { getTemporalHour(dayStart: alos18Degrees(), dayEnd: tzeis18Degrees()) }
    public func shaahZmanis26Degrees() -> Double? { getTemporalHour(dayStart: alos26Degrees(), dayEnd: tzeis26Degrees()) }
    public func shaahZmanis16Point1Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeis16Point1Degrees()) }
    public func shaahZmanis60Minutes() -> Double? { getTemporalHour(dayStart: alos60(), dayEnd: tzeis60()) }
    public func shaahZmanis72Minutes() -> Double? { shaahZmanisMga() }
    public func shaahZmanis72MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos72Zmanis(), dayEnd: tzeis72Zmanis()) }
    public func shaahZmanis90Minutes() -> Double? { getTemporalHour(dayStart: alos90(), dayEnd: tzeis90()) }
    public func shaahZmanis90MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos90Zmanis(), dayEnd: tzeis90Zmanis()) }
    public func shaahZmanis96MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos96Zmanis(), dayEnd: tzeis96Zmanis()) }
    public func shaahZmanisAteretTorah() -> Double? { getTemporalHour(dayStart: alos72Zmanis(), dayEnd: tzeisAteretTorah()) }
    public func shaahZmanis96Minutes() -> Double? { getTemporalHour(dayStart: alos96(), dayEnd: tzeis96()) }
    public func shaahZmanis120Minutes() -> Double? { getTemporalHour(dayStart: alos120(), dayEnd: tzeis120()) }
    public func shaahZmanis120MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos120Zmanis(), dayEnd: tzeis120Zmanis()) }
    public func plagHamincha120MinutesZmanis() -> Date? { calculatePlagHamincha(alos120Zmanis(), tzeis120Zmanis()) }
    public func plagHamincha120Minutes() -> Date? { calculatePlagHamincha(alos120(), tzeis120()) }
    public func alos60() -> Date? {
		AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -60 * AstronomicalCalendar.minuteMillis) }
    public func alos72Zmanis() -> Date? { zmanisBasedOffset(-1.2) }
    public func alos96() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -96 * AstronomicalCalendar.minuteMillis) }
    public func alos90Zmanis() -> Date? {
        guard let shaahZmanis = shaahZmanisGra() else { return nil }
        return AstronomicalCalendar
            .getTimeOffset(time: elevationAdjustedSunrise, offset: (shaahZmanis * -1.5))
    }
    
    public func alos96Zmanis() -> Date? { zmanisBasedOffset(-1.6) }
    public func alos90() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -90 * AstronomicalCalendar.minuteMillis) }
    public func alos120() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -120 * AstronomicalCalendar.minuteMillis) }
    public func alos120Zmanis() -> Date? { zmanisBasedOffset(-2) }
    public func alos26Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z26Deg) }
    public func alos18Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .astronomical) }
    public func alos19Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z19Deg) }
    public func alos19Point8Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z19_8) }
    public func alos16Point1Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_1) }
    public func misheyakir11Point5Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z11_5) }
    public func misheyakir11Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z11Deg) }
    public func misheyakir10Point2Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z10_2) }
    public func misheyakir7Point65Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z7_65) }
    public func misheyakir9Point5Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z9_5) }
    public func latestShemaMGA19Point8Degrees() -> Date? { calculateLatestZmanShema(alos19Point8Degrees(), tzeis19Point8Degrees()) }
    public func latestShemaMGA16Point1Degrees() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func latestShemaMGA18Degrees() -> Date? { calculateLatestZmanShema(alos18Degrees(), tzeis18Degrees()) }
    public func latestShemaMGA72Minutes() -> Date? { latestShemaMga()}
    public func latestShemaMGA72MinutesZmanis() -> Date? { calculateLatestZmanShema(alos72Zmanis(), tzeis72Zmanis()) }
    public func latestShemaMGA90Minutes() -> Date? { calculateLatestZmanShema(alos90(), tzeis90()) }
    public func latestShemaMGA90MinutesZmanis() -> Date? { calculateLatestZmanShema(alos90Zmanis(), tzeis90Zmanis()) }
    public func latestShemaMGA96Minutes() -> Date? { calculateLatestZmanShema(alos96(), tzeis96()) }
    public func latestShemaMGA96MinutesZmanis() -> Date? { calculateLatestZmanShema(alos96Zmanis(), tzeis96Zmanis()) }
    public func latestShema3HoursBeforeChatzos() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: -180 * AstronomicalCalendar.minuteMillis) }
    public func latestShemaMGA120Minutes() -> Date? { calculateLatestZmanShema(alos120(), tzeis120()) }
    public func latestShemaAlos16Point1ToSunset() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), elevationAdjustedSunset) }
    public func latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), tzeisGeonim7Point083Degrees()) }
    public func latestTefilaMGA19Point8Degrees() -> Date? { calculateLatestTefila(alos19Point8Degrees(), tzeis19Point8Degrees()) }
    public func latestTefilaMGA16Point1Degrees() -> Date? { calculateLatestTefila(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func latestTefilaMGA18Degrees() -> Date? { calculateLatestTefila(alos18Degrees(), tzeis18Degrees()) }
    public func latestTefilaMGA72Minutes() -> Date? { latestTefilaMga() }
    public func latestTefilaMGA72MinutesZmanis() -> Date? { calculateLatestTefila(alos72Zmanis(), tzeis72Zmanis()) }
    public func latestTefilaMGA90Minutes() -> Date? { calculateLatestTefila(alos90(), tzeis90()) }
    public func latestTefilaMGA90MinutesZmanis() -> Date? { calculateLatestTefila(alos90Zmanis(), tzeis90Zmanis()) }
    public func latestTefilaMGA96Minutes() -> Date? { calculateLatestTefila(alos96(), tzeis96()) }
    public func latestTefilaMGA96MinutesZmanis() -> Date? { calculateLatestTefila(alos96Zmanis(), tzeis96Zmanis()) }
    public func latestTefilaMGA120Minutes() -> Date? { calculateLatestTefila(alos120(), tzeis120()) }
    public func minchaGedola16Point1Degrees() -> Date? { calculateMinchaGedolah(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func minchaGedola72Minutes() -> Date? { calculateMinchaGedolah(alos72(), tzeis72()) }
    public func minchaKetana16Point1Degrees() -> Date? { calculateMinchaKetana(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func minchaKetana72Minutes() -> Date? { calculateMinchaKetana(alos72(), tzeis72()) }
    public func plagHamincha60Minutes() -> Date? { calculatePlagHamincha(alos60(), tzeis60()) }
    public func plagHamincha72Minutes() -> Date? { calculatePlagHamincha(alos72(), tzeis72()) }
    public func plagHamincha90Minutes() -> Date? { calculatePlagHamincha(alos90(), tzeis90()) }
    public func plagHamincha96Minutes() -> Date? { calculatePlagHamincha(alos96(), tzeis96()) }
    public func plagHamincha96MinutesZmanis() -> Date? { calculatePlagHamincha(alos96Zmanis(), tzeis96Zmanis()) }
    public func plagHamincha90MinutesZmanis() -> Date? { calculatePlagHamincha(alos90Zmanis(), tzeis90Zmanis()) }
    public func plagHamincha72MinutesZmanis() -> Date? { calculatePlagHamincha(alos72Zmanis(), tzeis72Zmanis()) }
    public func plagHamincha16Point1Degrees() -> Date? { calculatePlagHamincha(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func plagHamincha19Point8Degrees() -> Date? { calculatePlagHamincha(alos19Point8Degrees(), tzeis19Point8Degrees()) }
    public func plagHamincha26Degrees() -> Date? { calculatePlagHamincha(alos26Degrees(), tzeis26Degrees()) }
    public func plagHamincha18Degrees() -> Date? { calculatePlagHamincha(alos18Degrees(), tzeis18Degrees()) }
    public func plagAlosToSunset() -> Date? { calculatePlagHamincha(alos16Point1Degrees(), elevationAdjustedSunset) }
    public func tzeisGeonim3Point7Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_7) }
    public func tzeisGeonim3Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_8) }
    public func tzeisGeonim5Point95Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z5_95) }
    public func tzeisGeonim3Point65Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_65) }
    public func tzeisGeonim3Point676Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_676) }
    public func tzeisGeonim4Point61Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_61) }
    public func tzeisGeonim4Point37Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_37) }
    public func tzeisGeonim5Point88Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z5_88) }
    public func tzeisGeonim4Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_8) }
    public func tzeisGeonim6Point45Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z6_45) }
    public func tzeisGeonim7Point083Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z7_083) }
    public func tzeisGeonim7Point67Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z7_67) }
    public func tzeisGeonim8Point5Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z8_5) }
    public func tzeisGeonim9Point3Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z9_3) }
    public func tzeisGeonim9Point75Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z9_75) }
    public func latestShemaAteretTorah() -> Date? { calculateLatestZmanShema(alos72Zmanis(), tzeisAteretTorah()) }
    public func latestTefilahAteretTorah() -> Date? { calculateLatestTefila(alos72Zmanis(), tzeisAteretTorah()) }
    public func minchaGedolaAteretTorah() -> Date? { calculateMinchaGedolah(alos72Zmanis(), tzeisAteretTorah()) }
    public func minchaKetanaAteretTorah() -> Date? { calculateMinchaKetana(alos72Zmanis(), tzeisAteretTorah()) }
    public func plagHaminchaAteretTorah() -> Date? { calculatePlagHamincha(alos72Zmanis(), tzeisAteretTorah()) }
    public func tzeis72Zmanis() -> Date? { zmanisBasedOffset(1.2) }
    public func tzeis90Zmanis() -> Date? { zmanisBasedOffset(1.5) }
    public func tzeis96Zmanis() -> Date? { zmanisBasedOffset(1.6) }
    public func tzeis90() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 90 * AstronomicalCalendar.minuteMillis) }
    public func tzeis120() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 120 * AstronomicalCalendar.minuteMillis) }
    public func tzeis120Zmanis() -> Date? { zmanisBasedOffset(2.0) }
    public func tzeis16Point1Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z16_1) }
	public func tzeis26Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z26Deg) }
    public func tzeis18Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .astronomical) }
    public func latestTefila2HoursBeforeChatzos() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: -120 * AstronomicalCalendar.minuteMillis) }
    public func minchaGedola30Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: 30 * AstronomicalCalendar.minuteMillis) }
    public func plagAlos16Point1ToTzeisGeonim7Point083Degrees()  -> Date? { calculatePlagHamincha(alos16Point1Degrees(), tzeisGeonim7Point083Degrees()) }
    public func beinHashmashosRT13Point24Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z13_24) }
    public func beinHashmashosRT58Point5Minutes()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 58.5 * AstronomicalCalendar.minuteMillis) }
    public func beinHashmashosRT13Point5MinutesBefore7Point083Degrees()  -> Date? { AstronomicalCalendar.getTimeOffset(time: getSunsetOffsetByDegrees(offsetZenith: .z7_083), offset: -13.5 * AstronomicalCalendar.minuteMillis) }
    
    public func beinHashmashosRT2Stars() -> Date? {
        guard let alos19Point8 = alos19Point8Degrees(), let b = elevationAdjustedSunrise else { return nil }
        let offset = ((b - alos19Point8) * 1000) * (5 / 18)
        return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: offset)
    }
    
    public func tzeisAteretTorah() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: ComplexZmanimCalendar.ateretTorahSunsetOffset * AstronomicalCalendar.minuteMillis) }
    
    public func beinHashmashosYereim18Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -18 * AstronomicalCalendar.minuteMillis) }
    public func beinHashmashosYereim3Point5Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus3_05) }
    public func beinHashmashosYereim16Point875Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -16.875 * AstronomicalCalendar.minuteMillis) }
    public func beinHashmashosYereim2Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus2_8) }
    public func beinHashmashosYereim13Point5Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -13.5 * AstronomicalCalendar.minuteMillis) }
    public func beinHashmashosYereim2Point1Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus2_1)}
    public func tzeis60()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 60 * AstronomicalCalendar.minuteMillis) }
    public func tzeis19Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z19_8) }
    public func tzeis96()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 96 * AstronomicalCalendar.minuteMillis) }
	public func latestAchilasChametzGRA()  -> Date? { isErevPesach ? latestTefilaGra() : nil }
	public func latestAchilasChametzMGA72Minutes() -> Date? { isErevPesach ? latestTefilaMGA72Minutes() : nil }
	public func latestAchilasChametzMGA16Point1Degrees() -> Date? { isErevPesach ? latestTefilaMGA16Point1Degrees() : nil }
	public func latestBiurChametzGRA()  -> Date? { isErevPesach ? AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: shaahZmanisGra() != nil ? shaahZmanisGra()! * 5 : nil) : nil }
    public func latestBiurChametzMGA72Minutes()  -> Date? {
		isErevPesach ? AstronomicalCalendar.getTimeOffset(time: alos72(), offset: shaahZmanisMga() != nil ? shaahZmanisMga()! * 5 : nil) : nil }
    public func latestBiurChametzMGA16Point1Degrees()  -> Date? { isErevPesach ? AstronomicalCalendar.getTimeOffset(time: alos16Point1Degrees(), offset: shaahZmanis16Point1Degrees() != nil ? shaahZmanis16Point1Degrees()! * 5 : nil) : nil }
    public func sunriseBaalHatanya() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z1_583) }
    public func sunsetBaalHatanya() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z1_583) }
    public func shaahZmanisBaalHatanya() -> Double? { getTemporalHour(dayStart: sunriseBaalHatanya(), dayEnd: sunsetBaalHatanya()) }
    public func alosBaalHatanya() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_9) }
    public func latestShemaBaalHatanya() -> Date? { calculateLatestZmanShema(sunriseBaalHatanya(), sunsetBaalHatanya()) }
    public func latestTefilaBaalHatanya() -> Date? { calculateLatestTefila(sunriseBaalHatanya(), sunsetBaalHatanya()) }
	public func latestAchilasChametzBaalHatanya() -> Date? {isErevPesach ? latestTefilaBaalHatanya() : nil}
	public func latestBiurChametzBaalHatanya()  -> Date? {
		isErevPesach ? AstronomicalCalendar.getTimeOffset(time: sunriseBaalHatanya(), offset: shaahZmanisBaalHatanya() != nil ?  shaahZmanisBaalHatanya()! * 5 : nil) : nil
	}
    public func minchaGedolaBaalHatanya() -> Date? { calculateMinchaGedolah(sunriseBaalHatanya(), sunsetBaalHatanya()) }
    public func minchaGedolaBaalHatanyaGreaterThan30() -> Date? {
        guard let a = minchaGedola30Minutes(), let b = minchaGedolaBaalHatanya() else { return nil }
        return a > b ? a : b
    }
    public func minchaKetanaBaalHatanya() -> Date? { calculateMinchaKetana(sunriseBaalHatanya(), sunsetBaalHatanya()) }
    public func plagHaminchaBaalHatanya() -> Date? { calculatePlagHamincha(sunriseBaalHatanya(), sunsetBaalHatanya()) }
    public func tzeisBaalHatanya()  -> Date? { getSunsetOffsetByDegrees(offsetZenith: .civil) }
    public func latestShemaMGA18DegreesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos18Degrees(), getFixedLocalChatzos(), 3) }
    public func latestShemaMGA16Point1DegreesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos16Point1Degrees(), getFixedLocalChatzos(), 3)}
    public func latestShemaMGA90MinutesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos90(), getFixedLocalChatzos(), 3)}
    public func latestShemaMGA72MinutesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos72(), getFixedLocalChatzos(), 3)}
    public func latestShemaGRASunriseToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(sunrise, getFixedLocalChatzos(), 3) }
    public func latestTefilaGRASunriseToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(sunrise, getFixedLocalChatzos(), 4) }
    public func minchaGedolaGRAFixedLocalChatzos30Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: getFixedLocalChatzos(), offset: AstronomicalCalendar.minuteMillis * 30) }
    public func minchaKetanaGRAFixedLocalChatzosToSunset() -> Date? { getHalfDayBasedZman(startOfHalfDay: getFixedLocalChatzos(), endOfHalfDay: sunset, hours: 3.5) }
    public func plagHaminchaGRAFixedLocalChatzosToSunset() -> Date? { getHalfDayBasedZman(startOfHalfDay: getFixedLocalChatzos(), endOfHalfDay: sunset, hours: 4.75) }
    public func tzeis50() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 50 * AstronomicalCalendar.minuteMillis) }
    public func midday() -> Date? { getSolarMidnight()?.withAdded(hours: -12) }

    public func minchaGedolaGreaterThan30() -> Date? {
        guard let a = minchaGedola30Minutes(), let b = calculateMinchaGedolah() else { return nil }
        return a > b ? a : b
    }

    // Zmanim KosherJava has that KosherSwift was missing. Ahavat Shalom and samuch le'mincha ketana
    // are from KosherJava 2.5.0; the rest were added in KosherJava master. getCandleLighting() and chatzosAsHalfDay()
    // are on ZmanimCalendar.

    public func misheyakir12Point85Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z12_85) }
    public func tzeisGeonim4Point42Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_42) }
    public func tzeisGeonim4Point66Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_66) }

    public func shaahZmanisAlos16Point1ToTzeisGeonim3Point7Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeisGeonim3Point7Degrees()) }
    public func shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeisGeonim3Point8Degrees()) }
    public func shaahZmanisAlos16Point1ToTzeisGeonim7Point083Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeisGeonim7Point083Degrees()) }

    /// The later of 30 minutes after chatzos and half a shaah zmanis (alos 16.1° to tzais 3.7°) after chatzos.
    public func minchaGedolaAhavatShalom() -> Date? {
        guard let minchaGedola30 = minchaGedola30Minutes(), calculateMinchaGedolah() != nil,
              let shaahZmanis = shaahZmanisAlos16Point1ToTzeisGeonim3Point7Degrees(),
              let halfShaah = AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: shaahZmanis / 2) else { return nil }
        return minchaGedola30 > halfShaah ? minchaGedola30 : halfShaah
    }

    /// 2.5 shaos zmaniyos (alos 16.1° to tzais 3.8°) before tzais 3.8°.
    public func minchaKetanaAhavatShalom() -> Date? {
        guard let shaahZmanis = shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees() else { return nil }
        return AstronomicalCalendar.getTimeOffset(time: tzeisGeonim3Point8Degrees(), offset: -shaahZmanis * 2.5)
    }

    /// 1.25 shaos zmaniyos (alos 16.1° to tzais 3.8°) before tzais 3.8°.
    public func plagAhavatShalom() -> Date? {
        guard let shaahZmanis = shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees() else { return nil }
        return AstronomicalCalendar.getTimeOffset(time: tzeisGeonim3Point8Degrees(), offset: -shaahZmanis * 1.25)
    }

    /// Nine shaos zmaniyos into the day, half an hour before mincha ketana.
    public func samuchLeMinchaKetana(_ startOfDay: Date?, _ endOfDay: Date?) -> Date? {
        guard let startOfDay, let endOfDay else { return nil }
        return shaahZmanisBasedZman(startOfDay, endOfDay, 9)
    }
    public func samuchLeMinchaKetanaGRA() -> Date? { samuchLeMinchaKetana(elevationAdjustedSunrise, elevationAdjustedSunset) }
    public func samuchLeMinchaKetana16Point1Degrees() -> Date? { samuchLeMinchaKetana(alos16Point1Degrees(), tzeis16Point1Degrees()) }
    public func samuchLeMinchaKetana72Minutes() -> Date? { samuchLeMinchaKetana(alos72(), tzeis72()) }

    public func latestAchilasChametzMGA72MinutesZmanis() -> Date? { isErevPesach ? latestTefilaMGA72MinutesZmanis() : nil }
    public func latestBiurChametzMGA72MinutesZmanis() -> Date? {
        guard isErevPesach, let alos = alos72Zmanis(), let tzeis = tzeis72Zmanis() else { return nil }
        return shaahZmanisBasedZman(alos, tzeis, 5)
    }
    
    // Helpers
    public func zmanisBasedOffset(_ hours: Double) -> Date? {
        guard let shaahZmanis = shaahZmanisGra() else { return nil }
        
        if hours > 0 {
            return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: (shaahZmanis * hours))
        }
        
        return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: (shaahZmanis * hours))
    }
    
    public func getFixedLocalChatzosBasedZmanim(_ startOfHalfDay: Date?, _ endOfHalfDay: Date?, _ hours: Double) -> Date? {
//        guard let startOfHalfDay = startOfHalfDay, let endOfHalfDay = endOfHalfDay else { return nil }
//        
//        let shaahZmanis = (endOfHalfDay.millisecondsSince1970 - startOfHalfDay.millisecondsSince1970) / 6
//        return Date(milliseconds: startOfHalfDay.millisecondsSince1970 + shaahZmanis * Int64(hours))
        getHalfDayBasedZman(startOfHalfDay: startOfHalfDay, endOfHalfDay: endOfHalfDay, hours: hours)

    }
    
    public func getFixedLocalChatzos()  -> Date? {
        getLocalMeanTime(hours: 12.0)
    }
    
    public func latestShemaKolEliyahu() -> Date? {
        guard let chatzos = getFixedLocalChatzos(), let seaLevelSunrise = seaLevelSunrise else { return nil }
        let diff = (chatzos - seaLevelSunrise).inMilliseconds / 2
        return AstronomicalCalendar.getTimeOffset(time: chatzos, offset: -diff)
    }
    
    public func getShabbosStartTime() -> Date? {
        // days until Friday (weekday 6); 0 on Friday itself
        let delta = (DayOfWeek.friday.rawValue - dayOfWeek.rawValue + 7) % 7
        // Candle lighting: sea-level sunset minus candleLightingOffset, as KosherJava getCandleLighting()
        return copy(withDate: date(addingDays: delta)).getCandleLighting()
    }
    
    public func getShabbosExitTime() -> Date? {
        // days until Shabbos (weekday 7); 0 on Shabbos itself
        let delta = (DayOfWeek.saturday.rawValue - dayOfWeek.rawValue + 7) % 7
        let tempCal = copy(withDate: date(addingDays: delta))
        let ret = tempCal.beinHashmashosRT13Point5MinutesBefore7Point083Degrees()
        return ret?.withAdded(minutes: 22)
    }
    
    public func getYomTovStartTime() -> Date? {
        var jewishCalendar = JewishCalendar(date: deviceDate)
        while !jewishCalendar.isErevYomTov {
            jewishCalendar = JewishCalendar(date: jewishCalendar.gregDate.withAdded(days: 1)!)
        }
        
        // Candle lighting: sea-level sunset minus candleLightingOffset, as KosherJava getCandleLighting()
        return copy(withDate: locationDate(fromDeviceDate: jewishCalendar.gregDate)).getCandleLighting()
    }
    
    public func getYomTovExitTime() -> Date? {
        var jewishCalendar = JewishCalendar(date: deviceDate)
        while !jewishCalendar.isYomTov {
            jewishCalendar = JewishCalendar(date: jewishCalendar.gregDate.withAdded(days: 1)!)
        }
        
        let tempCal = copy(withDate: locationDate(fromDeviceDate: jewishCalendar.gregDate))
        let ret = tempCal.sunset
        return ret?.withAdded(minutes: 22)
    }
    
    public func getTaanisStartTime(isInIsrael: Bool = false, isAshkenaz: Bool = false) -> Date? {
        var jewishCalendar = JewishCalendar(date: deviceDate, isInIsrael: isInIsrael)
        while !jewishCalendar.isTaanis {
            jewishCalendar = JewishCalendar(date: jewishCalendar.gregDate.withAdded(days: 1)!)
        }
        let tempCal = copy(withDate: locationDate(fromDeviceDate: jewishCalendar.gregDate))
        
        if jewishCalendar.isTishaBeav || jewishCalendar.isYomKippur {
            // these fasts start at sunset the evening before
            return copy(withDate: locationDate(fromDeviceDate: jewishCalendar.gregDate.withAdded(days: -1)!)).sunset
        } else {
            return isAshkenaz
            ? tempCal.alosHashachar()
            : tempCal.alos72()
        }
    }
    
    public func getTaanisExitTime(isInIsrael: Bool = false, isAshkenaz: Bool = false) -> Date? {
        var jewishCalendar = JewishCalendar(date: deviceDate, isInIsrael: isInIsrael)
        while !jewishCalendar.isTaanis {
            jewishCalendar = JewishCalendar(date: jewishCalendar.gregDate.withAdded(days: 1)!)
        }
        
        let tempCal = copy(withDate: locationDate(fromDeviceDate: jewishCalendar.gregDate))
        
        return tempCal.beinHashmashosRT13Point5MinutesBefore7Point083Degrees()?.withAdded(minutes: isAshkenaz ? 20 : 0)
    }
    
    public func getTallisAndTefillin(isInIsrael: Bool = false, isAshkenaz: Bool = false) -> Date? {
        if (isAshkenaz) {
            return misheyakir10Point2Degrees()
        } else {
            let ret = alosHashachar()
            return ret == nil ? nil : ret!.withAdded(minutes: 6)
        }
    }
    
    /// Halfway between today's and tomorrow's chatzos, as in KosherJava getSolarMidnight().
    public func getSolarMidnight() -> Date? {
        let tempCal = copy(withDate: date(addingDays: 1))
        guard let chatzos = chatzos(), let nextChatzos = tempCal.chatzos() else { return nil }
        return chatzos.addingTimeInterval(nextChatzos.timeIntervalSince(chatzos) / 2)
    }
    
    public func getMidnightLastNight() -> Date? {
        Calendar.current.date(from: DateComponents(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0))
    }

    public func getMidnightTonight() -> Date? {
        Calendar.current.date(from: DateComponents(year: date.year, month: date.month, day: date.day + 1, hour: 0, minute: 0))
    }
    
    public func getMoladBasedTime(_ moladBasedTime: Date, _ alos: Date? = nil, _ tzeis: Date? = nil, _ techila: Bool) -> Date? {
        guard let lastMidnight = getMidnightLastNight(), let midnightTonight = getMidnightTonight() else {
            return nil
        }
        if !(moladBasedTime < lastMidnight || moladBasedTime > midnightTonight) {
            if (alos != nil && tzeis != nil) {
                if techila && !(moladBasedTime < tzeis! || moladBasedTime > alos!) {
                    return tzeis
                } else {
                    return alos
                }
            }
            return moladBasedTime
        }
        return nil
    }
	
	private var isErevPesach: Bool {
		JewishCalendar(date: deviceDate).isErevPesach
	}
}
