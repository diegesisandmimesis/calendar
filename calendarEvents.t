#charset "us-ascii"
//
// calendarEvents.t
//
//	Extension to calendar module to allow objects to subscribe to
//	the calendar for notification when the date changes.
//
//
// USAGE
//
//	In order to subscribe to calendar events, the subscribing object
//	must declare EventListener in its class list.
//
//	By default, the object's eventHandler() method will be called when
//	a matching event is fired.  The method must accept one argument,
//	the event object.
//
//		// Declare an object with the EventListener class.
//		pebble: Thing, EventListener '(small) (round) pebble' 'pebble'
//			"A small, round pebble. "
//
//			eventHandler(e) {
//				"<.p>This is a useless event handler.<.p> ";
//			}
//		;
//
//	To subscribe for notifications:
//
//		gCalendar.subscribe(pebble);
//
//	After subscribing, the object's eventHandler() object will be
//	called whenever the calendar's date/time changes.  The argument
//	to the handler in this case will be the new date (an instance
//	of the builtin TADS3 Date class).
//
//	
//	The event logic is implemented in the eventHandler module.  See it
//	for more details.
//
#include <adv3.h>
#include <en_us.h>

#include "calendar.h"

#ifdef CALENDAR_EVENTS

modify Calendar
	setDate(v?, j?) {
		local p0, p1, o;

		// Remember the old date.
		o = currentDate;

		// Remember the old period.
		p0 = currentPeriod();

		// Run the stock method.
		inherited(v, j);

		// Get the current period.
		p1 = currentPeriod();

		// If the date didn't change, we have nothing to do.
		if(o == currentDate)
			return;

		// If the period changed, fire the periodChange event.
		if(p0 != p1)
			notifySubscribers('periodChange', [ p0, p1 ]);

		// Notify our subscribers of the date change.
		notifySubscribers('dateChange', currentDate);

		if(j == true)
			notifySubscribers('timeWarp', currentDate);
	}
;

#endif // CALENDAR_EVENTS
