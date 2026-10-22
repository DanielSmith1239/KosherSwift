#!/usr/bin/env bash
# Runs the KosherJava side of KosherJavaParityTests.swift. Needs git and a JDK (11+).
#   Tests/KosherJavaParity/run.sh
# KosherJavaParity.java runs against KosherJava 2.5.0, KosherJavaYerushalmiParity.java against KosherJava master.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

run() { # tag, test class
	git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$1" https://github.com/KosherJava/zmanim "$WORK/$1"
	mkdir -p "$WORK/$1-classes"
	javac -nowarn -encoding UTF-8 -d "$WORK/$1-classes" $(find "$WORK/$1/src/main/java" -name '*.java') "$HERE/$2.java"
	echo "== $2 (KosherJava $1)"
	java -cp "$WORK/$1-classes" "$2"
}

# KosherJava's Calendar-based 2.5.0 API reads the JVM default time zone; pin it like the Swift tests' device zone
export TZ=America/New_York
run 2.5.0 KosherJavaParity
run master KosherJavaYerushalmiParity

# HebrewDateFormatterTests.swift reads KosherJava 2.5.0's formatter output from HebrewDateFormatterGolden.txt
echo "== HebrewDateFormatterGolden (KosherJava 2.5.0)"
javac -nowarn -encoding UTF-8 -cp "$WORK/2.5.0-classes" -d "$WORK/2.5.0-classes" "$HERE/HebrewDateFormatterGolden.java"
java -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Duser.language=en -Duser.country=US -cp "$WORK/2.5.0-classes" HebrewDateFormatterGolden > "$WORK/golden.txt"
diff "$HERE/../KosherSwiftTests/KosherJava/HebrewDateFormatterGolden.txt" "$WORK/golden.txt"
echo "$(wc -l < "$WORK/golden.txt") rows match HebrewDateFormatterGolden.txt"
