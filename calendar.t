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

class Calendar: object
	startingDate = nil
	currentDate = nil

	// Day of year and year.  When we change the current date, we
	// recompute things when these DO NOT remain the same.
	_doy = nil
	_y = nil

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
		_doy = getDayOfYear();
		_y = getYear();
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

	// Check to see if the date has changed since we computed things.
	dateChanged() {
		return((getDayOfYear() != _doy) || (getYear() != _y));
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
	getTZ() { return(currentDate.formatDate('%z', _tz)); }
	getTZOffset() {
		return(toInteger(currentDate.formatDate('%Z', _tz)) / 100);
	}
	getTZUTCOffset() {
		local off;
		off = getTZOffset();
		return('UTC<<((off > 0) ? '+' : '')>><<toString(off)>>');
	}

	setDate(v?) {
		if((v == nil) || !v.ofKind(Date))
			return;
		currentDate = v;
		if(dateChanged()) {
			clearCache();
			_doy = getDayOfYear();
			_y = getYear();
		}
	}

	setYMD(y, m, d, tz?) {
		setDate(new Date(y, m, d, tz));
	}

	advanceDay() { setDate(currentDate.addInterval([0, 0, 1])); }
	advanceMonth() { setDate(currentDate.addInterval([0, 1, 0])); }
	advanceYear() { setDate(currentDate.addInterval([1, 0, 0])); }

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


gameCalendar: Calendar, PreinitObject
	execute() {
		if(currentDate == nil)
			currentDate = new Date();
		if(startingDate == nil)
			startingDate = currentDate;
	}
;
