//
//  ComplexZmanimCalendar.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/21/23.
//

import Foundation

/// This class extends ZmanimCalendar and provides many more *zmanim* than available in the ZmanimCalendar. The basis
/// for most *zmanim* in this class are from the *sefer* **[Yisroel Vehazmanim](https://hebrewbooks.org/9765)** by
/// **[Rabbi Yisrael Dovid Harfenes](https://en.wikipedia.org/wiki/Yisroel_Dovid_Harfenes)**. As an example of the
/// number of different *zmanim* made available by this class, there are methods to return 18 different calculations for
/// *alos* (dawn), 18 for *plag hamincha* and 29 for *tzais* available in this API. The real power of this API is the
/// ease in calculating *zmanim* that are not part of the library. The methods for *zmanim* calculations not present in
/// this class or it's superclass `ZmanimCalendar` are contained in the `AstronomicalCalendar`, the base class of the
/// calendars in our API since they are generic methods for calculating time based on degrees or time before or after
/// sunrise and sunset and are of interest for calculation beyond *zmanim* calculations. Here are some examples.
///
/// First create the calendar for the location and date you would like to calculate:
///
/// ```swift
/// let location = GeoLocation(lat: 40.0828, lng: -74.2094, // Lakewood, NJ
///                            timezone: TimeZone(identifier: "America/New_York")!,
///                            elevation: 20, // optional elevation correction in meters
///                            name: "Lakewood, NJ")
/// var calendar = Calendar(identifier: .gregorian)
/// calendar.timeZone = location.timezone
/// let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 8))!
/// let czc = ComplexZmanimCalendar(location: location, date: date)
/// ```
///
/// To get *alos* calculated as 14° below the horizon (as calculated in the calendars published in Montreal), add
/// `Zenith.geometric` (90) to the 14° offset to get the desired time:
///
/// ```swift
/// let alos14 = czc.getSunriseOffsetByDegrees(offset: Zenith.geometric.rawValue + 14)
/// ```
///
/// To get *mincha gedola* calculated based on the [Magen Avraham
/// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) using a *shaah zmanis* based on the day starting 16.1° below
/// the horizon (and ending 16.1° after sunset) the following calculation can be used:
///
/// ```swift
/// let minchaGedola = AstronomicalCalendar.getTimeOffset(time: czc.alos16Point1Degrees(),
///                                                       offset: czc.shaahZmanis16Point1Degrees().map { $0 * 6.5 })
/// ```
///
/// or even simpler using the included convenience methods
///
/// ```swift
/// let minchaGedola = czc.calculateMinchaGedolah(czc.alos16Point1Degrees(), czc.tzeis16Point1Degrees())
/// ```
///
/// A little more complex example would be calculating *zmanim* that rely on a *shaah zmanis* that is not present in
/// this library. While a drop more complex, it is still rather easy. An example would be to calculate the [Trumas
/// Hadeshen](https://en.wikipedia.org/wiki/Israel_Isserlein)'s *alos* to *tzais* based *plag hamincha* as calculated in
/// the Machzikei Hadass calendar in Manchester, England. A number of this calendar's *zmanim* are calculated based on a
/// day starting at *alos* of 12° before sunrise and ending at *tzais* of 7.083° after sunset. Be aware that since the
/// *alos* and *tzais* do not use identical degree-based offsets, this leads to *chatzos* being at a time other than the
/// solar transit (solar midday). To calculate this *zman*, use the following steps. Note that *plag hamincha* is 10.75
/// hours after the start of the day, and the following steps are all that it takes.
///
/// ```swift
/// let plag = czc.calculatePlagHamincha(czc.getSunriseOffsetByDegrees(offset: Zenith.geometric.rawValue + 12),
///                                      czc.getSunsetOffsetByDegrees(offsetZenith: .z7_083))
/// ```
///
/// Something a drop more challenging, but still simple, would be calculating a *zman* using the same "complex" offset
/// day used in the above mentioned Manchester calendar, but for a *shaos zmaniyos* based *zman* not supported by this
/// library, such as calculating the point that one should be *makpid* not to eat on *erev Shabbos* or *erev Yom Tov*.
/// This is 9 *shaos zmaniyos* into the day.
///
/// - Calculate the *shaah zmanis* in milliseconds for this day
///
/// - Add 9 of these *shaos zmaniyos* to *alos* starting at 12°
///
/// ```swift
/// let alos12 = czc.getSunriseOffsetByDegrees(offset: Zenith.geometric.rawValue + 12)
/// let shaahZmanis = czc.getTemporalHour(dayStart: alos12, dayEnd: czc.getSunsetOffsetByDegrees(offsetZenith: .z7_083))
/// let sofZmanAchila = AstronomicalCalendar.getTimeOffset(time: alos12, offset: shaahZmanis.map { $0 * 9 })
/// ```
///
/// Calculating this *sof zman achila* according to the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) is simplicity
/// itself.
///
/// ```swift
/// let sofZmanAchila = AstronomicalCalendar.getTimeOffset(time: czc.sunrise, offset: czc.shaahZmanisGra().map { $0 * 9 })
/// ```
///
/// **Documentation from the `ZmanimCalendar` parent class**
public class ComplexZmanimCalendar: ZmanimCalendar {
    private static let ateretTorahSunsetOffset = 40.0
    
    public func copy(withDate date: Date) -> ComplexZmanimCalendar {
        ComplexZmanimCalendar(location: location, date: date, astronomicalCalculator: astronomicalCalculator, shouldUseElevation: shouldUseElevation, candleLightingOffset: candleLightingOffset)
    }
    
    // TODO
    /// Method to return a *shaah zmanis* (temporal hour) calculated using a 19.8° dip. This calculation divides the day
    /// based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day
    /// runs from dawn to dusk. Dawn for this calculation is when the sun is 19.8° below the eastern geometric horizon
    /// before sunrise. Dusk for this is when the sun is 19.8° below the western geometric horizon after sunset. This
    /// day is split into 12 equal parts with each part being a *shaah zmanis*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, a `MIN_VALUE` will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func shaahZmanis19Point8Degrees() -> Double? { getTemporalHour(dayStart: alos19Point8Degrees(), dayEnd: tzeis19Point8Degrees()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a 18° dip. This calculation divides the day
    /// based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day
    /// runs from dawn to dusk. Dawn for this calculation is when the sun is 18° below the eastern geometric horizon
    /// before sunrise. Dusk for this is when the sun is 18° below the western geometric horizon after sunset. This day
    /// is split into 12 equal parts with each part being a *shaah zmanis*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, a `MIN_VALUE` will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func shaahZmanis18Degrees() -> Double? { getTemporalHour(dayStart: alos18Degrees(), dayEnd: tzeis18Degrees()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a dip of 26°. This calculation divides the
    /// day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the
    /// day runs from dawn to dusk. Dawn for this calculation is when the sun is 26° below the eastern geometric horizon
    /// before sunrise. Dusk for this is when the sun is 26° below the western geometric horizon after sunset. This day
    /// is split into 12 equal parts with each part being a *shaah zmanis*. Since *zmanim* that use this method are
    /// extremely late or early and at a point when the sky is a long time past the 18° point where the darkest point is
    /// reached, *zmanim* that use this should only be used *lechumra*, such as delaying the start of nighttime
    /// *mitzvos*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, a `MIN_VALUE` will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis120Minutes()`
    public func shaahZmanis26Degrees() -> Double? { getTemporalHour(dayStart: alos26Degrees(), dayEnd: tzeis26Degrees()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a dip of 16.1°. This calculation divides the
    /// day based on the opinion that the day runs from dawn to dusk. Dawn for this calculation is when the sun is 16.1°
    /// below the eastern geometric horizon before sunrise and dusk is when the sun is 16.1° below the western geometric
    /// horizon after sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, a `MIN_VALUE` will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `tzeis16Point1Degrees()`, `latestShemaMGA16Point1Degrees()`,
    ///   `latestTefilaMGA16Point1Degrees()`, `minchaGedola16Point1Degrees()`, `minchaKetana16Point1Degrees()`,
    ///   `plagHamincha16Point1Degrees()`
    public func shaahZmanis16Point1Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeis16Point1Degrees()) }

    /// Method to return a *shaah zmanis* (solar hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern). This calculation divides the day based on the opinion
    /// of the MGA that the day runs from dawn to dusk. Dawn for this calculation is 60 minutes before sunrise and dusk
    /// is 60 minutes after sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*.
    /// Alternate methods of calculating a *shaah zmanis* are available in the subclass `ComplexZmanimCalendar`.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos60()`, `tzeis60()`, `plagHamincha60Minutes()`
    public func shaahZmanis60Minutes() -> Double? { getTemporalHour(dayStart: alos60(), dayEnd: tzeis60()) }

    /// Method to return a *shaah zmanis* (solar hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern). This calculation divides the day based on the opinion
    /// of the MGA that the day runs from dawn to dusk. Dawn for this calculation is 72 minutes before sunrise and dusk
    /// is 72 minutes after sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*.
    /// Alternate methods of calculating a *shaah zmanis* are available in the subclass `ComplexZmanimCalendar`.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    public func shaahZmanis72Minutes() -> Double? { shaahZmanisMga() }

    /// Method to return a *shaah zmanis* (temporal hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes *zmaniyos* before
    /// sunrise. This calculation divides the day based on the opinion of the MGA that the day runs from dawn to dusk.
    /// Dawn for this calculation is 72 minutes *zmaniyos* before sunrise and dusk is 72 minutes *zmaniyos* after
    /// sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*. This is identical to 1/10th
    /// of the day from sunrise to sunset.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeis72Zmanis()`
    public func shaahZmanis72MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos72Zmanis(), dayEnd: tzeis72Zmanis()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a dip of 90 minutes. This calculation divides
    /// the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that
    /// the day runs from dawn to dusk. Dawn for this calculation is 90 minutes before sunrise and dusk is 90 minutes
    /// after sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    public func shaahZmanis90Minutes() -> Double? { getTemporalHour(dayStart: alos90(), dayEnd: tzeis90()) }

    /// Method to return a *shaah zmanis* (temporal hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 90 minutes *zmaniyos* before
    /// sunrise. This calculation divides the day based on the opinion of the MGA that the day runs from dawn to dusk.
    /// Dawn for this calculation is 90 minutes *zmaniyos* before sunrise and dusk is 90 minutes *zmaniyos* after
    /// sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*. This is 1/8th of the day
    /// from sunrise to sunset.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos90Zmanis()`, `tzeis90Zmanis()`
    public func shaahZmanis90MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos90Zmanis(), dayEnd: tzeis90Zmanis()) }

    /// Method to return a *shaah zmanis* (temporal hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 96 minutes *zmaniyos* before
    /// sunrise. This calculation divides the day based on the opinion of the MGA that the day runs from dawn to dusk.
    /// Dawn for this calculation is 96 minutes *zmaniyos* before sunrise and dusk is 96 minutes *zmaniyos* after
    /// sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*. This is identical to
    /// 1/7.5th of the day from sunrise to sunset.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos96Zmanis()`, `tzeis96Zmanis()`
    public func shaahZmanis96MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos96Zmanis(), dayEnd: tzeis96Zmanis()) }

    /// Method to return a *shaah zmanis* (temporal hour) according to the opinion of the *Chacham* Yosef Harari-Raful
    /// of Yeshivat Ateret Torah calculated with *alos* being 1/10th of sunrise to sunset day, or 72 minutes *zmaniyos*
    /// of such a day before sunrise, and *tzais* is usually calculated as 40 minutes (configurable to any offset via
    /// KosherJava's `setAteretTorahSunsetOffset()`) after sunset. This day is split into 12 equal parts with each part
    /// being a *shaah zmanis*. Note that with this system, *chatzos* (mid-day) will not be the point that the sun is
    /// halfway across the sky.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`
    public func shaahZmanisAteretTorah() -> Double? { getTemporalHour(dayStart: alos72Zmanis(), dayEnd: tzeisAteretTorah()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a dip of 96 minutes. This calculation divides
    /// the day based on the opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that
    /// the day runs from dawn to dusk. Dawn for this calculation is 96 minutes before sunrise and dusk is 96 minutes
    /// after sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    public func shaahZmanis96Minutes() -> Double? { getTemporalHour(dayStart: alos96(), dayEnd: tzeis96()) }

    /// Method to return a *shaah zmanis* (temporal hour) calculated using a dip of 120 minutes. This calculation
    /// divides the day based on the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day runs from dawn to dusk. Dawn for this
    /// calculation is 120 minutes before sunrise and dusk is 120 minutes after sunset. This day is split into 12 equal
    /// parts with each part being a *shaah zmanis*. Since *zmanim* that use this method are extremely late or early and
    /// at a point when the sky is a long time past the 18° point where the darkest point is reached, *zmanim* that use
    /// this should only be used *lechumra* only, such as delaying the start of nighttime *mitzvos*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis26Degrees()`
    public func shaahZmanis120Minutes() -> Double? { getTemporalHour(dayStart: alos120(), dayEnd: tzeis120()) }

    /// Method to return a *shaah zmanis* (temporal hour) according to the opinion of the [Magen Avraham
    /// (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 120 minutes *zmaniyos* before
    /// sunrise. This calculation divides the day based on the opinion of the MGA that the day runs from dawn to dusk.
    /// Dawn for this calculation is 120 minutes *zmaniyos* before sunrise and dusk is 120 minutes *zmaniyos* after
    /// sunset. This day is split into 12 equal parts with each part being a *shaah zmanis*. This is identical to 1/6th
    /// of the day from sunrise to sunset. Since *zmanim* that use this method are extremely late or early and at a
    /// point when the sky is a long time past the 18° point where the darkest point is reached, *zmanim* that use this
    /// should only be used *lechumra* such as delaying the start of nighttime *mitzvos*.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, a `MIN_VALUE` will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos120Zmanis()`, `tzeis120Zmanis()`
    public func shaahZmanis120MinutesZmanis() -> Double? { getTemporalHour(dayStart: alos120Zmanis(), dayEnd: tzeis120Zmanis()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on sunrise being 120
    /// minutes *zmaniyos* or 1/6th of the day before sunrise. This is calculated as 10.75 hours after dawn. The formula
    /// used is 10.75 * `shaahZmanis120MinutesZmanis()` after dawn. Since the *zman* based on an extremely early *alos*
    /// and a very late *tzais*, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis120MinutesZmanis()`, `alos120()`, `tzeis120()`, `plagHamincha26Degrees()`,
    ///   `plagHamincha120Minutes()`
    public func plagHamincha120MinutesZmanis() -> Date? { calculatePlagHamincha(alos120Zmanis(), tzeis120Zmanis()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* according to the Magen
    /// Avraham with the day starting 120 minutes before sunrise and ending 120 minutes after sunset. This is calculated
    /// as 10.75 hours after dawn 120 minutes. The formula used is 10.75 `shaahZmanis120Minutes()` after `alos120()`.
    /// Since the *zman* based on an extremely early *alos* and a very late *tzais*, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis120Minutes()`, `plagHamincha26Degrees()`
    public func plagHamincha120Minutes() -> Date? { calculatePlagHamincha(alos120(), tzeis120()) }

    /// Method to return *alos* (dawn) calculated as 60 minutes before sunrise. This is the time to walk the distance of
    /// 4 *Mil* at 15 minutes a *Mil*. This seems to be the opinion of the [Chavas
    /// Yair](https://en.wikipedia.org/wiki/Yair_Bacharach) in the Mekor Chaim, Orach Chaim Ch. 90, though the Mekor
    /// Chaim in Ch. 58 and in the [Chut Hashani Cha 97](https://hebrewbooks.org/pdfpager.aspx?req=45193&pgnum=214)
    /// states that a a person walks 3 and a 1/3 *mil* in an hour, or an 18-minute *mil*. Also see the [Divrei
    /// Malkiel](https://he.wikipedia.org/wiki/%D7%9E%D7%9C%D7%9B%D7%99%D7%90%D7%9C_%D7%A6%D7%91%D7%99_%D7%98%D7%A0%D7%A0%D7%91%D7%95%D7%99%D7%9D)
    /// [Vol. 4, Ch. 20, page 34](https://hebrewbooks.org/pdfpager.aspx?req=803&pgnum=33)) who mentions the 15 minute
    /// *mil* lechumra by baking matzos. Also see the [Maharik](https://en.wikipedia.org/wiki/Joseph_Colon_Trabotto)
    /// [Ch. 173](https://hebrewbooks.org/pdfpager.aspx?req=1142&pgnum=216) where the questioner quoting the
    /// [Ra'avan](https://en.wikipedia.org/wiki/Eliezer_ben_Nathan) is of the opinion that the time to walk a *mil* is
    /// 15 minutes (5 *mil* in a little over an hour). There are many who believe that there is a *ta'us sofer*
    /// (scribe's error) in the Ra'avan, and it should 4 *mil* in a little over an hour, or an 18-minute *mil*. Time
    /// based offset calculations are based on the opinion of the *[Rishonim](https://en.wikipedia.org/wiki/Rishonim)*
    /// who stated that the time of the *neshef* (time between dawn and sunrise) does not vary by the time of year or
    /// location but purely depends on the time it takes to walk the distance of 4* *mil*.
    /// `tzeisGeonim9Point75Degrees()` is a related *zman* that is a degree-based calculation based on 60 minutes.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`. documentation.
    /// - SeeAlso: `tzeis60()`, `plagHamincha60Minutes()`, `shaahZmanis60Minutes()`
    public func alos60() -> Date? {
		AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -60 * AstronomicalCalendar.minuteMillis) }

    /// Method to return *alos* (dawn) calculated using 72 minutes *zmaniyos* or 1/10th of the day before sunrise. This
    /// is based on an 18-minute *Mil* so the time for 4 *Mil* is 72 minutes which is 1/10th of a day (12 * 60 = 720)
    /// based on the a day being from sea level sunrise to sea level sunset or sunrise to sunset (depending on the
    /// `shouldUseElevation` setting). The actual calculation is `seaLevelSunrise` - (`shaahZmanisGra()` * 1.2). This
    /// calculation is used in the calendars published by the [Hisachdus Harabanim D'Artzos Habris
    /// Ve'Canada](https://en.wikipedia.org/wiki/Central_Rabbinical_Congress).
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisGra()`
    public func alos72Zmanis() -> Date? { zmanisBasedOffset(-1.2) }

    /// Method to return *alos* (dawn) calculated using 96 minutes before before sunrise or sea level sunrise (depending
    /// on the `shouldUseElevation` setting) that is based on the time to walk the distance of 4 *Mil* at 24 minutes a
    /// *Mil*. Time based offset calculations for *alos* are based on the opinion of the
    /// *[Rishonim](https://en.wikipedia.org/wiki/Rishonim)* who stated that the time of the *Neshef* (time between dawn
    /// and sunrise) does not vary by the time of year or location but purely depends on the time it takes to walk the
    /// distance of 4 *Mil*.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func alos96() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -96 * AstronomicalCalendar.minuteMillis) }

    /// Method to return *alos* (dawn) calculated using 90 minutes *zmaniyos* or 1/8th of the day before sunrise or sea
    /// level sunrise (depending on the `shouldUseElevation` setting). This is based on a 22.5-minute *Mil* so the time
    /// for 4 *Mil* is 90 minutes which is 1/8th of a day (12 * 60) / 8 = 90 The day is calculated from sea level
    /// sunrise to sea level sunset or sunrise to sunset (depending on the `shouldUseElevation`. The actual calculation
    /// used is `sunrise` - (`shaahZmanisGra()` * 1.5).
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisGra()`
    public func alos90Zmanis() -> Date? {
        guard let shaahZmanis = shaahZmanisGra() else { return nil }
        return AstronomicalCalendar
            .getTimeOffset(time: elevationAdjustedSunrise, offset: (shaahZmanis * -1.5))
    }
    
    /// This method returns *alos* (dawn) calculated using 96 minutes *zmaniyos* or 1/7.5th of the day before sunrise or
    /// sea level sunrise (depending on the `shouldUseElevation` setting). This is based on a 24-minute *Mil* so the
    /// time for 4 *Mil* is 96 minutes which is 1/7.5th of a day (12 * 60 / 7.5 = 96). The day is calculated from sea
    /// level sunrise to sea level sunset or sunrise to sunset (depending on the `shouldUseElevation`. The actual
    /// calculation used is `sunrise` - (`shaahZmanisGra()` * 1.6).
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisGra()`
    public func alos96Zmanis() -> Date? { zmanisBasedOffset(-1.6) }

    /// Method to return *alos* (dawn) calculated using 90 minutes before sea level sunrise based on the time to walk
    /// the distance of 4 *Mil* at 22.5 minutes a *Mil*. Time based offset calculations for *alos* are based on the
    /// opinion of the *[Rishonim](https://en.wikipedia.org/wiki/Rishonim)* who stated that the time of the *Neshef*
    /// (time between dawn and sunrise) does not vary by the time of year or location but purely depends on the time it
    /// takes to walk the distance of 4 *Mil*.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func alos90() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -90 * AstronomicalCalendar.minuteMillis) }

    /// This method should be used *lechumra* only and returns *alos* (dawn) calculated using 120 minutes before sea
    /// level sunrise (no adjustment for elevation is made) based on the time to walk the distance of 5 *Mil*(*Ula*) at
    /// 24 minutes a *Mil*. Time based offset calculations for *alos* are based on the* opinion of the
    /// *[Rishonim](https://en.wikipedia.org/wiki/Rishonim)* who stated that the time of the *neshef* (time between dawn
    /// and sunrise) does not vary by the time of year or location but purely depends on the time it takes to walk the
    /// distance of 5 *Mil*(*Ula*). Since this time is extremely early, it should only be used *lechumra*, such as not
    /// eating after this time on a fast day, and not as the start time for *mitzvos* that can only be performed during
    /// the day.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only (such as stopping to eat at
    ///   this time on a fast day), since it returns a very early time, and if used
    ///   *lekula* can result in doing *mitzvos hayom* too early according to most
    ///   opinions. There is no current plan to remove this method from the API,
    ///   and this deprecation is intended to alert developers of the danger of
    ///   using it.
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeis120()`, `alos26Degrees()`
    public func alos120() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: -120 * AstronomicalCalendar.minuteMillis) }

    /// This method should be used *lechumra* only and method returns *alos* (dawn) calculated using 120 minutes
    /// *zmaniyos* or 1/6th of the day before sunrise or sea level sunrise (depending on the `shouldUseElevation`
    /// setting). This is based on a 24-minute *Mil* so the time for 5 *Mil* is 120 minutes which is 1/6th of a day (12
    /// * 60 / 6 = 120). The day is calculated from sea level sunrise to sea level sunset or sunrise to sunset
    /// (depending on the `shouldUseElevation`. The actual calculation used is `sunrise` - (`shaahZmanisGra()` * 2).
    /// Since this time is extremely early, it should only be used *lechumra*, such as not eating after this time on a
    /// fast day, and not as the start time for *mitzvos* that can only be performed during the day.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only (such as stopping to eat at
    ///   this time on a fast day), since it returns a very early time, and if used
    ///   *lekula* can result in doing *mitzvos hayom* too early according to most
    ///   opinions. There is no current plan to remove this method from the API,
    ///   and this deprecation is intended to alert developers of the danger of
    ///   using it.
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos120()`, `alos26Degrees()`
    public func alos120Zmanis() -> Date? { zmanisBasedOffset(-2) }

    /// This method should be used *lechumra* only and returns *alos* (dawn) calculated when the sun is 26° below the
    /// eastern geometric horizon before sunrise. This calculation is based on the same calculation of 120 minutes but
    /// uses a degree-based calculation instead of 120 exact minutes. This calculation is based on the position of the
    /// sun 120 minutes before sunrise in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 26°
    /// below geometric zenith. Since this time is extremely early, it should only be used *lechumra* only, such as not
    /// eating after this time on a fast day, and not as the start time for *mitzvos* that can only be performed during
    /// the day.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only (such as stopping to eat at
    ///   this time on a fast day), since it returns a very early time, and if used
    ///   *lekula* can result in doing *mitzvos hayom* too early according to most
    ///   opinions. There is no current plan to remove this method from the API,
    ///   and this deprecation is intended to alert developers of the danger of
    ///   using it.
    /// - Returns: the `Date` representing *alos*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z26Deg`, `alos120()`, `tzeis120()`, `tzeis26Degrees()`
    public func alos26Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z26Deg) }

    /// A method to return *alos* (dawn) calculated when the sun is 18° below the eastern geometric horizon before
    /// sunrise.
    ///
    /// - Returns: the `Date` representing *alos*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.astronomical`
    public func alos18Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .astronomical) }

    /// A method to return *alos* (dawn) calculated when the sun is 19° below the eastern geometric horizon before
    /// sunrise. This is the [Rambam](https://en.wikipedia.org/wiki/Maimonides)'s *alos* according to Rabbi Moshe
    /// Kosower's [Maaglei Tzedek](https://www.worldcat.org/oclc/145454098), page 88, [Ayeles Hashachar Vol. I, page
    /// 12](https://hebrewbooks.org/pdfpager.aspx?req=33464&pgnum=13), [Yom Valayla Shel Torah, Ch. 34, p.
    /// 222](https://hebrewbooks.org/pdfpager.aspx?req=55960&pgnum=258) and Rabbi Yaakov Shakow's [Luach Ikvei
    /// Hayom](https://www.worldcat.org/oclc/1043573513).
    ///
    /// - Returns: the `Date` representing *alos*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.astronomical`
    public func alos19Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z19Deg) }

    /// Method to return *alos* (dawn) calculated when the sun is 19.8° below the eastern geometric horizon before
    /// sunrise. This calculation is based on the same calculation of 90 minutes but uses a degree-based calculation
    /// instead of 90 exact minutes. This calculation is based on the position of the sun 90 minutes before sunrise in
    /// Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 19.8°
    /// below geometric zenith.
    ///
    /// - Returns: the `Date` representing *alos*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z19_8`, `alos90()`
    public func alos19Point8Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z19_8) }

    /// Method to return *alos* (dawn) calculated when the sun is 16.1° below the eastern geometric horizon before
    /// sunrise. This calculation is based on the same calculation of 72 minutes but uses a degree-based calculation
    /// instead of 72 exact minutes. This calculation is based on the position of the sun 72 minutes before sunrise in
    /// Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 16.1°
    /// below geometric zenith.
    ///
    /// - Returns: the `Date` representing *alos*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z16_1`, `alos72()`
    public func alos16Point1Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_1) }

    /// This method returns *misheyakir* based on the position of the sun when it is 11.5° below geometric zenith (90°).
    /// This calculation is used for calculating *misheyakir* according to some opinions. This calculation is based on
    /// the position of the sun 52 minutes before sunrise in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 11.5°
    /// below geometric zenith.
    ///
    /// - ToDo: recalculate.
    /// - Returns: the `Date` of *misheyakir*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z11_5`
    public func misheyakir11Point5Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z11_5) }

    /// This method returns *misheyakir* based on the position of the sun when it is 11° below geometric zenith (90°).
    /// This calculation is used for calculating *misheyakir* according to some opinions. This calculation is based on
    /// the position of the sun 48 minutes before sunrise in Jerusalem d[around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 11°
    /// below geometric zenith.
    ///
    /// - Returns: If the calculation can't be computed such as northern and southern locations even south of the Arctic
    ///   Circle and north of the Antarctic Circle where the sun may not reach low enough below the horizon for
    ///   this calculation, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `Zenith.z11Deg`
    public func misheyakir11Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z11Deg) }

    /// This method returns *misheyakir* based on the position of the sun when it is 10.2° below geometric zenith (90°).
    /// This calculation is used for calculating *misheyakir* according to some opinions. This calculation is based on
    /// the position of the sun 45 minutes before sunrise in Jerusalem [around the
    /// equinox](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) which calculates to 10.2°
    /// below geometric zenith.
    ///
    /// - Returns: the `Date` of *misheyakir*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z10_2`
    public func misheyakir10Point2Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z10_2) }

    /// This method returns *misheyakir* based on the position of the sun when it is 7.65° below geometric zenith (90°).
    /// The degrees are based on a 35/36 minute *zman* [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), when the *neshef*
    /// (twilight) is the shortest. This time is based on [Rabbi Moshe
    /// Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) who writes in [Ohr Hachaim Vol. 4, Ch.
    /// 6](https://hebrewbooks.org/pdfpager.aspx?req=14677&pgnum=7)) that *misheyakir* in New York is 35-40 minutes
    /// before sunset, something that is a drop less than 8°. [Rabbi Yisroel
    /// Taplin](https://en.wikipedia.org/wiki/Yisroel_Taplin) in [Zmanei
    /// Yisrael](https://www.worldcat.org/oclc/889556744) (page 117) notes that [Rabbi Yaakov
    /// Kamenetsky](https://en.wikipedia.org/wiki/Yaakov_Kamenetsky) stated that it is not less than 36 minutes before
    /// sunrise (maybe it is 40 minutes). Sefer Yisrael Vehazmanim (p. 7) quotes the Tamar Yifrach in the name of the
    /// [Satmar Rov](https://en.wikipedia.org/wiki/Joel_Teitelbaum) that one should be stringent not consider
    /// *misheyakir* before 36 minutes. This is also the accepted [minhag](https://en.wikipedia.org/wiki/Minhag) in
    /// [Lakewood](https://en.wikipedia.org/wiki/Lakewood_Township,_New_Jersey) that is used in the
    /// [Yeshiva](https://en.wikipedia.org/wiki/Beth_Medrash_Govoha). This follows the opinion of [Rabbi Shmuel
    /// Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who provided the time of 35/36 minutes, but did not
    /// provide a degree-based time. Since this *zman* depends on the level of light, Rabbi Yaakov Shakow presented this
    /// degree-based calculations to Rabbi Kamenetsky who agreed to them.
    ///
    /// - Returns: the `Date` of *misheyakir*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z7_65`, `misheyakir9Point5Degrees()`
    public func misheyakir7Point65Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z7_65) }

    /// This method returns *misheyakir* based on the position of the sun when it is 9.5° below geometric zenith (90°).
    /// This calculation is based on Rabbi Dovid Kronglass's Calculation of 45 minutes in Baltimore as mentioned in
    /// [Divrei Chachamim No. 24](https://hebrewbooks.org/pdfpager.aspx?req=20287&pgnum=29) brought down by the [Birur
    /// Halacha, Tinyana, Ch. 18](https://hebrewbooks.org/pdfpager.aspx?req=50535&pgnum=87). This calculates to 9.5°.
    /// Also see [Rabbi Yaakov Yitzchok Neiman](https://en.wikipedia.org/wiki/Jacob_Isaac_Neiman) in Kovetz Eitz Chaim
    /// Vol. 9, p. 202 that the Vya'an Yosef did not want to rely on times earlier than 45 minutes in New York. This
    /// *zman* is also used in the calendars published by Rabbi Hershel Edelstein. As mentioned in Yisroel Vehazmanim,
    /// Rabbi Edelstein who was given the 45 minute *zman* by Rabbi Bick. The calendars published by the *[Edot
    /// Hamizrach](https://en.wikipedia.org/wiki/Mizrahi_Jews)* communities also use this *zman*. This also follows the
    /// opinion of [Rabbi Shmuel Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who provided the time of
    /// 36 and 45 minutes, but did not provide a degree-based time. Since this *zman* depends on the level of light,
    /// Rabbi Yaakov Shakow presented these degree-based times to Rabbi Shmuel Kamenetsky who agreed to them.
    ///
    /// - Returns: the `Date` of *misheyakir*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z9_5`, `misheyakir7Point65Degrees()`
    public func misheyakir9Point5Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z9_5) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 19.8° before
    /// sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 19.8° below sunrise or sunset. This returns the time of 3 *
    /// `shaahZmanis19Point8Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis19Point8Degrees()`, `alos19Point8Degrees()`
    public func latestShemaMGA19Point8Degrees() -> Date? { calculateLatestZmanShema(alos19Point8Degrees(), tzeis19Point8Degrees()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 16.1° before
    /// sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 16.1° below sunrise or sunset. This returns the time of 3 *
    /// `shaahZmanis16Point1Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `alos16Point1Degrees()`
    public func latestShemaMGA16Point1Degrees() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 18° before
    /// sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 18° below sunrise or sunset. This returns the time of 3 *
    /// `shaahZmanis18Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis18Degrees()`, `alos18Degrees()`
    public func latestShemaMGA18Degrees() -> Date? { calculateLatestZmanShema(alos18Degrees(), tzeis18Degrees()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes
    /// before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that
    /// the day is calculated from a dawn of 72 minutes before sunrise to nightfall of 72 minutes after sunset. This
    /// returns the time of 3 * `shaahZmanis72Minutes()` after dawn. This class returns an identical time to
    /// `latestShemaMga()` and is repeated here for clarity.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis72Minutes()`, `alos72()`, `latestShemaMga()`
    public func latestShemaMGA72Minutes() -> Date? { latestShemaMga()}

    /// This method returns the latest *zman krias shema* (time to recite *Shema* in the morning) according to the
    /// opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72
    /// minutes *zmaniyos*, or 1/10th of the day before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after
    /// dawn based on the opinion of the MGA that the day is calculated from a dawn of 72 minutes *zmaniyos*, or 1/10th
    /// of the day before sea level sunrise to nightfall of 72 minutes *zmaniyos* after sea level sunset. This returns
    /// the time of 3 * `shaahZmanis72MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis72MinutesZmanis()`, `alos72Zmanis()`
    public func latestShemaMGA72MinutesZmanis() -> Date? { calculateLatestZmanShema(alos72Zmanis(), tzeis72Zmanis()) }

    /// This method returns the latest *zman krias shema* (time to recite *Shema* in the morning) according to the
    /// opinion of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 90
    /// minutes before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA
    /// that the day is calculated from a dawn of 90 minutes before sunrise to nightfall of 90 minutes after sunset.
    /// This returns the time of 3 * `shaahZmanis90Minutes()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90Minutes()`, `alos90()`
    public func latestShemaMGA90Minutes() -> Date? { calculateLatestZmanShema(alos90(), tzeis90()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 90 minutes
    /// *zmaniyos* before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the
    /// MGA that the day is calculated from a dawn of 90 minutes *zmaniyos* before sunrise to nightfall of 90 minutes
    /// *zmaniyos* after sunset. This returns the time of 3 * `shaahZmanis90MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90MinutesZmanis()`, `alos90Zmanis()`
    public func latestShemaMGA90MinutesZmanis() -> Date? { calculateLatestZmanShema(alos90Zmanis(), tzeis90Zmanis()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 96 minutes
    /// before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that
    /// the day is calculated from a dawn of 96 minutes before sunrise to nightfall of 96 minutes after sunset. This
    /// returns the time of 3 * `shaahZmanis96Minutes()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis96Minutes()`, `alos96()`
    public func latestShemaMGA96Minutes() -> Date? { calculateLatestZmanShema(alos96(), tzeis96()) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 96 minutes
    /// *zmaniyos* before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the
    /// MGA that the day is calculated from a dawn of 96 minutes *zmaniyos* before sunrise to nightfall of 96 minutes
    /// *zmaniyos* after sunset. This returns the time of 3 * `shaahZmanis96MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis96MinutesZmanis()`, `alos96Zmanis()`
    public func latestShemaMGA96MinutesZmanis() -> Date? { calculateLatestZmanShema(alos96Zmanis(), tzeis96Zmanis()) }

    /// This method returns the latest *zman krias shema* (time to recite *Shema* in the morning) calculated as 3 hours
    /// (regular clock hours and not *sha'os zmaniyos*) before `chatzos()`. Generally known as part of the "Komarno"
    /// *zmanim* after [Rav Yitzchak Eizik of
    /// Komarno](https://en.wikipedia.org/wiki/Komarno_(Hasidic_dynasty)#Rabbi_Yitzchak_Eisik_Safrin), a proponent of
    /// this calculation, it actually predates him a lot. It is the opinion of the *Shach* in the Nekudas Hakesef (Yoreh
    /// Deah 184), [Rav Moshe Lifshitz](https://hebrewbooks.org/pdfpager.aspx?req=21638&st=&pgnum=30) in his commentary
    /// [Lechem Mishneh on Brachos 1:2](https://hebrewbooks.org/pdfpager.aspx?req=21638&st=&pgnum=50). It is next
    /// brought down about 100 years later by the [Yaavetz](https://en.wikipedia.org/wiki/Jacob_Emden) (in his *siddur*,
    /// [Mor Uktziah Orach Chaim 1](https://hebrewbooks.org/pdfpager.aspx?req=7920&st=&pgnum=6), [Lechem Shamayim,
    /// Brachos 1:2](https://hebrewbooks.org/pdfpager.aspx?req=22309&st=&pgnum=30) and [She'elos Yaavetz vol. 1 no.
    /// 40](https://hebrewbooks.org/pdfpager.aspx?req=1408&st=&pgnum=69)), Rav Yitzchak Eizik of Komarno in the Ma'aseh
    /// Oreg on Mishnayos Brachos 11:2, Shevus Yaakov, Chasan Sofer and others. See Yisrael Vehazmanim [vol. 1 7:3, page
    /// 55 - 62](https://hebrewbooks.org/pdfpager.aspx?req=9765&st=&pgnum=83). A variant of this calculation
    /// KosherJava's `getSofZmanShmaFixedLocal()` uses fixed local *chatzos* for calculating this type of *zman*.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `chatzos()`, `latestTefila2HoursBeforeChatzos()`
    public func latestShema3HoursBeforeChatzos() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: -180 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) according to the opinion
    /// of the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 120 minutes
    /// or 1/6th of the day before sunrise. This time is 3 *shaos zmaniyos* (solar hours) after dawn based on the
    /// opinion of the MGA that the day is calculated from a dawn of 120 minutes before sunrise to nightfall of 120
    /// minutes after sunset. This returns the time of 3 `shaahZmanis120Minutes()` after dawn. This is an extremely
    /// early *zman* that is very much a *chumra*.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis120Minutes()`, `alos120()`
    public func latestShemaMGA120Minutes() -> Date? { calculateLatestZmanShema(alos120(), tzeis120()) }

    /// This method returns the latest *zman krias shema* (time to recite *Shema* in the morning) based on the opinion
    /// that the day starts at *alos* 16.1° and ends at sea level sunset. This is the opinion of the
    /// [\u05D7\u05D9\u05D3\u05D5\u05E9\u05D9 \u05D5\u05DB\u05DC\u05DC\u05D5\u05EA
    /// \u05D4\u05E8\u05D6\u05F4\u05D4](https://hebrewbooks.org/40357) and the [\u05DE\u05E0\u05D5\u05E8\u05D4
    /// \u05D4\u05D8\u05D4\u05D5\u05E8\u05D4](https://hebrewbooks.org/14799) as mentioned by Yisrael Vehazmanim [vol 1,
    /// sec. 7, ch. 3 no. 16](https://hebrewbooks.org/pdfpager.aspx?req=9765&pgnum=81). Three *shaos zmaniyos* are
    /// calculated based on this day and added to *alos* to reach this time. This time is 3 *shaos zmaniyos* (solar
    /// hours) after dawn based on the opinion that the day is calculated from a *alos* 16.1° to sea level sunset.
    /// **Note:** Based on this calculation *chatzos* will not be at midday.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema* based on this day. If the calculation can't be computed
    ///   such as northern and southern locations even south of the Arctic Circle and north of the Antarctic
    ///   Circle where the sun may not reach low enough below the horizon for this calculation, nil will be
    ///   returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `seaLevelSunset`
    public func latestShemaAlos16Point1ToSunset() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), elevationAdjustedSunset) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) based on the opinion
    /// that the day starts at *alos* 16.1° and ends at *tzais* 7.083°. 3 *shaos zmaniyos* are calculated based on this
    /// day and added to *alos* to reach this time. This time is 3 *shaos zmaniyos* (temporal hours) after *alos* 16.1°
    /// based on the opinion that the day is calculated from a *alos* 16.1° to *tzais* 7.083°. **Note:** Based on this
    /// calculation *chatzos* will not be at midday.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema* based on this calculation. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `tzeisGeonim7Point083Degrees()`
    public func latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees() -> Date? { calculateLatestZmanShema(alos16Point1Degrees(), tzeisGeonim7Point083Degrees()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 19.8° before
    /// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 19.8° below sunrise or sunset. This returns the time of 4 *
    /// `shaahZmanis19Point8Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis19Point8Degrees()`, `alos19Point8Degrees()`
    public func latestTefilaMGA19Point8Degrees() -> Date? { calculateLatestTefila(alos19Point8Degrees(), tzeis19Point8Degrees()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 16.1° before
    /// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 16.1° below sunrise or sunset. This returns the time of 4 *
    /// `shaahZmanis16Point1Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `alos16Point1Degrees()`
    public func latestTefilaMGA16Point1Degrees() -> Date? { calculateLatestTefila(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 18° before sunrise.
    /// This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day is
    /// calculated from dawn to nightfall with both being 18° below sunrise or sunset. This returns the time of 4 *
    /// `shaahZmanis18Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis18Degrees()`, `alos18Degrees()`
    public func latestTefilaMGA18Degrees() -> Date? { calculateLatestTefila(alos18Degrees(), tzeis18Degrees()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes before
    /// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from a dawn of 72 minutes before sunrise to nightfall of 72 minutes after sunset. This returns the
    /// time of 4 * `shaahZmanis72Minutes()` after dawn. This class returns an identical time to `latestTefilaMga()` and
    /// is repeated here for clarity.
    ///
    /// - Returns: the `Date` of the latest *zman tfila*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis72Minutes()`, `alos72()`, `latestShemaMga()`
    public func latestTefilaMGA72Minutes() -> Date? { latestTefilaMga() }

    /// This method returns the latest *zman tfila* (time to the morning prayers) according to the opinion of the [Magen
    /// Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes *zmaniyos*
    /// before sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that
    /// the day is calculated from a dawn of 72 minutes *zmaniyos* before sunrise to nightfall of 72 minutes *zmaniyos*
    /// after sunset. This returns the time of 4 * `shaahZmanis72MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis72MinutesZmanis()`, `alos72Zmanis()`
    public func latestTefilaMGA72MinutesZmanis() -> Date? { calculateLatestTefila(alos72Zmanis(), tzeis72Zmanis()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 90 minutes before
    /// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from a dawn of 90 minutes before sunrise to nightfall of 90 minutes after sunset. This returns the
    /// time of 4 * `shaahZmanis90Minutes()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman tfila*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90Minutes()`, `alos90()`
    public func latestTefilaMGA90Minutes() -> Date? { calculateLatestTefila(alos90(), tzeis90()) }

    /// This method returns the latest *zman tfila* (time to the morning prayers) according to the opinion of the [Magen
    /// Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 90 minutes *zmaniyos*
    /// before sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that
    /// the day is calculated from a dawn of 90 minutes *zmaniyos* before sunrise to nightfall of 90 minutes *zmaniyos*
    /// after sunset. This returns the time of 4 * `shaahZmanis90MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90MinutesZmanis()`, `alos90Zmanis()`
    public func latestTefilaMGA90MinutesZmanis() -> Date? { calculateLatestTefila(alos90Zmanis(), tzeis90Zmanis()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 96 minutes before
    /// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from a dawn of 96 minutes before sunrise to nightfall of 96 minutes after sunset. This returns the
    /// time of 4 * `shaahZmanis96Minutes()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman tfila*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis96Minutes()`, `alos96()`
    public func latestTefilaMGA96Minutes() -> Date? { calculateLatestTefila(alos96(), tzeis96()) }

    /// This method returns the latest *zman tfila* (time to the morning prayers) according to the opinion of the [Magen
    /// Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 96 minutes *zmaniyos*
    /// before sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that
    /// the day is calculated from a dawn of 96 minutes *zmaniyos* before sunrise to nightfall of 96 minutes *zmaniyos*
    /// after sunset. This returns the time of 4 * `shaahZmanis96MinutesZmanis()` after dawn.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90MinutesZmanis()`, `alos90Zmanis()`
    public func latestTefilaMGA96MinutesZmanis() -> Date? { calculateLatestTefila(alos96Zmanis(), tzeis96Zmanis()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 120 minutes before
    /// sunrise . This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from a dawn of 120 minutes before sunrise to nightfall of 120 minutes after sunset. This returns
    /// the time of 4 * `shaahZmanis120Minutes()` after dawn. This is an extremely early *zman* that is very much a
    /// *chumra*.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis120Minutes()`, `alos120()`
    public func latestTefilaMGA120Minutes() -> Date? { calculateLatestTefila(alos120(), tzeis120()) }

    /// This method returns the time of *mincha gedola* according to the Magen Avraham with the day starting and ending
    /// 16.1° below the horizon. This is the earliest time to pray *mincha*. For more information on this see the
    /// documentation on *mincha gedola*. This is calculated as 6.5 solar hours after *alos*. The calculation used is
    /// 6.5 * `shaahZmanis16Point1Degrees()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `calculateMinchaGedolah()`, `calculateMinchaKetana()`
    public func minchaGedola16Point1Degrees() -> Date? { calculateMinchaGedolah(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// This method returns the time of *mincha gedola* according to the Magen Avraham with the day starting 72 minutes
    /// before sunrise and ending 72 minutes after sunset. This is the earliest time to pray *mincha*. For more
    /// information on this see the documentation on *mincha gedola*. This is calculated as 6.5 solar hours after
    /// *alos*. The calculation used is 6.5 * `shaahZmanis72Minutes()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `alos72()`, `calculateMinchaGedolah()`, `calculateMinchaKetana()`
    public func minchaGedola72Minutes() -> Date? { calculateMinchaGedolah(alos72(), tzeis72()) }

    /// This method returns the time of *mincha ketana* according to the Magen Avraham with the day starting and ending
    /// 16.1° below the horizon. This is the preferred earliest time to pray *mincha* according to the opinion of the
    /// [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others. For more information on this see the
    /// documentation on *mincha gedola*. This is calculated as 9.5 solar hours after *alos*. The calculation used is
    /// 9.5 * `shaahZmanis16Point1Degrees()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha ketana*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `calculateMinchaGedolah()`, `calculateMinchaKetana()`
    public func minchaKetana16Point1Degrees() -> Date? { calculateMinchaKetana(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// This method returns the time of *mincha ketana* according to the Magen Avraham with the day starting 72 minutes
    /// before sunrise and ending 72 minutes after sunset. This is the preferred earliest time to pray *mincha*
    /// according to the opinion of the [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others. For more
    /// information on this see the documentation on *mincha gedola*. This is calculated as 9.5 `shaahZmanis72Minutes()`
    /// after *alos*. The calculation used is 9.5 * `shaahZmanis72Minutes()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha ketana*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `calculateMinchaGedolah()`, `calculateMinchaKetana()`
    public func minchaKetana72Minutes() -> Date? { calculateMinchaKetana(alos72(), tzeis72()) }

    /// This method returns the time of *plag hamincha* according to the Magen Avraham with the day starting 60 minutes
    /// before sunrise and ending 60 minutes after sunset. This is calculated as 10.75 hours after dawn. The formula
    /// used is 10.75 `shaahZmanis60Minutes()` after `alos60()`.
    ///
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis60Minutes()`, `alos60()`, `tzeis60()`
    public func plagHamincha60Minutes() -> Date? { calculatePlagHamincha(alos60(), tzeis60()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* according to the Magen
    /// Avraham with the day starting 72 minutes before sunrise and ending 72 minutes after sunset. This is calculated
    /// as 10.75 hours after dawn. The formula used is 10.75 `shaahZmanis72Minutes()` after `alos72()`. Since *plag* by
    /// this calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis72Minutes()`
    public func plagHamincha72Minutes() -> Date? { calculatePlagHamincha(alos72(), tzeis72()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* according to the Magen
    /// Avraham with the day starting 90 minutes before sunrise and ending 90 minutes after sunset. This is calculated
    /// as 10.75 hours after dawn. The formula used is 10.75 `shaahZmanis90Minutes()` after `alos90()`. Since *plag* by
    /// this calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis90Minutes()`
    public func plagHamincha90Minutes() -> Date? { calculatePlagHamincha(alos90(), tzeis90()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* according to the Magen
    /// Avraham with the day starting 96 minutes before sunrise and ending 96 minutes after sunset. This is calculated
    /// as 10.75 hours after dawn. The formula used is 10.75 `shaahZmanis96Minutes()` after `alos96()`. Since *plag* by
    /// this calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `shaahZmanis96Minutes()`
    public func plagHamincha96Minutes() -> Date? { calculatePlagHamincha(alos96(), tzeis96()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha*. This is calculated as 10.75
    /// hours after dawn. The formula used is 10.75 * `shaahZmanis96MinutesZmanis()` after dawn. Since *plag* by this
    /// calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    public func plagHamincha96MinutesZmanis() -> Date? { calculatePlagHamincha(alos96Zmanis(), tzeis96Zmanis()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha*. This is calculated as 10.75
    /// hours after dawn. The formula used is 10.75 * `shaahZmanis90MinutesZmanis()` after dawn. Since *plag* by this
    /// calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    public func plagHamincha90MinutesZmanis() -> Date? { calculatePlagHamincha(alos90Zmanis(), tzeis90Zmanis()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha*. This is calculated as 10.75
    /// hours after `alos72Zmanis()`. The formula used is 10.75 * `shaahZmanis72MinutesZmanis()` after dawn. Since
    /// *plag* by this calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    public func plagHamincha72MinutesZmanis() -> Date? { calculatePlagHamincha(alos72Zmanis(), tzeis72Zmanis()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on the opinion that the
    /// day starts at *alos* 16.1° and ends at *tzais* 16.1°. This is calculated as 10.75 hours *zmaniyos* after dawn.
    /// The formula used is 10.75 * `shaahZmanis16Point1Degrees()` after `alos16Point1Degrees()`. Since *plag* by this
    /// calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`
    public func plagHamincha16Point1Degrees() -> Date? { calculatePlagHamincha(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on the opinion that the
    /// day starts at *alos* 19.8° and ends at *tzais* 19.8°. This is calculated as 10.75 hours *zmaniyos* after dawn.
    /// The formula used is 10.75 * `shaahZmanis19Point8Degrees()` after `alos19Point8Degrees()`. Since *plag* by this
    /// calculation can occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis19Point8Degrees()`
    public func plagHamincha19Point8Degrees() -> Date? { calculatePlagHamincha(alos19Point8Degrees(), tzeis19Point8Degrees()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on the opinion that the
    /// day starts at *alos* 26° and ends at *tzais* 26°. This is calculated as 10.75 hours *zmaniyos* after dawn. The
    /// formula used is 10.75 * `shaahZmanis26Degrees()` after `alos26Degrees()`. Since the *zman* based on an extremely
    /// early *alos* and a very late *tzais*, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis26Degrees()`, `plagHamincha120Minutes()`
    public func plagHamincha26Degrees() -> Date? { calculatePlagHamincha(alos26Degrees(), tzeis26Degrees()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on the opinion that the
    /// day starts at *alos* 18° and ends at *tzais* 18°. This is calculated as 10.75 hours *zmaniyos* after dawn. The
    /// formula used is 10.75 * `shaahZmanis18Degrees()` after `alos18Degrees()`. Since *plag* by this calculation can
    /// occur after sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as northern and
    ///   southern locations even south of the Arctic Circle and north of the Antarctic Circle where the sun
    ///   may not reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis18Degrees()`
    public func plagHamincha18Degrees() -> Date? { calculatePlagHamincha(alos18Degrees(), tzeis18Degrees()) }

    /// This method should be used *lechumra* only and returns the time of *plag hamincha* based on the opinion that the
    /// day starts at *alos* 16.1° and ends at sunset. 10.75 *shaos zmaniyos* are calculated based on this day and added
    /// to *alos* to reach this time. This time is 10.75 *shaos zmaniyos* (temporal hours) after dawn based on the
    /// opinion that the day is calculated from a dawn of 16.1 degrees before sunrise to sea level sunset. This returns
    /// the time of 10.75 * the calculated *shaah zmanis* after dawn. Since *plag* by this calculation can occur after
    /// sunset, it should only be used *lechumra*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` of the *plag*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `seaLevelSunset`
    public func plagAlosToSunset() -> Date? { calculatePlagHamincha(alos16Point1Degrees(), elevationAdjustedSunset) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated at the sun's
    /// position at 3.7° below the western horizon.
    ///
    /// - Returns: the `Date` representing the time when the sun is 3.7° below sea level.
    /// - SeeAlso: `Zenith.z3_7`
    public func tzeisGeonim3Point7Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_7) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated at the sun's
    /// position at 3.8° below the western horizon.
    ///
    /// - Returns: the `Date` representing the time when the sun is 3.8° below sea level.
    /// - SeeAlso: `Zenith.z3_8`
    public func tzeisGeonim3Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_8) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated at the sun's
    /// position at 5.95° below the western horizon.
    ///
    /// - Returns: the `Date` representing the time when the sun is 5.95° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z5_95`
    public func tzeisGeonim5Point95Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z5_95) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [Mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement) based on an 18 minute Mil, or
    /// 13.5 minutes. It is the sun's position at 3.65° below the western horizon. This is a very early *zman* and
    /// should not be relied on without Rabbinical guidance.
    ///
    /// - Returns: the `Date` representing the time when the sun is 3.65° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z3_65`
    public func tzeisGeonim3Point65Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_65) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [Mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement) based on an 18 minute Mil, or
    /// 13.5 minutes. It is the sun's position at 3.676° below the western horizon based on the calculations of Stanley
    /// Fishkind. This is a very early *zman* and should not be relied on without Rabbinical guidance.
    ///
    /// - Returns: the `Date` representing the time when the sun is 3.676° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z3_676`
    public func tzeisGeonim3Point676Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z3_676) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// *[mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement)* based on a 24-minute Mil, or
    /// 18 minutes. It is the sun's position at 4.61° below the western horizon. This is a very early *zman* and should
    /// not be relied on without Rabbinical guidance.
    ///
    /// - Returns: the `Date` representing the time when the sun is 4.61° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z4_61`
    public func tzeisGeonim4Point61Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_61) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [Mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement), based on a 22.5 minute Mil, or
    /// 16 7/8 minutes. It is the sun's position at 4.37° below the western horizon. This is a very early *zman* and
    /// should not be relied on without Rabbinical guidance.
    ///
    /// - Returns: the `Date` representing the time when the sun is 4.37° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z4_37`
    public func tzeisGeonim4Point37Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_37) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// 24-minute *[Mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement)*, based on a *Mil*
    /// being 24 minutes, and is calculated as 18 + 2 + 4 for a total of 24 minutes. It is the sun's position at 5.88°
    /// below the western horizon. This is a very early *zman* and should not be relied on without Rabbinical guidance.
    ///
    /// - ToDo: Additional detailed documentation needed.
    /// - Returns: the `Date` representing the time when the sun is 5.88° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z5_88`
    public func tzeisGeonim5Point88Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z5_88) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [Mil](https://en.wikipedia.org/wiki/Biblical_and_Talmudic_units_of_measurement) based on the sun's position at
    /// 4.8° below the western horizon. This is based on Rabbi Leo Levi's calculations. This is the This is a very early
    /// *zman* and should not be relied on without Rabbinical guidance.
    ///
    /// - ToDo: Additional documentation needed.
    /// - Returns: the `Date` representing the time when the sun is 4.8° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z4_8`
    public func tzeisGeonim4Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_8) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* as calculated by [Rabbi Yechiel
    /// Michel Tucazinsky](https://en.wikipedia.org/wiki/Yechiel_Michel_Tucazinsky). It is based on of the position of
    /// the sun no later than 31 minutes after sunset in Jerusalem the height of the summer solstice and is 28 minutes
    /// after *shkiah* [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/). This computes to 6.45°
    /// below the western horizon.
    ///
    /// - ToDo: Additional documentation details needed.
    /// - Returns: the `Date` representing the time when the sun is 6.45° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z6_45`
    public func tzeisGeonim6Point45Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z6_45) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated when the sun's
    /// position 7.083° (or 7° 5\u2032) below the western horizon. This is often referred to as 7°5' or 7° and 5
    /// minutes. This calculation is based on the observation of 3 medium sized stars by Dr. Baruch (Berthold) Cohn in
    /// his *luach* [Tabellen enthaltend die Zeitangaben für den Beginn der Nacht und des Tages für die Breitengrade +
    /// 66 bis -38](https://sammlungen.ub.uni-frankfurt.de/freimann/content/titleinfo/983088) published in Strasbourg,
    /// France in 1899. This calendar was very popular in Europe, and many other calendars based their time on it. [Rav
    /// Dovid Tzvi Hoffman](https://en.wikipedia.org/wiki/David_Zvi_Hoffmann) in his [Sh"Ut Melamed
    /// Leho'il](https://hebrewbooks.org/1053) in an exchange of letters with Baruch Cohn in [Orach Chaim
    /// 30](https://hebrewbooks.org/pdfpager.aspx?req=1053&st=&pgnum=37) agreed to this *zman* (page 36), as did the
    /// Sh"Ut Bnei Tziyon and the Tenuvas Sadeh. It is very close to the time of the [Mekor
    /// Chesed](https://hebrewbooks.org/22044) of the Sefer chasidim. It is close to the position of the sun 30 minutes
    /// after sunset in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), but not Exactly. The actual
    /// position of the sun 30 minutes after sunset in Jerusalem at the equilux is 7.205° and 7.199° at the equinox. See
    /// Hazmanim Bahalacha vol 2, pages 520-521 for more details.
    ///
    /// - Returns: the `Date` representing the time when the sun is 7.083° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z7_083`
    public func tzeisGeonim7Point083Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z7_083) }

    /// This method returns *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 45 minutes after
    /// sunset during the summer solstice in New York, when the *neshef* (twilight) is the longest. The sun's position
    /// at this time computes to 7.75° below the western horizon. See [Igros Moshe Even Haezer 4, Ch.
    /// 4](https://hebrewbooks.org/pdfpager.aspx?req=921&pgnum=149) (regarding *tzais* for *krias Shema*). It is also
    /// mentioned in Rabbi Heber's [Shaarei Zmanim](https://hebrewbooks.org/53000) on in [chapter 10 (page
    /// 87)](https://hebrewbooks.org/pdfpager.aspx?req=53055&pgnum=101) and [chapter 12 (page
    /// 108)](https://hebrewbooks.org/pdfpager.aspx?req=53055&pgnum=122). Also see the time of 45 minutes in [Rabbi
    /// Simcha Bunim Cohen's](https://en.wikipedia.org/wiki/Simcha_Bunim_Cohen) [The radiance of
    /// Shabbos](https://www.worldcat.org/oclc/179728985) as the earliest *zman* for New York. This *zman* is also
    /// listed in the [Divrei Shalom Vol. III, chapter 75](https://hebrewbooks.org/pdfpager.aspx?req=1927&pgnum=90), and
    /// [Bais Av"i Vol. III, chapter 117](https://hebrewbooks.org/pdfpager.aspx?req=892&pgnum=431). This *zman* is also
    /// listed in the Divrei Shalom etc. chapter 177 (FIXME - could not be located). Since this *zman* depends on the
    /// level of light, Rabbi Yaakov Shakow presented this degree-based calculation to Rabbi [Rabbi Shmuel
    /// Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky) who agreed to it.
    ///
    /// - ToDo: add hyperlinks to source of Divrei Shalom.
    /// - Returns: the `Date` representing the time when the sun is 7.67° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z7_67`
    public func tzeisGeonim7Point67Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z7_67) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated at the sun's
    /// position at 8.5° below the western horizon.
    ///
    /// - Returns: the `Date` representing the time when the sun is 8.5° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z8_5`
    public func tzeisGeonim8Point5Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z8_5) }

    /// This method returns the *tzais* (nightfall) based on the calculations used in the [Luach Itim
    /// Lebinah](https://www.worldcat.org/oclc/243303103) as the stringent time for *tzais*. It is calculated at the
    /// sun's position at 9.3° below the western horizon.
    ///
    /// - Returns: the `Date` representing the time when the sun is 9.3° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func tzeisGeonim9Point3Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z9_3) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 60 minutes after
    /// sunset [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), the day that a solar hour
    /// is 60 minutes in New York. The sun's position at this time computes to 9.75° below the western horizon. This is
    /// the opinion of [Rabbi Eliyahu Henkin](https://en.wikipedia.org/wiki/Yosef_Eliyahu_Henkin). This also follows the
    /// opinion of [Rabbi Shmuel Kamenetsky](https://en.wikipedia.org/wiki/Shmuel_Kamenetsky). Rabbi Yaakov Shakow
    /// presented these degree-based times to Rabbi Shmuel Kamenetsky who agreed to them.
    ///
    /// - ToDo: recalculate based on equinox / equilux.
    /// - Returns: the `Date` representing the time when the sun is 9.75° below sea level. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeis60()`
    public func tzeisGeonim9Point75Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z9_75) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning) based on the calculation
    /// of *Chacham* Yosef Harari-Raful of Yeshivat Ateret Torah, that the day starts 1/10th of the day before sunrise
    /// and is usually calculated as ending 40 minutes after sunset (configurable to any offset via KosherJava's
    /// `setAteretTorahSunsetOffset()`). *shaos zmaniyos* are calculated based on this day and added to *alos* to reach
    /// this time. This time is 3 *shaos zmaniyos* (temporal hours) after *alos* 72 *zmaniyos*. **Note:** Based on this
    /// calculation *chatzos* will not be at midday.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema* based on this calculation. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`, `shaahZmanisAteretTorah()`
    public func latestShemaAteretTorah() -> Date? { calculateLatestZmanShema(alos72Zmanis(), tzeisAteretTorah()) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) based on the calculation of
    /// *Chacham* Yosef Harari-Raful of Yeshivat Ateret Torah, that the day starts 1/10th of the day before sunrise and
    /// is usually calculated as ending 40 minutes after sunset (configurable to any offset via KosherJava's
    /// `setAteretTorahSunsetOffset()`). *shaos zmaniyos* are calculated based on this day and added to *alos* to reach
    /// this time. This time is 4 * *shaos zmaniyos* (temporal hours) after *alos* 72 zmaniyos. **Note:** Based on this
    /// calculation *chatzos* will not be at midday.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema* based on this calculation. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`, `shaahZmanisAteretTorah()`
    public func latestTefilahAteretTorah() -> Date? { calculateLatestTefila(alos72Zmanis(), tzeisAteretTorah()) }

    /// This method returns the time of *mincha gedola* based on the calculation of *Chacham* Yosef Harari-Raful of
    /// Yeshivat Ateret Torah, that the day starts 1/10th of the day before sunrise and is usually calculated as ending
    /// 40 minutes after sunset (configurable to any offset via KosherJava's `setAteretTorahSunsetOffset()`). This is
    /// the preferred earliest time to pray *mincha* according to the opinion of the
    /// [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others. For more information on this see the
    /// documentation on *mincha gedola*. This is calculated as 6.5 solar hours after *alos*. The calculation used is
    /// 6.5 * `shaahZmanisAteretTorah()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`, `shaahZmanisAteretTorah()`, `calculateMinchaGedolah()`,
    ///   `minchaKetanaAteretTorah()`
    public func minchaGedolaAteretTorah() -> Date? { calculateMinchaGedolah(alos72Zmanis(), tzeisAteretTorah()) }

    /// This method returns the time of *mincha ketana* based on the calculation of *Chacham* Yosef Harari-Raful of
    /// Yeshivat Ateret Torah, that the day starts 1/10th of the day before sunrise and is usually calculated as ending
    /// 40 minutes after sunset (configurable to any offset via KosherJava's `setAteretTorahSunsetOffset()`). This is
    /// the preferred earliest time to pray *mincha* according to the opinion of the
    /// [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others. For more information on this see the
    /// documentation on *mincha gedola*. This is calculated as 9.5 solar hours after *alos*. The calculation used is
    /// 9.5 * `shaahZmanisAteretTorah()` after *alos*.
    ///
    /// - Returns: the `Date` of the time of *mincha ketana*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`, `shaahZmanisAteretTorah()`, `calculateMinchaGedolah()`,
    ///   `calculateMinchaKetana()`
    public func minchaKetanaAteretTorah() -> Date? { calculateMinchaKetana(alos72Zmanis(), tzeisAteretTorah()) }

    /// This method returns the time of *plag hamincha* based on the calculation of *Chacham* Yosef Harari-Raful of
    /// Yeshivat Ateret Torah, that the day starts 1/10th of the day before sunrise and is usually calculated as ending
    /// 40 minutes after sunset (configurable to any offset via KosherJava's `setAteretTorahSunsetOffset()`). *shaos
    /// zmaniyos* are calculated based on this day and added to *alos* to reach this time. This time is 10.75 *shaos
    /// zmaniyos* (temporal hours) after dawn.
    ///
    /// - Returns: the `Date` of the *plag*. If the calculation can't be computed such as in the Arctic Circle where
    ///   there is at least one day a year where the sun does not rise, and one where it does not set, nil will
    ///   be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`, `tzeisAteretTorah()`, `shaahZmanisAteretTorah()`
    public func plagHaminchaAteretTorah() -> Date? { calculatePlagHamincha(alos72Zmanis(), tzeisAteretTorah()) }

    /// Method to return *tzais* (dusk) calculated as 72 minutes zmaniyos, or 1/10th of the day after sea level sunset.
    /// This is the way that the [Minchas Cohen](https://en.wikipedia.org/wiki/Abraham_Cohen_Pimentel) in Ma'amar 2:4
    /// calculates Rebbeinu Tam's time of *tzeis*. It should be noted that this calculation results in the shortest time
    /// from sunset to *tzais* being during the winter solstice, the longest at the summer solstice and 72 clock minutes
    /// at the equinox. This does not match reality, since there is no direct relationship between the length of the day
    /// and twilight. The shortest twilight is during the equinox, the longest is during the the summer solstice, and in
    /// the winter with the shortest daylight, the twilight period is longer than during the equinoxes.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72Zmanis()`
    public func tzeis72Zmanis() -> Date? { zmanisBasedOffset(1.2) }

    /// Method to return *tzais* (dusk) calculated using 90 minutes zmaniyos or 1/8th of the day after sea level sunset.
    /// This time is known in Yiddish as the *achtel* (an eighth) *zman*.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos90Zmanis()`
    public func tzeis90Zmanis() -> Date? { zmanisBasedOffset(1.5) }

    /// Method to return *tzais* (dusk) calculated using 96 minutes *zmaniyos* or 1/7.5 of the day after sea level
    /// sunset.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos96Zmanis()`
    public func tzeis96Zmanis() -> Date? { zmanisBasedOffset(1.6) }

    /// Method to return *tzais* (dusk) calculated as 90 minutes after sea level sunset. This method returns *tzais*
    /// (nightfall) based on the opinion of the Magen Avraham that the time to walk the distance of a *Mil* according to
    /// the [Rambam](https://en.wikipedia.org/wiki/Maimonides)'s opinion is 18 minutes for a total of 90 minutes based
    /// on the opinion of Ula who calculated *tzais* as 5 *Mil* after sea level *shkiah* (sunset). A similar calculation
    /// `tzeis19Point8Degrees()` uses solar position calculations based on this time.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeis19Point8Degrees()`, `alos90()`
    public func tzeis90() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 90 * AstronomicalCalendar.minuteMillis) }

    /// This method should be used *lechumra* only and returns *tzais* (nightfall) based on the calculations of [Rav
    /// Chaim Naeh](https://en.wikipedia.org/wiki/Avraham_Chaim_Naeh) that the time to walk the distance of a *Mil*
    /// according to the [Rambam](https://en.wikipedia.org/wiki/Maimonides)'s opinion is 2/5 of an hour (24 minutes) for
    /// a total of 120 minutes based on the opinion of *Ula* who calculated *tzais* as 5 *Mil* after sea level *shkiah*
    /// (sunset). A similar calculation `tzeis26Degrees()` uses degree-based calculations based on this 120 minute
    /// calculation. Since the *zman* is extremely late and at a point that is long past the 18° point where the darkest
    /// point is reached, it should only be used *lechumra*, such as delaying the start of nighttime *mitzvos*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`. documentation.
    /// - SeeAlso: `tzeis26Degrees()`, `alos120()`
    public func tzeis120() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 120 * AstronomicalCalendar.minuteMillis) }

    /// This method should be used *lechumra* only and returns *tzais* (dusk) calculated using 120 minutes *zmaniyos*
    /// after sea level sunset. Since the *zman* is extremely late and at a point when the it is long past the 18° point
    /// where the darkest point is reached, it should only be used *lechumra*, such as delaying the start of nighttime
    /// *mitzvos*.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos120Zmanis()`, `tzeis120()`, `tzeis26Degrees()`
    public func tzeis120Zmanis() -> Date? { zmanisBasedOffset(2.0) }

    /// This calculates the time of *tzais* at the point when the sun is 16.1° below the horizon. This is the sun's dip
    /// below the horizon 72 minutes after sunset according Rabbeinu Tam's calculation of *tzais* [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) in Jerusalem. The question
    /// of equinox VS equilux is complex, with Rabbi Meir Posen in the [Ohr
    /// Meir](https://www.worldcat.org/oclc/956316270) of the opinion that the equilux should be used. See Yisrael
    /// Vehazmanim vol I, 34:1:4. Rabbi Yedidya Manet in his [Zmanei Halacha
    /// Lema'aseh](https://www.nli.org.il/en/books/NNL_ALEPH002542826/NLI) (4th edition part 2, pages and 22 and 24) and
    /// Rabbi Yonah Metzbuch (in a letter published by Rabbi Manet) are of the opinion that the astronomical equinox
    /// should be used. The difference adds up to about 9 seconds, too trivial to make much of a difference. For
    /// information on how this is calculated see the comments on `alos16Point1Degrees()`.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeis72()`, `alos16Point1Degrees()`
    public func tzeis16Point1Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z16_1) }

	/// This method should be used *lechumra* only and returns *tzais* based on when the sun is 26° below the
	/// horizon.For information on how this is calculated see the comments on `alos26Degrees()`. Since the *zman* is
	/// extremely late and at a point when it is long past the 18° point where the darkest point is reached, it should
	/// only be used *lechumra* such as delaying the start of nighttime *mitzvos*.
	///
	/// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very late
	///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
	///   no current plan to remove this method from the API, and this deprecation
	///   is intended to alert developers of the danger of using it.
	/// - Returns: the `Date` representing the time. If the calculation can't be computed such as northern and southern
	///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
	///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
	///   explanation on top of the `AstronomicalCalendar` documentation.
	/// - SeeAlso: `tzeis120()`, `alos26Degrees()`
	public func tzeis26Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z26Deg) }

    /// For information on how this is calculated see the comments on `alos18Degrees()`
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos18Degrees()`
    public func tzeis18Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .astronomical) }

    /// This method returns the latest *zman tfila* (time to recite the morning prayers) calculated as 2 hours before
    /// `chatzos()`. This is based on the opinions that calculate *sof zman krias shema* as
    /// `latestShema3HoursBeforeChatzos()`. This returns the time of 2 hours before `chatzos()`.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `chatzos()`, `latestShema3HoursBeforeChatzos()`
    public func latestTefila2HoursBeforeChatzos() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: -120 * AstronomicalCalendar.minuteMillis) }

    /// This method returns *mincha gedola* calculated as 30 minutes after *chatzos* and not 1/2 of a *shaah zmanis*
    /// after *chatzos* as calculated by `calculateMinchaGedolah()`. Some use this time to delay the start of *mincha*
    /// in the winter when 1/2 of a *shaah zmanis* is less than 30 minutes. See `minchaGedolaGreaterThan30()` for a
    /// convenience method that returns the later of the 2 calculations. One should not use this time to start *mincha*
    /// before the standard *mincha gedola*. See Shulchan Aruch [Orach Chayim
    /// 234:1](https://hebrewbooks.org/pdfpager.aspx?req=49624&st=&pgnum=291) and the Shaar Hatziyon *seif katan ches*.
    ///
    /// - Returns: the `Date` of 30 minutes after *chatzos*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaGedolah()`, `minchaGedolaGreaterThan30()`
    public func minchaGedola30Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: chatzos(), offset: 30 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the time of *plag hamincha* based on the opinion that the day starts at *alos* 16.1° and
    /// ends at *tzais*. 10.75 *shaos zmaniyos* are calculated based on this day and added to *alos* to reach this time.
    /// This time is 10.75 *shaos zmaniyos* (temporal hours) after dawn based on the opinion that the day is calculated
    /// from a dawn of 16.1 degrees before sunrise to *tzais* . This returns the time of 10.75 * the calculated *shaah
    /// zmanis* after dawn.
    ///
    /// - Returns: the `Date` of the *plag*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `tzeisGeonim7Point083Degrees()`
    public func plagAlos16Point1ToTzeisGeonim7Point083Degrees()  -> Date? { calculatePlagHamincha(alos16Point1Degrees(), tzeisGeonim7Point083Degrees()) }

    /// Method to return the beginning of *bain hashmashos* of Rabbeinu Tam calculated when the sun is 13.24° below the
    /// western geometric horizon (90°) after sunset. This calculation is based on the same calculation of *bain
    /// hashmashos* Rabbeinu Tam 58.5 minutes but uses a degree-based calculation instead of 58.5 exact minutes. This
    /// calculation is based on the position of the sun 58.5 minutes after sunset in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 13.24°
    /// below geometric zenith. NOTE: As per Yisrael Vehazmanim Vol. III page 1028, No. 50, a dip of slightly less than
    /// 13° should be used. Calculations show that the proper dip to be 13.2456° (truncated to 13.24 that provides about
    /// 1.5 second earlier (*lechumra*) time) below the horizon at that time. This makes a difference of 1 minute and 10
    /// seconds in Jerusalem during the Equinox, and 1 minute 29 seconds during the solstice as compared to the proper
    /// 13.24° versus 13°. For NY during the solstice, the difference is 1 minute 56 seconds.
    ///
    /// - ToDo: recalculate the above based on equilux/equinox calculations.
    /// - Returns: the `Date` of the sun being 13.24° below geometric zenith (90°). If the calculation can't be computed
    ///   such as northern and southern locations even south of the Arctic Circle and north of the Antarctic
    ///   Circle where the sun may not reach low enough below the horizon for this calculation, nil will be
    ///   returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z13_24`, `beinHashmashosRT58Point5Minutes()`
    public func beinHashmashosRT13Point24Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z13_24) }

    /// This method returns the beginning of *Bain hashmashos* of Rabbeinu Tam calculated as a 58.5 minute offset after
    /// sunset. *bain hashmashos* is 3/4 of a *Mil* before *tzais* or 3 1/4 *Mil* after sunset. With a *Mil* calculated
    /// as 18 minutes, 3.25 * 18 = 58.5 minutes.
    ///
    /// - Returns: the `Date` of 58.5 minutes after sunset. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    public func beinHashmashosRT58Point5Minutes()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 58.5 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the beginning of *bain hashmashos* based on the calculation of 13.5 minutes (3/4 of an
    /// 18-minute *Mil*) before *shkiah* calculated as 7.083°.
    ///
    /// - Returns: the `Date` of the *bain hashmashos* of Rabbeinu Tam in this calculation. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeisGeonim7Point083Degrees()`
    public func beinHashmashosRT13Point5MinutesBefore7Point083Degrees()  -> Date? { AstronomicalCalendar.getTimeOffset(time: getSunsetOffsetByDegrees(offsetZenith: .z7_083), offset: -13.5 * AstronomicalCalendar.minuteMillis) }
    
    /// This method returns the beginning of *bain hashmashos* of Rabbeinu Tam calculated according to the opinion of
    /// the *Divrei Yosef* (see Yisrael Vehazmanim) calculated 5/18th (27.77%) of the time between *alos* (calculated as
    /// 19.8° before sunrise) and sunrise. This is added to sunset to arrive at the time for *bain hashmashos* of
    /// Rabbeinu Tam.
    ///
    /// - Returns: the `Date` of *bain hashmashos* of Rabbeinu Tam for this calculation. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func beinHashmashosRT2Stars() -> Date? {
        guard let alos19Point8 = alos19Point8Degrees(), let b = elevationAdjustedSunrise else { return nil }
        let offset = ((b - alos19Point8) * 1000) * (5 / 18)
        return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: offset)
    }
    
    /// This method returns *tzais* usually calculated as 40 minutes (configurable to any offset via KosherJava's
    /// `setAteretTorahSunsetOffset()`) after sunset. Please note that *Chacham* Yosef Harari-Raful of Yeshivat Ateret
    /// Torah who uses this time, does so only for calculating various other *zmanai hayom* such as *Sof Zman Krias
    /// Shema* and *Plag Hamincha*. His calendars do not publish a *zman* for *Tzais*. It should also be noted that
    /// *Chacham* Harari-Raful provided a 25 minute *zman* for Israel. This API uses 40 minutes year round in any place
    /// on the globe by default. This offset can be change by calling KosherJava's `setAteretTorahSunsetOffset()`.
    ///
    /// - Returns: the `Date` representing 40 minutes (configurable via KosherJava's `setAteretTorahSunsetOffset`) after
    ///   sea level sunset. If the calculation can't be computed such as in the Arctic Circle where there is at
    ///   least one day a year where the sun does not rise, and one where it does not set, nil will be
    ///   returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func tzeisAteretTorah() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: ComplexZmanimCalendar.ateretTorahSunsetOffset * AstronomicalCalendar.minuteMillis) }
    
    /// This method returns the beginning of *bain hashmashos* (twilight) according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 18 minutes or 3/4 of a 24-minute *Mil*
    /// before sunset. According to the Yereim, *bain hashmashos* starts 3/4 of a *Mil* before sunset and *tzais* or
    /// nightfall starts at sunset.
    ///
    /// - Returns: the `Date` of 18 minutes before sunset. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `beinHashmashosYereim3Point5Degrees()`
    public func beinHashmashosYereim18Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -18 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the beginning of *bain hashmashos* (twilight) according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 3.05° above the
    /// horizon [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), its position 18 minutes or
    /// 3/4 of an 24-minute *mil* before sunset. According to the Yereim, *bain hashmashos* starts 3/4 of a *Mil* before
    /// sunset and *tzais* or nightfall starts at sunset. Note that *lechumra* (of about 14 seconds) a refraction value
    /// of 0.5166° as opposed to the traditional 0.566° is used. This is more inline with the actual refraction in
    /// *Eretz Yisrael* and is brought down by [Rabbi Yedidya
    /// Manet](http://beinenu.com/rabbis/%D7%94%D7%A8%D7%91-%D7%99%D7%93%D7%99%D7%93%D7%99%D7%94-%D7%9E%D7%A0%D7%AA) in
    /// his [Zmanei Halacha Lema’aseh](https://www.nli.org.il/en/books/NNL_ALEPH002542826/NLI) (p. 11). That is the
    /// first source that I am aware of that calculates degree-based Yereim *zmanim*. The 0.5166° refraction is also
    /// used by the [Luach Itim Lebinah](https://zmanim.online/). Calculating the Yereim's *bain hashmashos* using
    /// 18-minute based degrees is also suggested in the upcoming 8th edition of the zmanim Kehilchasam. For more
    /// details, see the article [The Yereim’s *Bein
    /// Hashmashos*](https://kosherjava.com/2020/12/07/the-yereims-bein-hashmashos/).
    ///
    /// - ToDo: recalculate based on equinox/equilux
    /// - Returns: the `Date` of the sun's position 3.05° minutes before sunset. If the calculation can't be computed
    ///   such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and
    ///   one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.zMinus3_05`, `beinHashmashosYereim18Minutes()`, `beinHashmashosYereim2Point8Degrees()`,
    ///   `beinHashmashosYereim2Point1Degrees()`
    public func beinHashmashosYereim3Point5Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus3_05) }

    /// This method returns the beginning of *bain hashmashos* (twilight) according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 16.875 minutes or 3/4 of a 22.5-minute
    /// *Mil* before sunset. According to the Yereim, *bain hashmashos* starts 3/4 of a *Mil* before sunset and *tzais*
    /// or nightfall starts at sunset.
    ///
    /// - Returns: the `Date` of 16.875 minutes before sunset. If the calculation can't be computed such as in the
    ///   Arctic Circle where there is at least one day a year where the sun does not rise, and one where it
    ///   does not set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `beinHashmashosYereim2Point8Degrees()`
    public func beinHashmashosYereim16Point875Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -16.875 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the beginning of *bain hashmashos* (twilight) according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 2.8° above the horizon
    /// [around the equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), its
    /// position 16.875 minutes or 3/4 of an 18-minute *Mil* before sunset. According to the Yereim, *bain hashmashos*
    /// starts 3/4 of a *Mil* before sunset and *tzais* or nightfall starts at sunset. Details, including how the
    /// degrees were calculated can be seen in the documentation of `beinHashmashosYereim3Point5Degrees()`.
    ///
    /// - Returns: the `Date` of the sun's position 2.8° minutes before sunset. If the calculation can't be computed
    ///   such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and
    ///   one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.zMinus2_8`, `beinHashmashosYereim16Point875Minutes()`,
    ///   `beinHashmashosYereim3Point5Degrees()`, `beinHashmashosYereim2Point1Degrees()`
    public func beinHashmashosYereim2Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus2_8) }

    /// This method returns the beginning of *bain hashmashos* (twilight) according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as 13.5 minutes or 3/4 of an 18-minute *Mil*
    /// before sunset. According to the Yereim, *bain hashmashos* starts 3/4 of a *Mil* before sunset and *tzais* or
    /// nightfall starts at sunset.
    ///
    /// - Returns: the `Date` of 13.5 minutes before sunset. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `beinHashmashosYereim2Point1Degrees()`
    public func beinHashmashosYereim13Point5Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: -13.5 * AstronomicalCalendar.minuteMillis) }

    /// This method returns the beginning of *bain hashmashos* according to the [Yereim (Rabbi Eliezer of
    /// Metz)](https://en.wikipedia.org/wiki/Eliezer_ben_Samuel) calculated as the sun's position 2.1° above the horizon
    /// [around the equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) in
    /// Yerushalayim, its position 13.5 minutes or 3/4 of an 18-minute *Mil* before sunset. According to the Yereim,
    /// *bain hashmashos* starts 3/4 of a *mil* before sunset and *tzais* or nightfall starts at sunset. Details,
    /// including how the degrees were calculated can be seen in the documentation of
    /// `beinHashmashosYereim3Point5Degrees()`.
    ///
    /// - Returns: the `Date` of the sun's position 2.1° minutes before sunset. If the calculation can't be computed
    ///   such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and
    ///   one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.zMinus2_1`, `beinHashmashosYereim13Point5Minutes()`, `beinHashmashosYereim2Point8Degrees()`,
    ///   `beinHashmashosYereim3Point5Degrees()`
    public func beinHashmashosYereim2Point1Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .zMinus2_1)}

    /// This method returns the *tzais* (nightfall) based on the opinion of the [Chavas
    /// Yair](https://en.wikipedia.org/wiki/Yair_Bacharach) and [Divrei
    /// Malkiel](https://he.wikipedia.org/wiki/%D7%9E%D7%9C%D7%9B%D7%99%D7%90%D7%9C_%D7%A6%D7%91%D7%99_%D7%98%D7%A0%D7%A0%D7%91%D7%95%D7%99%D7%9D)
    /// that the time to walk the distance of a *Mil* is 15 minutes for a total of 60 minutes for 4 *Mil* after sea
    /// level sunset. See detailed documentation explaining the 60 minute concept at `alos60()`.
    ///
    /// - Returns: the `Date` representing 60 minutes after sea level sunset. If the calculation can't be computed such
    ///   as in the Arctic Circle where there is at least one day a year where the sun does not rise, and one
    ///   where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos60()`, `plagHamincha60Minutes()`, `shaahZmanis60Minutes()`
    public func tzeis60()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 60 * AstronomicalCalendar.minuteMillis) }

    /// For information on how this is calculated see the comments on `alos19Point8Degrees()`
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `tzeis90()`, `alos19Point8Degrees()`
    public func tzeis19Point8Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z19_8) }

    /// A method to return *tzais* (dusk) calculated as 96 minutes after sea level sunset. For information on how this
    /// is calculated see the comments on `alos96()`.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos96()`
    public func tzeis96()  -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 96 * AstronomicalCalendar.minuteMillis) }

	/// This method returns the latest time one is allowed eating *chametz* on *Erev Pesach* according to the opinion of
	/// the[GRA](https://en.wikipedia.org/wiki/Vilna_Gaon). This time is identical to the *Sof zman tfilah* GRA and is
	/// provided as a convenience method for those who are unaware how this *zman* is calculated. This time is 4 hours
	/// into the day based on the opinion of the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that the day is
	/// calculated from sunrise to sunset. This returns the time 4 * `shaahZmanisGra()` after sea level sunrise.
	///
	/// - Returns: the `Date` one is allowed eating *chametz* on *Erev Pesach*. If the calculation can't be computed
	///   such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and
	///   one where it does not set, nil will be returned. See detailed explanation on top of the
	///   `AstronomicalCalendar` documentation.
	/// - SeeAlso: `shaahZmanisGra()`, `latestTefilaGra()`
	public func latestAchilasChametzGRA()  -> Date? { isErevPesach ? latestTefilaGra() : nil }

	/// This method returns the latest time one is allowed eating *chametz* on *Erev Pesach* according to the opinion of
	/// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes
	/// before sunrise. This time is identical to the *Sof zman tfilah* MGA 72 minutes. This time is 4 *shaos zmaniyos*
	/// (temporal hours) after dawn based on the opinion of the MGA that the day is calculated from a dawn of 72 minutes
	/// before sunrise to nightfall of 72 minutes after sunset. This returns the time of 4 * `shaahZmanisMga()` after
	/// dawn.
	///
	/// - Returns: the `Date` of the latest time of eating *chametz*. If the calculation can't be computed such as in
	///   the Arctic Circle where there is at least one day a year where the sun does not rise, and one where
	///   it does not set), nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
	///   documentation.
	/// - SeeAlso: `shaahZmanisMga()`, `alos72()`, `latestTefilaMGA72Minutes()`
	public func latestAchilasChametzMGA72Minutes() -> Date? { isErevPesach ? latestTefilaMGA72Minutes() : nil }

	/// This method returns the latest time one is allowed eating *chametz* on *Erev Pesach* according to the opinion of
	/// the[Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 16.1° before
	/// sunrise. This time is 4 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
	/// is calculated from dawn to nightfall with both being 16.1° below sunrise or sunset. This returns the time of 4
	/// `shaahZmanis16Point1Degrees()` after dawn.
	///
	/// - Returns: the `Date` of the latest time of eating *chametz*. If the calculation can't be computed such as
	///   northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
	///   where the sun may not reach low enough below the horizon for this calculation, nil will be returned.
	///   See detailed explanation on top of the `AstronomicalCalendar` documentation.
	/// - SeeAlso: `shaahZmanis16Point1Degrees()`, `alos16Point1Degrees()`, `latestTefilaMGA16Point1Degrees()`
	public func latestAchilasChametzMGA16Point1Degrees() -> Date? { isErevPesach ? latestTefilaMGA16Point1Degrees() : nil }

	/// This method returns the latest time for burning *chametz* on *Erev Pesach* according to the opinion of the
	/// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon). This time is 5 hours into the day based on the opinion of the
	/// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that the day is calculated from sunrise to sunset. This returns
	/// the time 5 * `shaahZmanisGra()` after sea level sunrise.
	///
	/// - Returns: the `Date` of the latest time for burning *chametz* on *Erev Pesach*. If the calculation can't be
	///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
	///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
	///   `AstronomicalCalendar` documentation.
	/// - SeeAlso: `shaahZmanisGra()`
	public func latestBiurChametzGRA()  -> Date? { isErevPesach ? AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: shaahZmanisGra() != nil ? shaahZmanisGra()! * 5 : nil) : nil }

    /// This method returns the latest time for burning *chametz* on *Erev Pesach* according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 72 minutes before
    /// sunrise. This time is 5 *shaos zmaniyos* (temporal hours) after dawn based on the opinion of the MGA that the
    /// day is calculated from a dawn of 72 minutes before sunrise to nightfall of 72 minutes after sunset. This returns
    /// the time of 5 * `shaahZmanisMga()` after dawn.
    ///
    /// - Returns: the `Date` of the latest time for burning *chametz* on *Erev Pesach*. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set), nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisMga()`, `alos72()`
    public func latestBiurChametzMGA72Minutes()  -> Date? {
		isErevPesach ? AstronomicalCalendar.getTimeOffset(time: alos72(), offset: shaahZmanisMga() != nil ? shaahZmanisMga()! * 5 : nil) : nil }

    /// This method returns the latest time for burning *chametz* on *Erev Pesach* according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) based on *alos* being 16.1° before
    /// sunrise. This time is 5 *shaos zmaniyos* (solar hours) after dawn based on the opinion of the MGA that the day
    /// is calculated from dawn to nightfall with both being 16.1° below sunrise or sunset. This returns the time of 5
    /// `shaahZmanis16Point1Degrees()` after dawn.
    ///
    /// - Returns: the `Date` of the latest time for burning *chametz* on *Erev Pesach*. If the calculation can't be
    ///   computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, nil
    ///   will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`, `alos16Point1Degrees()`
    public func latestBiurChametzMGA16Point1Degrees()  -> Date? { isErevPesach ? AstronomicalCalendar.getTimeOffset(time: alos16Point1Degrees(), offset: shaahZmanis16Point1Degrees() != nil ? shaahZmanis16Point1Degrees()! * 5 : nil) : nil }

    /// A method that returns the [Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)'s *netz amiti*
    /// (sunrise) without elevation adjustment. This forms the base for the Baal Hatanya's dawn-based calculations that
    /// are calculated as a dip below the horizon before sunrise. According to the Baal Hatanya, *netz amiti*, or true
    /// (halachic) sunrise, is when the top of the sun's disk is visible at an elevation similar to the mountains of
    /// Eretz Yisrael. The time is calculated as the point at which the center of the sun's disk is 1.583° below the
    /// horizon. This degree-based calculation can be found in Rabbi Shalom DovBer Levine's commentary on The [Baal
    /// Hatanya's Seder Hachnasas Shabbos](https://www.chabadlibrary.org/books/pdf/Seder-Hachnosas-Shabbos.pdf). From an
    /// elevation of 546 meters, the top of [Har Hacarmel](https://en.wikipedia.org/wiki/Mount_Carmel), the sun
    /// disappears when it is 1° 35' or 1.583° below the sea level horizon. This in turn is based on the Gemara [Shabbos
    /// 35a](https://hebrewbooks.org/shas.aspx?mesechta=2&daf=35). There are other opinions brought down by Rabbi
    /// Levine, including Rabbi Yosef Yitzchok Feigelstock who calculates it as the degrees below the horizon 4 minutes
    /// after sunset in Yerushalayim (on the equinox). That is brought down as 1.583°. This is identical to the 1° 35'
    /// *zman* and is probably a typo and should be 1.683°. These calculations are used by most
    /// [Chabad](https://en.wikipedia.org/wiki/Chabad) calendars that use the Baal Hatanya's *zmanim*. See [About Our
    /// *Zmanim* Calculations @
    /// Chabad.org](https://www.chabad.org/library/article_cdo/aid/3209349/jewish/About-Our-Zmanim-Calculations.htm).
    /// Note: *netz amiti* is used only for calculating certain *zmanim*, and is intentionally unpublished. For
    /// practical purposes, daytime *mitzvos* like *shofar* and *lulav* should not be done until after the published
    /// time for *netz* / sunrise.
    ///
    /// - Returns: the `Date` representing the exact sea-level *netz amiti* (sunrise) time. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   page.
    /// - SeeAlso: `sunrise`, `seaLevelSunrise`, `sunsetBaalHatanya()`, `Zenith.z1_583`
    public func sunriseBaalHatanya() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z1_583) }

    /// A method that returns the [Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)'s *shkiah amiti*
    /// (sunset) without elevation adjustment. This forms the base for the Baal Hatanya's dusk-based calculations that
    /// are calculated as a dip below the horizon after sunset. According to the Baal Hatanya, *shkiah amiti*, true
    /// (*halachic*) sunset, is when the top of the sun's disk disappears from view at an elevation similar to the
    /// mountains of *Eretz Yisrael*. This time is calculated as the point at which the center of the sun's disk is
    /// 1.583 degrees below the horizon. Note: *shkiah amiti* is used only for calculating certain *zmanim*, and is
    /// intentionally unpublished. For practical purposes, all daytime mitzvos should be completed before the published
    /// time for *shkiah* / sunset. For further explanation of the calculations used for the Baal Hatanya's *zmanim* in
    /// this library, see [About Our *Zmanim* Calculations @
    /// Chabad.org](https://www.chabad.org/library/article_cdo/aid/3209349/jewish/About-Our-Zmanim-Calculations.htm).
    ///
    /// - Returns: the `Date` representing the exact sea-level *shkiah amiti* (sunset) time. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `sunset`, `seaLevelSunset`, `sunriseBaalHatanya()`, `Zenith.z1_583`
    public func sunsetBaalHatanya() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z1_583) }

    /// A method that returns the [Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)'s a *shaah
    /// zmanis* (`getTemporalHour()`). This forms the base for the Baal Hatanya's day based calculations that are
    /// calculated as a 1.583° dip below the horizon after sunset. According to the Baal Hatanya, *shkiah amiti*, true
    /// (halachic) sunset, is when the top of the sun's disk disappears from view at an elevation similar to the
    /// mountains of Eretz Yisrael. This time is calculated as the point at which the center of the sun's disk is 1.583
    /// degrees below the horizon. A method that returns a *shaah zmanis* (`getTemporalHour()`) calculated based on the
    /// [Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)'s *netz amiti* and *shkiah amiti* using a
    /// dip of 1.583° below the sea level horizon. This calculation divides the day based on the opinion of the Baal
    /// Hatanya that the day runs from netz amiti to *shkiah amiti*. The calculations are based on a day from sea level
    /// *netz amiti* to sea level *shkiah amiti*. The day is split into 12 equal parts with each one being a *shaah
    /// zmanis*. This method is similar to `getTemporalHour()`, but all calculations are based on a sea level sunrise
    /// and sunset.
    ///
    /// - Returns: the millisecond length of a *shaah zmanis* calculated from *netz amiti* (sunrise) to *shkiah amiti*
    ///   ("real" sunset). If the calculation can't be computed such as in the Arctic Circle where there is at
    ///   least one day a year where the sun does not rise, and one where it does not set, `MIN_VALUE` will be
    ///   returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `getTemporalHour()`, `sunriseBaalHatanya()`, `sunsetBaalHatanya()`, `Zenith.z1_583`
    public func shaahZmanisBaalHatanya() -> Double? { getTemporalHour(dayStart: sunriseBaalHatanya(), dayEnd: sunsetBaalHatanya()) }

    /// Returns the [Baal Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi)'s *alos* (dawn) calculated as
    /// the time when the sun is 16.9° below the eastern geometric horizon before sunrise. For more information the
    /// source of 16.9° see `Zenith.z16_9`.
    ///
    /// - Returns: The `Date` of dawn. If the calculation can't be computed such as northern and southern locations even
    ///   south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach low enough
    ///   below the horizon for this calculation, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z16_9`
    public func alosBaalHatanya() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z16_9) }

    /// This method returns the latest *zman krias shema* (time to recite Shema in the morning). This time is 3 *shaos
    /// zmaniyos* (solar hours) after *netz amiti* (sunrise) based on the opinion of the Baal Hatanya that the day is
    /// calculated from sunrise to sunset. This returns the time 3 * `shaahZmanisBaalHatanya()` after *netz amiti*
    /// (sunrise).
    ///
    /// - Returns: the `Date` of the latest *zman shema* according to the Baal Hatanya. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `calculateLatestZmanShema()`, `shaahZmanisBaalHatanya()`
    public func latestShemaBaalHatanya() -> Date? { calculateLatestZmanShema(sunriseBaalHatanya(), sunsetBaalHatanya()) }

    /// This method returns the latest *zman tfilah* (time to recite the morning prayers). This time is 4 hours into the
    /// day based on the opinion of the Baal Hatanya that the day is calculated from sunrise to sunset. This returns the
    /// time 4 * `shaahZmanisBaalHatanya()` after *netz amiti* (sunrise).
    ///
    /// - Returns: the `Date` of the latest *zman tfilah*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateLatestTefila()`, `shaahZmanisBaalHatanya()`
    public func latestTefilaBaalHatanya() -> Date? { calculateLatestTefila(sunriseBaalHatanya(), sunsetBaalHatanya()) }

	/// This method returns the latest time one is allowed eating *chametz* on *Erev Pesach* according to the opinion of
	/// the Baal Hatanya. This time is identical to the *Sof zman tfilah* Baal Hatanya. This time is 4 hours into the
	/// day based on the opinion of the Baal Hatanya that the day is calculated from sunrise to sunset. This returns the
	/// time 4 `shaahZmanisBaalHatanya()` after *netz amiti* (sunrise).
	///
	/// - Returns: the `Date` one is allowed eating *chametz* on *Erev Pesach*. If the calculation can't be computed
	///   such as in the Arctic Circle where there is at least one day a year where the sun does not rise, and
	///   one where it does not set, nil will be returned. See detailed explanation on top of the
	///   `AstronomicalCalendar` documentation.
	/// - SeeAlso: `shaahZmanisBaalHatanya()`, `latestTefilaBaalHatanya()`
	public func latestAchilasChametzBaalHatanya() -> Date? {isErevPesach ? latestTefilaBaalHatanya() : nil}

	/// This method returns the latest time for burning *chametz* on *Erev Pesach* according to the opinion of the Baal
	/// Hatanya. This time is 5 hours into the day based on the opinion of the Baal Hatanya that the day is calculated
	/// from sunrise to sunset. This returns the time 5 * `shaahZmanisBaalHatanya()` after *netz amiti* (sunrise).
	///
	/// - Returns: the `Date` of the latest time for burning *chametz* on *Erev Pesach*. If the calculation can't be
	///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
	///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
	///   `AstronomicalCalendar` documentation.
	/// - SeeAlso: `shaahZmanisBaalHatanya()`
	public func latestBiurChametzBaalHatanya()  -> Date? {
		isErevPesach ? AstronomicalCalendar.getTimeOffset(time: sunriseBaalHatanya(), offset: shaahZmanisBaalHatanya() != nil ?  shaahZmanisBaalHatanya()! * 5 : nil) : nil
	}

    /// This method returns the time of *mincha gedola*. *Mincha gedola* is the earliest time one can pray *mincha*. The
    /// [Rambam](https://en.wikipedia.org/wiki/Maimonides) is of the opinion that it is better to delay *mincha* until
    /// *mincha ketana* while the [Ra"sh](https://en.wikipedia.org/wiki/Asher_ben_Jehiel),
    /// [Tur](https://en.wikipedia.org/wiki/Jacob_ben_Asher), [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) and others
    /// are of the opinion that *mincha* can be prayed *lechatchila* starting at *mincha gedola*. This is calculated as
    /// 6.5 sea level solar hours after *netz amiti* (sunrise). This calculation is based on the opinion of the Baal
    /// Hatanya that the day is calculated from sunrise to sunset. This returns the time 6.5 *
    /// `shaahZmanisBaalHatanya()` after *netz amiti* ("real" sunrise).
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaGedolah()`, `shaahZmanisBaalHatanya()`, `minchaKetanaBaalHatanya()`
    public func minchaGedolaBaalHatanya() -> Date? { calculateMinchaGedolah(sunriseBaalHatanya(), sunsetBaalHatanya()) }

    /// This is a convenience method that returns the later of `minchaGedolaBaalHatanya()` and
    /// `minchaGedola30Minutes()`. In the winter when 1/2 of a *shaah zmanis* is less than 30 minutes
    /// `minchaGedola30Minutes()` will be returned, otherwise `minchaGedolaBaalHatanya()` will be returned.
    ///
    /// - Returns: the `Date` of the later of `minchaGedolaBaalHatanya()` and `minchaGedola30Minutes()`. If the
    ///   calculation can't be computed such as in the Arctic Circle where there is at least one day a year
    ///   where the sun does not rise, and one where it does not set, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    public func minchaGedolaBaalHatanyaGreaterThan30() -> Date? {
        guard let a = minchaGedola30Minutes(), let b = minchaGedolaBaalHatanya() else { return nil }
        return a > b ? a : b
    }

    /// This method returns the time of *mincha ketana*. This is the preferred earliest time to pray *mincha* in the
    /// opinion of the [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others. For more information on this see
    /// the documentation on *mincha gedola*. This is calculated as 9.5 sea level solar hours after *netz amiti*
    /// (sunrise). This calculation is calculated based on the opinion of the Baal Hatanya that the day is calculated
    /// from sunrise to sunset. This returns the time 9.5 * `shaahZmanisBaalHatanya()` after *netz amiti* (sunrise).
    ///
    /// - Returns: the `Date` of the time of *mincha ketana*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaKetana()`, `shaahZmanisBaalHatanya()`, `minchaGedolaBaalHatanya()`
    public func minchaKetanaBaalHatanya() -> Date? { calculateMinchaKetana(sunriseBaalHatanya(), sunsetBaalHatanya()) }

    /// This method returns the time of *plag hamincha*. This is calculated as 10.75 hours after sunrise. This
    /// calculation is based on the opinion of the Baal Hatanya that the day is calculated from sunrise to sunset. This
    /// returns the time 10.75 * `shaahZmanisBaalHatanya()` after *netz amiti* (sunrise).
    ///
    /// - Returns: the `Date` of the time of *plag hamincha*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculatePlagHamincha()`
    public func plagHaminchaBaalHatanya() -> Date? { calculatePlagHamincha(sunriseBaalHatanya(), sunsetBaalHatanya()) }

    /// A method that returns *tzais* (nightfall) when the sun is 6° below the western geometric horizon (90°) after
    /// sunset. For information on the source of this calculation see `ZENITH_6_DEGREES`.
    ///
    /// - Returns: The `Date` of nightfall. If the calculation can't be computed such as northern and southern locations
    ///   even south of the Arctic Circle and north of the Antarctic Circle where the sun may not reach low
    ///   enough below the horizon for this calculation, nil will be returned. See detailed explanation on top
    ///   of the `AstronomicalCalendar` documentation.
    public func tzeisBaalHatanya()  -> Date? { getSunsetOffsetByDegrees(offsetZenith: .civil) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman krias shema* (latest time to recite *Shema* in the morning) according to the opinion of
    /// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day is calculated from dawn
    /// to nightfall, but calculated using the first half of the day only. The half a day starts at *alos* defined as
    /// 18° and ends at fixed local chatzos. *Sof Zman Shema* is 3 *shaos zmaniyos* (solar hours) after *alos* or half
    /// of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos18Degrees()`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestShemaMGA18DegreesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos18Degrees(), getFixedLocalChatzos(), 3) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman krias shema* (latest time to recite *Shema* in the morning) according to the opinion of
    /// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day is calculated from dawn
    /// to nightfall, but calculated using the first half of the day only. The half a day starts at *alos* defined as
    /// 16.1° and ends at fixed local chatzos. *Sof Zman Shema* is 3 *shaos zmaniyos* (solar hours) after this *alos* or
    /// half of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos16Point1Degrees()`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestShemaMGA16Point1DegreesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos16Point1Degrees(), getFixedLocalChatzos(), 3)}

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman krias shema* (latest time to recite *Shema* in the morning) according to the opinion of
    /// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day is calculated from dawn
    /// to nightfall, but calculated using the first half of the day only. The half a day starts at *alos* defined as 90
    /// minutes before sunrise and ends at fixed local chatzos. *Sof Zman Shema* is 3 *shaos zmaniyos* (solar hours)
    /// after this *alos* or half of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos90()`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestShemaMGA90MinutesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos90(), getFixedLocalChatzos(), 3)}

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman krias shema* (latest time to recite *Shema* in the morning) according to the opinion of
    /// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombinern) that the day is calculated from dawn
    /// to nightfall, but calculated using the first half of the day only. The half a day starts at *alos* defined as 72
    /// minutes before sunrise and ends at fixed local chatzos. *Sof Zman Shema* is 3 *shaos zmaniyos* (solar hours)
    /// after this *alos* or half of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `alos72()`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestShemaMGA72MinutesToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(alos72(), getFixedLocalChatzos(), 3)}

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman krias shema* (latest time to recite *Shema* in the morning) according to the opinion of
    /// the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that the day is calculated from sunrise to sunset, but
    /// calculated using the first half of the day only. The half a day starts at sunrise and ends at fixed local
    /// chatzos. *Sof zman Shema* is 3 *shaos zmaniyos* (solar hours) after sunrise or half of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `sunrise`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestShemaGRASunriseToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(sunrise, getFixedLocalChatzos(), 3) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *sof zman tfila* (*zman tfilah* (the latest time to recite the morning prayers)) according to the
    /// opinion of the [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that the day is calculated from sunrise to
    /// sunset, but calculated using the first half of the day only. The half a day starts at sunrise and ends at fixed
    /// local chatzos. *Sof zman tefila* is 4 *shaos zmaniyos* (solar hours) after sunrise or 2/3 of this half-day.
    ///
    /// - Returns: the `Date` of the latest *zman krias shema*. If the calculation can't be computed such as northern
    ///   and southern locations even south of the Arctic Circle and north of the Antarctic Circle where the
    ///   sun may not reach low enough below the horizon for this calculation, nil will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `sunrise`, `getFixedLocalChatzos()`, `getFixedLocalChatzosBasedZmanim()`
    public func latestTefilaGRASunriseToFixedLocalChatzos() -> Date? { getFixedLocalChatzosBasedZmanim(sunrise, getFixedLocalChatzos(), 4) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *mincha gedola*, the earliest time one can pray *mincha*
    /// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon)that is 30 minutes after fixed local chatzos.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaGedolah()`, `getFixedLocalChatzos()`, `minchaKetanaGRAFixedLocalChatzosToSunset()`
    public func minchaGedolaGRAFixedLocalChatzos30Minutes() -> Date? { AstronomicalCalendar.getTimeOffset(time: getFixedLocalChatzos(), offset: AstronomicalCalendar.minuteMillis * 30) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *mincha ketana* (the preferred time to recite the *mincha prayers* according to the opinion of
    /// the [Rambam](https://en.wikipedia.org/wiki/Maimonides) and others) calculated according to the
    /// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that is 3.5 *shaos zmaniyos* (solar hours) after fixed local
    /// chatzos.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculateMinchaGedolah()`, `getFixedLocalChatzos()`, `minchaGedolaGRAFixedLocalChatzos30Minutes()`
    public func minchaKetanaGRAFixedLocalChatzosToSunset() -> Date? { getHalfDayBasedZman(startOfHalfDay: getFixedLocalChatzos(), endOfHalfDay: sunset, hours: 3.5) }

    /// This method returns [Rav Moshe Feinstein's](https://en.wikipedia.org/wiki/Moshe_Feinstein) opinion of the
    /// calculation of *plag hamincha*. This method returns *plag hamincha* calculated according to the
    /// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) that the day ends at sunset and is 4.75 *shaos zmaniyos* (solar
    /// hours) after fixed local chatzos.
    ///
    /// - Returns: the `Date` of the time of *mincha gedola*. If the calculation can't be computed such as in the Arctic
    ///   Circle where there is at least one day a year where the sun does not rise, and one where it does not
    ///   set, nil will be returned. See detailed explanation on top of the `AstronomicalCalendar`
    ///   documentation.
    /// - SeeAlso: `calculatePlagHamincha()`, `getFixedLocalChatzos()`, `minchaKetanaGRAFixedLocalChatzosToSunset()`,
    ///   `minchaGedolaGRAFixedLocalChatzos30Minutes()`
    public func plagHaminchaGRAFixedLocalChatzosToSunset() -> Date? { getHalfDayBasedZman(startOfHalfDay: getFixedLocalChatzos(), endOfHalfDay: sunset, hours: 4.75) }

    /// Method to return *tzais* (dusk) calculated as 50 minutes after sea level sunset. This method returns *tzais*
    /// (nightfall) based on the opinion of Rabbi Moshe Feinstein for the New York area. This time should not be used
    /// for latitudes different than the NY area.
    ///
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func tzeis50() -> Date? { AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: 50 * AstronomicalCalendar.minuteMillis) }
    public func midday() -> Date? { getSolarMidnight()?.withAdded(hours: -12) }

    /// This is a convenience method that returns the later of `calculateMinchaGedolah()` and `minchaGedola30Minutes()`.
    /// In the winter when 1/2 of a *shaah zmanis* is less than 30 minutes `minchaGedola30Minutes()` will be returned,
    /// otherwise `calculateMinchaGedolah()` will be returned.
    ///
    /// - Returns: the `Date` of the later of `calculateMinchaGedolah()` and `minchaGedola30Minutes()`. If the
    ///   calculation can't be computed such as in the Arctic Circle where there is at least one day a year
    ///   where the sun does not rise, and one where it does not set, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    public func minchaGedolaGreaterThan30() -> Date? {
        guard let a = minchaGedola30Minutes(), let b = calculateMinchaGedolah() else { return nil }
        return a > b ? a : b
    }

    // Zmanim KosherJava has that KosherSwift was missing. Ahavat Shalom and samuch le'mincha ketana
    // are from KosherJava 2.5.0; the rest were added in KosherJava master. getCandleLighting() and chatzosAsHalfDay()
    // are on ZmanimCalendar.

    /// This method returns *misheyakir* based on the position of the sun 12.85° below `Zenith.geometric` (90°). This is
    /// based on the position of the sun slightly later than 57 minutes before `sunrise` in Jerusalem [around the
    /// equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/). This *zman* is
    /// mentioned for use ***bish'as hadchak*** in the Birur Halacha
    /// [Tinyana](https://hebrewbooks.org/pdfpager.aspx?req=50535&st=&pgnum=88) and
    /// [Tlisa'ah](https://hebrewbooks.org/pdfpager.aspx?req=50537&st=&pgnum=31) in Orach Chaim siman 18 as 12.85°.
    /// Actual calculations show it to be slightly more than 12.9°, but the Birur Halacha indicates that 12.85° is a
    /// slight *chumra* (on a *bedieved* time) VS the 12.9° that 57 minutes calculates as (a difference of about 14
    /// seconds at the equinox/equilux in Jerusalem). The *zman* of 12.9° is also mentioned in the Piskei Tshuvos siman
    /// 18, page 190 (where a typo indicates that this is the degree equivalent to 60 minutes before sunrise, when in
    /// fact at that point the sun is about 13.5° below the horizon). The 57 minute based time is mentioned by the
    /// Minchas Yitzchak [vol. 9, siman 9](https://hebrewbooks.org/pdfpager.aspx?req=1601&st=&pgnum=21) as 15 minutes
    /// before *alos hashachar* (though he is not clear what location he refers to, and does not mention a degree-based
    /// conversion). The Kaf Hachaim [vol.1 siman 18, no.
    /// 18](https://hebrewbooks.org/pdfpager.aspx?req=8140&st=&pgnum=81) states that in Yerushalayim 60 fixed minutes
    /// are used year round. Calculations show that 60 fixed minutes in Yerushalayim ranges from 13.5° at the spring
    /// equinox to 11.5° at the summer solstice. 57-minute *misheyakir* range from 12.9° at the winter equinox to 11° at
    /// the summer solstice. Analysis of the difference between 12.85° and 12.9°, shows that the maximum difference
    /// occurs at the summer solstice. In Lakewood, NJ at a latitude of 40.096°, the maximum difference throughout the
    /// year is 23 seconds. In the winter where there is the greatest need for very early *misheyakir* times, the
    /// difference is in the 16 second range. Going north to Montreal at latitude 45.5°, the maximum is 29 seconds and
    /// is about 18 seconds in the winter. Moving farther north to the latitude of Vilnius at a latitude of 54.68°,
    /// things change. Firstly, around the summer solstice it will not reach that far below the horizon. On the dates
    /// that both can be calculated, the maximum difference can be pretty high on one or two days of the year (around
    /// Jul 8), with about a week having over a two minute difference between the two. Even at the latitude of Vilna,
    /// from Dec - March, the difference is about 22 seconds.
    ///
    /// - Important: Deprecated in KosherJava. This method returns a very early *misheyakir* time that should only be
    ///   used ***bish'as hadchak***. *Lechatchila*, a later *zman* should be used.
    ///   There is no current plan to remove this method from the API, and this
    ///   deprecation is intended to notify developers to add an alert to users of
    ///   the risk of using it.
    /// - Returns: The `Instant` of *misheyakir*. If the calculation can't be computed such as northern and southern
    ///   locations even south of the Arctic Circle and north of the Antarctic Circle where the sun may not
    ///   reach low enough below the horizon for this calculation, a `nil` will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z12_85`
    public func misheyakir12Point85Degrees() -> Date? { getSunriseOffsetByDegrees(offsetZenith: .z12_85) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [mil](https://en.wikipedia.org/wiki/Biblical_mile), based on a 22.5-minute mil, or 16.875 minutes. It is the
    /// sun's position at 4.42° below the western horizon. This is a very early *zman* and should not be relied on
    /// without Rabbinical guidance. This does not cover the 33.07 seconds it takes to walk 49 amos (the *heref ayin* of
    /// *bain hashmashos* of Rav Yosi) at the pace of a 22.5 minute-mil. Rabbi Yedidya Manet in his [Zmanei HaHalacha
    /// Lema'aseh](https://www.nli.org.il/en/books/NNL_ALEPH002542826/NLI) (5th edition, vol. I page 36, no. 23) lists
    /// 4.37° as the value for this *tzais*, however it is based on sunset calculated using a refreaction value of 31′
    /// (arcminutes) or 0.516° (page 16) based on his calculations of the refraction value in Israel at the autumn
    /// equinox (something he himself questions in vol II, page 36). Even for Israel, most consider that refraction
    /// value too low. Regardless, the dip for *tzais* must be based on sunset using a specific refraction model (and
    /// solar radius), and this library currently uses a global average refraction value of 34′ (arcminutes) or 0.566°.
    /// Based on the global average refraction for sunset, this *tzais* calculates as 4.42°.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very early
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Instant` representing the time when the sun is 4.42° below sea level. If the calculation can't
    ///   be computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
    ///   `nil` will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z4_42`
    public func tzeisGeonim4Point42Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_42) }

    /// This method returns the *tzais* (nightfall) based on the opinion of the *Geonim* calculated as 3/4 of a
    /// [mil](https://en.wikipedia.org/wiki/Biblical_mile) based on a 24-minute mil, or 18 minutes. It is the sun's
    /// position at 4.66° below the western horizon. This is a very early *zman* and should not be relied on without
    /// Rabbinical guidance. This does not cover the 35.28 seconds it takes to walk 49 amos (the *heref ayin* of *bain
    /// hashmashos* of Rav Yosi) at the pace of a 24-minute mil. See `tzeisGeonim4Point8Degrees()` for a time that
    /// covers the *heref ayin*. Rabbi Yedidya Manet in his [Zmanei HaHalacha
    /// Lema'aseh](https://www.nli.org.il/en/books/NNL_ALEPH002542826/NLI) (5th edition, vol. I page 36, no. 24) lists
    /// 4.61° as the value for this *tzais*, however it is based on sunset calculated using a refreaction value of 31′
    /// (arcminutes) or 0.516° (page 16) based on his calculations of the refraction value in Israel at the autumn
    /// equinox (something he himself questions in vol II, page 36). Even for Israel, most consider that refraction
    /// value too low. Regardless, the dip for *tzais* must be based on sunset using a specific refraction model (and
    /// solar radius), and this library currently uses a global average refraction value of 34′ (arcminutes) or 0.566°.
    /// Based on the global average refraction for sunset, this *tzais* calculates as 4.66°.
    ///
    /// - Important: Deprecated in KosherJava. This method should be used *lechumra* only since it returns a very early
    ///   time, and if used *lekula* can result in *chillul Shabbos* etc. There is
    ///   no current plan to remove this method from the API, and this deprecation
    ///   is intended to alert developers of the danger of using it.
    /// - Returns: the `Instant` representing the time when the sun is 4.66° below sea level. If the calculation can't
    ///   be computed such as northern and southern locations even south of the Arctic Circle and north of the
    ///   Antarctic Circle where the sun may not reach low enough below the horizon for this calculation, a
    ///   `nil` will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `Zenith.z4_66`, `tzeisGeonim4Point8Degrees()`
    public func tzeisGeonim4Point66Degrees() -> Date? { getSunsetOffsetByDegrees(offsetZenith: .z4_66) }

    /// Method to return a *shaah zmanis* (temporal hour) used by some *zmanim* according to the opinion of [Rabbi
    /// Yaakov Moshe Hillel](https://en.wikipedia.org/wiki/Yaakov_Moshe_Hillel) as published in the *luach* of the Bais
    /// Horaah of Yeshivat Chevrat Ahavat Shalom that is based on a day starting 72 minutes before sunrise in degrees
    /// *alos* 16.1° and ending 13.5 minutes after sunset in degrees *tzais* 3.7°. This day is split into 12 equal parts
    /// with each part being a *shaah zmanis*. Note that with this system, *chatzos* (midday) will not be the point that
    /// the sun is halfway across the sky. These *shaos zmaniyos* are used for *Mincha Gedola* calculation. Sources for
    /// an asymmetrical day-based calculation can be seen in the documentation of
    /// `latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees()`.
    ///
    /// - Returns: the `Duration` of a *shaah zmanis*. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year when the sun does not rise, and one where it does not set, a
    ///   `nil` will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees()`,
    ///   `shaahZmanisAlos16Point1ToTzeisGeonim7Point083Degrees()`
    public func shaahZmanisAlos16Point1ToTzeisGeonim3Point7Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeisGeonim3Point7Degrees()) }

    /// Method to return a *shaah zmanis* (temporal hour) used by some *zmanim* according to the opinion of [Rabbi
    /// Yaakov Moshe Hillel](https://en.wikipedia.org/wiki/Yaakov_Moshe_Hillel) as published in the *luach* of the Bais
    /// Horaah of Yeshivat Chevrat Ahavat Shalom that is based on a day starting 72 minutes before sunrise in degrees
    /// *alos* 16.1° and ending 14 minutes after sunset in degrees *tzais* 3.8°. This day is split into 12 equal parts
    /// with each part being a *shaah zmanis*. Note that with this system, *chatzos* (midday) will not be the point that
    /// the sun is halfway across the sky. These *shaos zmaniyos* are used for *Mincha Ketana* and *Plag Hamincha*. The
    /// 14 minutes are based on 3/4 of an 18 minute [mil](https://en.wikipedia.org/wiki/Biblical_mile), with half a
    /// minute added for Rav Yosi's *Bain Hashmashos*. Sources for an asymmetrical day-based calculation can be seen in
    /// the documentation of `latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees()`.
    ///
    /// - Returns: the `Duration` of a *shaah zmanis*. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year when the sun does not rise, and one where it does not set, a
    ///   `nil` will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisAlos16Point1ToTzeisGeonim3Point7Degrees()`,
    ///   `shaahZmanisAlos16Point1ToTzeisGeonim7Point083Degrees()`
    public func shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees() -> Double? { getTemporalHour(dayStart: alos16Point1Degrees(), dayEnd: tzeisGeonim3Point8Degrees()) }

    /// Method to return a *shaah zmanis* (temporal hour) used by some *zmanim* according to some opinions that is based
    /// on a day starting at *alos* 16.1° and ending *tzais* 8.083°. This day is split into 12 equal parts with each
    /// part being a *shaah zmanis*. Note that with this system, *chatzos* (midday) will not be the point that the sun
    /// is halfway across the sky. Sources for an asymmetrical day-based calculation can be seen in the documentation of
    /// `latestShemaAlos16Point1ToTzeisGeonim7Point083Degrees()`.
    ///
    /// - Returns: the `Duration` of a *shaah zmanis*. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year when the sun does not rise, and one where it does not set, a
    ///   `nil` will be returned. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisAlos16Point1ToTzeisGeonim3Point7Degrees()`,
    ///   `shaahZmanisAlos16Point1ToTzeisGeonim3Point8Degrees()`
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

    /// A method for calculating *samuch lemincha ketana*, / near *mincha ketana* time that is half an hour before
    /// `calculateMinchaKetana()` or is 9 * *shaos zmaniyos* (solar hours) after sunrise or sea level sunrise (depending
    /// on the `shouldUseElevation` setting), calculated according to the
    /// [GRA](https://en.wikipedia.org/wiki/Vilna_Gaon) using a day starting at sunrise and ending at sunset. This is
    /// the time that eating or other activity can't begin prior to praying *mincha*. The calculation used is 9 *
    /// `shaahZmanis16Point1Degrees()` after *alos* 16.1°. See the [Mechaber and Mishna Berurah
    /// 232](https://hebrewbooks.org/pdfpager.aspx?req=60387&st=&pgnum=294) for details.
    ///
    /// - Returns: the `Date` of the time of *samuch lemincha ketana*. If the calculation can't be computed such as
    ///   northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
    ///   where the sun may not reach low enough below the horizon for this calculation, nil will be returned.
    ///   See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanisGra()`, `samuchLeMinchaKetana16Point1Degrees()`
    public func samuchLeMinchaKetanaGRA() -> Date? { samuchLeMinchaKetana(elevationAdjustedSunrise, elevationAdjustedSunset) }

    /// A method for calculating *samuch lemincha ketana*, / near *mincha ketana* time that is half an hour before
    /// `minchaGedola16Point1Degrees()` or 9 * *shaos zmaniyos* (temporal hours) after the start of the day, calculated
    /// using a day starting and ending 16.1° below the horizon. This is the time that eating or other activity can't
    /// begin prior to praying *mincha*. The calculation used is 9 * `shaahZmanis16Point1Degrees()` after *alos* 16.1°.
    /// See the [Mechaber and Mishna Berurah 232](https://hebrewbooks.org/pdfpager.aspx?req=60387&st=&pgnum=294).
    ///
    /// - Returns: the `Date` of the time of *samuch lemincha ketana*. If the calculation can't be computed such as
    ///   northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
    ///   where the sun may not reach low enough below the horizon for this calculation, nil will be returned.
    ///   See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`
    public func samuchLeMinchaKetana16Point1Degrees() -> Date? { samuchLeMinchaKetana(alos16Point1Degrees(), tzeis16Point1Degrees()) }

    /// A method for calculating *samuch lemincha ketana*, / near *mincha ketana* time that is half an hour before
    /// `minchaKetana72Minutes()` or 9 * *shaos zmaniyos* (temporal hours) after the start of the day, calculated using
    /// a day starting 72 minutes before sunrise and ending 72 minutes after sunset. This is the time that eating or
    /// other activity can't begin prior to praying *mincha*. The calculation used is 9 * `shaahZmanis16Point1Degrees()`
    /// after *alos* 16.1°. See the [Mechaber and Mishna Berurah
    /// 232](https://hebrewbooks.org/pdfpager.aspx?req=60387&st=&pgnum=294).
    ///
    /// - Returns: the `Date` of the time of *samuch lemincha ketana*. If the calculation can't be computed such as
    ///   northern and southern locations even south of the Arctic Circle and north of the Antarctic Circle
    ///   where the sun may not reach low enough below the horizon for this calculation, nil will be returned.
    ///   See detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis16Point1Degrees()`
    public func samuchLeMinchaKetana72Minutes() -> Date? { samuchLeMinchaKetana(alos72(), tzeis72()) }

    /// This method returns the latest time one is allowed eating *chametz* on *Erev Pesach* according to the opinion of
    /// the [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombiner) based on *alos* being 72 zmaniyos
    /// minutes before `sunrise`. This time is identical to the *Sof zman tfilah* MGA 72 minutes zmanis. This time is 4
    /// *shaos zmaniyos* (temporal hours) after dawn based on the opinion of the MGA that the day is calculated from a
    /// dawn of 72 minutes zmanis before sunrise to nightfall of 72 minutes zmanis after sunset. This returns the time
    /// of 4 * `shaahZmanis72MinutesZmanis()` after dawn. If it is not *erev Pesach*, a `nil` will be returned.
    ///
    /// - Returns: the `Instant` of the latest time of eating *chametz*. If it is not *erev Pesach* or the calculation
    ///   can't be computed such as in the Arctic Circle where there is at least one day a year when the sun
    ///   does not rise, and one where it does not set, a `nil` will be returned. See detailed explanation on
    ///   top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis72MinutesZmanis()`, `alos72Zmanis()`, `latestTefilaMGA72MinutesZmanis()`
    public func latestAchilasChametzMGA72MinutesZmanis() -> Date? { isErevPesach ? latestTefilaMGA72MinutesZmanis() : nil }

    /// This method returns the latest time for burning *chametz* on *Erev Pesach* according to the opinion of the
    /// [Magen Avraham (MGA)](https://en.wikipedia.org/wiki/Avraham_Gombiner) based on *alos* being 72 minutes zmanis
    /// before `sunrise`. This time is 5 *shaos zmaniyos* (temporal hours) after dawn based on the opinion of the MGA
    /// that the day is calculated from a dawn of 72 minutes zmanis before sunrise to nightfall of 72 minutes zmanis
    /// after sunset. This returns the time of 5 * `shaahZmanis72MinutesZmanis()` after dawn. If it is not *erev
    /// Pesach*, a `nil` will be returned.
    ///
    /// - Returns: the `Instant` of the latest time for burning *chametz* on *Erev Pesach*. If it is not *erev Pesach*
    ///   or the calculation can't be computed such as in the Arctic Circle where there is at least one day a
    ///   year when the sun does not rise, and one where it does not set, a `nil` will be returned. See
    ///   detailed explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `shaahZmanis72MinutesZmanis()`, `alos72Zmanis()`
    public func latestBiurChametzMGA72MinutesZmanis() -> Date? {
        guard isErevPesach, let alos = alos72Zmanis(), let tzeis = tzeis72Zmanis() else { return nil }
        return shaahZmanisBasedZman(alos, tzeis, 5)
    }
    
    // Helpers
    /// A utility method to return *alos* (dawn) or *tzais* (dusk) based on a fractional day offset.
    ///
    /// - Parameter hours: the number of *shaaos zmaniyos* (temporal hours) before sunrise or after sunset that defines
    ///   dawn or dusk. If a negative number is passed in, it will return the time of *alos* (dawn)
    ///   (subtracting the time from sunrise) and if a positive number is passed in, it will return the
    ///   time of *tzais* (dusk) (adding the time to sunset). If 0 is passed in, nil will be returned
    ///   (since we can't tell if it is sunrise or sunset based).
    /// - Returns: the `Date` representing the time. If the calculation can't be computed such as in the Arctic Circle
    ///   where there is at least one day a year where the sun does not rise, and one where it does not set,
    ///   nil will be returned. nil will also be returned if 0 is passed in, since we can't tell if it is
    ///   sunrise or sunset based. See detailed explanation on top of the `AstronomicalCalendar` documentation.
    public func zmanisBasedOffset(_ hours: Double) -> Date? {
        guard let shaahZmanis = shaahZmanisGra() else { return nil }
        
        if hours > 0 {
            return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunset, offset: (shaahZmanis * hours))
        }
        
        return AstronomicalCalendar.getTimeOffset(time: elevationAdjustedSunrise, offset: (shaahZmanis * hours))
    }
    
    /// A utility methos to calculate zmanim based on [Rav Moshe
    /// Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) as calculated in
    /// [MTJ](https://en.wikipedia.org/wiki/Mesivtha_Tifereth_Jerusalem), [Yeshiva of Staten
    /// Island](https://en.wikipedia.org/wiki/Mesivtha_Tifereth_Jerusalem), and Camp Yeshiva of Staten Island. The day
    /// is split in two, from *alos* / sunrise to fixed local *chatzos*, and the second half of the day, from fixed
    /// local *chatzos* to sunset / *tzais*. Morning based times are calculated based on the first 6 hours, and
    /// afternoon times based on the second half of the day.
    ///
    /// - Parameters:
    ///   - startOfHalfDay: The start of the half day. This would be *alos* or sunrise for morning based times and fixed
    ///     local *chatzos* for the second half of the day.
    ///   - endOfHalfDay: The end of the half day. This would be fixed local *chatzos* for morning based times and
    ///     sunset or *tzais* for afternoon based times.
    ///   - hours: the number of hours to offset the beginning of the first or second half of the day
    /// - Returns: the `Date` of the later of `minchaGedolaBaalHatanya()` and `minchaGedola30Minutes()`. If the
    ///   calculation can't be computed such as in the Arctic Circle where there is at least one day a year
    ///   where the sun does not rise, and one where it does not set, nil will be returned. See detailed
    ///   explanation on top of the `AstronomicalCalendar` documentation.
    /// - SeeAlso: `getFixedLocalChatzos()`
    public func getFixedLocalChatzosBasedZmanim(_ startOfHalfDay: Date?, _ endOfHalfDay: Date?, _ hours: Double) -> Date? {
//        guard let startOfHalfDay = startOfHalfDay, let endOfHalfDay = endOfHalfDay else { return nil }
//        
//        let shaahZmanis = (endOfHalfDay.millisecondsSince1970 - startOfHalfDay.millisecondsSince1970) / 6
//        return Date(milliseconds: startOfHalfDay.millisecondsSince1970 + shaahZmanis * Int64(hours))
        getHalfDayBasedZman(startOfHalfDay: startOfHalfDay, endOfHalfDay: endOfHalfDay, hours: hours)

    }
    
    /// A method that returns the local time for fixed *chatzos*. This time is noon and midnight adjusted from standard
    /// time to account for the local latitude. The 360° of the globe divided by 24 calculates to 15° per hour with 4
    /// minutes per degree, so at a longitude of 0 , 15, 30 etc... *Chatzos* is at exactly 12:00 noon. This is the time
    /// of *chatzos* according to the [Aruch Hashulchan](https://en.wikipedia.org/wiki/Aruch_HaShulchan) in [Orach Chaim
    /// 233:14](https://hebrewbooks.org/pdfpager.aspx?req=7705&pgnum=426) and [Rabbi Moshe
    /// Feinstein](https://en.wikipedia.org/wiki/Moshe_Feinstein) in Igros Moshe [Orach Chaim
    /// 1:24](https://hebrewbooks.org/pdfpager.aspx?req=916&st=&pgnum=67) and
    /// [2:20](https://hebrewbooks.org/pdfpager.aspx?req=14675&pgnum=191). Lakewood, N.J., with a longitude of -74.2094,
    /// is 0.7906 away from the closest multiple of 15 at -75°. This is multiplied by 4 to yield 3 minutes and 10
    /// seconds for a *chatzos* of 11:56:50. This method is not tied to the theoretical 15° timezones, but will adjust
    /// to the actual timezone and [Daylight saving time](https://en.wikipedia.org/wiki/Daylight_saving_time).
    ///
    /// - Returns: the Date representing the local *chatzos*
    public func getFixedLocalChatzos()  -> Date? {
        getLocalMeanTime(hours: 12.0)
    }
    
    /// From the GRA in Kol Eliyahu on Berachos #173 that states that *zman krias shema* is calculated as half the time
    /// from sea level sunrise to fixed local chatzos. The GRA himself seems to contradict this when he stated that
    /// *zman krias shema* is 1/4 of the day from sunrise to sunset. See *Sarah Lamoed* #25 in Yisroel Vehazmanim Vol.
    /// III page 1016.
    ///
    /// - Important: Deprecated in KosherJava. As per a conversation Rabbi Yisroel Twerski had with Rabbi Harfenes, this
    ///   *zman* published in the Yisrael Vehazmanim was based on a
    ///   misunderstanding and should not be used. This deprecated method will be
    ///   removed (likely in v3.0) pending confirmation from Rabbi Harfenes.
    /// - Returns: the `Date` of the latest *zman krias shema* based on this calculation. If the calculation can't be
    ///   computed such as in the Arctic Circle where there is at least one day a year where the sun does not
    ///   rise, and one where it does not set, nil will be returned. See detailed explanation on top of the
    ///   `AstronomicalCalendar` documentation.
    /// - SeeAlso: `getFixedLocalChatzos()`
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
    
    /// Used by Molad based *zmanim* to determine if *zmanim* occur during the current day.
    ///
    /// - Returns: previous midnight
    /// - SeeAlso: `getMoladBasedTime()`
    public func getMidnightLastNight() -> Date? {
        Calendar.current.date(from: DateComponents(year: date.year, month: date.month, day: date.day, hour: 0, minute: 0))
    }

    /// Used by Molad based *zmanim* to determine if *zmanim* occur during the current day.
    ///
    /// - Returns: following midnight
    /// - SeeAlso: `getMoladBasedTime()`
    public func getMidnightTonight() -> Date? {
        Calendar.current.date(from: DateComponents(year: date.year, month: date.month, day: date.day + 1, hour: 0, minute: 0))
    }
    
    /// Returns the Date of the *molad* based time if it occurs on the current date. Since *Kiddush Levana* can only be
    /// said during the day, there are parameters to limit it to between *alos* and *tzais*. If the time occurs between
    /// *alos* and *tzais*, *tzais* will be returned.
    ///
    /// - Parameters:
    ///   - moladBasedTime: the *molad* based time such as *molad*, *tchilas* and *sof zman Kiddush Levana*
    ///   - alos: optional start of day to limit *molad* times to the end of the night before or beginning of the next
    ///     night. Ignored if either *alos* or *tzais* are nil.
    ///   - tzeis: optional end of day to limit *molad* times to the end of the night before or beginning of the next
    ///     night. Ignored if either *tzais* or *alos* are nil
    ///   - techila: is it the start of *Kiddush Levana* time or the end? If it is start roll it to the next *tzais*,
    ///     and and if it is the end, return the end of the previous night (*alos* passed in). Ignored if
    ///     either *alos* or *tzais* are nil.
    /// - Returns: the *molad* based time. If the *zman* does not occur during the current date, nil will be returned.
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
