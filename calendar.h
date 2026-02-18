//
// calendar.h
//

#ifdef CALENDAR_EVENTS
#include "asyncEvent.h"
#ifndef ASYNC_EVENT_H
#error "This module requires the asyncEvent module."
#error "https://github.com/diegesisandmimesis/asyncEvent"
#error "It should be in the same parent directory as this module.  So if"
#error "calendar is in /home/user/tads/calendar, then"
#error "asyncEvent should be in /home/user/tads/asyncEvent ."
#endif // ASYNC_EVENT_H
#endif // CALENDAR_EVENTS

#define gSetDate(y, m, d) (gameCalendar.setYMD(y, m, d))
#define gSetTime(h) (gameCalendar.setTime(h))
#define gCalendar (gameCalendar)
#define gCalendarTime (gameCalendar.currentTime)
#define gCalendarDiff(v) (gameCalendar.dateDiff(v))

Period template 'id' 'name'? +hour;

#define CALENDAR_H
