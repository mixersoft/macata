'use strict'

###
  NOTE: using component-directives form,
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
###
TileCreateNew = ()->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'onNewTile': '&'
      'getWidth': '&'  # optional
    }
    templateUrl: 'blocks/components/tile-create-new.html'
    # require: ['?^searchRefresher', 'tileCreateNew']   # ???: enforce dependency?
    controllerAs: 'tc'
    controller: [
      '$scope', '$window'
      ($scope, $window)->

        tc = this

        tc.show = {
          spinner: false
        }

        tc.tileWidth = ()->
          if tc.getWidth?
            return tc.getWidth()
          return Math.min($window.innerWidth, 960)

        tc.data = {
        }

        tc.on = {
          # passthru - called by <new-tile on-complete="onComplete()">
          newTile: (result)->
            tc.data = result
            if tc.onNewTile?
              tc.onNewTile({result:result})
        }

        return tc
      ]

  }



TileCreateNew.$inject = []

angular.module 'blocks.components'
  .directive 'tileCreateNew', TileCreateNew
