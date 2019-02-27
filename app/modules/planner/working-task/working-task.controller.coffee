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
        # @.watching = Immutable.Map()

    _setAssignedTo: (workInProgress) ->
        epics = workInProgress.get("assignedTo").get("epics")
        userStories = workInProgress.get("assignedTo").get("userStories")
        tasks = workInProgress.get("assignedTo").get("tasks")
        issues = workInProgress.get("assignedTo").get("issues")

        @.assignedTo = userStories.concat(tasks).concat(issues)
        # tasks.forEach((item, index) -> 
            # console.log(JSON.stringify(item)))
        # .sort((a, b) => { return })
        
        if @.assignedTo.size > 0
            @.assignedTo = @.assignedTo.sortBy((elem) -> elem.get("project").get("id")).reverse()

    # _setWatching: (workInProgress) ->
    #     epics = workInProgress.get("watching").get("epics")
    #     userStories = workInProgress.get("watching").get("userStories")
    #     tasks = workInProgress.get("watching").get("tasks")
    #     issues = workInProgress.get("watching").get("issues")

    #     @.watching = userStories.concat(tasks).concat(issues).concat(epics)
    #     if @.watching.size > 0
    #         @.watching = @.watching.sortBy((elem) -> elem.get("modified_date")).reverse()

    getWorkInProgress: (userId) ->
        return @plannerService.getWorkInProgress(userId).then (workInProgress) =>
            @._setAssignedTo(workInProgress)

angular.module("taigaPlanner").controller("WorkingTaskController", WorkingTaskController)
