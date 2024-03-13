#charset "us-ascii"
//
// testCanonical.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the calendar library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f testCanonical.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "calendar.h"

versionInfo: GameID;
gameMain: GameMainDef
	initialPlayerChar = me
	inlineCommand(cmd) { "<b>&gt;<<toString(cmd).toUpper()>></b>"; }
	printCommand(cmd) { "<.p>\n\t<<inlineCommand(cmd)>><.p> "; }

	newGame() {
		gCalendar.dailyCycle = canonicalHours;
		gCalendar._debugDailyCycle();
		"<.p> ";

		gCalendar.setDateAndPeriod(1980, 7, 23, 'vespers');
		"Should output the date July 23, 1980, and the time 18:00.\n ";
		"<<gCalendar.currentDate.formatDate('%c')>>\n ";
		"<.p> ";

		gCalendar.setPeriodNextDay('lauds');
		"Should output the date July 24, 1980, and the time 05:00.\n ";
		"<<gCalendar.currentDate.formatDate('%c')>>\n ";
		"<.p> ";
	}

	// Log some stuff about the date:
	_logDate(d) {
		"Date: <<d.currentDate.formatDate('%c', d._tz)>>\n ";
		"<.p> ";
	}
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
