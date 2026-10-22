import com.kosherjava.zmanim.hebrewcalendar.Daf;
import com.kosherjava.zmanim.hebrewcalendar.JewishCalendar;
import com.kosherjava.zmanim.hebrewcalendar.YerushalmiYomiCalculator;

import java.time.LocalDate;

/**
 * The Daf Yomi Yerushalmi cases from KosherJavaParityTests.swift, against KosherJava master, which fixed the DST and
 * Tisha B'Av nidche issues that 2.5.0 shares with the old KosherSwift code. See run.sh.
 */
public class KosherJavaYerushalmiParity {
	public static void main(String[] args) {
		int[][] cases = {
				// year, month, day, masechta number, daf
				{2022, 1, 15, 29, 42},
				{2022, 7, 15, 35, 7},
				{2022, 8, 5, 35, 28},
				{2022, 8, 8, 35, 30},
				{2022, 12, 1, 0, 18},
				{2023, 7, 1, 5, 16},
				{2025, 7, 15, 24, 19},
		};
		int failures = 0;
		for (int[] c : cases) {
			Daf daf = YerushalmiYomiCalculator.getDafYomiYerushalmi(new JewishCalendar(LocalDate.of(c[0], c[1], c[2])));
			if (daf == null || daf.getMasechtaNumber() != c[3] || daf.getDaf() != c[4]) {
				failures++;
				System.out.println("FAIL " + c[0] + "-" + c[1] + "-" + c[2] + ": got "
						+ (daf == null ? null : daf.getMasechtaNumber() + " " + daf.getDaf()) + ", expected " + c[3] + " " + c[4]);
			}
		}
		if (YerushalmiYomiCalculator.getDafYomiYerushalmi(new JewishCalendar(LocalDate.of(2022, 8, 7))) != null) {
			failures++;
			System.out.println("FAIL 2022-8-7: expected no daf (Tisha B'Av nidche)");
		}
		System.out.println((cases.length + 1) + " checks, " + failures + " failures");
		System.exit(failures == 0 ? 0 : 1);
	}
}
