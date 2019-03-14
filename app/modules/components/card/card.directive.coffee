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
# File: components/card/card.directive.coffee
###

module = angular.module("taigaComponents")

cardDirective = () ->
    toManHour = (value) ->
        if(value) 
            rawHour = parseInt(value)
            rawMinute = value - rawHour
            return pad(rawHour, 2) + ":" + pad(rawMinute * 60, 2)
        return undefined

    pad = (num, size) -> 
        return ("0000" + num).slice(-size)

    return {
        link: (scope) ->
            # scope.vm = {}
            scope.vm.getManHour = () ->
                return toManHour(scope.vm.item.get("man_hour"))

        controller: "Card",
        controllerAs: "vm",
        bindToController: true,
        templateUrl: "components/card/card.html",
        scope: {
            onToggleFold: "&",
            onClickAssignedTo: "&",
            onClickEdit: "&",
            onClickRemove: "&",
            onClickDelete: "&",
            project: "=",
            item: "=",
            zoom: "=",
            zoomLevel: "=",
            archived: "=",
            type: "@"
        }
    }

module.directive('tgCard', cardDirective)
