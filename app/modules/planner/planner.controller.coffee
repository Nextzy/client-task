###
# Copyright (C) 2014-2018 Taiga Agile LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: home/home.controller.coffee
###

class PlannerController
    @.$inject = [
        "$scope"
        "tgCurrentUserService",
        "$location",
        "$tgNavUrls", 
        "uiCalendarConfig"
    ]

    constructor: (@scope, @currentUserService, @location, @navUrls) ->
        if not @currentUserService.getUser() 
            @location.path(@navUrls.resolve("planner"))
        # @scope.eventSources = []
        # @scope.uiConfig = {
        #         calendar: {
        #             height: 700, 
        #             header: {
        #                 left: ""
        #                 center: "title"
        #                 right: ""
        #             }, 
        #             footer: {
        #                 right: "today prev,next"
        #             }, 
        #             droppable: true, 
        #             editable: true
        #             eventStartEditable: true,
        #             eventDurationEditable: false,
        #             defaultTimedEventDuration: "00:30",
        #             handleWindowResize: true,
        #             titleFormat: "D MMM YYYY",
        #             defaultView: "agendaDay", 
        #             allDaySlot: false, 
        #             dragScroll: false
        #         }
        #     }
    


angular.module("taigaPlanner").controller("PlannerController", PlannerController)