#charset "us-ascii"
//
// calendarCanonical.t
//
//	Calendar extension to support canonical hours as time of day.
//
//
#include <adv3.h>
#include <en_us.h>

#include "bignum.h"

#include "calendar.h"

canonicalHours: DailyCycle;
+Period 'vigil' +2;
+Period 'matins' +3;
+Period 'lauds' +5;
+Period 'prime' +6;
+Period 'terce' +9;
+Period 'sext' +12;
+Period 'nones' +15;
+Period 'vespers' +18;
+Period 'compline' +19;
