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

	getSeason() {
		local d0, d, m;

		if(_season != nil)
			return(_season);

		if(_seasons == nil)
			_initSeasons();

		m = getMonth();
		d = getDay();

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

	getSeasonName() {
		return(_seasonName[getSeason()]);
	}

	// Functionally identical to the nethack moon phase code, given in
	// hacklib.c phase_of_moon()
	getMoonPhase() {
		local d, e, g;

		if(_phase != nil)
			return(_phase);

		d = getDayOfYear();
		g = (getYear() % 19) + 1;
		e = ((11 * g) + 18) % 30;
		if(((e == 25) && (g > 11)) || (e == 24))
			e++;

		_phase = ( ((((((d + e) * 6) + 11) % 177) / 22) & 7) + 1);
		return(_phase);
	}

	getMoonPhaseName() {
		return(_moonPhase[getMoonPhase()]);
	}

	getDay() { return(parseInt(currentDate.formatDate('%d', _tz))); }
	getDayOrd() { return(currentDate.formatDate('%t', _tz)); }
	getMonth() { return(parseInt(currentDate.formatDate('%m', _tz))); }
	getMonthName() { return(currentDate.formatDate('%B', _tz)); }
	getMonthAbbr() { return(currentDate.formatDate('%b', _tz)); }
	getYear() { return(parseInt(currentDate.formatDate('%Y', _tz))); }
	getDayOfYear() { return(parseInt(currentDate.formatDate('%j', _tz))); }
	getDayOfWeek() { return(parseInt(currentDate.formatDate('%w', _tz))); }
	getDayOfWeekName() { return(currentDate.formatDate('%A', _tz)); }
	getTZ() { return(currentDate.formatDate('%z')); }
	getTZOffset() {
		return(toInteger(currentDate.formatDate('%Z', _tz)) / 100);
	}
	getTZUTCOffset() {
		local off;
		off = getTZOffset();
		return('UTC<<((off > 0) ? '+' : '')>><<toString(off)>>');
	}
	getHour() { return(parseInt(currentDate.formatDate('%H', _tz))); }
	getJulianDate() { return(parseInt(currentDate.formatDate('%J'))); }
	getFullJulianDate() { return(currentDate.formatDate('%J')); }
	getTimestamp() { return(toInteger(currentDate.formatDate('%s'))); }

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
	getSiderealTime() {
		local d0, jd;

		if(_sidereal != nil)
			return(_sidereal);

		d0 = new Date(getYear(), getMonth(), getDay(),
			_tz);

		jd = d0.getJulianDay();
		jd -= 2451545.0;
		jd = (18.697375 + (24.065709824279 * jd));
		jd = toInteger(jd.roundToDecimal(0)) % 24;


		while(jd < 0)
			jd += 24;
		while(jd > 24)
			jd -= 24;
		_sidereal = jd;

		return(_sidereal);
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
