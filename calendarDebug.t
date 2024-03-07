#charset "us-ascii"
//
// calendarDebug.t
//
#include <adv3.h>
#include <en_us.h>

#include "calendar.h"

#ifdef __DEBUG

DefineLiteralAction(SetDate)
	execAction() {
		local ar, c, str;

		str = getLiteral();
		ar = str.split(R'<space>');
		if(ar.length != 3) {
			reportFailure('Usage:  set date &lt;month number&gt;
				&lt;day numer&gt;');
			exit;
		}
		gSetDate(toInteger(ar[1]), toInteger(ar[2]), toInteger(ar[3]));
		c = gCalendar;
		"Date is now <<c.getMonthName()>> <<toString(c.getDay())>>,
			<<toString(c.getYear())>>.\n ";
		"<.p> ";
		"Season: <<c.getSeasonName()>>\n ";
		"Phase of Moon: <<c.getMoonPhaseName()>>\n ";
	}
;

VerbRule(SetDate)
	'set' 'date' singleLiteral
	:SetDateAction
	verbPhrase = 'set/setting date to (what)'
;

#endif // __DEBUG
