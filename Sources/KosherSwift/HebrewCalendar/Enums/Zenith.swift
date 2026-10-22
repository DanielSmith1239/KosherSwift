//
//  Zenith.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/20/23.
//

import Foundation

public enum Zenith: Double {    
    /// Sun's zenith at civil twilight (96°).
    case civil = 96

    /// Sun's zenith at nautical twilight (102°).
    case nautical = 102

    /// Sun's zenith at astronomical twilight (108°).
    case astronomical = 108

    /// 90° below the vertical. Used as a basis for most calculations since the location of the sun is 90° below the
    /// horizon at sunrise and sunset. **Note** : it is important to note that for sunrise and sunset the adjusted
    /// zenith is required to account for the radius of the sun and refraction. The adjusted zenith should not be used
    /// for calculations above or below 90° since they are usually calculated as an offset to 90°.
    case geometric = 90
    
    /// The zenith of 16.1° below geometric zenith (90°). This calculation is used for determining *alos* (dawn) and
    /// *tzais* (nightfall) in some opinions. It is based on the calculation that the time between dawn and sunrise (and
    /// sunset to nightfall) is 72 minutes, the time that is takes to walk 4 *mil* at 18 minutes a mil
    /// (*[Rambam](https://en.wikipedia.org/wiki/Maimonides)* and others). The sun's position at 72 minutes before
    /// sunrise in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) is 16.1° below geometric
    /// zenith.
    ///
    /// - SeeAlso: `alosHashachar()`, `alos16Point1Degrees()`, `tzeis16Point1Degrees()`,
    ///   `latestShemaMGA16Point1Degrees()`, `latestTefilaMGA16Point1Degrees()`,
    ///   `minchaGedola16Point1Degrees()`, `minchaKetana16Point1Degrees()`, `plagHamincha16Point1Degrees()`,
    ///   `plagAlos16Point1ToTzeisGeonim7Point083Degrees()`, `latestShemaAlos16Point1ToSunset()`
    case z16_1 = 106.1

    /// The zenith of 8.5° below geometric zenith (90°). This calculation is used for calculating *alos* (dawn) and
    /// *tzais* (nightfall) in some opinions. This calculation is based on the position of the sun 36 minutes after
    /// sunset in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which is 8.5° below
    /// geometric zenith. The *[Ohr Meir](https://www.worldcat.org/oclc/29283612)* considers this the time that 3 small
    /// stars are visible, which is later than the required 3 medium stars.
    ///
    /// - SeeAlso: `tzeis()`, `tzeisGeonim8Point5Degrees()`
    case z8_5 = 98.5

    /// The zenith of 3.7° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// based on the opinion of the *Geonim* that *tzais* is the time it takes to walk 3/4 of a *Mil* at 18 minutes a
    /// *Mil*, or 13.5 minutes after sunset. The sun is 3.7° below geometric zenith at this time in Jerusalem [around
    /// the equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/).
    ///
    /// - SeeAlso: `tzeisGeonim3Point7Degrees()`
    case z3_7 = 93.7

    /// The zenith of 3.8° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// based on the opinion of the *Geonim* that *tzais* is the time it takes to walk 3/4 of a *Mil* at 18 minutes a
    /// *Mil*, or 13.5 minutes after sunset. The sun is 3.8° below geometric zenith at this time in Jerusalem [around
    /// the equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/).
    ///
    /// - SeeAlso: `tzeisGeonim3Point8Degrees()`
    case z3_8 = 93.8

    /// The zenith of 5.95° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions. This calculation is based on the position of the sun 24 minutes after sunset in
    /// Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 5.95°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `tzeisGeonim5Point95Degrees()`
    case z5_95 = 95.95

    /// The zenith of 7.083° below geometric zenith (90°). This is often referred to as 7°5' or 7° and 5 minutes. This
    /// calculation is used for calculating *alos* (dawn) and *tzais* (nightfall) according to some opinions. This
    /// calculation is based on observation of 3 medium sized stars by Dr. Baruch Cohen in his calendar published in in
    /// 1899 in Strasbourg, France. This calculates to 7.0833333° below geometric zenith. The [Sh"Ut Melamed
    /// Leho'il](https://hebrewbooks.org/1053) in Orach Chaim 30 agreed to this *zman*, as did the Sh"Ut Bnei Tziyon,
    /// Tenuvas Sadeh and it is very close to the time of the [Mekor Chesed](https://hebrewbooks.org/22044) of the Sefer
    /// chasidim. It is close to the position of the sun 30 minutes after sunset in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), but not Exactly. The actual
    /// position of the sun 30 minutes after sunset in Jerusalem at the equilux is 7.205° and 7.199° at the equinox. See
    /// Hazmanim Bahalacha vol 2, pages 520-521 for details.
    ///
    /// - ToDo: Hyperlink the proper sources.
    /// - SeeAlso: `tzeisGeonim7Point083Degrees()`, `beinHashmashosRT13Point5MinutesBefore7Point083Degrees()`
    case z7_083 = 97.08333333333333 // 7° 5′, KosherJava's ZENITH_7_POINT_083

    /// The zenith of 10.2° below geometric zenith (90°). This calculation is used for calculating *misheyakir*
    /// according to some opinions. This calculation is based on the position of the sun 45 minutes before sunrise in
    /// Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) which calculates to 10.2°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `misheyakir10Point2Degrees()`
    case z10_2 = 100.2

    /// The zenith of 11° below geometric zenith (90°). This calculation is used for calculating *misheyakir* according
    /// to some opinions. This calculation is based on the position of the sun 48 minutes before sunrise in Jerusalem
    /// [around the equinox / equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which
    /// calculates to 11° below geometric zenith.
    ///
    /// - SeeAlso: `misheyakir11Degrees()`
    case z11Deg = 101

    /// The zenith of 11.5° below geometric zenith (90°). This calculation is used for calculating *misheyakir*
    /// according to some opinions. This calculation is based on the position of the sun 52 minutes before sunrise in
    /// Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 11.5°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `misheyakir11Point5Degrees()`
    case z11_5 = 101.5

    /// The zenith of 13.24° below geometric zenith (90°). This calculation is used for calculating Rabbeinu Tam's *bain
    /// hashmashos* according to some opinions. NOTE: See comments on `beinHashmashosRT13Point24Degrees()` for
    /// additional details about the degrees.
    ///
    /// - SeeAlso: `beinHashmashosRT13Point24Degrees()`
    case z13_24 = 103.24

    /// The zenith of 19° below geometric zenith (90°). This calculation is used for calculating *alos* according to
    /// some opinions.
    ///
    /// - SeeAlso: `alos19Degrees()`, `Zenith.z19_8`
    case z19Deg = 109

    /// The zenith of 19.8° below geometric zenith (90°). This calculation is used for calculating *alos* (dawn) and
    /// *tzais* (nightfall) according to some opinions. This calculation is based on the position of the sun 90 minutes
    /// after sunset in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) which calculates to 19.8°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `tzeis19Point8Degrees()`, `alos19Point8Degrees()`, `alos90()`, `tzeis90()`, `Zenith.z19Deg`
    case z19_8 = 109.8

    /// The zenith of 26° below geometric zenith (90°). This calculation is used for calculating *alos* (dawn) and
    /// *tzais* (nightfall) according to some opinions. This calculation is based on the position of the sun 120 minutes
    /// after sunset in Jerusalem o[around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) which calculates to 26°
    /// below geometric zenith. Since the level of darkness when the sun is 26° and at a point when the level of
    /// darkness is long past the 18° point where the darkest point is reached, it should only be used *lechumra* such
    /// as delaying the start of nighttime *mitzvos* or avoiding eating this early on a fast day.
    ///
    /// - SeeAlso: `alos26Degrees()`, `tzeis26Degrees()`, `alos120()`, `tzeis120()`
    case z26Deg = 116.0

    /// The zenith of 4.37° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions. This calculation is based on the position of the sun 16 7/8 minutes after sunset
    /// (3/4 of a 22.5-minute *Mil*) in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 4.37°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `tzeisGeonim4Point37Degrees()`
    case z4_37 = 94.37

    /// The zenith of 4.61° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions. This calculation is based on the position of the sun 18 minutes after sunset (3/4 of
    /// a 24-minute *Mil*) in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/), which calculates to 4.61°
    /// below geometric zenith.
    ///
    /// - ToDo: add documentation links
    /// - SeeAlso: `tzeisGeonim4Point61Degrees()`
    case z4_61 = 94.61

    /// The zenith of 4.8° below geometric zenith (90°).
    ///
    /// - ToDo: Add more documentation.
    /// - SeeAlso: `tzeisGeonim4Point8Degrees()`
    case z4_8 = 94.8

    /// The zenith of 3.65° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions. This calculation is based on the position of the sun 13.5 minutes after sunset (3/4
    /// of an 18-minute *Mil*) in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) which calculates to 3.65°
    /// below geometric zenith.
    ///
    /// - SeeAlso: `tzeisGeonim3Point65Degrees()`
    case z3_65 = 93.65

    /// The zenith of 3.676° below geometric zenith (90°).
    ///
    /// - ToDo: Add more documentation.
    case z3_676 = 93.676

    /// The zenith of 5.88° below geometric zenith (90°).
    ///
    /// - ToDo: Add more documentation.
    case z5_88 = 95.88

    /// The zenith of 1.583° below geometric zenith (90°). This calculation is used for calculating *netz amiti*
    /// (sunrise) and *shkiah amiti* (sunset) based on the opinion of the [Baal
    /// Hatanya](https://en.wikipedia.org/wiki/Shneur_Zalman_of_Liadi).
    ///
    /// - SeeAlso: `sunriseBaalHatanya()`, `sunsetBaalHatanya()`
    case z1_583 = 91.583

    /// The zenith of 16.9° below geometric zenith (90°). This calculation is used for determining *alos* (dawn) based
    /// on the opinion of the Baal Hatanya. It is based on the calculation that the time between dawn and *netz amiti*
    /// (sunrise) is 72 minutes, the time that is takes to walk 4 *mil* at 18 minutes a *mil*
    /// ([Rambam](https://en.wikipedia.org/wiki/Maimonides) and others). The sun's position at 72 minutes before *netz
    /// amiti* (sunrise) in Jerusalem [around the equinox /
    /// equilux](https://kosherjava.com/2022/01/12/equinox-vs-equilux-zmanim-calculations/) is 16.9° below geometric
    /// zenith.
    ///
    /// - SeeAlso: `alosBaalHatanya()`
    case z16_9 = 106.9
//    case z6Deg = civil
    /// The zenith of 6.45° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions. This is based on the calculations of [Rabbi Yechiel Michel
    /// Tucazinsky](https://en.wikipedia.org/wiki/Yechiel_Michel_Tucazinsky) of the position of the sun no later than 31
    /// minutes after sunset in Jerusalem, and at the height of the summer solstice, this *zman* is 28 minutes after
    /// *shkiah*. This computes to 6.45° below geometric zenith. This calculation is found in the [Birur Halacha Yoreh
    /// Deah 262](https://hebrewbooks.org/pdfpager.aspx?req=50536&st=&pgnum=51) it the commonly used *zman* in Israel.
    /// It should be noted that this differs from the 6.1°/6.2° calculation for Rabbi Tucazinsky's time as calculated by
    /// the Hazmanim Bahalacha Vol II chapter 50:7 (page 515).
    ///
    /// - SeeAlso: `tzeisGeonim6Point45Degrees()`
    case z6_45 = 96.45

    /// The zenith of 7.65° below geometric zenith (90°). This calculation is used for calculating *misheyakir*
    /// according to some opinions.
    ///
    /// - SeeAlso: `misheyakir7Point65Degrees()`
    case z7_65 = 97.65

    /// The zenith of 7.67° below geometric zenith (90°). This calculation is used for calculating *tzais* according to
    /// some opinions.
    ///
    /// - SeeAlso: `tzeisGeonim7Point67Degrees()`
    case z7_67 = 97.67

    /// The zenith of 9.3° below geometric zenith (90°). This calculation is used for calculating *tzais* (nightfall)
    /// according to some opinions.
    ///
    /// - SeeAlso: `tzeisGeonim9Point3Degrees()`
    case z9_3 = 99.3

    /// The zenith of 9.5° below geometric zenith (90°). This calculation is used for calculating *misheyakir* according
    /// to some opinions.
    ///
    /// - SeeAlso: `misheyakir9Point5Degrees()`
    case z9_5 = 99.5

    /// The zenith of 9.75° below geometric zenith (90°). This calculation is used for calculating *alos* (dawn) and
    /// *tzais* (nightfall) according to some opinions.
    ///
    /// - SeeAlso: `tzeisGeonim9Point75Degrees()`
    case z9_75 = 99.75

    /// The zenith of 2.1° above geometric zenith (90°). This calculation is used for calculating the start of *bain
    /// hashmashos* (twilight) of 13.5 minutes before sunset converted to degrees according to the Yereim. As is
    /// traditional with degrees below the horizon, this is calculated without refraction and from the center of the
    /// sun. It would be 0.833° less without this.
    ///
    /// - SeeAlso: `beinHashmashosYereim2Point1Degrees()`
    case zMinus2_1 = 87.9

    /// The zenith of 2.8° above geometric zenith (90°). This calculation is used for calculating the start of *bain
    /// hashmashos* (twilight) of 16.875 minutes before sunset converted to degrees according to the Yereim. As is
    /// traditional with degrees below the horizon, this is calculated without refraction and from the center of the
    /// sun. It would be 0.833° less without this.
    ///
    /// - SeeAlso: `beinHashmashosYereim2Point8Degrees()`
    case zMinus2_8 = 87.2

    /// The zenith of 3.05° above geometric zenith (90°). This calculation is used for calculating the start of *bain
    /// hashmashos* (twilight) of 18 minutes before sunset converted to degrees according to the Yereim. As is
    /// traditional with degrees below the horizon, this is calculated without refraction and from the center of the
    /// sun. It would be 0.833° less without this.
    ///
    /// - SeeAlso: `beinHashmashosYereim3Point5Degrees()`
    case zMinus3_05 = 86.95

    /// The zenith of 12.85° below `Zenith.geometric` (90°).
    ///
    /// - SeeAlso: `misheyakir12Point85Degrees()`
    case z12_85 = 102.85

    /// The zenith of 4.42° below `Zenith.geometric` (90°).
    ///
    /// - SeeAlso: `tzeisGeonim4Point42Degrees()`
    case z4_42 = 94.42

    /// The zenith of 4.66° below `Zenith.geometric` (90°).
    ///
    /// - SeeAlso: `tzeisGeonim4Point66Degrees()`
    case z4_66 = 94.66
}
