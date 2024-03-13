#charset "us-ascii"
//
// calendarCycles.t
//
//	Examples of daily cycles.
//
//
#include <adv3.h>
#include <en_us.h>

#include "calendar.h"

// A simple daily cycle.  The basic design idea here is to have three
// main "phases" for the player's day:  early/planning phase;  first
// action phase; second action phase; free time/summary at the end of
// the day; and then a "not giving up/staying up too late" period
// before the cycle repeats.
simpleDay: DailyCycle;
+Period 'early' 'Early Morning' +4;	// Stayed up too late
+Period 'morning' 'Morning' +8;		// Normal start of the day
+Period 'afternoon' 'Afternoon' +12;	// Middle of the day
+Period 'evening' 'Evening' +19;	// End of the day
+Period 'night' 'Nighttime' +22;	// After hours


// Daily cycle of the common medieval canonical hours.
canonicalHours: DailyCycle;
+Period 'vigil' 'Vigil' +2;
+Period 'matins' 'Matins' +3;
+Period 'lauds' 'Lauds' +5;
+Period 'prime' 'Prime' +6;
+Period 'terce' 'Terce' +9;
+Period 'sext' 'Sext' +12;
+Period 'nones' 'Nones' +15;
+Period 'vespers' 'Vespers' +18;
+Period 'compline' 'Compline' +19;
