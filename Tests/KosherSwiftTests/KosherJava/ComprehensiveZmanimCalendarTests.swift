//
//  ComprehensiveZmanimCalendarTests.swift
//  KosherSwiftTests
//
//  Port of KosherJava master's ComprehensiveZmanimCalendarTest.java: every zman at Lakewood, NJ on 17 October 2017,
//  checked against KosherJava's golden output. KosherSwift's ComplexZmanimCalendar is KosherJava's
//  ComprehensiveZmanimCalendar (renamed in master), and the first column keeps KosherJava's method name.
//
//  KosherJava zmanim that KosherSwift doesn't have, so aren't ported: getCandleLighting (KosherSwift's candleLighting()
//  only returns a time on days candles are lit), getChatzosHayomAsHalfDay, getMisheyakir12Point85Degrees,
//  getTzaisGeonim4Point42Degrees, getTzaisGeonim4Point66Degrees, the Ahavat Shalom and samuch le'mincha ketana zmanim,
//  the getShaahZmanisAlos16Point1DegreesToTzaisGeonim* hours, the MGA 72 minutes zmanis chametz times, and the polar
//  zmanim. KosherJava's ComprehensiveZmanimCalendar returns kiddush levana times only on the day they fall, while
//  KosherSwift has them on JewishCalendar; SpecialDayZmanimTests covers those.
//

import XCTest
@testable import KosherSwift

final class ComprehensiveZmanimCalendarTests: XCTestCase {
    private enum Zman {
        case date((ComplexZmanimCalendar) -> Date?)
        case duration((ComplexZmanimCalendar) -> Double?)
    }

    private let expected: [(String, Zman, String?)] = [
        ("getAlos120Minutes", .date { $0.alos120() }, "2017-10-17T09:09:51.403184642Z"),
        ("getAlos120Zmanis", .date { $0.alos120Zmanis() }, "2017-10-17T09:19:10.103476730Z"),
        ("getAlos16Point1Degrees", .date { $0.alos16Point1Degrees() }, "2017-10-17T09:49:30.219906135Z"),
        ("getAlos18Degrees", .date { $0.alos18Degrees() }, "2017-10-17T09:39:33.523030241Z"),
        ("getAlos19Degrees", .date { $0.alos19Degrees() }, "2017-10-17T09:34:19.165263704Z"),
        ("getAlos19Point8Degrees", .date { $0.alos19Point8Degrees() }, "2017-10-17T09:30:07.461349050Z"),
        ("getAlos26Degrees", .date { $0.alos26Degrees() }, "2017-10-17T08:57:25.521762580Z"),
        ("getAlos60Minutes", .date { $0.alos60() }, "2017-10-17T10:09:51.403184642Z"),
        ("getAlos72Minutes", .date { $0.alos72() }, "2017-10-17T09:57:51.403184642Z"),
        ("getAlos72Zmanis", .date { $0.alos72Zmanis() }, "2017-10-17T10:03:26.623359895Z"),
        ("getAlos90Minutes", .date { $0.alos90() }, "2017-10-17T09:39:51.403184642Z"),
        ("getAlos90Zmanis", .date { $0.alos90Zmanis() }, "2017-10-17T09:46:50.428403708Z"),
        ("getAlos96Minutes", .date { $0.alos96() }, "2017-10-17T09:33:51.403184642Z"),
        ("getAlos96Zmanis", .date { $0.alos96Zmanis() }, "2017-10-17T09:41:18.363418313Z"),
        ("getAlosBaalHatanya", .date { $0.alosBaalHatanya() }, "2017-10-17T09:45:19.050001055Z"),
        ("getBainHashmashosRT13Point24Degrees", .date { $0.beinHashmashosRT13Point24Degrees() }, "2017-10-17T23:19:17.914866983Z"),
        ("getBainHashmashosRT13Point5MinutesBefore7Point083Degrees", .date { $0.beinHashmashosRT13Point5MinutesBefore7Point083Degrees() }, "2017-10-17T22:33:33.446858525Z"),
        ("getBainHashmashosRT2Stars", .date { $0.beinHashmashosRT2Stars() }, "2017-10-17T22:41:41.407497564Z"),
        ("getBainHashmashosRT58Point5Minutes", .date { $0.beinHashmashosRT58Point5Minutes() }, "2017-10-17T23:12:29.201432122Z"),
        ("getBainHashmashosYereim13Point5Minutes", .date { $0.beinHashmashosYereim13Point5Minutes() }, "2017-10-17T22:00:29.201432122Z"),
        ("getBainHashmashosYereim16Point875Minutes", .date { $0.beinHashmashosYereim16Point875Minutes() }, "2017-10-17T21:57:06.701432122Z"),
        ("getBainHashmashosYereim18Minutes", .date { $0.beinHashmashosYereim18Minutes() }, "2017-10-17T21:55:59.201432122Z"),
        ("getBainHashmashosYereim2Point1Degrees", .date { $0.beinHashmashosYereim2Point1Degrees() }, "2017-10-17T21:58:15.259245832Z"),
        ("getBainHashmashosYereim2Point8Degrees", .date { $0.beinHashmashosYereim2Point8Degrees() }, "2017-10-17T21:54:28.539077180Z"),
        ("getBainHashmashosYereim3Point05Degrees", .date { $0.beinHashmashosYereim3Point5Degrees() }, "2017-10-17T21:53:07.410874002Z"),
        ("getBeginAstronomicalTwilight", .date { $0.astronomicalTwilightStart }, "2017-10-17T09:39:33.523030241Z"),
        ("getBeginCivilTwilight", .date { $0.civilTwilightStart }, "2017-10-17T10:42:27.439221886Z"),
        ("getBeginNauticalTwilight", .date { $0.nauticalTwilightStart }, "2017-10-17T10:10:57.242471901Z"),
        ("getChatzosHalayla", .date { $0.getSolarMidnight() }, "2017-10-18T04:42:06.833038724Z"),
        ("getChatzosHayom", .date { $0.chatzos() }, "2017-10-17T16:42:12.781249470Z"),
        ("getEndAstronomicalTwilight", .date { $0.astronomicalTwilightEnd }, "2017-10-17T23:44:09.707296295Z"),
        ("getEndCivilTwilight", .date { $0.civilTwilightEnd }, "2017-10-17T22:41:21.435143220Z"),
        ("getEndNauticalTwilight", .date { $0.nauticalTwilightEnd }, "2017-10-17T23:12:49.151356447Z"),
        ("getFixedLocalChatzosHayom", .date { $0.getFixedLocalChatzos() }, "2017-10-17T16:56:57.605832Z"),
        ("getMinchaGedola16Point1Degrees", .date { $0.minchaGedola16Point1Degrees() }, "2017-10-17T17:16:13.988705527Z"),
        ("getMinchaGedola30Minutes", .date { $0.minchaGedola30Minutes() }, "2017-10-17T17:12:12.781249470Z"),
        ("getMinchaGedola72Minutes", .date { $0.minchaGedola72Minutes() }, "2017-10-17T17:15:35.627235356Z"),
        ("getMinchaGedolaAteretTorah", .date { $0.minchaGedolaAteretTorah() }, "2017-10-17T17:00:49.269815683Z"),
        ("getMinchaGedolaBaalHatanya", .date { $0.minchaGedolaBaalHatanya() }, "2017-10-17T17:09:55.476611672Z"),
        ("getMinchaGedolaGRA", .date { $0.calculateMinchaGedolah() }, "2017-10-17T17:09:35.627235356Z"),
        ("getMinchaGedolaGRAFixedLocalChatzos30Minutes", .date { $0.minchaGedolaGRAFixedLocalChatzos30Minutes() }, "2017-10-17T17:26:57.605832Z"),
        ("getMinchaGedolaGRAGreaterThan30", .date { $0.minchaGedolaGreaterThan30() }, "2017-10-17T17:12:12.781249470Z"),
        ("getMinchaKetana16Point1Degrees", .date { $0.minchaKetana16Point1Degrees() }, "2017-10-17T20:42:24.958920631Z"),
        ("getMinchaKetana72Minutes", .date { $0.minchaKetana72Minutes() }, "2017-10-17T20:37:37.576797224Z"),
        ("getMinchaKetanaAteretTorah", .date { $0.minchaKetanaAteretTorah() }, "2017-10-17T20:13:27.414333739Z"),
        ("getMinchaKetanaBaalHatanya", .date { $0.minchaKetanaBaalHatanya() }, "2017-10-17T19:57:57.216239627Z"),
        ("getMinchaKetanaGRA", .date { $0.calculateMinchaKetana() }, "2017-10-17T19:55:37.576797224Z"),
        ("getMinchaKetanaGRAFixedLocalChatzosToSunset", .date { $0.minchaKetanaGRAFixedLocalChatzosToSunset() }, "2017-10-17T20:02:16.630Z"), // KosherJava 2.5.0. Master switched this zman from elevation-adjusted to sea-level sunrise/sunset
        ("getMisheyakir10Point2Degrees", .date { $0.misheyakir10Point2Degrees() }, "2017-10-17T10:20:22.960720797Z"),
        ("getMisheyakir11Degrees", .date { $0.misheyakir11Degrees() }, "2017-10-17T10:16:11.433376090Z"),
        ("getMisheyakir11Point5Degrees", .date { $0.misheyakir11Point5Degrees() }, "2017-10-17T10:13:34.311221155Z"),
        ("getMisheyakir7Point65Degrees", .date { $0.misheyakir7Point65Degrees() }, "2017-10-17T10:33:46.155182911Z"),
        ("getMisheyakir9Point5Degrees", .date { $0.misheyakir9Point5Degrees() }, "2017-10-17T10:24:03.203710034Z"),
        ("getPlagAlos16Point1DegreesToTzaisGeonim7Point083Degrees", .date { $0.plagAlos16Point1ToTzeisGeonim7Point083Degrees() }, "2017-10-17T21:26:03.735717649Z"),
        ("getPlagAlosToSunset", .date { $0.plagAlosToSunset() }, "2017-10-17T20:56:26.182523158Z"),
        ("getPlagHamincha120Minutes", .date { $0.plagHamincha120Minutes() }, "2017-10-17T22:39:48.389114669Z"),
        ("getPlagHamincha120MinutesZmanis", .date { $0.plagHamincha120MinutesZmanis() }, "2017-10-17T22:32:26.084716766Z"),
        ("getPlagHamincha16Point1Degrees", .date { $0.plagHamincha16Point1Degrees() }, "2017-10-17T22:08:19.529843591Z"),
        ("getPlagHamincha18Degrees", .date { $0.plagHamincha18Degrees() }, "2017-10-17T22:16:10.938101909Z"),
        ("getPlagHamincha19Point8Degrees", .date { $0.plagHamincha19Point8Degrees() }, "2017-10-17T22:23:38.065797743Z"),
        ("getPlagHamincha26Degrees", .date { $0.plagHamincha26Degrees() }, "2017-10-17T22:49:27.074658511Z"),
        ("getPlagHamincha60Minutes", .date { $0.plagHamincha60Minutes() }, "2017-10-17T21:52:18.389114669Z"),
        ("getPlagHamincha72Minutes", .date { $0.plagHamincha72Minutes() }, "2017-10-17T22:01:48.389114669Z"),
        ("getPlagHamincha72MinutesZmanis", .date { $0.plagHamincha72MinutesZmanis() }, "2017-10-17T21:57:23.006475925Z"),
        ("getPlagHamincha90Minutes", .date { $0.plagHamincha90Minutes() }, "2017-10-17T22:16:03.389114669Z"),
        ("getPlagHamincha90MinutesZmanis", .date { $0.plagHamincha90MinutesZmanis() }, "2017-10-17T22:10:31.660816241Z"),
        ("getPlagHamincha96Minutes", .date { $0.plagHamincha96Minutes() }, "2017-10-17T22:20:48.389114669Z"),
        ("getPlagHamincha96MinutesZmanis", .date { $0.plagHamincha96MinutesZmanis() }, "2017-10-17T22:14:54.545596351Z"),
        ("getPlagHaminchaAteretTorah", .date { $0.plagHaminchaAteretTorah() }, "2017-10-17T21:33:43.307882929Z"),
        ("getPlagHaminchaBaalHatanya", .date { $0.plagHaminchaBaalHatanya() }, "2017-10-17T21:07:57.941084608Z"),
        ("getPlagHaminchaGRA", .date { $0.calculatePlagHamincha() }, "2017-10-17T21:04:48.389114669Z"),
        ("getPlagHaminchaGRAFixedLocalChatzosToSunset", .date { $0.plagHaminchaGRAFixedLocalChatzosToSunset() }, "2017-10-17T21:08:27.710Z"), // KosherJava 2.5.0. Master switched this zman from elevation-adjusted to sea-level sunrise/sunset
        ("getSeaLevelSunrise", .date { $0.seaLevelSunrise }, "2017-10-17T11:09:51.403184642Z"),
        ("getSeaLevelSunset", .date { $0.seaLevelSunset }, "2017-10-17T22:13:59.201432122Z"),
        ("getShaahZmanis120Minutes", .duration { $0.shaahZmanis120Minutes() }, "PT1H15M20.649853956S"),
        ("getShaahZmanis120MinutesZmanis", .duration { $0.shaahZmanis120MinutesZmanis() }, "PT1H13M47.533138608S"),
        ("getShaahZmanis16Point1Degrees", .duration { $0.shaahZmanis16Point1Degrees() }, "PT1H8M43.656738368S"),
        ("getShaahZmanis18Degrees", .duration { $0.shaahZmanis18Degrees() }, "PT1H10M23.015355504S"),
        ("getShaahZmanis19Point8Degrees", .duration { $0.shaahZmanis19Point8Degrees() }, "PT1H11M57.265530111S"),
        ("getShaahZmanis26Degrees", .duration { $0.shaahZmanis26Degrees() }, "PT1H17M23.865385668S"),
        ("getShaahZmanis60Minutes", .duration { $0.shaahZmanis60Minutes() }, "PT1H5M20.649853956S"),
        ("getShaahZmanis72Minutes", .duration { $0.shaahZmanis72Minutes() }, "PT1H7M20.649853956S"),
        ("getShaahZmanis72MinutesZmanis", .duration { $0.shaahZmanis72MinutesZmanis() }, "PT1H6M24.779824747S"),
        ("getShaahZmanis90Minutes", .duration { $0.shaahZmanis90Minutes() }, "PT1H10M20.649853956S"),
        ("getShaahZmanis90MinutesZmanis", .duration { $0.shaahZmanis90MinutesZmanis() }, "PT1H9M10.812317445S"),
        ("getShaahZmanis96Minutes", .duration { $0.shaahZmanis96Minutes() }, "PT1H11M20.649853956S"),
        ("getShaahZmanis96MinutesZmanis", .duration { $0.shaahZmanis96MinutesZmanis() }, "PT1H10M6.156481678S"),
        ("getShaahZmanisAteretTorah", .duration { $0.shaahZmanisAteretTorah() }, "PT1H4M12.714839352S"),
        ("getShaahZmanisBaalHatanya", .duration { $0.shaahZmanisBaalHatanya() }, "PT56M0.579875985S"),
        ("getShaahZmanisGRA", .duration { $0.shaahZmanisGra() }, "PT55M20.649853956S"),
        ("getSofZmanAchilasChametzBaalHatanya", .date { $0.latestAchilasChametzBaalHatanya() }, nil),
        ("getSofZmanAchilasChametzGRA", .date { $0.latestAchilasChametzGRA() }, nil),
        ("getSofZmanAchilasChametzMGA16Point1Degrees", .date { $0.latestAchilasChametzMGA16Point1Degrees() }, nil),
        ("getSofZmanAchilasChametzMGA72Minutes", .date { $0.latestAchilasChametzMGA72Minutes() }, nil),
        ("getSofZmanBiurChametzBaalHatanya", .date { $0.latestBiurChametzBaalHatanya() }, nil),
        ("getSofZmanBiurChametzGRA", .date { $0.latestBiurChametzGRA() }, nil),
        ("getSofZmanBiurChametzMGA16Point1Degrees", .date { $0.latestBiurChametzMGA16Point1Degrees() }, nil),
        ("getSofZmanBiurChametzMGA72Minutes", .date { $0.latestBiurChametzMGA72Minutes() }, nil),
        ("getSofZmanShma3HoursBeforeChatzos", .date { $0.latestShema3HoursBeforeChatzos() }, "2017-10-17T13:42:12.781249470Z"),
        ("getSofZmanShmaAlos16Point1DegreesToTzaisGeonim7Point083Degrees", .date { $0.latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees() }, "2017-10-17T13:03:53.526644232Z"),
        ("getSofZmanShmaAlos16Point1ToSunset", .date { $0.latestShemaAlos16Point1ToSunset() }, "2017-10-17T12:55:37.465287630Z"),
        ("getSofZmanShmaAteretTorah", .date { $0.latestShemaAteretTorah() }, "2017-10-17T13:16:04.767877951Z"),
        ("getSofZmanShmaBaalHatanya", .date { $0.latestShemaBaalHatanya() }, "2017-10-17T13:53:53.447045725Z"),
        ("getSofZmanShmaGRA", .date { $0.latestShemaGra() }, "2017-10-17T13:55:53.352746510Z"),
        ("getSofZmanShmaGRASunriseToFixedLocalChatzos", .date { $0.latestShemaGRASunriseToFixedLocalChatzos() }, "2017-10-17T14:03:04.688Z"), // KosherJava 2.5.0. Master switched this zman from elevation-adjusted to sea-level sunrise/sunset
        ("getSofZmanShmaMGA120Minutes", .date { $0.latestShemaMGA120Minutes() }, "2017-10-17T12:55:53.352746510Z"),
        ("getSofZmanShmaMGA16Point1Degrees", .date { $0.latestShemaMGA16Point1Degrees() }, "2017-10-17T13:15:41.190121239Z"),
        ("getSofZmanShmaMGA16Point1DegreesToFixedLocalChatzos", .date { $0.latestShemaMGA16Point1DegreesToFixedLocalChatzos() }, "2017-10-17T13:23:13.912869066Z"),
        ("getSofZmanShmaMGA18Degrees", .date { $0.latestShemaMGA18Degrees() }, "2017-10-17T13:10:42.569096753Z"),
        ("getSofZmanShmaMGA18DegreesToFixedLocalChatzos", .date { $0.latestShemaMGA18DegreesToFixedLocalChatzos() }, "2017-10-17T13:18:15.564431120Z"),
        ("getSofZmanShmaMGA19Point8Degrees", .date { $0.latestShemaMGA19Point8Degrees() }, "2017-10-17T13:05:59.257939383Z"),
        ("getSofZmanShmaMGA72Minutes", .date { $0.latestShemaMGA72Minutes() }, "2017-10-17T13:19:53.352746510Z"),
        ("getSofZmanShmaMGA72MinutesToFixedLocalChatzos", .date { $0.latestShemaMGA72MinutesToFixedLocalChatzos() }, "2017-10-17T13:27:24.504508319Z"),
        ("getSofZmanShmaMGA72MinutesZmanis", .date { $0.latestShemaMGA72MinutesZmanis() }, "2017-10-17T13:22:40.962834136Z"),
        ("getSofZmanShmaMGA90Minutes", .date { $0.latestShemaMGA90Minutes() }, "2017-10-17T13:10:53.352746510Z"),
        ("getSofZmanShmaMGA90MinutesToFixedLocalChatzos", .date { $0.latestShemaMGA90MinutesToFixedLocalChatzos() }, "2017-10-17T13:18:24.504508319Z"),
        ("getSofZmanShmaMGA90MinutesZmanis", .date { $0.latestShemaMGA90MinutesZmanis() }, "2017-10-17T13:14:22.865356043Z"),
        ("getSofZmanShmaMGA96Minutes", .date { $0.latestShemaMGA96Minutes() }, "2017-10-17T13:07:53.352746510Z"),
        ("getSofZmanShmaMGA96MinutesZmanis", .date { $0.latestShemaMGA96MinutesZmanis() }, "2017-10-17T13:11:36.832863347Z"),
        ("getSofZmanTfila2HoursBeforeChatzos", .date { $0.latestTefila2HoursBeforeChatzos() }, "2017-10-17T14:42:12.781249470Z"),
        ("getSofZmanTfilaAteretTorah", .date { $0.latestTefilahAteretTorah() }, "2017-10-17T14:20:17.482717303Z"),
        ("getSofZmanTfilaBaalHatanya", .date { $0.latestTefilaBaalHatanya() }, "2017-10-17T14:49:54.026921710Z"),
        ("getSofZmanTfilaGRA", .date { $0.latestTefilaGra() }, "2017-10-17T14:51:14.002600466Z"),
        ("getSofZmanTfilaGRASunriseToFixedLocalChatzos", .date { $0.latestTefilaGRASunriseToFixedLocalChatzos() }, "2017-10-17T15:01:02.326Z"), // KosherJava 2.5.0. Master switched this zman from elevation-adjusted to sea-level sunrise/sunset
        ("getSofZmanTfilaMGA120Minutes", .date { $0.latestTefilaMGA120Minutes() }, "2017-10-17T14:11:14.002600466Z"),
        ("getSofZmanTfilaMGA16Point1Degrees", .date { $0.latestTefilaMGA16Point1Degrees() }, "2017-10-17T14:24:24.846859607Z"),
        ("getSofZmanTfilaMGA18Degrees", .date { $0.latestTefilaMGA18Degrees() }, "2017-10-17T14:21:05.584452257Z"),
        ("getSofZmanTfilaMGA19Point8Degrees", .date { $0.latestTefilaMGA19Point8Degrees() }, "2017-10-17T14:17:56.523469494Z"),
        ("getSofZmanTfilaMGA72Minutes", .date { $0.latestTefilaMGA72Minutes() }, "2017-10-17T14:27:14.002600466Z"),
        ("getSofZmanTfilaMGA72MinutesZmanis", .date { $0.latestTefilaMGA72MinutesZmanis() }, "2017-10-17T14:29:05.742658883Z"),
        ("getSofZmanTfilaMGA90Minutes", .date { $0.latestTefilaMGA90Minutes() }, "2017-10-17T14:21:14.002600466Z"),
        ("getSofZmanTfilaMGA90MinutesZmanis", .date { $0.latestTefilaMGA90MinutesZmanis() }, "2017-10-17T14:23:33.677673488Z"),
        ("getSofZmanTfilaMGA96Minutes", .date { $0.latestTefilaMGA96Minutes() }, "2017-10-17T14:19:14.002600466Z"),
        ("getSofZmanTfilaMGA96MinutesZmanis", .date { $0.latestTefilaMGA96MinutesZmanis() }, "2017-10-17T14:21:42.989345025Z"),
        ("getSolarMidnight", .date { $0.getSolarMidnight() }, "2017-10-18T04:42:06.833038724Z"),
        ("getSunTransit", .date { $0.getSunTransit() }, "2017-10-17T16:42:12.781249470Z"),
        ("getSunrise", .date { $0.sunrise }, "2017-10-17T11:09:11.571783718Z"),
        ("getSunset", .date { $0.sunset }, "2017-10-17T22:14:38.994862349Z"),
        ("getTemporalHour", .duration { $0.getTemporalHour() }, "PT55M20.649853956S"),
        ("getTzais120Minutes", .date { $0.tzeis120() }, "2017-10-18T00:13:59.201432122Z"),
        ("getTzais120Zmanis", .date { $0.tzeis120Zmanis() }, "2017-10-18T00:04:40.501140034Z"),
        ("getTzais16Point1Degrees", .date { $0.tzeis16Point1Degrees() }, "2017-10-17T23:34:14.100766559Z"),
        ("getTzais18Degrees", .date { $0.tzeis18Degrees() }, "2017-10-17T23:44:09.707296295Z"),
        ("getTzais19Point8Degrees", .date { $0.tzeis19Point8Degrees() }, "2017-10-17T23:53:34.647710389Z"),
        ("getTzais26Degrees", .date { $0.tzeis26Degrees() }, "2017-10-18T00:26:11.906390602Z"),
        ("getTzais50Minutes", .date { $0.tzeis50() }, "2017-10-17T23:03:59.201432122Z"),
        ("getTzais60Minutes", .date { $0.tzeis60() }, "2017-10-17T23:13:59.201432122Z"),
        ("getTzais72Minutes", .date { $0.tzeis72() }, "2017-10-17T23:25:59.201432122Z"),
        ("getTzais72Zmanis", .date { $0.tzeis72Zmanis() }, "2017-10-17T23:20:23.981256869Z"),
        ("getTzais90Minutes", .date { $0.tzeis90() }, "2017-10-17T23:43:59.201432122Z"),
        ("getTzais90Zmanis", .date { $0.tzeis90Zmanis() }, "2017-10-17T23:37:00.176213056Z"),
        ("getTzais96Minutes", .date { $0.tzeis96() }, "2017-10-17T23:49:59.201432122Z"),
        ("getTzais96Zmanis", .date { $0.tzeis96Zmanis() }, "2017-10-17T23:42:32.241198451Z"),
        ("getTzaisAteretTorah", .date { $0.tzeisAteretTorah() }, "2017-10-17T22:53:59.201432122Z"),
        ("getTzaisBaalHatanya", .date { $0.tzeisBaalHatanya() }, "2017-10-17T22:41:21.435143220Z"),
        ("getTzaisGeonim3Point7Degrees", .date { $0.tzeisGeonim3Point7Degrees() }, "2017-10-17T22:29:12.858867416Z"),
        ("getTzaisGeonim3Point8Degrees", .date { $0.tzeisGeonim3Point8Degrees() }, "2017-10-17T22:29:44.614329739Z"),
        ("getTzaisGeonim4Point8Degrees", .date { $0.tzeisGeonim4Point8Degrees() }, "2017-10-17T22:35:01.761613150Z"),
        ("getTzaisGeonim5Point95Degrees", .date { $0.tzeisGeonim5Point95Degrees() }, "2017-10-17T22:41:05.633594744Z"),
        ("getTzaisGeonim6Point45Degrees", .date { $0.tzeisGeonim6Point45Degrees() }, "2017-10-17T22:43:43.582328133Z"),
        ("getTzaisGeonim7Point083Degrees", .date { $0.tzeisGeonim7Point083Degrees() }, "2017-10-17T22:47:03.446858525Z"),
        ("getTzaisGeonim7Point67Degrees", .date { $0.tzeisGeonim7Point67Degrees() }, "2017-10-17T22:50:08.395485971Z"),
        ("getTzaisGeonim8Point5Degrees", .date { $0.tzeisGeonim8Point5Degrees() }, "2017-10-17T22:54:29.772724455Z"),
        ("getTzaisGeonim9Point3Degrees", .date { $0.tzeisGeonim9Point3Degrees() }, "2017-10-17T22:58:41.421314719Z"),
        ("getTzaisGeonim9Point75Degrees", .date { $0.tzeisGeonim9Point75Degrees() }, "2017-10-17T23:01:02.865384009Z"),

    ]

    private func fixtureCalendar() -> ComplexZmanimCalendar {
        ComplexZmanimCalendar(location: TestLocations.lakewood(), date: TestLocations.date(2017, 10, 17))
    }

    func testAllZmanimMatchGoldenOutput() {
        let calendar = fixtureCalendar()
        for (name, zman, value) in expected {
            switch zman {
            case .date(let zman): assertInstant(zman(calendar), value, name)
            case .duration(let zman): assertDuration(zman(calendar), value!, name)
            }
        }
    }
}
