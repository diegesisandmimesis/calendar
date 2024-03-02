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
//		// Outputs "spring".
//		"<<c.getSeasonName()>>";
//
//	Getting the season value, which is an enum consisting of:
//	seasonWinter, seasonSpring, seasonSummer, seasonFall.
//
//		// Assigns seasonSpring to s.
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

	construct(y?, m?, d?) {
		if(y && m && d) {
			if(!m) m = 1;
			if(!d) d = 1;
			startingDate = new Date(y, m, d);
		} else {
			startingDate = new Date();
		}
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

	getSeason(m?, d?) {
		local d0;

		if(_seasons == nil)
			_initSeasons();

		if(m == nil)
			m = getMonth();
		if(d == nil)
			d = getDay();

		d0 = new Date(2012, m, d);
		
		if((d0.compareTo(_seasons[eWinterSolstice]) >= 0)
			|| (d0.compareTo(_seasons[eSpringEquinox]) < 0))
			return(seasonWinter);
		if((d0.compareTo(_seasons[eSpringEquinox]) >= 0)
			|| (d0.compareTo(_seasons[eSummerSolstice]) < 0))
			return(seasonSpring);
		if((d0.compareTo(_seasons[eSummerSolstice]) >= 0)
			|| (d0.compareTo(_seasons[eFallEquinox]) < 0))
			return(seasonSummer);
		return(seasonFall);
	}

	getSeasonName(m?, d?) {
		return(_seasonName[getSeason(m, d)]);
	}

	// Functionally identical to the nethack moon phase code, given in
	// hacklib.c phase_of_moon()
	getMoonPhase() {
		local d, e, g;

		d = getDayOfYear();
		g = (getYear() % 19) + 1;
		e = ((11 * g) + 18) % 30;
		if(((e == 25) && (g > 11)) || (e == 24))
			e++;

		return( ((((((d + e) * 6) + 11) % 177) / 22) & 7) + 1);
	}

	getMoonPhaseName() {
		return(_moonPhase[getMoonPhase()]);
	}

	getDay() { return(parseInt(currentDate.formatDate('%d'))); }
	getDayOrd() { return(currentDate.formatDate('%t')); }
	getMonth() { return(parseInt(currentDate.formatDate('%m'))); }
	getMonthName() { return(currentDate.formatDate('%B')); }
	getMonthAbbr() { return(currentDate.formatDate('%b')); }
	getYear() { return(parseInt(currentDate.formatDate('%Y'))); }
	getDayOfYear() { return(parseInt(currentDate.formatDate('%j'))); }

	advanceDay() { currentDate = currentDate.addInterval([0, 0, 1]); }
	advanceMonth() { currentDate = currentDate.addInterval([0, 1, 0]); }
	advanceYear() { currentDate = currentDate.addInterval([1, 0, 0]); }
;
