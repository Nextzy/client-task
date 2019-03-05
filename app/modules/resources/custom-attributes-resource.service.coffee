Resource = (urlsService, http, paginateResponseService) ->
    service = {}

    service.getTaskCustomAttributeValues = (taskId) ->
        url = urlsService.resolve("custom-attributes-values/task")

        return http.get(url + "/" + taskId)

    service.getCustomAttributes = (projectId) -> 
        url = urlsService.resolve("custom-attributes/task")

        return http.get(url + "?project=" + projectId)

    return () ->
        return {"customAttributes": service}

Resource.$inject = ["$tgUrls", "$tgHttp"]

module = angular.module("taigaResources2")
module.factory("tgCustomAttributesResources", Resource)
