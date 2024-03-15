#charset "us-ascii"
//
// calendarDebug.t
//
#include <adv3.h>
#include <en_us.h>

#include "calendar.h"

#ifdef __DEBUG

modify Calendar
	_debugDailyCycle() {
		if(dailyCycle == nil) {
			"No daily cycle\n ";
			return;
		}
		dailyCycle._debugDailyCycle();
	}
;

modify DailyCycle
	// Go through a 24 hour cycle, outputting the period ID for
	// each hour.
	_debugDailyCycle() {
		local c, i, id;

		c = new Calendar();
		c.dailyCycle = self;

		for(i = 0; i <= 23; i++) {
			c.setTime(i);
			"\n<<sprintf('%02d', i)>>:\t";
			if((id = c.matchPeriod(i)) == nil)
				"no period";
			else
				"<<id>>";
			"\n ";
		}
	}
;

DefineLiteralAction(SetDate)
	execAction() {
		local ar, c, str;

		str = getLiteral();
		ar = str.split(R'<space>');
		if((ar.length < 3) || (ar.length > 4)) {
			reportFailure('Usage:  set date &lt;month number&gt;
				&lt;day numer&gt; [&lt;hour&gt;]');
			exit;
		}
		gSetDate(toInteger(ar[1]), toInteger(ar[2]), toInteger(ar[3]));
		if(ar.length == 4)
			gSetTime(toInteger(ar[4]));

		c = gCalendar;
		"It is now <<toString(c.getHour())>>:00
			<<c.getMonthName()>> <<toString(c.getDay())>>,
			<<toString(c.getYear())>>.\n ";
		"<.p> ";
		"Season: <<c.getSeasonName()>>\n ";
		"Phase of Moon: <<c.getMoonPhaseName()>>\n ";
	}
;

VerbRule(SetDate)
	'set' 'date' singleLiteral: SetDateAction
	verbPhrase = 'set/setting date to (what)'
;

DefineSystemAction(DebugDate)
	execSystemAction() {
		local c;

		c = gCalendar;

		"It is now <<toString(c.getHour)>>:00
			<<c.getMonthName()>> <<toString(c.getDay())>>,
			<<toString(c.getYear())>>.\n ";
	}
;
VerbRule(DebugDate) 'debug' 'date': DebugDateAction
	verbPhrase = 'debug/debugging the date'
;

#endif // __DEBUG
