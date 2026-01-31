#charset "us-ascii"
//
// calendar.t
//
//	A TADS3/adv3 module for managing calendars and calendar-based
//	cycles, like seasons and phases of the moon.
//
//	Internally the module uses TADS3's Date class to track dates
//	and do date-based arithmetic.
//
//	Seasons are based on fixed-date solstices and equinoxes, which
//	is an approximation but will be accurate to +/- one day.
//
//	The moon phase is always one of eight discrete phases: the
//	four major phases (new, first quarter, full, third quarter); and
//	the minor phases (waxing and waning gibbous and crescent), meaning
//	each phase lasts several days.  The algorithm used to calculate the
//	phase is the one used by nethack, which is an approximation but is
//	accurate to within a day.
//
//
// USAGE:
//
//	Create a calendar instance:
//
//		// Creates a calendar, current date June 22, 1979.
//		local c = new Calendar(1979, 6, 22);
//
//	Basic date information:
//
//		// Outputs "June 22, 1979".
//		"<<c.getMonthName()>> <<toString(c.getDay())>>,
//			<<toString(c.getYear())>>\n ";
//
//
//	Getting the season name:
//
//		// Outputs "summer".
//		"<<c.getSeasonName()>>";
//
//	Getting the season value, which is an enum consisting of:
//	seasonWinter, seasonSpring, seasonSummer, seasonFall.
//
//		// Assigns seasonSummer to s.
//		local s = c.getSeason();
//
//
//	Get the name of the moon phase:
//
//		// Outputs "new"
//		"<<c.getMoonPhaseName()>>";
//
//	Get the numeric moon phase, an integer from 1 and 8, with 1 new
//	and 4 full.
//
//		// Assigns 1 to v
//		local v = c.getMoonPhase();
//
//
// GLOBAL GAME CALENDAR
//
//	In addition to the usage above (creating standalone calendars),
//	by default the module creates a global Calendar instance, gameCalendar.
//
//	By default the calendar is created with the local system time as
//	the current date and time.
//
//	The following macros use the global calendar:
//
//		gCalendar		returns the global Calendar instance
//		gSetDate(y, m, d)	sets the year, month, and day of the
//						global calendar
//		gSetTime(h)		sets the hour of the global calendar
//
//
// GLOBAL GAME ENVIRONMENT
//
//	In addition to the global calendar, the module defines a
//	gameEnvironment singleton to make configuring things easier.
//
//	The gameEnvironment.currentTime property, if non-nil, will be used
//	to set the starting calendar time during preinit.
//
//		// Sets the starting date/time to be June 22, 1979, at
//		// 23:00 local time.
//		// The Date syntax is just the standard TADS3 Date syntax.
//		modify gameEnvironment
//			currentDate = new Date(1979, 6, 22, 23, 0, 0, 0,
//				'EST-5EDT');
//		;
//
//	By itself this doesn't accomplish much (you can declare the time
//	exactly the same way on gameCalendar), but other modules (like
//	the nightSky module) will also use the gameEnvironment singleton to
//	configure things, enabling you to set everything in one place.
//
//
#include <adv3.h>
#include <en_us.h>

#include "bignum.h"

#include "calendar.h"

#include "date.h"

// Module ID for the library
calendarModuleID: ModuleID {
        name = 'Calendar Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

enum seasonWinter, seasonSpring, seasonSummer, seasonFall;
enum eWinterSolstice, eSpringEquinox, eSummerSolstice, eFallEquinox;

#ifdef CALENDAR_EVENTS
class Calendar: EventNotifier
#else // CALENDAR_EVENTS
class Calendar: object
#endif // CALENDAR_EVENTS
	// Update cached computations if the time has changed by this many
	// seconds.
	// By default we update if the difference is a day or more.
	updateInterval = 86400

	startingDate = nil
	currentDate = nil

	// Cached values
	_season = nil
	_phase = nil
	_sidereal = nil

	longitude = nil

	// Save the timezone, because Date will only return the LOCAL timezone
	_tz = nil

	_seasons = nil

	_seasonName = static [
		seasonWinter -> 'winter',
		seasonSpring -> 'spring',
		seasonSummer -> 'summer',
		seasonFall -> 'fall'
	]

	_moonPhase = static [
		'new',
		'waxing crescent',
		'first quarter',
		'waxing gibbous',
		'full',
		'waning gibbous',
		'last quarter',
		'waning crescent'
	]

	construct(y?, m?, d?, tz?) {
		if(y != nil) {
			if(!m) m = 1;
			if(!d) d = 1;
			startingDate = new Date(y, m, d, tz);
		} else {
			startingDate = new Date();
		}
		if(tz != nil)
			_tz = tz;
		currentDate = startingDate;
	}

	_initSeasons() {
		local t;

		t = new LookupTable();
		t[eWinterSolstice] = new Date(2012, 12, 15);
		t[eSpringEquinox] = new Date(2012, 3, 15);
		t[eSummerSolstice] = new Date(2012, 6, 15);
		t[eFallEquinox] = new Date(2012, 9, 15);

		_seasons = t;
	}

	// Returns the difference between the passed Date and the
	// currentDate, in seconds.
	dateDiff(v) {
		return(currentDate
			? abs(toInteger((v - currentDate) * 86400)) : nil);
	}

	getSeason(v?) {
		local d0, d, m;

		if(_season != nil)
			return(_season);

		if(_seasons == nil)
			_initSeasons();

		m = getMonth(v);
		d = getDay(v);

		d0 = new Date(2012, m, d);

		if((d0.compareTo(_seasons[eWinterSolstice]) >= 0)
			|| (d0.compareTo(_seasons[eSpringEquinox]) < 0)) {
			_season = seasonWinter;
		} else if((d0.compareTo(_seasons[eSpringEquinox]) >= 0)
			&& (d0.compareTo(_seasons[eSummerSolstice]) < 0)) {
			_season = seasonSpring;
		} else if((d0.compareTo(_seasons[eSummerSolstice]) >= 0)
			&& (d0.compareTo(_seasons[eFallEquinox]) < 0)) {
			_season = seasonSummer;
		} else {
			_season = seasonFall;
		}

		return(_season);
	}

	getSeasonName(v?) {
		return(_seasonName[getSeason(v)]);
	}

	// Functionally identical to the nethack moon phase code, given in
	// hacklib.c phase_of_moon()
	getMoonPhase(v?) {
		local d, e, g, r;

		if((_phase != nil) && (v == nil))
			return(_phase);

		d = getDayOfYear(v);
		g = (getYear(v) % 19) + 1;
		e = ((11 * g) + 18) % 30;
		if(((e == 25) && (g > 11)) || (e == 24))
			e++;

		r = ( ((((((d + e) * 6) + 11) % 177) / 22) & 7) + 1);
		if(v == nil)
			_phase = r;
		return(r);
	}

	getMoonPhaseName(v?) {
		return(_moonPhase[getMoonPhase(v)]);
	}

	getDay(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%d', _tz)));
	}
	getDayOrd(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%t', _tz));
	}
	getMonth(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%m', _tz)));
	}
	getMonthName(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%B', _tz));
	}
	getMonthAbbr(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%b', _tz));
	}
	getYear(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%Y', _tz)));
	}
	getDayOfYear(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%j', _tz)));
	}
	getDayOfWeek(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%w', _tz)));
	}
	getDayOfWeekName(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%A', _tz));
	}
	getTZ(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%z'));
	}
	getTZOffset(v?) {
		v = (v ? v : currentDate);
		return(toInteger(v.formatDate('%Z', _tz)) / 100);
	}
	getTZUTCOffset(v?) {
		local off;
		off = getTZOffset(v);
		return('UTC<<((off > 0) ? '+' : '')>><<toString(off)>>');
	}
	getHour(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%H', _tz)));
	}
	getJulianDate(v?) {
		v = (v ? v : currentDate);
		return(parseInt(v.formatDate('%J')));
	}
	getFullJulianDate(v?) {
		v = (v ? v : currentDate);
		return(v.formatDate('%J'));
	}
	getTimestamp(v?) {
		v = (v ? v : currentDate);
		return(toInteger(v.formatDate('%s')));
	}

	cloneDate() {
		return(new Date(toInteger(currentDate.formatDate('%s')), 'U'));
	}

	resolveHour(h?) { return(h ? h : getHour()); }

	setDate(v?, j?) {
		if((v == nil) || !v.ofKind(Date))
			return;

		if(dateDiff(v) >= updateInterval)
			clearCache();

		currentDate = v;
	}

	setYMD(y, m, d, tz?, j?) {
		setDate(new Date(y, m, d, tz), j);
	}

	setHour(h, j?) { setTime(h, j); }

	setTime(h, j?) {
		setDate(new Date(getYear(), getMonth(), getDay(),
			(h % 24), 0, 0, 0, _tz), j);
	}

	advanceDay(j?) { setDate(currentDate.addInterval([0, 0, 1]), j); }
	advanceMonth(j?) { setDate(currentDate.addInterval([0, 1, 0]), j); }
	advanceYear(j?) { setDate(currentDate.addInterval([1, 0, 0]), j); }
	advanceHour(j?) { setDate(currentDate.addInterval([0, 0, 0, 1]), j); }

	clearCache() {
		_season = nil;
		_phase = nil;
		_sidereal = nil;
	}

	// Get a (very) approximate Greenwich sidereal time at midnight.
	getSiderealTime(v?) {
		local d0, jd;

		if((_sidereal != nil) && (v == nil))
			return(_sidereal);

		d0 = new Date(getYear(v), getMonth(v), getDay(v),
			_tz);

		jd = d0.getJulianDay();
		jd -= 2451545.0;
		jd = (18.697375 + (24.065709824279 * jd));
		jd = toInteger(jd.roundToDecimal(0)) % 24;


		while(jd < 0)
			jd += 24;
		while(jd > 24)
			jd -= 24;
		if(v == nil)
			_sidereal = jd;

		return(jd);
	}

	// Get the local sidereal time.  
	// First arg is the local hour, second is the local longitude.
	getLocalSiderealTime(h?, long?) {
		local st;

		if(h == nil)
			h = 0;
		st = getSiderealTime() + h;
		if(long != nil)
			st += (long / 15);
		while(st < 0)
			st += 24;
		while (st > 24)
			st -= 24;
		return(st);
	}
;

// Global game calendar.
gameCalendar: Calendar, PreinitObject
	execBeforeMe = static [ gameEnvironment ]
	execute() {
		if(currentDate == nil)
			currentDate = new Date();
		if(startingDate == nil)
			startingDate = currentDate;
	}
;

gameEnvironment: PreinitObject
	currentDate = nil

	execute() {
		if(currentDate != nil)
			gameCalendar.currentDate = currentDate;
	}
;
