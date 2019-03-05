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
# File: home/home.service.coffee
###

groupBy = @.taiga.groupBy

class PlannerService extends taiga.Service
    @.$inject = [
        "$tgNavUrls",
        "tgResources",
        "tgProjectsService"
    ]

    constructor: (@navurls, @rs, @projectsService) ->

    _attachProjectInfoToWorkInProgress: (workInProgress, projectsById) ->
        _attachProjectInfoToDuty = (duty, objType) =>
            project = projectsById.get(String(duty.get('project')))

            ctx = {
                project: project.get('slug')
                ref: duty.get('ref')
            }

            url = @navurls.resolve("project-#{objType}-detail", ctx)

            duty = duty.set('url', url)
            duty = duty.set('project', project)
            duty = duty.set("_name", objType)

            return duty

        _getValidDutiesAndAttachProjectInfo = (duties, dutyType)->
            # Exclude duties where I'm not member of the project
            duties = duties.filter((duty) ->
                return projectsById.get(String(duty.get('project'))))

            duties = duties.map (duty) ->
                return _attachProjectInfoToDuty(duty, dutyType)

            return duties

        assignedTo = workInProgress.get("assignedTo")

        if assignedTo.get("epics")
            _duties = _getValidDutiesAndAttachProjectInfo(assignedTo.get("epics"), "epics")
            assignedTo = assignedTo.set("epics", _duties)

        if assignedTo.get("userStories")
            _duties = _getValidDutiesAndAttachProjectInfo(assignedTo.get("userStories"), "userstories")
            assignedTo = assignedTo.set("userStories", _duties)

        if assignedTo.get("tasks")
            _duties = _getValidDutiesAndAttachProjectInfo(assignedTo.get("tasks"), "tasks")
            assignedTo = assignedTo.set("tasks", _duties)

        if assignedTo.get("issues")
            _duties = _getValidDutiesAndAttachProjectInfo(assignedTo.get("issues"), "issues")
            assignedTo = assignedTo.set("issues", _duties)


        watching = workInProgress.get("watching")

        if watching.get("epics")
            _duties = _getValidDutiesAndAttachProjectInfo(watching.get("epics"), "epics")
            watching = watching.set("epics", _duties)

        if watching.get("userStories")
            _duties = _getValidDutiesAndAttachProjectInfo(watching.get("userStories"), "userstories")
            watching = watching.set("userStories", _duties)

        if watching.get("tasks")
            _duties = _getValidDutiesAndAttachProjectInfo(watching.get("tasks"), "tasks")
            watching = watching.set("tasks", _duties)

        if watching.get("issues")
            _duties = _getValidDutiesAndAttachProjectInfo(watching.get("issues"), "issues")
            watching = watching.set("issues", _duties)

        workInProgress = workInProgress.set("assignedTo", assignedTo)
        workInProgress = workInProgress.set("watching", watching)

    getWorkInProgress: (userId) ->
        projectsById = Immutable.Map()

        projectsPromise = @projectsService.getProjectsByUserId(userId).then (projects) ->
            projectsById = Immutable.fromJS(groupBy(projects.toJS(), (p) -> p.id))

        assignedTo = Immutable.Map()

        params_epics = {
            status__is_closed: false
            assigned_to: userId
        }

        params_uss = {
            is_closed: false
            assigned_users: userId
        }

        params_tasks = {
            status__is_closed: false
            assigned_to: userId
        }

        params_issues = {
            status__is_closed: false
            assigned_to: userId
        }

        service = @rs

        assignedEpicsPromise = @rs.epics.listInAllProjects(params_epics).then (epics) ->
            assignedTo = assignedTo.set("epics", epics)

        assignedUserStoriesPromise = @rs.userstories.listInAllProjects(params_uss).then (userstories) ->
            assignedTo = assignedTo.set("userStories", userstories)

        # assignedTasksPromise = @rs.tasks.listInAllProjects(params_tasks).then (tasks) -> 
        #     assignedTo = assignedTo.set("tasks", tasks)

        resource = @rs
        assignedTasksPromise = @rs.tasks.listInAllProjects(params_tasks).then (tasks) -> 
            promises = tasks.map (task) -> 
                projectId = task.get("project")
                return getCustomAttributesPromise(projectId, task, resource)
                    .then (result) -> getManHourFromTaskPromise(result, resource)
                    .then (result) -> putManHourToTaskPromise(result, tasks)
            
            Promise.all(promises).then () =>
                assignedTo = assignedTo.set("tasks", tasks)
                console.log("Success Fucking Awesome")

        assignedIssuesPromise = @rs.issues.listInAllProjects(params_issues).then (issues) ->
            console.log('Immutable : ' + Immutable.Iterable.isIterable(issues))
            assignedTo = assignedTo.set("issues", issues)

        params_epics = {
            status__is_closed: false
            watchers: userId
        }

        params_uss = {
            is_closed: false
            watchers: userId
        }

        params_tasks = {
            status__is_closed: false
            watchers: userId
        }

        params_issues = {
            status__is_closed: false
            watchers: userId
        }

        watching = Immutable.Map()

        watchingEpicsPromise = @rs.epics.listInAllProjects(params_epics).then (epics) ->
            watching = watching.set("epics", epics)

        watchingUserStoriesPromise = @rs.userstories.listInAllProjects(params_uss).then (userstories) ->
            watching = watching.set("userStories", userstories)

        watchingTasksPromise = @rs.tasks.listInAllProjects(params_tasks).then (tasks) ->
            watching = watching.set("tasks", tasks)

        watchingIssuesPromise = @rs.issues.listInAllProjects(params_issues).then (issues) ->
            watching = watching.set("issues", issues)

        workInProgress = Immutable.Map()

        Promise.all([
            projectsPromise,
            assignedEpicsPromise,
            watchingEpicsPromise,
            assignedUserStoriesPromise,
            watchingUserStoriesPromise,
            assignedTasksPromise,
            watchingTasksPromise,
            assignedIssuesPromise,
            watchingIssuesPromise
        ]).then =>
            workInProgress = workInProgress.set("assignedTo", assignedTo)
            workInProgress = workInProgress.set("watching", watching)

            workInProgress = @._attachProjectInfoToWorkInProgress(workInProgress, projectsById)

            return workInProgress

    getCustomAttributesPromise = (projectId, task, resource) -> 
        return resource.customAttributes.getCustomAttributes(projectId).then (attrs) ->
            manHourAttr = attrs.data.find (attr) -> attr.name == "man-hour"
            return { manHourAttr, task }

    getManHourFromTaskPromise = (result, resource) -> 
        manHourAttr = result.manHourAttr
        task = result.task
        if manHourAttr?
            return resource.customAttributes.getTaskCustomAttributeValues(task.get("id")).then (values) -> 
                manHourValue = values.data.attributes_values[manHourAttr.id]
                if manHourValue?
                    rawHour = parseInt(manHourValue)
                    rawMinute = manHourValue - rawHour
                    manHour = pad(rawHour, 2) + ":" + pad(rawMinute * 60, 2)
                    return { manHour, task }
                return { "manHour" : undefined, task }
        else 
            new Promise((resolve, reject) => 
                resolve({ "manHour" : undefined, task })
            )

    putManHourToTaskPromise = (result, tasks) ->
        new Promise((resolve, reject) => 
            manHour = result.manHour
            task = result.task
            task.set('blocked_note', 'Akexorcist')
            # task["manHour"] = manHour
            # index = tasks.findIndex(item => item.id == task.id)
            # tasks = tasks.update(tasks.findIndex((item) ->
            #     return item.get("id") == task.id; 
            # ), (item) ->
            #     return item.set("manHour", manHour)
            # )

            # tasks = tasks.setIn([index, "manHour"], manHour)
            resolve(task)
            # actualTasks.push(task)
        )

    pad = (num, size) -> 
        return ("0000" + num).slice(-size)

angular.module("taigaPlanner").service("tgPlannerService", PlannerService)
