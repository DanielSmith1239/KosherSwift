//
//  ZmanimCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/20/23.
//

import Foundation

typealias ZmanCalculator = () -> Date?

/// The ZmanimCalendar is a specialized calendar that can calculate sunrise, sunset and Jewish *zmanim* (religious
/// times) for prayers and other Jewish religious duties. This class contains the main functionality of the *Zmanim*
/// library. For a much more extensive list of *zmanim*, use the `ComplexZmanimCalendar` that extends this class. See
/// documentation for the `ComplexZmanimCalendar` and `AstronomicalCalendar` for simple examples on using the API.
/// **Elevation based *zmanim* (even sunrise and sunset) should not be used *lekula* without the guidance of a
/// *posek***. According to Rabbi Dovid Yehudah Bursztyn in his [Zmanim Kehilchasam, 7th
/// edition](https://www.worldcat.org/oclc/1158574217) chapter 2, section 7 (pages 181-182) and section 9 (pages
/// 186-187), no *zmanim* besides sunrise and sunset should use elevation. However, Rabbi Yechiel Avrahom Zilber in the
/// [Birur Halacha Vol. 6](https://hebrewbooks.org/51654) Ch. 58 Pages
/// [34](https://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=42) and
/// [42](https://hebrewbooks.org/pdfpager.aspx?req=51654&pgnum=50) is of the opinion that elevation should be accounted
/// for in *zmanim* calculations. Related to this, Rabbi Yaakov Karp in [Shimush
/// Zekeinim](https://www.worldcat.org/oclc/919472094), Ch. 1, page 17 states that obstructing horizons should be
/// factored into *zmanim* calculations. The setting defaults to false (elevation will not be used for *zmanim*
/// calculations besides sunrise and sunset), unless the setting is changed to true in `shouldUseElevation`. This will
/// impact sunrise and sunset-based *zmanim* such as `sunrise`, `sunset`, `latestShemaGra()`, *alos*-based *zmanim* such
/// as `latestShemaMga()` that are based on a fixed offset of sunrise or sunset and *zmanim* based on a percentage of
/// the day such as `latestShemaMGA90MinutesZmanis()` that are based on sunrise and sunset. Even when set to true it
/// will not impact *zmanim* that are a degree-based offset of sunrise and sunset, such as
/// `latestShemaMGA16Point1Degrees()` or `latestShemaBaalHatanya()` since these *zmanim* are not linked to sunrise or
/// sunset times (the calculations are based on the astronomical definition of sunrise and sunset calculated in a vacuum
/// with the solar radius above the horizon), and are therefore not impacted by the use of elevation. For additional
/// information on the *halachic* impact of elevation on *zmanim* see:
///
/// - [Zmanei Halacha Lema'aseh](https://www.nli.org.il/en/books/NNL_ALEPH002542826/NLI) 4th edition by [Rabbi Yedidya
///   Manat](http://beinenu.com/rabbis/%D7%94%D7%A8%D7%91-%D7%99%D7%93%D7%99%D7%93%D7%99%D7%94-%D7%9E%D7%A0%D7%AA). See
///   section 1, pages 11-12 for a very concise write-up, with details in section 2, pages 37 - 63 and 133 - 151.
///
/// - [Zmanim Kehilchasam](https://www.worldcat.org/oclc/1158574217) 7th edition, by Rabbi Dovid Yehuda Burstein, vol 1,
///   chapter 2, pages 95 - 188.
///
/// - [Hazmanim Bahalacha](https://www.worldcat.org/oclc/36089452) by Rabbi Chaim Banish , perek 7, pages 53 - 63.
///
/// **Note:** It is important to read the technical notes on top of the `AstronomicalCalculator` documentation before
/// using this code.
///
/// I would like to thank [Rabbi Yaakov Shakow](https://www.worldcat.org/search?q=au%3AShakow%2C+Yaakov), the author of
/// Luach Ikvei Hayom who spent a considerable amount of time reviewing, correcting and making suggestions on the
/// documentation in this library.
///
/// **Disclaimer:**
///
/// I did my best to get accurate results, but please double-check before relying on these *zmanim* for *halacha
/// lema'aseh*.
public class ZmanimCalendar: AstronomicalCalendar {
    let shouldUseElevation: Bool

    /// A method to get the offset in minutes before sea level sunset which is used in calculating candle lighting time.
    /// The default time used is 18 minutes before sea level sunset. Some calendars use 15 minutes, while the custom in
    /// Jerusalem is to use a 40 minute offset. Please check the local custom for candle lighting time.
    ///
    /// - Returns: Returns the currently set candle lighting offset in minutes.
    /// - SeeAlso: `candleLighting()`, `candleLightingOffset`
    public let candleLightingOffset: Double
    
    public init(location: GeoLocation, date: Date, astronomicalCalculator: AstronomicalCalculator = NOAACalculator(), shouldUseElevation: Bool = false, candleLightingOffset: Double = 18) {
        self.shouldUseElevation = shouldUseElevation
        self.candleLightingOffset = candleLightingOffset
        super.init(location: location, date: date, astronomicalCalculator: astronomicalCalculator)
    }
    
    var elevationAdjustedSunrise: Date? { shouldUseElevation ? sunrise : seaLevelSunrise }
    var elevationAdjustedSunset: Date? { shouldUseElevation ? sunset : seaLevelSunset }
    
    // Zmanim
    /// A method that returns *tzais* (nightfall) when the sun is 8.5° below the geometric horizon (90°) after sunset, a
    /// time that Rabbi Meir Posen in his the *[Ohr Meir](https://www.worldcat.org/oclc/29283612)* calculated that 3
    /// small stars are visible, which is later than the required 3 medium stars. See the `Zenith.z8_5` constant.
    ///
    /// - Returns: The `Date` of nightfall. If the calculation can't be computed such as northern and southern locations
    ///   even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach low
    ///   enough below the horizon for this calculation, nil will be returned. See detailed explanation on top
    ///   of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z8_5`
    public func tzeis() -> Date? { getSunsetOffsetByDegrees(offsetZenith: Zenith.z8_5) }

    /// Returns *alos* (dawn) based on the time when the sun is 16.1° below the eastern geometric horizon before
    /// sunrise. This is based on the calculation that the time between dawn and sunrise (and sunset to nightfall) is 72
    /// minutes, the time that is takes to walk 4 *mil* at 18 minutes a mil
    /// (*[Rambam](https://en.wikipedia.org/wiki/Maimonides)* and others). The sun's position at 72 minutes before
    /// sunrise in Jerusalem on the [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) is 16.1° below
    /// `Zenith.geometric`.
    ///
    /// - Returns: The `Date` of dawn. If the calculation can't be computed such as northern and southern locations even
    ///   south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach low enough
    ///   below the horizon for this calculation, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z16_1`, `alos16Point1Degrees()`
    public func alosHashachar() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_1) }

    /// Method to return *alos* (dawn) calculated using 72 minutes before sunrise or sea level sunrise (depending on the
    /// `shouldUseElevation` setting). This time is based on the time to walk the distance of 4 *Mil* at 18 minutes a
    /// *Mil*. The 72 minute time (but not the concept of fixed minutes) is based on the opinion that the time of the
    /// *Neshef* (twilight between dawn and sunrise) does not vary by the time of year or location but depends on the
    /// time it takes to walk the distance of 4 *Mil*.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func alos72() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -72 * ZmanimCalendar.minuteMillis) }

	/// This method returns *chatzos* (midday) following most opinions that *chatzos* is the midpoint between sea level
	/// sunrise and sea level sunset. A day starting at *alos* and ending at *tzais* using the same time or degree
	/// offset will also return the same time. The returned value is identical to `getSunTransit()`. In reality due to
	/// lengthening or shortening of day, this is not necessarily the exact midpoint of the day, but it is very close.
	///
	/// - Returns: the `Date` of chatzos. If the calculation can't be computed such as in the Arctic Circle where there
	///   is at least one day where the sun does not rise, and one where it does not set, nil will be returned.
	///   See detailed explanation on top of the `AstronomicalCalendar` documentation.
	/// - SeeAlso: `getSunTransit()`
	public func chatzos() -> Date? { return getSunTransit() }

    /// This method returns the latest *zman krias shema* (time to recite shema in the morning) that is 3 * *shaos
    /// zmaniyos* (solar hours) after sunrise or sea level sunrise (depending on the `shouldUseElevation` setting),
    /// according to the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon). The day is calculated from sea level sunrise
    /// to sea level sunset or sunrise to sunset (depending on the `shouldUseElevation` setting).
    ///
    /// - Returns: the `Date` of the latest *zman shema* according to the GRA. If the calculation can't be computed such
    ///   as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
    ///   where it does not set, nil will be returned. See the detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `calculateLatestZmanShema()`, `shaahZmanisGra()`, `shouldUseElevation`, `latestShemaBaalHatanya()`
    public func latestShemaGra() -> Date? { calculateLatestZmanShema(elevationAdjustedSunrise, elevationAdjustedSunset) }

    /// This method returns the latest *zman krias shema* (time to recite shema in the morning) that is 3 * *shaos
    /// zmaniyos* (solar hours) after `alos72()`, according to the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern). The day is calculated from 72 minutes before sea level
    /// sunrise to 72 minutes after sea level sunset or from 72 minutes before sunrise to sunset (depending on the
    /// `shouldUseElevation` setting).
    ///
    /// - Returns: the `Date` of the latest *zman shema*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateLatestZmanShema()`, `shaahZmanis72Minutes()`, `alos72()`, `latestShemaMGA72Minutes()`
    public func latestShemaMga() -> Date? { calculateLatestZmanShema(alos72(), tzeis72()) }

    /// This method returns the *tzais* (nightfall) based on the opinion of *Rabbeinu Tam* that *tzais hakochavim* is
    /// calculated as 72 minutes, the time it takes to walk 4 *Mil* at 18 minutes a *Mil*. According to the [Machtzis
    /// Hashekel](https://en.wikipedia.org/wiki/Samuel_Loew) in Orach Chaim 235:3, the [Pri
    /// Megadim](https://en.wikipedia.org/wiki/Joseph_ben_Meir_Teomim) in Orach Chaim 261:2 (see the Biur Halacha) and
    /// others (see Hazmanim Bahalacha 17:3 and 17:5) the 72 minutes are standard clock minutes any time of the year in
    /// any location. Depending on the `shouldUseElevation` setting) a 72 minute offset from either sunset or sea level
    /// sunset is used.
    ///
    /// - Returns: the `Date` representing 72 minutes after sunset. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `tzeis16Point1Degrees()`
    public func tzeis72() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 72 * AstronomicalCalendar.minuteMillis) }
    
    /// A method to return candle lighting time, calculated as `candleLightingOffset` minutes before sea level sunset.
    /// This will return the time for any day of the week, since it can be used to calculate candle lighting time for
    /// *Yom Tov* (mid-week holidays) as well. Elevation adjustments are intentionally not performed by this method, but
    /// you can calculate it by passing the elevation adjusted sunset to `getTimeOffset()`.
    ///
    /// - Returns: candle lighting time. If the calculation can't be computed such as in the Arctic Circle where there
    ///   is at least one day a year where the sun does not rise, and one where it does not set, nil will be
    ///   returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `seaLevelSunset`, `candleLightingOffset`
    public func candleLighting() -> Date? {
        let todayCal = JewishCalendar(date: deviceDate)
        let yesterdayCal = JewishCalendar(date: deviceDate.withAdded(days: -1)!)
        if (todayCal.dow == .saturday && todayCal.isErevYomTov)
            || (todayCal.isRoshHashana && yesterdayCal.isErevYomTov)
            || (todayCal.isChanukah && todayCal.dow != .friday) {
            let offsetDate = getSunsetOffsetByDegrees(offsetZenith: .z7_083)
            return AstronomicalCalendar.getTimeOffset(time: offsetDate, offset: -13.5 * AstronomicalCalendar.minuteMillis)
        } else if todayCal.dow == .friday || todayCal.isErevYomTov {
            return AstronomicalCalendar.getTimeOffset(time: seaLevelSunset, offset: -candleLightingOffset * AstronomicalCalendar.minuteMillis)
        }
        
        return nil
    }
    
    /// KosherJava getCandleLighting(): sea-level sunset minus the candle lighting offset, on any day. candleLighting()
    /// only returns a time on days candles are lit.
    public func getCandleLighting() -> Date? {
        AstronomicalCalendar.getTimeOffset(time: seaLevelSunset, offset: -candleLightingOffset * AstronomicalCalendar.minuteMillis)
    }

    /// KosherJava master getChatzosHayomAsHalfDay(): halfway between sea-level sunrise and sunset.
    public func chatzosAsHalfDay() -> Date? {
        guard let sunrise = seaLevelSunrise, let sunset = seaLevelSunset else { return nil }
        return sunrise.addingTimeInterval(sunset.timeIntervalSince(sunrise) / 2)
    }

    /// This method returns the latest *zman tfila* (time to recite shema in the morning) that is 4 * *shaos
    /// zmaniyos*(solar hours) after sunrise or sea level sunrise (depending on the `shouldUseElevation` setting),
    /// according to the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon). The day is calculated from sea level sunrise
    /// to sea level sunset or sunrise to sunset (depending on the `shouldUseElevation` setting).
    ///
    /// - Returns: the `Date` of the latest *zman tfilah*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateLatestTefila()`, `shaahZmanisGra()`, `latestTefilaBaalHatanya()`
    public func latestTefilaGra() -> Date? { calculateLatestTefila(elevationAdjustedSunrise, elevationAdjustedSunset) }

    /// This method returns the latest *zman tfila* (time to recite shema in the morning) that is 4 * *shaos zmaniyos*
    /// (solar hours) after `alos72()`, according to the *[Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)*. The day is calculated from 72 minutes before sea level
    /// sunrise to 72 minutes after sea level sunset or from 72 minutes before sunrise to sunset (depending on the
    /// `shouldUseElevation` setting).
    ///
    /// - Returns: the `Date` of the latest *zman tfila*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set), nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateLatestTefila()`, `shaahZmanisMga()`, `alos72()`
    public func latestTefilaMga() -> Date? { calculateLatestTefila(alos72(), tzeis72()) }

    /// A method that returns a *shaah zmanis* (`getTemporalHour()`) according to the opinion of the
    /// *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*. This calculation divides the day based on the opinion of the
    /// *GRA* that the day runs from from sea level sunrise to sea level sunset or sunrise to sunset (depending on the
    /// `shouldUseElevation` setting). The day is split into 12 equal parts with each one being a *shaah zmanis*. This
    /// method is similar to `getTemporalHour()`, but can account for elevation.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis* calculated from sunrise to sunset. If the calculation
    ///   can't be computed such as in the Arctic Circle where there is at least one day a year where the sun
    ///   does not rise, and one where it does not set, `MIN_VALUE` will be returned. See detailed explanation
    ///   on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `getTemporalHour()`, `seaLevelSunrise`, `seaLevelSunset`, `shaahZmanisBaalHatanya()`
    public func shaahZmanisGra() -> Double? { getTemporalHour(dayStart: elevationAdjustedSunrise, dayEnd: elevationAdjustedSunset) }

    /// A method that returns a *shaah zmanis* (temporal hour) according to the opinion of the *[Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern)* based on a 72 minutes *alos* and *tzais*. This
    /// calculation divides the day that runs from dawn to dusk (for *sof zman krias shema* and *tfila*). Dawn for this
    /// calculation is 72 minutes before sunrise or sea level sunrise (depending on the `shouldUseElevation` elevation
    /// setting) and dusk is 72 minutes after sunset or sea level sunset (depending on the `shouldUseElevation`
    /// elevation setting). This day is split into 12 equal parts with each part being a *shaah zmanis*. Alternate
    /// methods of calculating a *shaah zmanis* according to the Magen Avraham (MGA) are available in the subclass
    /// `ComplexZmanimCalendar`.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    public func shaahZmanisMga() -> Double? { getTemporalHour(dayStart: alos72(), dayEnd: tzeis72()) }
    
    // Helpers
    /// A generic method for calculating the latest *zman tfilah* (time to recite the morning prayers) that is 4 *
    /// *shaos zmaniyos* (temporal hours) after the start of the day, calculated using the start and end of the day
    /// passed to this method. The time from the start of day to the end of day are divided into 12 *shaos zmaniyos*
    /// (temporal hours), and *sof zman tfila* is calculated as 4 of those *shaos zmaniyos* after the beginning of the
    /// day. As an example, passing sunrise and sunset or sea level sunrise and sea level sunset (depending on the
    /// `shouldUseElevation` elevation setting) to this method will return *zman tfilah* according to the opinion of the
    /// *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*.
    ///
    /// - Parameters:
    ///   - dayStart: the start of day for calculating *zman tfilah*. This can be sunrise or any *alos* passed to this
    ///     method.
    ///   - dayEnd: the end of day for calculating *zman tfilah*. This can be sunset or any *tzais* passed to this
    ///     method.
    /// - Returns: the `Date` of the latest *zman tfilah* based on the start and end of day times passed to this method.
    ///   If the calculation can't be computed such as in the Arctic Circle where there is at least one day a
    ///   year where the sun does not rise, and one where it does not set, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    public func calculateLatestTefila(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart, let dayEnd, let shaahZmanis = getTemporalHour(dayStart: dayStart, dayEnd: dayEnd) else { return nil }
        return AstronomicalCalendar.getTimeOffset(time: dayStart, offset: shaahZmanis * 4)
    }
    
    /// A generic method for calculating the latest *zman krias shema* (time to recite shema in the morning) that is 3 *
    /// *shaos zmaniyos* (temporal hours) after the start of the day, calculated using the start and end of the day
    /// passed to this method. The time from the start of day to the end of day are divided into 12 *shaos zmaniyos*
    /// (temporal hours), and the latest *zman krias shema* is calculated as 3 of those *shaos zmaniyos* after the
    /// beginning of the day. As an example, passing sunrise and sunset or sea level sunrise and sea level sunset
    /// (depending on the `shouldUseElevation` elevation setting) to this method will return *sof zman krias shema*
    /// according to the opinion of the *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*.
    ///
    /// - Parameters:
    ///   - dayStart: the start of day for calculating *zman krias shema*. This can be sunrise or any *alos* passed to
    ///     this method.
    ///   - dayEnd: the end of day for calculating *zman krias shema*. This can be sunset or any *tzais* passed to this
    ///     method.
    /// - Returns: the `Date` of the latest *zman shema* based on the start and end of day times passed to this method.
    ///   If the calculation can't be computed such as in the Arctic Circle where there is at least one day a
    ///   year where the sun does not rise, and one where it does not set, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    public func calculateLatestZmanShema(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else {
            return nil
        }
        return shaahZmanisBasedZman(dayStart, dayEnd, 3)
    }
    
    // A nil start or end of day (e.g. an alos that doesn't occur at high latitudes) returns nil, as in KosherJava.
    // Call the overloads without arguments for the GRA (elevation-adjusted sunrise to sunset) zman.
    /// A generic method for calculating *mincha ketana*, (the preferred time to recite the mincha prayers in the
    /// opinion of the *[Rambam](https://en.wikipedia.org/wiki/Maimonides)* and others) that is 9.5 * *shaos zmaniyos*
    /// (temporal hours) after the start of the day, calculated using the start and end of the day passed to this
    /// method. The time from the start of day to the end of day are divided into 12 *shaos zmaniyos* (temporal hours),
    /// and *mincha ketana* is calculated as 9.5 of those *shaos zmaniyos* after the beginning of the day. As an
    /// example, passing sunrise and sunset or sea level sunrise and sea level sunset (depending on the
    /// `shouldUseElevation` elevation setting) to this method will return *mincha ketana* according to the opinion of
    /// the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon).
    ///
    /// - Parameters:
    ///   - dayStart: the start of day for calculating *Mincha ketana*. This can be sunrise or any *alos* passed to this
    ///     method.
    ///   - dayEnd: the end of day for calculating *Mincha ketana*. This can be sunset or any *tzais* passed to this
    ///     method.
    /// - Returns: the `Date` of the time of *Mincha ketana* based on the start and end of day times passed to this
    ///   method. If the calculation can't be computed such as in the Arctic Circle where there is at least one
    ///   day a year where the sun does not rise, and one where it does not set, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func calculateMinchaKetana(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else { return nil }
        return shaahZmanisBasedZman(dayStart, dayEnd, 9.5)
    }
    
    /// This method returns *mincha ketana*,the preferred earliest time to pray *mincha* in the opinion of the
    /// *[Rambam](https://en.wikipedia.org/wiki/Maimonides)* and others, that is 9.5 * *shaos zmaniyos* (solar hours)
    /// after sunrise or sea level sunrise (depending on the `shouldUseElevation` setting), according to the
    /// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon). For more information on this see the documentation on *mincha
    /// gedola*. The day is calculated from sea level sunrise to sea level sunset or sunrise to sunset (depending on the
    /// `shouldUseElevation` setting.
    ///
    /// - Returns: the `Date` of the time of mincha ketana. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaKetana()`, `shaahZmanisGra()`, `calculateMinchaGedolah()`,
    ///   `minchaKetanaBaalHatanya()`
    public func calculateMinchaKetana() -> Date? { calculateMinchaKetana(elevationAdjustedSunrise, elevationAdjustedSunset) }
    
    /// A generic method for calculating *plag hamincha* (the earliest time that Shabbos can be started) that is 10.75
    /// hours after the start of the day, (or 1.25 hours before the end of the day) based on the start and end of the
    /// day passed to the method. The time from the start of day to the end of day are divided into 12 *shaos zmaniyos*
    /// (temporal hours), and *plag hamincha* is calculated as 10.75 of those *shaos zmaniyos* after the beginning of
    /// the day. As an example, passing sunrise and sunset or sea level sunrise and sea level sunset (depending on the
    /// `shouldUseElevation` elevation setting) to this method will return *plag mincha* according to the opinion of the
    /// *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*.
    ///
    /// - Parameters:
    ///   - dayStart: the start of day for calculating plag. This can be sunrise or any *alos* passed to this method.
    ///   - dayEnd: the end of day for calculating plag. This can be sunset or any *tzais* passed to this method.
    /// - Returns: the `Date` of the time of *plag hamincha* based on the start and end of day times passed to this
    ///   method. If the calculation can't be computed such as in the Arctic Circle where there is at least one
    ///   day a year where the sun does not rise, and one where it does not set, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func calculatePlagHamincha(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else { return nil }
        return shaahZmanisBasedZman(dayStart, dayEnd, 10.75)
    }
    
    /// This method returns *plag hamincha*, that is 10.75 * *shaos zmaniyos* (solar hours) after sunrise or sea level
    /// sunrise (depending on the `shouldUseElevation` setting), according to the
    /// *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*. Plag hamincha is the earliest time that *Shabbos* can be
    /// started. The day is calculated from sea level sunrise to sea level sunset or sunrise to sunset (depending on the
    /// `shouldUseElevation`
    ///
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculatePlagHamincha()`, `plagHaminchaBaalHatanya()`
    public func calculatePlagHamincha() -> Date? { calculatePlagHamincha(elevationAdjustedSunrise, elevationAdjustedSunset) }
    
    /// A generic method for calculating the latest *mincha gedola* (the earliest time to recite the mincha prayers)
    /// that is 6.5 * *shaos zmaniyos* (temporal hours) after the start of the day, calculated using the start and end
    /// of the day passed to this method. The time from the start of day to the end of day are divided into 12 *shaos
    /// zmaniyos* (temporal hours), and *mincha gedola* is calculated as 6.5 of those *shaos zmaniyos* after the
    /// beginning of the day. As an example, passing sunrise and sunset or sea level sunrise and sea level sunset
    /// (depending on the `shouldUseElevation` elevation setting) to this method will return *mincha gedola* according
    /// to the opinion of the *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*.
    ///
    /// - Parameters:
    ///   - dayStart: the start of day for calculating *Mincha gedola*. This can be sunrise or any *alos* passed to this
    ///     method.
    ///   - dayEnd: the end of day for calculating *Mincha gedola*. This can be sunset or any *tzais* passed to this
    ///     method.
    /// - Returns: the `Date` of the time of *Mincha gedola* based on the start and end of day times passed to this
    ///   method. If the calculation can't be computed such as in the Arctic Circle where there is at least one
    ///   day a year where the sun does not rise, and one where it does not set, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func calculateMinchaGedolah(_ dayStart: Date?, _ dayEnd: Date?) -> Date? {
        guard let dayStart = dayStart, let dayEnd = dayEnd else { return nil }
        return shaahZmanisBasedZman(dayStart, dayEnd, 6.5)
    }
    
    /// This method returns the latest *mincha gedola*,the earliest time one can pray *mincha* that is 6.5 * *shaos
    /// zmaniyos* (solar hours) after sunrise or sea level sunrise (depending on the `shouldUseElevation` setting),
    /// according to the *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*. *Mincha gedola* is the earliest time one can
    /// pray *mincha*. The Ramba"m is of the opinion that it is better to delay *mincha* until *mincha ketana* while the
    /// *Ra"sh, Tur, GRA* and others are of the opinion that *mincha* can be prayed *lechatchila* starting at *mincha
    /// gedola*. The day is calculated from sea level sunrise to sea level sunset or sunrise to sunset (depending on the
    /// `shouldUseElevation` setting).
    ///
    /// - Returns: the `Date` of the time of mincha gedola. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaGedolah()`, `shaahZmanisGra()`, `calculateMinchaKetana()`,
    ///   `minchaGedolaBaalHatanya()`
    public func calculateMinchaGedolah() -> Date? { calculateMinchaGedolah(elevationAdjustedSunrise, elevationAdjustedSunset) }
    
    /// A generic utility method for calculating any *shaah zmanis* (temporal hour) based *zman* with the day defined as
    /// the start and end of day (or night) and the number of *shaahos zmaniyos* passed to the method. This simplifies
    /// the code in other methods such as `calculatePlagHamincha()` and cuts down on code replication. As an example,
    /// passing sunrise and sunset or sea level sunrise and sea level sunset (depending on the `shouldUseElevation`
    /// elevation setting) and 10.75 hours to this method will return *plag mincha* according to the opinion of the
    /// *[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)*.
    ///
    /// - Parameters:
    ///   - startOfDay: the start of day for calculating the *zman*. This can be sunrise or any *alos* passed to this
    ///     method.
    ///   - endOfDay: the end of day for calculating the *zman*. This can be sunset or any *tzais* passed to this
    ///     method.
    ///   - hours: the number of *shaahos zmaniyos* (temporal hours) to offset from the start of day
    /// - Returns: the `Date` of the time of *zman* with the *shaahos zmaniyos* (temporal hours) in the day offset from
    ///   the start of day passed to this method. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    public func shaahZmanisBasedZman(_ startOfDay: Date, _ endOfDay: Date, _ hours: Double) -> Date? {
        guard let shaahZmanis = getTemporalHour(dayStart: startOfDay, dayEnd: endOfDay) else {
            return nil
        }
        return AstronomicalCalendar.getTimeOffset(time: startOfDay, offset: shaahZmanis * hours)
    }
    
    /// A utility method to calculate *zmanim* based on [Rav Moshe
    /// Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) and others as calculated in
    /// [MTJ](https://en.wikipedia.org/wiki/Mesivtha_Tifereth_Jerusalem), [Yeshiva of Staten
    /// Island](https://en.wikipedia.org/wiki/Mesivtha_Tifereth_Jerusalem), and Camp Yeshiva of Staten Island and other
    /// calendars. The day is split in two, from *alos* / sunrise to *chatzos*, and the second half of the day, from
    /// *chatzos* to sunset / *tzais*. Morning based times are calculated. based on the first 6 hours of the day, and
    /// afternoon times based on the second half of the day. As an example, passing 0.5, a start of *chatzos* and an end
    /// of day as sunset will return the time of *mincha gedola* GRA as half an hour *zmanis* based on the second half
    /// of the day. Some *zmanim* calculations can be based on subtracting *shaos zmaniyos* from the end of the day, and
    /// that is supported by passing a negative hour to this method.
    ///
    /// - Parameters:
    ///   - startOfHalfDay: The start of the half day. This would be *alos* or sunrise for morning based times such as
    ///     *sof zman krias shema* and *chatzos* for afternoon based times such as *mincha gedola*.
    ///   - endOfHalfDay: The end of the half day. This would be *chatzos* for morning based times such as *sof zman
    ///     krias shema* and sunset or *tzais* for afternoon based times such as *mincha gedola*.
    ///   - hours: The number of *shaos zmaniyos* (hours) to offset the beginning of the first or second half of the
    ///     day. For example, 3 for *sof zman Shma*, 0.5 for *mincha gedola* (half an hour after *chatzos*) and
    ///     4.75 for *plag hamincha*. If the number of hours is negative, it will subtract the number of *shaos
    ///     zmaniyos* from the end of the day.
    /// - Returns: the `Instant` of *zman* based on calculation of the first or second half of the day. If the
    ///   calculation can't be computed such as in the Arctic Circle where there is at least one day a year
    ///   where the sun does not rise, and one where it does not set, a `nil` will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    public func getHalfDayBasedZman(startOfHalfDay:Date?, endOfHalfDay:Date?, hours:Double) -> Date? {
        if (startOfHalfDay == nil || endOfHalfDay == nil) {
            return nil;
        }
        
        let shaahZmanis = getHalfDayBasedShaahZmanis(startOfHalfDay: startOfHalfDay, endOfHalfDay: endOfHalfDay)
        if (shaahZmanis == Int64.min) { //defensive, should not be needed
            return nil;
        }
        
        if hours >= 0 { // forward from start a day
            return ZmanimCalendar.getTimeOffset(time: startOfHalfDay, offset: Double(shaahZmanis) * hours)
        } else { // subtract from end of day
            return ZmanimCalendar.getTimeOffset(time: endOfHalfDay, offset: Double(shaahZmanis) * hours)
        }
    }
    
    /// Length of a half-day based shaah zmanis in milliseconds, like KosherJava.
    public func getHalfDayBasedShaahZmanis(startOfHalfDay:Date?, endOfHalfDay:Date?) -> Int64 {
        if (startOfHalfDay == nil || endOfHalfDay == nil) {
            return Int64.min;
        }
        return Int64((endOfHalfDay!.timeIntervalSince1970 - startOfHalfDay!.timeIntervalSince1970) * 1000) / 6
    }
}
