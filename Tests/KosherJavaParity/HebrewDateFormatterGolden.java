import com.kosherjava.zmanim.hebrewcalendar.Daf;
import com.kosherjava.zmanim.hebrewcalendar.HebrewDateFormatter;
import com.kosherjava.zmanim.hebrewcalendar.JewishCalendar;

/**
 * Prints KosherJava 2.5.0's HebrewDateFormatter output for the cases in
 * Tests/KosherSwiftTests/KosherJava/HebrewDateFormatterGolden.txt, one tab-separated row per case. run.sh compares
 * this output with that file, and HebrewDateFormatterTests.swift checks KosherSwift against the same file.
 */
public class HebrewDateFormatterGolden {
	private static final StringBuilder out = new StringBuilder();

	private static void row(Object... fields) {
		for (int i = 0; i < fields.length; i++) {
			out.append(i == 0 ? "" : "\t").append(fields[i]);
		}
		out.append('\n');
	}

	private static HebrewDateFormatter formatter(boolean hebrew, boolean gersh, boolean longYears, boolean finalForm) {
		HebrewDateFormatter f = new HebrewDateFormatter();
		f.setHebrewFormat(hebrew);
		f.setUseGershGershayim(gersh);
		f.setUseLongHebrewYears(longYears);
		f.setUseFinalFormLetters(finalForm);
		return f;
	}

	public static void main(String[] args) throws Exception {
		int[] numbers = {0, 1, 3, 9, 10, 11, 14, 15, 16, 17, 19, 20, 21, 30, 40, 50, 80, 90, 99, 100, 101, 115, 116, 200,
				300, 400, 410, 500, 600, 700, 769, 800, 900, 999, 1000, 1001, 1015, 2000, 5000, 5015, 5016, 5050, 5100,
				5729, 5760, 5770, 5780, 5784, 5790, 5800, 6000, 9999};
		for (int n : numbers) {
			for (int flags = 0; flags < 8; flags++) {
				boolean gersh = (flags & 1) != 0, longYears = (flags & 2) != 0, finalForm = (flags & 4) != 0;
				row("number", n, gersh, longYears, finalForm, formatter(true, gersh, longYears, finalForm).formatHebrewNumber(n));
			}
		}

		for (int year = 5780; year <= 5790; year++) {
			row("kviah", year, new HebrewDateFormatter().getFormattedKviah(year));
		}

		for (int masechta = 0; masechta < 40; masechta++) {
			for (int daf : new int[] {2, 15, 21}) {
				Daf d = new Daf(masechta, daf);
				row("daf", masechta, daf, formatter(true, true, false, false).formatDafYomiBavli(d),
						formatter(false, true, false, false).formatDafYomiBavli(d));
				if (masechta < 39) {
					row("dafYerushalmi", masechta, daf, formatter(true, true, false, false).formatDafYomiYerushalmi(d),
							formatter(false, true, false, false).formatDafYomiYerushalmi(d));
				}
			}
		}

		HebrewDateFormatter heb = formatter(true, true, false, false);
		HebrewDateFormatter hebNoGersh = formatter(true, false, false, false);
		HebrewDateFormatter translit = formatter(false, true, false, false);
		translit.setLongWeekFormat(true); // 2.5.0 only creates its day-of-week formatter here
		HebrewDateFormatter hebShortWeek = formatter(true, true, false, false);
		hebShortWeek.setLongWeekFormat(false);
		for (int year = 5784; year <= 5785; year++) { // 5784 is a leap year
			JewishCalendar cal = new JewishCalendar(year, JewishCalendar.TISHREI, 1);
			cal.setUseModernHolidays(true); // KosherSwift always includes Yom Hashoah, Yom Hazikaron etc.
			while (cal.getJewishYear() == year) {
				JewishCalendar israel = (JewishCalendar) cal.clone();
				israel.setInIsrael(true);
				row("day", cal.getJewishYear(), cal.getJewishMonth(), cal.getJewishDayOfMonth(),
						heb.format(cal), hebNoGersh.format(cal), translit.format(cal),
						heb.formatMonth(cal), hebNoGersh.formatMonth(cal), translit.formatMonth(cal),
						heb.formatDayOfWeek(cal), hebShortWeek.formatDayOfWeek(cal), translit.formatDayOfWeek(cal),
						heb.formatYomTov(cal), translit.formatYomTov(cal), heb.formatYomTov(israel), translit.formatYomTov(israel),
						heb.formatRoshChodesh(cal), translit.formatRoshChodesh(cal),
						heb.formatOmer(cal), translit.formatOmer(cal),
						heb.formatParsha(cal), translit.formatParsha(cal), heb.formatParsha(israel), translit.formatParsha(israel),
						heb.formatSpecialParsha(cal), translit.formatSpecialParsha(cal));
				cal.forward(java.util.Calendar.DATE, 1);
			}
		}
		System.out.print(out);
	}
}
