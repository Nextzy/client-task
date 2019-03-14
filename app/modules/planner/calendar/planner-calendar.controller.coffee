class PlannerCalendarController
  @.$inject = [
    "$scope"
    "$location",
    "$tgNavUrls", 
    "uiCalendarConfig"
  ]

  constructor: (@scope, @location, @navUrls) -> 
    console.log("Calendar")
    @scope.eventSources = []
    @scope.uiConfig = {
      calendar: {
        header: {
          left: ""
          center: "title"
          right: ""
        }, 
        footer: {
          right: "today prev,next"
        }, 
        editable: true,
        droppable: true, 
        eventStartEditable: true,
        eventDurationEditable: false,
        defaultTimedEventDuration: "00:30",
        # handleWindowResize: true,
        titleFormat: "D MMM YYYY",
        defaultView: "agendaDay", 
        allDaySlot: false, 
        # dragScroll: false
      }
    }

angular.module("taigaPlanner").controller("PlannerCalendarController", PlannerCalendarController)