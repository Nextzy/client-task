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
# File: modules/wiki/main.coffee
###

taiga = @.taiga

mixOf = @.taiga.mixOf
trim = @.taiga.trim
toString = @.taiga.toString
joinStr = @.taiga.joinStr
groupBy = @.taiga.groupBy
bindOnce = @.taiga.bindOnce
debounceLeading = @.taiga.debounceLeading
startswith = @.taiga.startswith
bindMethods = @.taiga.bindMethods
debounceLeading = @.taiga.debounceLeading

module = angular.module("taigaCalendar")

#############################################################################
## Wiki Detail Controller
#############################################################################

class CalendarController  extends mixOf(taiga.Controller, taiga.PageMixin, taiga.FiltersMixin)
    @.$inject = [
        "$scope",
        "$rootScope",
        "$tgRepo",
        "$tgConfirm",
        "$tgResources",
        "$tgUrls",
        "$routeParams",
        "$q",
        "$tgLocation",
        "tgAppMetaService",
        "$tgNavUrls",
        "$tgEvents",
        "$tgAnalytics",
        "$translate",
        "tgErrorHandlingService",
        "$tgStorage",
        "tgFilterRemoteStorageService",
        "tgProjectService",
        "tgUserActivityService"
    ]

    filtersHashSuffix: "issues-filters"
    myFiltersHashSuffix: "issues-my-filters"
    excludePrefix: "exclude_"
    filterCategories: [
        "tags",
        "status",
        "type",
        "severity",
        "priority",
        "assigned_to",
        "owner",
        "role",
    ]


    constructor: (@scope, @rootscope, @repo, @confirm, @rs, @urls, @params, @q, @location, @appMetaService,
                  @navUrls, @events, @analytics, @translate, @errorHandlingService, @storage, @filterRemoteStorageService, @projectService) ->
        bindMethods(@)

        @scope.sectionName = @translate.instant("PROJECT.SECTION.ISSUES")
        @.voting = false

        return if @.applyStoredFilters(@params.pslug, @.filtersHashSuffix)

        promise = @.loadInitialData()

        # On Success
        promise.then =>
            title = @translate.instant("ISSUES.PAGE_TITLE", {projectName: @scope.project.name})
            description = @translate.instant("ISSUES.PAGE_DESCRIPTION", {
                projectName: @scope.project.name,
                projectDescription: @scope.project.description
            })
            @appMetaService.setAll(title, description)

        # On Error
        promise.then null, @.onInitialDataError.bind(@)

        @scope.$on "issueform:new:success", =>
            @analytics.trackEvent("issue", "create", "create issue on issues list", 1)
            @.loadIssues()

        @scope.$on "assigned-to:changed", =>
            @.generateFilters()
            if @.isFilterDataTypeSelected('assigned_to') ||\
                @.isFilterDataTypeSelected('role') ||\
                @.isOrderedBy('assigned_to') || @.isOrderedBy('modified')
                    @.loadIssues()

        @scope.$on "status:changed", =>
            @.generateFilters()
            if @.isFilterDataTypeSelected('status') ||\
                @.isOrderedBy('status') || @.isOrderedBy('modified')
                    @.loadIssues()

    isOrderedBy: (fieldName) ->
        pattern = new RegExp("-*"+fieldName)
        return pattern.test(@location.search().order_by)

    changeQ: (q) ->
        @.unselectFilter("page")
        @.replaceFilter("q", q)
        @.loadIssues()
        @.generateFilters()

    removeFilter: (filter) ->
        @.unselectFilter("page")
        @.unselectFilter(filter.dataType, filter.id, false, filter.mode)
        @.loadIssues()
        @.generateFilters()

    addFilter: (newFilter) ->
        @.unselectFilter("page")
        @.selectFilter(newFilter.category.dataType, newFilter.filter.id, false, newFilter.mode)
        @.loadIssues()
        @.generateFilters()

    selectCustomFilter: (customFilter) ->
        orderBy = @location.search().order_by

        if orderBy
            customFilter.filter.order_by = orderBy

        @.unselectFilter("page")
        @.replaceAllFilters(customFilter.filter)
        @.loadIssues()
        @.generateFilters()

    removeCustomFilter: (customFilter) ->
        @filterRemoteStorageService.getFilters(@scope.projectId, @.myFiltersHashSuffix).then (userFilters) =>
            delete userFilters[customFilter.id]
            @filterRemoteStorageService.storeFilters(@scope.projectId, userFilters, @.myFiltersHashSuffix).then(@.generateFilters)

    isFilterDataTypeSelected: (filterDataType) ->
        for filter in @.selectedFilters
            if (filter['dataType'] == filterDataType)
                return true
        return false

    saveCustomFilter: (name) ->
        filters = {}
        urlfilters = @location.search()

        for key in @.filterCategories
            excludeKey = @.excludePrefix.concat(key)
            filters[key] = urlfilters[key]
            filters[excludeKey] = urlfilters[excludeKey]

        @filterRemoteStorageService.getFilters(@scope.projectId, @.myFiltersHashSuffix).then (userFilters) =>
            userFilters[name] = filters

            @filterRemoteStorageService.storeFilters(@scope.projectId, userFilters, @.myFiltersHashSuffix).then(@.generateFilters)

    generateFilters: ->
        @.storeFilters(@params.pslug, @location.search(), @.filtersHashSuffix)
        urlfilters = @location.search()

        loadFilters = {}
        loadFilters.project = @scope.projectId
        loadFilters.q = urlfilters.q

        for key in @.filterCategories
            excludeKey = @.excludePrefix.concat(key)
            loadFilters[key] = urlfilters[key]
            loadFilters[excludeKey] = urlfilters[excludeKey]

        return @q.all([
            @rs.issues.filtersData(loadFilters),
            @filterRemoteStorageService.getFilters(@scope.projectId, @.myFiltersHashSuffix)
        ]).then (result) =>
            data = result[0]
            customFiltersRaw = result[1]
            dataCollection = {}

            dataCollection.status = _.map data.statuses, (it) ->
                it.id = it.id.toString()

                return it
            dataCollection.type = _.map data.types, (it) ->
                it.id = it.id.toString()

                return it
            dataCollection.severity = _.map data.severities, (it) ->
                it.id = it.id.toString()

                return it
            dataCollection.priority = _.map data.priorities, (it) ->
                it.id = it.id.toString()

                return it
            dataCollection.tags = _.map data.tags, (it) ->
                it.id = it.name

                return it

            tagsWithAtLeastOneElement = _.filter dataCollection.tags, (tag) ->
                return tag.count > 0

            dataCollection.assigned_to = _.map data.assigned_to, (it) ->
                if it.id
                    it.id = it.id.toString()
                else
                    it.id = "null"

                it.name = it.full_name || "Unassigned"

                return it
            dataCollection.owner = _.map data.owners, (it) ->
                it.id = it.id.toString()
                it.name = it.full_name

                return it
            dataCollection.role = _.map data.roles, (it) ->
                if it.id
                    it.id = it.id.toString()
                else
                    it.id = "null"

                it.name = it.name || "Unassigned"

                return it

            @.selectedFilters = []

            for key in @.filterCategories
                excludeKey = @.excludePrefix.concat(key)
                if loadFilters[key]
                    selected = @.formatSelectedFilters(key, dataCollection[key], loadFilters[key])
                    @.selectedFilters = @.selectedFilters.concat(selected)
                if loadFilters[excludeKey]
                    selected = @.formatSelectedFilters(key, dataCollection[key], loadFilters[excludeKey], "exclude")
                    @.selectedFilters = @.selectedFilters.concat(selected)

            @.filterQ = loadFilters.q

            @.filters = [
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.TYPE"),
                    dataType: "type",
                    content: dataCollection.type
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.SEVERITY"),
                    dataType: "severity",
                    content: dataCollection.severity
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.PRIORITIES"),
                    dataType: "priority",
                    content: dataCollection.priority
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.STATUS"),
                    dataType: "status",
                    content: dataCollection.status
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.TAGS"),
                    dataType: "tags",
                    content: dataCollection.tags,
                    hideEmpty: true,
                    totalTaggedElements: tagsWithAtLeastOneElement.length
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.ASSIGNED_TO"),
                    dataType: "assigned_to",
                    content: dataCollection.assigned_to
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.ROLE"),
                    dataType: "role",
                    content: dataCollection.role
                },
                {
                    title: @translate.instant("COMMON.FILTERS.CATEGORIES.CREATED_BY"),
                    dataType: "owner",
                    content: dataCollection.owner
                }
            ]

            @.customFilters = []
            _.forOwn customFiltersRaw, (value, key) =>
                @.customFilters.push({id: key, name: key, filter: value})

    initializeSubscription: ->
        routingKey = "changes.project.#{@scope.projectId}.issues"
        @events.subscribe @scope, routingKey, debounceLeading(500, (message) =>
            @.loadIssues())

    loadProject: ->
        project = @projectService.project.toJS()

        if not project.is_issues_activated
            @errorHandlingService.permissionDenied()

        @scope.projectId = project.id
        @scope.project = project
        @scope.$emit('project:loaded', project)

        @scope.issueStatusById = groupBy(project.issue_statuses, (x) -> x.id)
        @scope.issueStatusList = _.sortBy(project.issue_statuses, "order")
        @scope.severityById = groupBy(project.severities, (x) -> x.id)
        @scope.severityList = _.sortBy(project.severities, "order")
        @scope.priorityById = groupBy(project.priorities, (x) -> x.id)
        @scope.priorityList = _.sortBy(project.priorities, "order")
        @scope.issueTypes = _.sortBy(project.issue_types, "order")
        @scope.issueTypeById = groupBy(project.issue_types, (x) -> x.id)

        return project

    # We need to guarantee that the last petition done here is the finally used
    # When searching by text loadIssues can be called fastly with different parameters and
    # can be resolved in a different order than generated
    # We count the requests made and only if the callback is for the last one data is updated
    loadIssuesRequests: 0
    loadIssues: =>
        params = @location.search()

        promise = @rs.issues.list(@scope.projectId, params)
        @.loadIssuesRequests += 1
        promise.index = @.loadIssuesRequests
        promise.then (data) =>
            if promise.index == @.loadIssuesRequests
                @scope.issues = data.models
                @scope.page = data.current
                @scope.count = data.count
                @scope.paginatedBy = data.paginatedBy

            return data

        return promise

    loadInitialData: ->
        project = @.loadProject()

        @.fillUsersAndRoles(project.members, project.roles)
        @.initializeSubscription()
        @.generateFilters()

        return @.loadIssues()

    # Functions used from templates
    addNewIssue: ->
        project = @projectService.project.toJS()
        @rootscope.$broadcast("genericform:new", {
            'objType': 'issue',
            'project': project
        })

    addIssuesInBulk: ->
        @rootscope.$broadcast("issueform:bulk", @scope.projectId)

    upVoteIssue: (issueId) ->
        @.voting = issueId
        onSuccess = =>
            @.loadIssues()
            @.voting = null
        onError = =>
            @confirm.notify("error")
            @.voting = null

        return @rs.issues.upvote(issueId).then(onSuccess, onError)

    downVoteIssue: (issueId) ->
        @.voting = issueId
        onSuccess = =>
            @.loadIssues()
            @.voting = null
        onError = =>
            @confirm.notify("error")
            @.voting = null

        return @rs.issues.downvote(issueId).then(onSuccess, onError)

    getOrderBy: ->
        if _.isString(@location.search().order_by)
            return @location.search().order_by
        else
            return "created_date"

module.controller("CalendarController", CalendarController)
