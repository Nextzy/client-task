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
# File: home/working-on/working-on.controller.coffee
###

class WorkingTaskController
    @.$inject = [
        "tgPlannerService"
    ]

    constructor: (@plannerService) ->
        @.assignedTo = Immutable.Map()
        # console.log("Yo")
        # $('.fc-event').each(() ->
        #     console.log("Yo")
        #     $(this).data('event', {
        #         title: $.trim($(this).text()), 
        #         stick: true
        #     })

        #     $(this).draggable({
        #         zIndex: 999,
        #         revert: true,    
        #         revertDuration: 0
        #     })
        # )

    _setAssignedTo: (workInProgress) ->
        tasks = workInProgress.get("assignedTo").get("tasks")

        @.assignedTo = tasks

        if @.assignedTo.size > 0
            @.assignedTo = @.assignedTo.sortBy((elem) -> elem.get("project").get("id")).reverse()
            
    getWorkInProgress: (userId) ->
        return @plannerService.getWorkInProgress(userId).then (workInProgress) =>
            @._setAssignedTo(workInProgress)

angular.module("taigaPlanner").controller("WorkingTaskController", WorkingTaskController)
