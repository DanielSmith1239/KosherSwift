import com.kosherjava.zmanim.ComplexZmanimCalendar;
import com.kosherjava.zmanim.ZmanimCalendar;
import com.kosherjava.zmanim.hebrewcalendar.HebrewDateFormatter;
import com.kosherjava.zmanim.hebrewcalendar.JewishCalendar;
import com.kosherjava.zmanim.hebrewcalendar.JewishDate;
import com.kosherjava.zmanim.hebrewcalendar.TefilaRules;
import com.kosherjava.zmanim.util.GeoLocation;

import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

/**
 * Runs the cases in Tests/KosherSwiftTests/KosherJavaParityTests.swift against KosherJava 2.5.0 (the release KosherSwift
 * was ported from) and asserts the same expected values. See run.sh.
 */
public class KosherJavaParity {
	private static int failures = 0;
	private static int checks = 0;

	private static final GeoLocation NEW_YORK = new GeoLocation("New York", 40.7128, -74.0060, 0, TimeZone.getTimeZone("America/New_York"));
	private static final GeoLocation APIA = new GeoLocation("Apia", -13.8333, -171.7667, 0, TimeZone.getTimeZone("Pacific/Apia"));
	private static final GeoLocation LONDON = new GeoLocation("London", 51.5074, -0.1278, 0, TimeZone.getTimeZone("Europe/London"));

	public static void main(String[] args) {
		holidays();
		moladAndKiddushLevana();
		tefilaRules();
		formatting();
		zmanim();
		System.out.println(checks + " checks, " + failures + " failures");
		System.exit(failures == 0 ? 0 : 1);
	}

	private static void check(String name, Object actual, Object expected) {
		checks++;
		if (expected == null ? actual != null : !expected.equals(actual)) {
			failures++;
			System.out.println("FAIL " + name + ": got " + actual + ", expected " + expected);
		}
	}

	private static void checkInstant(String name, Date actual, long expectedMillis) {
		checks++;
		if (actual == null || Math.abs(actual.getTime() - expectedMillis) > 1000) {
			failures++;
			System.out.println("FAIL " + name + ": got " + (actual == null ? null : actual.getTime()) + ", expected " + expectedMillis);
		}
	}

	private static JewishCalendar jc(int year, int month, int day) {
		return new JewishCalendar(year, month, day);
	}

	private static JewishCalendar jc(int year, int month, int day, boolean inIsrael) {
		return new JewishCalendar(year, month, day, inIsrael);
	}

	private static JewishCalendar gregorian(int year, int month, int day) {
		JewishCalendar cal = new JewishCalendar();
		cal.setGregorianDate(year, month - 1, day);
		return cal;
	}

	private static ComplexZmanimCalendar zmanim(GeoLocation location, int year, int month, int day) {
		ComplexZmanimCalendar cal = new ComplexZmanimCalendar(location);
		cal.getCalendar().set(year, month - 1, day);
		return cal;
	}

	private static void holidays() {
		JewishCalendar erevRoshChodesh = jc(5785, JewishDate.CHESHVAN, 29);
		check("29 Cheshvan isErevRoshChodesh", erevRoshChodesh.isErevRoshChodesh(), true);
		check("29 Cheshvan isErevYomTov", erevRoshChodesh.isErevYomTov(), false);
		check("29 Cheshvan isYomTov", erevRoshChodesh.isYomTov(), false);

		JewishCalendar kislev29 = jc(5785, JewishDate.KISLEV, 29);
		check("29 Kislev isYomTov", kislev29.isYomTov(), true);
		check("29 Kislev chag", kislev29.getYomTovIndex(), JewishCalendar.CHANUKAH);
		check("29 Kislev tachanun", new TefilaRules().isTachanunRecitedShacharis(kislev29), false);

		check("1 Shevat isYomTov", jc(5785, JewishDate.SHEVAT, 1).isYomTov(), false);

		JewishCalendar tammuz17 = jc(5789, JewishDate.TAMMUZ, 17);
		JewishCalendar tammuz18 = jc(5789, JewishDate.TAMMUZ, 18);
		check("17 Tammuz 5789 day of week", tammuz17.getDayOfWeek(), Calendar.SATURDAY);
		check("17 Tammuz 5789 fast", tammuz17.getYomTovIndex() == JewishCalendar.SEVENTEEN_OF_TAMMUZ, false);
		check("17 Tammuz 5789 isTaanis", tammuz17.isTaanis(), false);
		check("18 Tammuz 5789 fast", tammuz18.getYomTovIndex() == JewishCalendar.SEVENTEEN_OF_TAMMUZ, true);
		check("18 Tammuz 5789 isTaanis", tammuz18.isTaanis(), true);

		JewishCalendar iyar5 = jc(5784, JewishDate.IYAR, 5);
		JewishCalendar iyar6 = jc(5784, JewishDate.IYAR, 6);
		iyar5.setUseModernHolidays(true);
		iyar6.setUseModernHolidays(true);
		check("5 Iyar 5784 day of week", iyar5.getDayOfWeek(), Calendar.MONDAY);
		check("5 Iyar 5784 Yom HaZikaron", iyar5.getYomTovIndex() == JewishCalendar.YOM_HAZIKARON, true);
		check("6 Iyar 5784 Yom HaZikaron", iyar6.getYomTovIndex() == JewishCalendar.YOM_HAZIKARON, false);
		check("6 Iyar 5784 Yom Ha'atzmaut", iyar6.getYomTovIndex() == JewishCalendar.YOM_HAATZMAUT, true);

		check("23 Nissan isIsruChag", jc(5785, JewishDate.NISSAN, 23).isIsruChag(), true);
		check("22 Nissan Israel isIsruChag", jc(5785, JewishDate.NISSAN, 22, true).isIsruChag(), true);
		check("24 Tishrei isIsruChag", jc(5785, JewishDate.TISHREI, 24).isIsruChag(), true);
		check("23 Tishrei Israel isIsruChag", jc(5785, JewishDate.TISHREI, 23, true).isIsruChag(), true);
		check("23 Tishrei isIsruChag", jc(5785, JewishDate.TISHREI, 23).isIsruChag(), false);

		JewishCalendar hoshanaRabba = jc(5785, JewishDate.TISHREI, 21);
		check("Hoshana Rabba isCholHamoedSuccos", hoshanaRabba.isCholHamoedSuccos(), true);
		check("Hoshana Rabba chag", hoshanaRabba.getYomTovIndex(), JewishCalendar.HOSHANA_RABBA);
		check("Hoshana Rabba isYomTov", hoshanaRabba.isYomTov(), true);

		JewishCalendar kislev30 = jc(5785, JewishDate.KISLEV, 30);
		check("30 Kislev chag", kislev30.getYomTovIndex(), JewishCalendar.CHANUKAH);
		check("30 Kislev formatYomTov", new HebrewDateFormatter().formatYomTov(kislev30), "Chanukah 6");

		check("Shabbos HaGadol", jc(5785, JewishDate.NISSAN, 14).getSpecialShabbos(), JewishCalendar.Parsha.HAGADOL);
		check("Shabbos Shira", gregorian(2025, 2, 8).getSpecialShabbos(), JewishCalendar.Parsha.SHIRA);
		check("Shabbos Chazon", gregorian(2025, 8, 2).getSpecialShabbos(), JewishCalendar.Parsha.CHAZON);
		check("Shabbos Nachamu", gregorian(2025, 8, 9).getSpecialShabbos(), JewishCalendar.Parsha.NACHAMU);
		check("Shabbos Shuva", gregorian(2024, 10, 5).getSpecialShabbos(), JewishCalendar.Parsha.SHUVA);
		check("Hagadol formatted", new HebrewDateFormatter().formatSpecialParsha(jc(5785, JewishDate.NISSAN, 14)), "Hagadol");
	}

	private static void moladAndKiddushLevana() {
		JewishCalendar teves = jc(5784, JewishDate.TEVES, 1);
		JewishDate molad = teves.getMolad();
		check("molad hours", molad.getMoladHours(), 20);
		check("molad minutes", molad.getMoladMinutes(), 1);
		check("molad chalakim", molad.getMoladChalakim(), 3);
		checkInstant("molad", teves.getMoladAsDate(), 1702402813504L);
		checkInstant("Kiddush Levana 3 days", teves.getTchilasZmanKidushLevana3Days(), 1702662013504L);
		checkInstant("Kiddush Levana between moldos", teves.getSofZmanKidushLevanaBetweenMoldos(), 1703678535170L);
	}

	private static void tefilaRules() {
		TefilaRules rules = new TefilaRules();
		check("Hallel 15 Nissan", rules.isHallelRecited(jc(5785, JewishDate.NISSAN, 15)), true);
		check("Hallel 15 Nissan Israel", rules.isHallelRecited(jc(5785, JewishDate.NISSAN, 15, true)), true);
		check("Hallel 23 Tishrei", rules.isHallelRecited(jc(5785, JewishDate.TISHREI, 23)), true);
		check("Hallel 23 Tishrei Israel", rules.isHallelRecited(jc(5785, JewishDate.TISHREI, 23, true)), false);
		check("Hallel Shalem 15 Nissan", rules.isHallelShalemRecited(jc(5785, JewishDate.NISSAN, 15)), true);

		check("V'sein tal umatar Sat 5 Dec 2020", rules.isVeseinTalUmatarStartDate(gregorian(2020, 12, 5)), false);
		check("V'sein tal umatar Sun 6 Dec 2020", rules.isVeseinTalUmatarStartDate(gregorian(2020, 12, 6)), true);
		check("V'sein tal umatar Fri 5 Dec 2025", rules.isVeseinTalUmatarStartDate(gregorian(2025, 12, 5)), true);
	}

	private static void formatting() {
		HebrewDateFormatter formatter = new HebrewDateFormatter();
		formatter.setHebrewFormat(true);
		check("Nissan", formatter.formatMonth(new JewishDate(5785, JewishDate.NISSAN, 1)), "ניסן");
		check("Adar", formatter.formatMonth(new JewishDate(5785, JewishDate.ADAR, 1)), "אדר");
		check("Adar I", formatter.formatMonth(new JewishDate(5784, JewishDate.ADAR, 1)), "אדר א׳");
		check("Adar II", formatter.formatMonth(new JewishDate(5784, JewishDate.ADAR_II, 1)), "אדר ב׳");
		check("Rosh Chodesh Nissan", formatter.formatRoshChodesh(jc(5785, JewishDate.NISSAN, 1)),
				"ראש חודש ניסן");
	}

	private static void zmanim() {
		check("Apia antimeridian adjustment", APIA.getAntimeridianAdjustment(), -1);
		check("Apia local mean time offset", APIA.getLocalMeanTimeOffset(), -88024008L);
		ComplexZmanimCalendar apia = zmanim(APIA, 2025, 6, 15);
		checkInstant("Apia sunrise", apia.getSeaLevelSunrise(), 1749923284242L);
		checkInstant("Apia sunset", apia.getSeaLevelSunset(), 1749964017721L);
		checkInstant("Apia fixed local chatzos", apia.getFixedLocalChatzos(), 1749943624008L);

		ComplexZmanimCalendar ny = zmanim(NEW_YORK, 2025, 6, 15);
		checkInstant("New York fixed local chatzos", ny.getFixedLocalChatzos(), 1750006561440L);
		checkInstant("New York sunrise", ny.getSeaLevelSunrise(), 1749979456066L);

		ComplexZmanimCalendar london = zmanim(LONDON, 2025, 6, 21);
		check("London alos 16.1", london.getAlos16Point1Degrees(), null);
		check("London plag 16.1", london.getPlagHamincha16Point1Degrees(), null);
		check("London mincha gedola 16.1", london.getMinchaGedola16Point1Degrees(), null);
		check("London mincha ketana 16.1", london.getMinchaKetana16Point1Degrees(), null);
		checkInstant("London GRA plag", london.getPlagHamincha(), 1750531057068L);

		// Swift candleLighting() on the second night of Rosh Hashana == 13.5 minutes before 7.083 degrees
		ComplexZmanimCalendar roshHashana = zmanim(NEW_YORK, 2024, 10, 3);
		checkInstant("RH second night candle lighting", roshHashana.getBainHashmashosRT13Point5MinutesBefore7Point083Degrees(), 1727996002341L);
		check("RH second night candle lighting after sunset",
				roshHashana.getBainHashmashosRT13Point5MinutesBefore7Point083Degrees().after(roshHashana.getSeaLevelSunset()), true);

		// 29 Teves 5785 (Wed 29 Jan 2025) is Erev Rosh Chodesh on a weekday: no candle lighting
		check("29 Teves 5785 date", jc(5785, JewishDate.TEVES, 29).getGregorianDayOfMonth(), 29);
		check("Erev Rosh Chodesh hasCandleLighting", gregorian(2025, 1, 29).hasCandleLighting(), false);

		// Swift getTaanisStartTime() for Tisha B'Av 5785 == sunset on Shabbos 2 Aug 2025
		checkInstant("Tisha B'Av start", zmanim(NEW_YORK, 2025, 8, 2).getSeaLevelSunset(), 1754179798622L);
	}
}
