'use strict'

###
  NOTE: using component-directives form,
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
###
TileSearchSort = ( FeedHelpers, PostHelpers)->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'show': '='
      'onFilterBy': '&'
    }
    templateUrl: 'blocks/components/tile-search-sort.html'
    controllerAs: 'ss'
    controller: [
      '$scope', '$window'
      ($scope, $window)->

        ss = this

        ss.tileWidth = ()->
          return Math.min($window.innerWidth, 960)


        ss.tile = {
          filter: null
        }


        ss.on = {
          'hide': ($ev)->
            $scope.$emit('overscrollTile.reveal', false)
            return

        }

        return ss
      ]

  }



TileSearchSort.$inject = [ 'FeedHelpers', 'PostHelpers']

angular.module 'blocks.components'
  .directive 'tileSearchSort', TileSearchSort
