//
//  JewishMonth.swift
//  YidKitiOS
//
//  Created by Daniel Smith on 12/19/23.
//

/// An Object representing a *daf* (page) in the [Daf Yomi](https://en.wikipedia.org/wiki/Daf_Yomi) cycle.
public struct Daf {
    /// Gets the *masechta* number of the currently set *Daf*. The sequence is: Berachos, Shabbos, Eruvin, Pesachim,
    /// Shekalim, Yoma, Sukkah, Beitzah, Rosh Hashana, Taanis, Megillah, Moed Katan, Chagigah, Yevamos, Kesubos,
    /// Nedarim, Nazir, Sotah, Gitin, Kiddushin, Bava Kamma, Bava Metzia, Bava Basra, Sanhedrin, Makkos, Shevuos, Avodah
    /// Zarah, Horiyos, Zevachim, Menachos, Chullin, Bechoros, Arachin, Temurah, Kerisos, Meilah, Kinnim, Tamid, Midos
    /// and Niddah.
    ///
    /// - Returns: the masechtaNumber.
    public let masechtaNumber: Int

    /// Returns the *daf* (page) number of the Daf Yomi.
    ///
    /// - Returns: the *daf* (page) number of the Daf Yomi.
    public let daf: Int
    public let dafType: DafType
    
    init(masechta masechtaNumber: Int, daf: Int, dafType: DafType) {
        self.masechtaNumber = masechtaNumber
        self.daf = daf
        self.dafType = dafType
    }
    
    static private var masechtosBavliTransliterated = [
        "Berachos",
        "Shabbos",
        "Eruvin",
        "Pesachim",
        "Shekalim",
        "Yoma",
        "Sukkah",
        "Beitzah",
        "Rosh Hashana",
        "Taanis",
        "Megillah",
        "Moed Katan",
        "Chagigah",
        "Yevamos",
        "Kesubos",
        "Nedarim",
        "Nazir",
        "Sotah",
        "Gitin",
        "Kiddushin",
        "Bava Kamma",
        "Bava Metzia",
        "Bava Basra",
        "Sanhedrin",
        "Makkos",
        "Shevuos",
        "Avodah Zarah",
        "Horiyos",
        "Zevachim",
        "Menachos",
        "Chullin",
        "Bechoros",
        "Arachin",
        "Temurah",
        "Kerisos",
        "Meilah",
        "Kinnim",
        "Tamid",
        "Midos",
        "Niddah"
    ]
    
    static let masechtosBavli = [
        "ברכות",
        "שבת",
        "עירובין",
        "פסחים",
        "שקלים",
        "יומא",
        "סוכה",
        "ביצה",
        "ראש השנה",
        "תענית",
        "מגילה",
        "מועד קטן",
        "חגיגה",
        "יבמות",
        "כתובות",
        "נדרים",
        "נזיר",
        "סוטה",
        "גיטין",
        "קידושין",
        "בבא קמא",
        "בבא מציעא",
        "בבא בתרא",
        "סנהדרין",
        "מכות",
        "שבועות",
        "עבודה זרה",
        "הוריות",
        "זבחים",
        "מנחות",
        "חולין",
        "בכורות",
        "ערכין",
        "תמורה",
        "כריתות",
        "מעילה",
        "קינים",
        "תמיד",
        "מידות",
        "נדה",
    ]
    
    static let masechtosYerushalmiTransliterated = [
        "Berachos",
        "Pe'ah",
        "Demai",
        "Kilayim",
        "Shevi'is",
        "Terumos",
        "Ma'asros",
        "Ma'aser Sheni",
        "Chalah",
        "Orlah",
        "Bikurim",
        "Shabbos",
        "Eruvin",
        "Pesachim",
        "Beitzah",
        "Rosh Hashanah",
        "Yoma",
        "Sukah",
        "Ta'anis",
        "Shekalim",
        "Megilah",
        "Chagigah",
        "Moed Katan",
        "Yevamos",
        "Kesuvos",
        "Sotah",
        "Nedarim",
        "Nazir",
        "Gitin",
        "Kidushin",
        "Bava Kama",
        "Bava Metzia",
        "Bava Basra",
        "Shevuos",
        "Makos",
        "Sanhedrin",
        "Avodah Zarah",
        "Horayos",
        "Nidah",
        "No Daf Today",
    ]
    
    static let masechtosYerushlmi = [
        "ברכות",
        "פיאה",
        "דמאי",
        "כלאים",
        "שביעית",
        "תרומות",
        "מעשרות",
        "מעשר שני",
        "חלה",
        "עורלה",
        "ביכורים",
        "שבת",
        "עירובין",
        "פסחים",
        "ביצה",
        "ראש השנה",
        "יומא",
        "סוכה",
        "תענית",
        "שקלים",
        "מגילה",
        "חגיגה",
        "מועד קטן",
        "יבמות",
        "כתובות",
        "סוטה",
        "נדרים",
        "נזיר",
        "גיטין",
        "קידושין",
        "בבא קמא",
        "בבא מציעא",
        "בבא בתרא",
        "שבועות",
        "מכות",
        "סנהדרין",
        "עבודה זרה",
        "הוריות",
        "נידה",
        "אין דף היום",
    ]
    
    /// Returns the *masechta* (tractate) of the Daf Yomi in Hebrew. The list is in the following format
    ///
    /// `["ברכות", "שבת", "עירובין", "פסחים", "שקלים", "יומא", "סוכה", "ביצה", "ראש השנה", "תענית", "מגילה", "מועד קטן",
    /// "חגיגה", "יבמות", "כתובות", "נדרים","נזיר", "סוטה", "גיטין", "קידושין", "בבא קמא", "בבא מציעא", "בבא בתרא",
    /// "סנהדרין", "מכות", "שבועות", "עבודה זרה", "הוריות", "זבחים", "מנחות", "חולין", "בכורות", "ערכין", "תמורה",
    /// "כריתות", "מעילה", "קינים", "תמיד", "מידות", "נדה"]`.
    ///
    /// - Returns: the *masechta* (tractate) of the Daf Yomi in Hebrew. As an example, it will return ברכות for
    ///   Berachos.
    public var masechta: String {
        dafType == .bavli ? bavliMasechta : yerushalmiMasechta
    }
    
    /// Returns the transliterated name of the *masechta* (tractate) of the Daf Yomi. The list of *mashechtos* is:
    /// Berachos, Shabbos, Eruvin, Pesachim, Shekalim, Yoma, Sukkah, Beitzah, Rosh Hashana, Taanis, Megillah, Moed
    /// Katan, Chagigah, Yevamos, Kesubos, Nedarim, Nazir, Sotah, Gitin, Kiddushin, Bava Kamma, Bava Metzia, Bava Basra,
    /// Sanhedrin, Makkos, Shevuos, Avodah Zarah, Horiyos, Zevachim, Menachos, Chullin, Bechoros, Arachin, Temurah,
    /// Kerisos, Meilah, Kinnim, Tamid, Midos and Niddah.
    ///
    /// - Returns: the transliterated name of the *masechta* (tractate) of the Daf Yomi such as Berachos.
    public var masechtaTransliterated: String {
        dafType == .bavli ? bavliMasechtaTransliterated : yerushlmiMasechtaTransliterated
    }
    
    var bavliMasechtaTransliterated: String {
        Daf.masechtosBavliTransliterated[masechtaNumber]
    }
    
    var bavliMasechta: String {
        Daf.masechtosBavli[masechtaNumber]
    }
    
    var yerushlmiMasechtaTransliterated: String {
        Daf.masechtosYerushalmiTransliterated[masechtaNumber]
    }
    
    var yerushalmiMasechta: String {
        Daf.masechtosYerushlmi[masechtaNumber]
    }
}

public enum DafType {
    case bavli, yerushalmi
}
