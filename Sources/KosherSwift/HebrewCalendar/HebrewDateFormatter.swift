//
//  JewishCalendarExtensions.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/18/23.
//

import Foundation

public struct HebrewDateFormatter {
    ///Sets the formatter to format in Hebrew in the various formatting methods.
    let hebrewFormat: Bool
    
    /// When formatting a Hebrew Year, traditionally the thousands digit is omitted and output for a year such as 5729
    /// (1969 Gregorian) would be calculated for 729 and format as תשכ״ט. This method
    /// allows setting this to true to return the long format year such as ה׳ תשכ״ט for 5729/1969.
    let useLongHebrewYears: Bool
    
    /// Sets whether to use the Geresh ׳ and Gershayim ״ in formatting Hebrew dates and numbers. The default
    /// value is true and output would look like כ״א שבט תש״כ
    /// (or כ״א שבט תש״ך). When set to false, this output would display as כא שבט תשכ (or כא שבט תשך).
    /// Single digit days or month or years such as כ׳ שבט ו׳ אלפים show the use of the Geresh.
    let useGershGershayim: Bool
    
    /// Setting to control if the {@link #formatDayOfWeek(JewishDate)} will use the long format such as ראשון
    /// or short such as א when formatting the day of week in Hebrew.
    let longWeekFormat: Bool
    
    /// Returns whether the class is set to use the מנצפ״ך letters when
    /// formatting years ending in 20, 40, 50, 80 and 90 to produce תש״פ if false or
    /// or תש״ף if true. Traditionally non-final form letters are used, so the year
    /// 5780 would be formatted as תש״פ if the default false is used here. If this returns
    /// true, the format תש״ף would be used.
    let useFinalFormLetters: Bool
    
    let longOmerFormat: Bool
    
    let useShortHolidayFormat: Bool
    
    /// The [gersh](https://en.wikipedia.org/wiki/Geresh#Punctuation_mark) character is the ׳ char
    /// that is similar to a single quote and is used in formatting Hebrew numbers.
    static let _GERESH = "׳"
    
    /// The [gersh](https://en.wikipedia.org/wiki/Geresh#Punctuation_mark) character is the " char
    /// that is similar to a single quote and is used in formatting Hebrew numbers.
    static let _GERSHAYIM = "״"
    
    /// Hebrew Omer prefix. By default it is the letter ב, but can be set to ל (or any other prefix).
    let hebrewOmerPrefix = "ב"
    
    ///day of Shabbos transliterated into Latin chars. The default uses Ashkenazi pronunciation "Shabbos".
    let transliteratedShabbosDayOfWeek = "Shabbos"
    let hebrewParshaPrefix = "פרשת "
    let transliteratedParshaPrefix = "Parashat "
    let hebrewShabbosStartPrefix = "כניסת שבת: "
    let transliteratedShabbosStartPrefix = "Shabbos start at: "
    let hebrewShabbosEndPrefix = "כניסת שבת: "
    let transliteratedShabbosEndPrefix = "Shabbos end at: "
    let hebrewYomTovStartPrefix = "כניסת שבת: "
    let transliteratedYomTovStartPrefix = "Shabbos start at: "
    let hebrewYomTovEndPrefix = "כניסת שבת: "
    let transliteratedYomTovEndPrefix = "Shabbos end at: "
    
    public init(hebrewFormat: Bool = false, useLongHebrewYears: Bool = false, useGershGershayim: Bool = true, longWeekFormat: Bool = true, useFinalFormLetters: Bool = false, longOmerFormat: Bool = false, useShortHolidayFormat: Bool = false) {
        self.hebrewFormat = hebrewFormat
        self.useLongHebrewYears = useLongHebrewYears
        self.useGershGershayim = useGershGershayim
        self.longWeekFormat = longWeekFormat
        self.useFinalFormLetters = useFinalFormLetters
        self.longOmerFormat = longOmerFormat
        self.useShortHolidayFormat = useShortHolidayFormat
    }
    
    static let _hebrewDaysOfWeek = [
        "ראשון",
        "שני",
        "שלישי",
        "רביעי",
        "חמישי",
        "שישי",
        "שבת"
    ]
    
    /// List of months transliterated into Latin chars. The default list of months uses Ashkenazi
    /// pronunciation in typical American English spelling. This list has a length of 14 with 3 variations for Adar -
    /// "Adar", "Adar II", "Adar I"
    static let transliteratedMonths = [
        "Nissan",
        "Iyar",
        "Sivan",
        "Tammuz",
        "Av",
        "Elul",
        "Tishrei",
        "Cheshvan",
        "Kislev",
        "Teves",
        "Shevat",
        "Adar",
        "Adar II",
        "Adar I"
    ]
    
    static let hebrewMonths = [
        "ניסן",
        "אייר",
        "סיוון",
        "תמוז",
        "אב",
        "אלול",
        "תשרי",
        "חשוון",
        "כסלו",
        "טבת",
        "שבט",
        "אדר",
        "אדר ב",
        "אדר א"
    ]
    
    /// List of holidays transliterated into Latin chars. This is used by the
    /// _[formatYomTov(JewishCalendar)]_ when formatting the Yom Tov String. The default list of months uses
    /// Ashkenazi pronunciation in typical American English spelling.
    static let transliteratedHolidays = [
        "Erev Pesach",
        "Pesach",
        "Chol Hamoed Pesach",
        "Pesach Sheni",
        "Erev Shavuos",
        "Shavuos",
        "Seventeenth of Tammuz",
        "Tishah B'Av",
        "Tu B'Av",
        "Erev Rosh Hashana",
        "Rosh Hashana",
        "Fast of Gedalyah",
        "Erev Yom Kippur",
        "Yom Kippur",
        "Erev Succos",
        "Succos",
        "Chol Hamoed Succos",
        "Hoshana Rabbah",
        "Shemini Atzeres",
        "Simchas Torah",
        "Erev Chanukah",
        "Chanukah",
        "Tenth of Teves",
        "Tu B'Shvat",
        "Fast of Esther",
        "Purim",
        "Shushan Purim",
        "Purim Katan",
        "Erev Rosh Chodesh",
        "Rosh Chodesh",
        "Yom HaShoah",
        "Yom Hazikaron",
        "Yom Ha'atzmaut",
        "Yom Yerushalayim",
        "Lag B'Omer",
        "Shushan Purim Katan",
        "Isru Chag"
    ]
    
    /// Hebrew holiday list
    static let hebrewHolidays = [
        "ערב פסח",
        "פסח",
        "חול המועד פסח",
        "פסח שני",
        "ערב שבועות",
        "שבועות",
        "שבעה עשר בתמוז",
        "תשעה באב",
        "ט״ו באב",
        "ערב ראש השנה",
        "ראש השנה",
        "צום גדליה",
        "ערב יום כיפור",
        "יום כיפור",
        "ערב סוכות",
        "סוכות",
        "חול המועד סוכות",
        "הושענא רבה",
        "שמיני עצרת",
        "שמחת תורה",
        "ערב חנוכה",
        "חנוכה",
        "עשרה בטבת",
        "ט״ו בשבט",
        "תענית אסתר",
        "פורים",
        "פורים שושן",
        "פורים קטן",
        "ערב ראש חודש",
        "ראש חודש",
        "יום השואה",
        "יום הזיכרון",
        "יום העצמאות",
        "יום ירושלים",
        "ל״ג בעומר",
        "פורים שושן קטן",
        "אסרו חג"
    ]
    
    static let hebrewShortHolidays = [
        "ער״פ",
        "פסח",
        "חוהמ״פ",
        "פ״ש",
        "ערב שבועות",
        "שבועות",
        "יז בתמוז",
        "תשעה באב",
        "ט״ו באב",
        "ער״ה",
        "ר״ה",
        "צום גדליה",
        "עיו'כ",
        "כיפור",
        "ערב סוכות",
        "סוכות",
        "חומה״ס",
        "הו״ר",
        "שמ״ע",
        "שמח״ת",
        "ערב חנוכה",
        "חנוכה",
        "עשרה בטבת",
        "ט״ו בשבט",
        "תענית אסתר",
        "פורים",
        "פורים שושן",
        "פורים קטן",
        "ער״ח    ",
        "ר״ח",
        "יום השואה",
        "יום הזיכרון",
        "יום העצמאות",
        "יום ירושלים",
        "ל״ג בעומר",
        "פורים שושן קטן",
        "אסרו חג"
    ]
    
    static let longOmerDay = [
        "הַיּוֹם יוֹם אֶחָד לָעֹמֶר:",
        "הַיּוֹם שְׁנֵי יָמִים לָעֹמֶר:",
        "הַיּוֹם שְׁלֹשָׁה יָמִים לָעֹמֶר:",
        "הַיּוֹם אַרְבָּעָה יָמִים לָעֹמֶר:",
        "הַיּוֹם חֲמִשָּׁה יָמִים לָעֹמֶר:",
        "הַיּוֹם שִׁשָּׁה יָמִים לָעֹמֶר:",
        "הַיּוֹם שִׁבְעָה יָמִים לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד:",
        "הַיּוֹם שְׁמוֹנָה יָמִים לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד ויוֹם אֶחָד:",
        "הַיּוֹם תִּשְׁעָה יָמִים לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד וּשְׁנֵי יָמִים:",
        "הַיּוֹם עֲשָׂרָה יָמִים לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם אַחַד עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד ואַרְבָּעָה יָמִים:",
        "הַיּוֹם שְׁנֵים עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם שְׁלֹשָׁה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שָׁבוּעַ אֶחָד ושִׁשָּׁה יָמִים:",
        "הַיּוֹם אַרְבָּעָה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת:",
        "הַיּוֹם חֲמִשָּׁה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת ויוֹם אֶחָד:",
        "הַיּוֹם שִׁשָּׁה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת וּשְׁנֵי יָמִים:",
        "הַיּוֹם שִׁבְעָה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם שְׁמוֹנָה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת ואַרְבָּעָה יָמִים:",
        "הַיּוֹם תִּשְׁעָה עָשָׂר יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם עֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁנֵי שָׁבוּעוֹת ושִׁשָּׁה יָמִים:",
        "הַיּוֹם אֶחָד וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת:",
        "הַיּוֹם שְׁנַיִם וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת ויוֹם אֶחָד:",
        "הַיּוֹם שְׁלֹשָׁה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת וּשְׁנֵי יָמִים:",
        "הַיּוֹם אַרְבָּעָה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם חֲמִשָּׁה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת ואַרְבָּעָה יָמִים:",
        "הַיּוֹם שִׁשָּׁה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם שִׁבְעָה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם שׁלֹשָׁה שָׁבוּעוֹת ושִׁשָּׁה יָמִים:",
        "הַיּוֹם שְׁמוֹנָה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת:",
        "הַיּוֹם תִּשְׁעָה וְעֶשְׂרִים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת ויוֹם אֶחָד:",
        "הַיּוֹם שׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת וּשְׁנֵי יָמִים:",
        "הַיּוֹם אֶחָד וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם שְׁנַיִם וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת ואַרְבָּעָה יָמִים:",
        "הַיּוֹם שְׁלֹשָׁה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם אַרְבָּעָה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת ושִׁשָּׁה יָמִים:",
        "הַיּוֹם חֲמִשָּׁה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת:",
        "הַיּוֹם שִׁשָּׁה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת ויוֹם אֶחָד:",
        "הַיּוֹם שִׁבְעָה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת וּשְׁנֵי יָמִים:",
        "הַיּוֹם שְׁמוֹנָה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם תִּשְׁעָה וּשְׁלֹשִׁים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת ואַרְבָּעָה יָמִים:",
        "הַיּוֹם אַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם אֶחָד וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם חֲמִשָּׁה שָׁבוּעוֹת ושִׁשָּׁה יָמִים:",
        "הַיּוֹם שְׁנַיִם וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת:",
        "הַיּוֹם שְׁלֹשָׁה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת ויוֹם אֶחָד:",
        "הַיּוֹם אַרְבָּעָה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת וּשְׁנֵי יָמִים:",
        "הַיּוֹם חֲמִשָּׁה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת וּשְׁלֹשָׁה יָמִים:",
        "הַיּוֹם שִׁשָּׁה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת ואַרְבָּעָה יָמִים:",
        "הַיּוֹם שִׁבְעָה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים:",
        "הַיּוֹם שְׁמוֹנָה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁשָּׁה שָׁבוּעוֹת ושִׁשָּׁה יָמִים:",
        "הַיּוֹם תִּשְׁעָה וְאַרְבָּעִים יוֹם לָעֹמֶר, שֶׁהֵם שִׁבְעָה שָׁבוּעוֹת:"
    ]
    
    static let hebrewParshaMap: [Parsha: String] = [
        .none: "",
        .bereshis: "בראשית",
        .noach: "נח",
        .lech_lecha: "לך לך",
        .vayera: "וירא",
        .chayei_sara: "חיי שרה",
        .toldos: "תולדות",
        .vayetzei: "ויצא",
        .vayishlach: "וישלח",
        .vayeshev: "וישב",
        .miketz: "מקץ",
        .vayigash: "ויגש",
        .vayechi: "ויחי",
        .shemos: "שמות",
        .vaera: "וארא",
        .bo: "בא",
        .beshalach: "בשלח",
        .yisro: "יתרו",
        .mishpatim: "משפטים",
        .terumah: "תרומה",
        .tetzaveh: "תצוה",
        .ki_sisa: "כי תשא",
        .vayakhel: "ויקהל",
        .pekudei: "פקודי",
        .vayikra: "ויקרא",
        .tzav: "צו",
        .shmini: "שמיני",
        .tazria: "תזריע",
        .metzora: "מצרע",
        .achrei_mos: "אחרי מות",
        .kedoshim: "קדושים",
        .emor: "אמור",
        .behar: "בהר",
        .bechukosai: "בחקתי",
        .bamidbar: "במדבר",
        .nasso: "נשא",
        .behaaloscha: "בהעלתך",
        .shlach: "שלח לך",
        .korach: "קרח",
        .chukas: "חוקת",
        .balak: "בלק",
        .pinchas: "פינחס",
        .matos: "מטות",
        .masei: "מסעי",
        .devarim: "דברים",
        .vaeschanan: "ואתחנן",
        .eikev: "עקב",
        .reeh: "ראה",
        .shoftim: "שופטים",
        .ki_seitzei: "כי תצא",
        .ki_savo: "כי תבוא",
        .nitzavim: "ניצבים",
        .vayeilech: "וילך",
        .haazinu: "האזינו",
        .vzos_haberacha: "וזאת הברכה",
        .vayakhel_pekudei: "ויקהל פקודי",
        .tazria_metzora: "תזריע מצרע",
        .achrei_mos_kedoshim: "אחרי מות קדושים",
        .behar_bechukosai: "בהר בחקתי",
        .chukas_balak: "חוקת בלק",
        .matos_masei: "מטות מסעי",
        .nitzavim_vayeilech: "ניצבים וילך",
        .shkalim: "שקלים",
        .zachor: "זכור",
        .para: "פרה",
        .hachodesh: "החדש",
        .shuva: "שובה",
        .shira: "שירה",
        .hagadol: "הגדול",
        .chazon: "חזון",
        .nachamu: "נחמו"
    ]
    
    static let transliteratedParshaMap: [Parsha: String] = [
        .none: "",
        .bereshis: "Bereshis",
        .noach: "Noach",
        .lech_lecha: "Lech Lecha",
        .vayera: "Vayera",
        .chayei_sara: "Chayei Sara",
        .toldos: "Toldos",
        .vayetzei: "Vayetzei",
        .vayishlach: "Vayishlach",
        .vayeshev: "Vayeshev",
        .miketz: "Miketz",
        .vayigash: "Vayigash",
        .vayechi: "Vayechi",
        .shemos: "Shemos",
        .vaera: "Vaera",
        .bo: "Bo",
        .beshalach: "Beshalach",
        .yisro: "Yisro",
        .mishpatim: "Mishpatim",
        .terumah: "Terumah",
        .tetzaveh: "Tetzaveh",
        .ki_sisa: "Ki Sisa",
        .vayakhel: "Vayakhel",
        .pekudei: "Pekudei",
        .vayikra: "Vayikra",
        .tzav: "Tzav",
        .shmini: "Shmini",
        .tazria: "Tazria",
        .metzora: "Metzora",
        .achrei_mos: "Achrei Mos",
        .kedoshim: "Kedoshim",
        .emor: "Emor",
        .behar: "Behar",
        .bechukosai: "Bechukosai",
        .bamidbar: "Bamidbar",
        .nasso: "Nasso",
        .behaaloscha: "Beha'aloscha",
        .shlach: "Sh'lach",
        .korach: "Korach",
        .chukas: "Chukas",
        .balak: "Balak",
        .pinchas: "Pinchas",
        .matos: "Matos",
        .masei: "Masei",
        .devarim: "Devarim",
        .vaeschanan: "Vaeschanan",
        .eikev: "Eikev",
        .reeh: "Re'eh",
        .shoftim: "Shoftim",
        .ki_seitzei: "Ki Seitzei",
        .ki_savo: "Ki Savo",
        .nitzavim: "Nitzavim",
        .vayeilech: "Vayeilech",
        .haazinu: "Ha'Azinu",
        .vzos_haberacha: "Vezos Habracha",
        .vayakhel_pekudei: "Vayakhel Pekudei",
        .tazria_metzora: "Tazria Metzora",
        .achrei_mos_kedoshim: "Achrei Mos Kedoshim",
        .behar_bechukosai: "Behar Bechukosai",
        .chukas_balak: "Chukas Balak",
        .matos_masei: "Matos Masei",
        .nitzavim_vayeilech: "Nitzavim Vayeilech",
        .shkalim: "Shekalim",
        .zachor: "Zachor",
        .para: "Parah",
        .hachodesh: "Hachodesh",
        .shuva: "Shuva",
        .shira: "Shira",
        .hagadol: "Hagadol",
        .chazon: "Chazon",
        .nachamu: "Nachamu",
    ]
    
    /// Formats the Yom Tov (holiday) in Hebrew or transliterated Latin characters.
    ///
    /// @param jewishCalendar the JewishCalendar
    /// @return the formatted holiday or an empty String if the day is not a holiday.
    /// @see #isHebrewFormat()
    public func formatYomTov(_ cal: JewishCalendar) throws -> String? {
        let chag = cal.getCurrentChag()
        guard let chag = chag else {
            return nil
        }
        
        if cal.isChanukah {
            let dayOfChanukah = cal.dayOfChanukah
            return hebrewFormat
            ? (try formatHebrewNumber(dayOfChanukah!) + " " + HebrewDateFormatter.hebrewHolidays[chag.rawValue])
            : (HebrewDateFormatter.transliteratedHolidays[chag.rawValue] + " \(dayOfChanukah!)")
        }
        
        return hebrewFormat
        ? (useShortHolidayFormat
           ? HebrewDateFormatter.hebrewShortHolidays[chag.rawValue]
           : HebrewDateFormatter.hebrewHolidays[chag.rawValue])
        : HebrewDateFormatter.transliteratedHolidays[chag.rawValue]
    }
    
    /// Formats a day as Rosh Chodesh in the format of in the format of ראש חודש שבט
    /// or Rosh Chodesh Shevat. If it is not Rosh Chodesh, an empty <code>String</code> will be returned.
    /// @param jewishCalendar the JewishCalendar
    /// @return The formatted <code>String</code> in the format of ראש חודש שבט
    /// or Rosh Chodesh Shevat. If it is not Rosh Chodesh, an empty <code>String</code> will be returned.
    public func formatRoshChodesh(_ cal: JewishCalendar) -> String? {
        let jewishCalendar = cal
        if !jewishCalendar.isRoshChodesh {
            return nil
        }
        var formattedRoshChodesh = ""
        var month = cal.month
        if cal.day == 30 {
            if month.rawValue < JewishMonth.adar.rawValue ||
                (month == JewishMonth.adar && jewishCalendar.isJewishLeapYear) {
                month = JewishMonth(rawValue: jewishCalendar.month.rawValue + 1)!
            } else {
                month = JewishMonth.nissan
            }
        }
        
        let tempCal = jewishCalendar.copy(month: month, day: 1)
        formattedRoshChodesh = hebrewFormat
        ? (useShortHolidayFormat
           ? HebrewDateFormatter.hebrewShortHolidays[JewishHoliday.roshChodesh.rawValue]
           : HebrewDateFormatter.hebrewHolidays[JewishHoliday.roshChodesh.rawValue])
        : HebrewDateFormatter.transliteratedHolidays[JewishHoliday.roshChodesh.rawValue]
        
        formattedRoshChodesh += " " + formatMonth(tempCal)
        
        return formattedRoshChodesh
    }
    
    /// Formats a day as Erev Rosh Chodesh in the format of in the format of ערב ראש חודש שבט
    /// or Rosh Chodesh Shevat. If it is not Erev Rosh Chodesh, an empty <code>String</code> will be returned.
    /// @param jewishCalendar the JewishCalendar
    /// @return The formatted <code>String</code> in the format of ערב ראש חודש שבט
    /// or Rosh Chodesh Shevat. If it is not Rosh Chodesh, an empty <code>String</code> will be returned.
    public func formatErevRoshChodesh(_ cal: JewishCalendar) -> String? {
        if !cal.isErevRoshChodesh {
            return ""
        }
        
        var month = cal.month
        
        var formattedErevRoshChodesh = ""
        if cal.day == 29 {
            if cal.month.rawValue < JewishMonth.adar.rawValue ||
                (cal.month == JewishMonth.adar && cal.isJewishLeapYear) {
                month = JewishMonth(rawValue: Int(cal.month.rawValue + 1))!
            } else {
                month = JewishMonth.nissan
            }
        }
        
        // This method is only about formatting, so we shouldn"t make any changes to the params passed in...
        let tempCal = cal.copy(month: month, day: 1)
        formattedErevRoshChodesh = hebrewFormat
        ? (useShortHolidayFormat
           ? HebrewDateFormatter.hebrewShortHolidays[JewishHoliday.erevRoshChodesh.rawValue]
           : HebrewDateFormatter.hebrewHolidays[JewishHoliday.erevRoshChodesh.rawValue])
        : HebrewDateFormatter.transliteratedHolidays[JewishHoliday.erevRoshChodesh.rawValue]
        formattedErevRoshChodesh += " " + formatMonth(tempCal)
        return formattedErevRoshChodesh
    }
    
    /// Returns a string of the current Hebrew month such as "Tishrei".
    /// Returns a string of the current Hebrew month such as "אדר ב׳".
    ///
    /// @param jewishDate
    ///            the JewishDate to format
    /// @return the formatted month name
    /// @see #isHebrewFormat()
    /// @see #setHebrewFormat(letean)
    /// @see #getTransliteratedMonthList()
    /// @see #setTransliteratedMonthList(String[])
    public func formatMonth(_ jewishDate: JewishDate) -> String {
        let month = jewishDate.month
        if hebrewFormat {
            if jewishDate.isJewishLeapYear && month == JewishMonth.adar {
                return HebrewDateFormatter.hebrewMonths[13] +
                (useGershGershayim
                 ? HebrewDateFormatter._GERESH
                 : "") // return Adar I, not Adar in a leap year
            } else if jewishDate.isJewishLeapYear && month == JewishMonth.adar2 {
                return HebrewDateFormatter.hebrewMonths[12] + (useGershGershayim ? HebrewDateFormatter._GERESH : "")
            } else {
                return HebrewDateFormatter.hebrewMonths[month.rawValue - 1]
            }
        } else {
            if jewishDate.isJewishLeapYear && month == JewishMonth.adar {
                return HebrewDateFormatter.transliteratedMonths[
                    13] // return Adar I, not Adar in a leap year
            } else {
                return HebrewDateFormatter.transliteratedMonths[month.rawValue - 1]
            }
        }
    }
    
    private static let monthNameMap = [
        "Heshvan": "Cheshvan",
        "Tishri": "Tishrei"
    ]
    
    public func formatDate(_ jewishDate: JewishDate, pattern: String = "d MMMM, yyyy") throws -> String {
        let formatter = DateFormatter()
        
        formatter.calendar = Calendar(identifier: .hebrew)
        formatter.locale = Locale(identifier: hebrewFormat ? "he" : "en")
        formatter.dateFormat = pattern
        //        formatter.setLocalizedDateFormatFromTemplate(pattern)
        
        var ret = formatter.string(from: jewishDate.gregDate)
        
        for m in HebrewDateFormatter.monthNameMap {
            ret = ret.replacingOccurrences(of: m.key, with: m.value)
        }
        
        return ret
    }
    
    /// Returns a String of the Omer day in the form ל״ג בעומר if Hebrew Format is set,
    /// or "Omer X" or "Lag BaOmer" if not. An empty string if there is no Omer this day.
    ///
    /// @param jewishCalendar
    ///            the JewishCalendar to be formatted
    ///
    /// @return a String of the Omer day in the form or an empty string if there is no Omer this day. The default
    ///         formatting has a ב׳ prefix that would output בעומר, but this
    ///         can be set via the {@link #hebrewOmerPrefix}  to use a ל and output ל״ג לעומר.
    /// @see #isHebrewFormat()
    /// @see #getHebrewOmerPrefix()
    /// @see #setHebrewOmerPrefix(String)
    public func formatOmer(jewishCalendar: JewishCalendar) throws -> String? {
        guard let omer = jewishCalendar.dayOfOmer else { return nil }
        
        if hebrewFormat {
            return longOmerFormat
            ? HebrewDateFormatter.longOmerDay[omer - 1]
            : try formatHebrewNumber(omer) + " " + hebrewOmerPrefix + "עומר"
        } else {
            if omer == 33 {
                return HebrewDateFormatter.transliteratedHolidays[JewishHoliday.lagBaomer.rawValue]
            } else {
                return "Omer \(omer)"
            }
        }
    }
    
    ///
    /// Formats the [Daf Yomi](https://en.wikipedia.org/wiki/Daf_Yomi) Bavli in the format of
    /// "&#x05E2&#x05D9&#x05E8&#x05D5&#x05D1&#x05D9&#x05DF &#x05E0&#x05F4&#x05D1" in [hebrewFormat],
    /// or the transliterated format of "Eruvin 52".
    ///
    /// @param daf the Daf to be formatted.
    /// @return the formatted daf.
    ///
    public func formatDafYomi(daf: Daf) throws -> String {
        if hebrewFormat {
            return try daf.masechta + " " + formatHebrewNumber(daf.daf)
        } else {
            return "\(daf.masechtaTransliterated) \(daf.daf)"
        }
    }
    
    /// Returns a Hebrew formatted string of a number. The method can calculate from 0 - 9999.
    /// <ul>
    /// <li>Single digit numbers such as 3, 30 and 100 will be returned with a ׳ (<a
    /// href="http://en.wikipedia.org/wiki/Geresh">Geresh</a>) appended as at the end. For example ג׳, and ק׳</li>
    /// <li>multi digit numbers such as 21 and 769 will be returned with a ״ (<a href="http://en.wikipedia.org/wiki/Gershayim">Gershayim</a>)
    /// between the second to last and last letters. For example כ״א, תשכ״ט</li>
    /// <li>15 and 16 will be returned as ט״ו and ט״ז</li>
    /// <li>Single digit numbers (years assumed) such as 6000 (%1000=0) will be returned as ו׳ אלפים</li>
    /// <li>0 will return אפס</li>
    /// </ul>
    ///
    /// @param number
    ///            the number to be formatted. It will trow an IllegalArgumentException if the number is &lt 0 or &gt 9999.
    /// @return the Hebrew formatted number such as תשכ״ט
    /// @see #isUseFinalFormLetters()
    /// @see #isUseGershGershayim()
    /// @see #isHebrewFormat()
    ///
    public func formatHebrewNumber(_ num: Int) throws ->  String {
        var number = num
        if number < 0 {
            throw HebrewFormatterError.ParameterError("negative numbers can't be formatted")
        } else if number > 9999 {
            throw HebrewFormatterError.ParameterError("numbers > 9999 can't be formatted")
        }
        
        let ALAFIM = "אלפים"
        let EFES = "אפס"
        
        let jHundreds = [
            "",
            "ק",
            "ר",
            "ש",
            "ת",
            "תק",
            "תר",
            "תש",
            "תת",
            "תתק"
        ]
        let jTens = ["", "י", "כ", "ל", "מ", "נ", "ס", "ע", "פ", "צ"]
        let jTenEnds = ["", "י", "ך", "ל", "ם", "ן", "ס", "ע", "ף", "ץ"]
        let tavTaz = ["טו", "טז"]
        let jOnes = ["", "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט"]
        
        if number == 0 {
            // do we really need this? Should it be applicable to a date?
            return EFES
        }
        let shortNumber = number % 1000 // discard thousands
        // next check for all possible single Hebrew digit years
        let singleDigitNumber = (shortNumber < 11 ||
                                 (shortNumber < 100 && shortNumber % 10 == 0) ||
                                 (shortNumber <= 400 && shortNumber % 100 == 0))
        let thousands = number / 1000 // get # thousands
        var sb = ""
        // append thousands to String
        if number % 1000 == 0 {
            // in year is 5000, 4000 etc
            sb.append(jOnes[thousands])
            if useGershGershayim {
                sb.append(HebrewDateFormatter._GERESH)
            }
            sb.append(" ")
            sb.append(
                ALAFIM) // add # of thousands plus word thousand (overide alafim letean)
            return sb
        } else if useLongHebrewYears && number >= 1000 {
            // if alafim letean display thousands
            sb.append(jOnes[thousands])
            if useGershGershayim {
                sb.append(HebrewDateFormatter._GERESH) // write thousands quote
            }
            sb.append(" ")
        }
        number = number % 1000 // remove 1000s
        let hundreds = number / 100 // # of hundreds
        sb.append(jHundreds[hundreds]) // add hundreds to String
        number = number % 100 // remove 100s
        if number == 15 {
            // special case 15
            sb.append(tavTaz[0])
        } else if number == 16 {
            // special case 16
            sb.append(tavTaz[1])
        } else {
            let tens = number / 10
            if number % 10 == 0 {
                // if evenly divisable by 10
                if !singleDigitNumber {
                    if useFinalFormLetters {
                        sb.append(jTenEnds[
                            tens]) // years like 5780 will end with a final form &#x05E3
                    } else {
                        sb.append(jTens[
                            tens]) // years like 5780 will end with a regular &#x05E4
                    }
                } else {
                    sb.append(jTens[
                        tens]) // standard letters so years like 5050 will end with a regular nun
                }
            } else {
                sb.append(jTens[tens])
                number = number % 10
                sb.append(jOnes[number])
            }
        }
        
        if useGershGershayim {
            if singleDigitNumber {
                sb.append(HebrewDateFormatter._GERESH) // write single quote
            } else {
                // write double quote before last digit
                let str = sb
                return "\(str.prefix(str.count - 1))\(HebrewDateFormatter._GERSHAYIM)\(str.last!)"
            }
        }
        return sb
    }
    
    public func formatParsha(_ parsha: Parsha) -> String {
        (hebrewFormat
                ? HebrewDateFormatter.hebrewParshaMap[parsha]
                : HebrewDateFormatter.transliteratedParshaMap[parsha])!
    }
    
    public func formatSpecialParsha(jewishCalendar: JewishCalendar) -> String {
        let specialParsha = jewishCalendar.getSpecialShabbos()
        return (hebrewFormat
                ? HebrewDateFormatter.hebrewParshaMap[specialParsha]
                : HebrewDateFormatter.transliteratedParshaMap[specialParsha])!
    }
}

public enum HebrewFormatterError: Error {
    case ParameterError(String)
}
