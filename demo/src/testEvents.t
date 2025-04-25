#charset "us-ascii"
//
// testEvents.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the calendar library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f testEvents.t3m
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
	showIntro() {
		"Use <<inlineCommand('advance time')>> to advance the
		calendar to the next step in the daily cycle (afternoon
		becomes evening, evening becomes night, and so on).
		<.p>
		Each time this happens a notification should be displayed.
		<.p> ";
	}
	newGame() {
		gCalendar.subscribe(myNotifier);
		inherited();
	}
;

myNotifier: EventListener
	eventHandler(obj) {
		// We're subscribed to ALL calendar notifications, so
		// we filter here in the handler.  We could
		// alternately add an event type as the second arg
		// when we subscribe.
		if(obj.type != 'dateChange')
			return;
		"<.p>This is the rather useless event handler.<.p> ";
	}
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;

DefineSystemAction(AdvanceTime)
	execSystemAction() {
		local c;

		defaultReport('Time advances. ');
		c = gCalendar;
		if(c.advancePeriod() == nil) {
			reportFailure('That didn\'t work for some reason. ');
			exit;
		}
		defaultReport('It is now <<toString(c.matchPeriod())>>
			on the <<toString(c.getDayOrd())>>. ');
	}
;
VerbRule(AdvanceTime) 'advance' 'time': AdvanceTimeAction;

DefineSystemAction(CheckTime)
	execSystemAction() {
		local c;

		c = gCalendar;
		defaultReport('It is now <<toString(c.matchPeriod())>>
			on the <<toString(c.getDayOrd())>>. ');
	}
;
VerbRule(CheckTime) 'check' 'time': CheckTimeAction;
