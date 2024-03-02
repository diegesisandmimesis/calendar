#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the calendar library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
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
		local c, i;

		// Create a calendar with a current date of June 22, 1979.
		c = new Calendar(1979, 6, 22);

		// Loop through a hundred days.
		for(i = 1; i <= 100; i++) {
			// Output information about the current date.
			_logDate(c);

			// Advance the calendar's date by one day.
			c.advanceDay();
		}
	}

	// Log some stuff about the date:
	_logDate(d) {
		"Date: <<d.getMonthName()>> <<toString(d.getDay())>>,
			<<toString(d.getYear())>>\n ";
		"Season: <<d.getSeasonName()>>\n ";
		"Phase of moon: <<toString(d.getMoonPhaseName())>>\n ";
		"<.p> ";
	}
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
