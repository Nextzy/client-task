PlannerCalendarDirective = () ->
    link = (scope, el, attrs, ctrl) ->

    return {
        controller: "PlannerCalendarController",
        controllerAs: "vm",
        templateUrl: "planner/calendar/planner-calendar.html",
        scope: {},
        link: link
    }

PlannerCalendarDirective.$inject = [ ]

angular.module("taigaPlanner").directive("tgPlannerCalendar", PlannerCalendarDirective)