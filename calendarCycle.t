#charset "us-ascii"
//
// calendarCycle.t
//
//	Extensions to implement daily cycles of fixed "slots".
//
//	Cycles are implemented using two classes:  DailyCycle and Period.
//	Period instances define intervals during the day, and DailyCycle
//	is a container for holding Periods (and methods for working with
//	them).
//
//
// EXAMPLE
//
//	The simpleDay singleton is an example DailyCycle defined in
//	calendarCycles.t .
//
//		SimpleDay: DailyCycle;
//			+Period 'early' 'Early Morning' +4;
//			+Period 'morning' 'Morning' +8;
//			+Period 'afternoon' 'Afternoon' +12;
//			+Period 'evening' 'Evening' +19;
//			+Period 'night' 'Nighttime' +22;
//
//	The Period template includes the ID (first single-quoted string),
//	an optional name (second single-quoted string, if present), and
//	the hour the period starts (the number after the '+').
//
//	Periods run from their stated starting hour until the next
//	declared period.  So in this example 'early' runs from 04:00
//	to 07:00, because the next period after it is 'morning' starting
//	at 08:00.
//
//	The periods automatically "wrap" around the end of day, so in this
//	example 'night' runs from 22:00 (its declared starting time) to
//	03:00 (because the next declared period is 'early' starting at
//	04:00).
//
//
// METHODS
//
//	There are methods available on the DailyCycle instance itself, but
//	in most cases you'll want to associate a DailyCycle instance with
//	a Calendar, and then use the methods on the Calendar instance.
//
//
//	SETTING THE CYCLE
//
//		The simpleDay example described above is the default calendar
//		cycle.  If you want to assign a different cycle, you can use
//		something like:
//
//			// Use the medieval canonical hour daily cycle.
//			gCalendar.setDailyCycle(canonicalHours);
//
//
//	SETTING THE PERIOD
//
//		You can move the calendar's current time to be the start of
//		any period defined for the cycle by using setPeriod():
//
//			// Set the time to local 18:00.  Only works if the daily
//			// cycle is canonicalHours.
//			gCalendar.setPeriod('vespers');
//
//		By default setPeriod() keeps the current date, only changing
//		the time.  You can set both the date and period at the same
//		time with setDateAndPeriod():
//
//			// Set the current time to be Vespers on June 22, 1979:
//			gCalendar.setDateAndPeriod(1979, 6, 22, 'vespers');
//
//		You can advance to a specific period in the next day
//		using setPeriodNextDay():
//
//			// Set the current time to be Lauds on June 23, 1979:
//			gCalendar.setPeriodNextDay('lauds');
//
//
//	GETTING THE PERIOD BY HOUR
//
//		You can also get the period for a given hour with
//		matchPeriod().  The optional argument is the hour to
//		query.  If no argument is given, the calendar's current
//		hour will be used.
//
//			// Will return 'compline', if the cycle is
//			// canonicalHours.
//			id = gCalendar.matchPeriod(1);
//
//
#include <adv3.h>
#include <en_us.h>

#include "bignum.h"

#include "calendar.h"

calendarCyclePreinit: PreinitObject
	execute() {
		initPeriods();
		initCycles();
	}

	initPeriods() {
		forEachInstance(Period, function(o) {
			o.initializePeriod();
		});
	}

	initCycles() {
		forEachInstance(DailyCycle, function(o) {
			o.initializeDailyCycle();
		});
	}
;

class DailyCycle: object
	// A table containing the Period instances for this cycle, keyed
	// by ID.
	periodTable = nil

	// A 24-element vector in which each element is the ID of a period,
	// and the index is the hour it represents plus one (the indices
	// are 1-24 and the hours are 0-23, with index 1 being hour 0).
	periodVector = nil

	// Sorted list of the period IDs
	periods = nil

	initializeDailyCycle() {
	}

	// Create our data structures.
	initPeriodTable() {
		periodTable = new LookupTable();
		periodVector = new Vector(24, 24);
	}

	// Adds a period to the cycle
	addPeriod(obj) {
		// Make sure the arg is a valid Period.
		if((obj == nil) || !obj.ofKind(Period))
			return(nil);

		// Initialize the lookup table if it doesn't already exist.
		if(periodTable == nil)
			initPeriodTable();

		// Add the Period to the table.
		periodTable[obj.id] = obj;

		// Re-twiddle the vector.
		_recalculateHours();

		return(true);
	}

	// Twiddles the periodVector vector to reflect the current cycle
	// contents.
	_recalculateHours() {
		local h, i, id, j;

		// Get a list of the values in the table, sorted in ascending
		// order by their hour.
		periods = periodTable.valsToList().sort(nil,
			{ a, b: a.hour - b.hour });

		// Start out with an hour of one and the ID of the LAST hour
		// of the cycle (in case the first enumerated period doesn't
		// start precisely at midnight).
		h = 1;
		id = periods[periods.length].id;

		// Go through the sorted list of periods, filling in
		// the 24-element vector's slots with the ID corresponding
		// to each hour.
		for(i = 1; i <= periods.length; i++) {
			// Fill in the hours from the last hour we handled
			// through this Period's start time.  Note that
			// our index here (j) is the hour plus one.
			for(j = h; j <= (periods[i].hour + 1); j++)
				periodVector[j] = id;

			// Remember the highest slot we've filled, and
			// the ID of the current period.
			h = (periods[i].hour + 1);
			id = periods[i].id;
		}

		// Fill out the last bit of the day, in case the last period
		// doesn't end at 23:00.
		for(j = h; j <= 24; j++)
			periodVector[j] = id;
	}

	// Returns the period object for the given period ID.
	getPeriod(id) { return(periodTable ? periodTable[id] : nil);  }

	// Returns the period ID for the given hour.
	matchPeriod(h) {
		if(periodVector == nil)
			initPeriodTable();

		return(periodVector[(h % 24) + 1]);
	}
;

class Period: object
	id = nil		// unique (in the cycle) ID for the period
	name = nil		// optional name for the period
	hour = nil		// the hour the period starts

	construct(v?, n?, h?) {
		if(v != nil) id = v;
		if(n != nil) name = n;
		if(h != nil) hour = h;
	}

	initializePeriod() {
		if((location == nil) || !location.ofKind(DailyCycle))
			return;
		location.addPeriod(self);
	}
;

modify Calendar
	dailyCycle = nil

	setDailyCycle(v) {
		if((v == nil) || !v.ofKind(DailyCycle))
			return(nil);
		dailyCycle = v;

		return(true);
	}

	getDailyCycle() {
		if(dailyCycle == nil)
			dailyCycle = simpleDay;
		return(dailyCycle);
	}

	setPeriod(id) {
		local obj;

		if(id == nil)
			return(nil);
		if((obj = getDailyCycle().getPeriod(id)) == nil)
			return(nil);

		setTime(obj.hour);

		return(true);
	}

	setPeriodNextDay(id) {
		advanceDay();
		setPeriod(id);
	}

	matchPeriod(h?) { return(getDailyCycle().matchPeriod(resolveHour(h))); }

	currentPeriod() { return(matchPeriod()); }

	// Advance to the next period, advancing the day if necessary.
	advancePeriod() {
		local c, id, idx, p;

		if((id = matchPeriod()) == nil)
			return(nil);

		c = getDailyCycle();
		if(c.periods == nil)
			return(nil);

		if((p = c.getPeriod(id)) == nil)
			return(nil);

		if((idx = c.periods.indexOf(p)) == nil)
			return(nil);

		idx += 1;
		if(idx > c.periods.length) {
			advanceDay();
			idx = 1;
		}
		p = c.periods[idx];
		setPeriod(p.id);

		return(true);
	}

	setDateAndPeriod(y, m, d, id) {
		setYMD(y, m, d);
		setPeriod(id);
	}
;
