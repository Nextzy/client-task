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
# File: home/duties/duty.directive.coffee
###

UnplanTaskDirective = (navurls, $translate) ->

    link = (scope, el, attrs, ctrl) ->
        scope.vm = {}
        scope.vm.duty = scope.duty
        scope.vm.type = scope.type

        getManHour = () -> 
            return if scope.duty.get("manHour")? 
                scope.duty.get("manHour")
            else 
                "00:30"
            
        el.data('event', {
                title: "Hello",
                stick: true,
                duration: getManHour()
        })
        # el.draggable({
        #     zIndex: 999,
        #     revert: true,     
        #     revertDuration: 0 
        # })

        scope.vm.getDutyType = () ->
            if scope.vm.duty
                if scope.vm.duty.get('_name') == "epics"
                    return $translate.instant("COMMON.EPIC")
                if scope.vm.duty.get('_name') == "userstories"
                    return $translate.instant("COMMON.USER_STORY")
                if scope.vm.duty.get('_name') == "tasks"
                    return $translate.instant("COMMON.TASK")
                if scope.vm.duty.get('_name') == "issues"
                    return $translate.instant("COMMON.ISSUE")

        scope.vm.getManHour = () -> getManHour() 

        el.on "dragstart", (ev) -> 
            console.log("Yo")

            
            # manHour = if scope.duty.get("manHour")? 
                # scope.duty.get("manHour") 
            # else 
                # "00:30"
            # $('#list-itemtype-ticket [data-duration]').removeAttr('data-duration')
            # ev.target.setAttribute("data-duration", manHour)
            # ev.target.setAttribute("data-event", "{'duration': " + manHour + "}")
            # console.log('ManHour : ' + JSON.stringify(ev.target.parentElement))

    return {
        templateUrl: "planner/unplan-task/unplan-task.html"
        scope: {
            "duty": "=tgUnplanTask",
            "type": "@"
        },
        link: link
    }

UnplanTaskDirective.$inject = [
    "$tgNavUrls",
    "$translate"
]

angular.module("taigaPlanner").directive("tgUnplanTask", UnplanTaskDirective)
