//
// calendar.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_CALENDAR

#define gSetDate(y, m, d) (gameCalendar.setYMD(y, m, d))
#define gSetTime(h) (gameCalendar.setTime(h))
#define gCalendar (gameCalendar)

#define CALENDAR_H
