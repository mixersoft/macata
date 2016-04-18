'use strict'

###
  NOTE: using component-directives form,
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
###
TileSetLocation = ( locationHelpers, FeedHelpers, PostHelpers)->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'show': '='
    }
    templateUrl: 'blocks/components/tile-set-location.html'
    controllerAs: 'sl'
    controller: [
      '$scope', '$window'
      ($scope, $window)->

        sl = this

        sl.lastLocationString = ()->
          sl.location = locationHelpers.lastKnownLocation()
          if !sl.location.lonlat && me = Meteor.user()
            sl.location.lonlat = locationHelpers.asLonLat me.profile.location
          return sl.location.address || sl.location.lonlat?.join(', ') || null

        sl.tileWidth = ()->
          return Math.min($window.innerWidth, 960)


        sl.tile = {
          search: sl.lastLocationString()
        }


        sl.on = {
          'getCurrentPosition': ($event, geocode)->
            if geocode == "CURRENT"
              return locationHelpers.getCurrentPosition('loading')
              .then (result)->
                sl.location = locationHelpers.lastKnownLocation()
                sl.search = sl.lastLocationString()
                Meteor.call 'Profile.saveLocation', sl.location.lonlat, (err, retval)->
                  'check'
              , (err)->
                console.warn ["WARNING: getCurrentPosition", err]
            return locationHelpers.getLocationFromAddress(sl.search)
            .then (result)->
              sl.location = locationHelpers.lastKnownLocation()
              sl.search = sl.lastLocationString()
              return sl.search
          'hide': ($ev)->
            $scope.$emit('overscrollTile.reveal', false)
            return

        }

        return sl
      ]

  }



TileSetLocation.$inject = [ 'locationHelpers', 'FeedHelpers', 'PostHelpers']

angular.module 'blocks.components'
  .directive 'tileSetLocation', TileSetLocation
