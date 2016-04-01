'use strict'

EventCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc, eventUtils
  AAAHelpers, locationHelpers
  $reactive, UsersResource, EventsResource
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.viewId = ["events-view",$scope.$id].join('-')
    vm.title = "Events"
    vm.listItemDelegate = null
    vm.RecipeM = RecipeModel::

    # required for directive:map-view
    vm.rows = []
    vm.markerKeymap = {
      id: '_id'
      location: 'location'
      label: 'title'
    }
    vm.selectedItemId = null

    vm.pg = {
      perpage: 20
      page: 1
      sort:
        startTime: -1
    }
    # exportDebug.set 'pg', vm.pg
    vm.filter = {
    }

    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        map: false
        newTile: false
        spinner:
          newTile: false
        fabIcon: 'ion-plus'
    }


    _filters = {
      CONST:
        COMING_SOON_DAYS: 21
        NEARBY: 10000 # meters

      'comingSoon': ()->
        now = moment()
        return {
          label: "Coming Soon"
          sortBy: {'startTime' : 1}  # ASC
          filterBy: {
            $and: [
              {'startTime': {$gt: moment().toDate()}}
              {'startTime': {$lt: moment().add(_filters.CONST.COMING_SOON_DAYS, 'd').toDate()}}
            ]
          }
        }
      'nearby': (lonlat)->
        ###
        TODO: don't forget to create index in mongo
          $ meteor mongo
          > db.events.createIndex({geojson:"2dsphere"})
        ###
        lonlat ?= locationHelpers.asLonLat Meteor.user()?.profile.location
        if !lonlat
          toastr.warning "Your location is not available."
          return $state.go( 'app.events', {filter: 'comingSoon'})
        return {
          label: "Events Nearby"
          sortBy: {}  # $near is already sorted
          filterBy: {
            'geojson':
              $near:
                $geometry:
                  type: "Point"
                  coordinates: lonlat # [lon,lat]
                $maxDistance: _filters.CONST.NEARBY
          }
        }
      'recent': ()->
        now = moment()  # .subtract(event.duration)
        return {
          label: "Recent Events"
          sortBy: {'startTime' : -1}  # DESC
          filterBy: {
            $and: [
              {'startTime': {$lt: moment().toDate()}}
              {'startTime': {$gt: moment().subtract(_filters.CONST.COMING_SOON_DAYS, 'd').toDate()}}
            ]
          }
        }
      'all': ()->
        return {
          label: "Events"
          sortBy: {'title' : 1}  # ASC
          filterBy: {}
      }
    }

    vm.on = {
      scrollTo: (anchor)->
        $location.hash(anchor)
        $ionicScrollDelegate.anchorScroll(true)
        return

      setView: (value)->
        if 'value==null'
          next = if vm.settings.show == 'grid' then 'list' else 'grid'
          return vm.settings.view.show = next
        return vm.settings.view.show = value

      createNewTile: ()->
        vm.on.notReady('Create Event')

      fabClick: ()->
        return vm.on['createNewTile']()

      notReady: (value)->
        toastr.info "Sorry, " + value + " is not available yet"
        return false

      'favorite': ()->
        eventUtils['favorite'].apply vm, arguments

    }


    vm.showRowcount = ()->
      formatted =
        if vm.rowcount
        then '(' + vm.rowcount + ')'
        else null
      return formatted

    initialize = ()->
      $reactive(vm).attach($scope)
      # vm.subscribe 'userProfiles'
      vm.subscribe 'myVisibleEvents'
        ,()->
          return [
            vm.getReactively('filter.filterBy')
            ,{
              limit: parseInt(vm.pg.perpage),
              skip: parseInt((vm.getReactively('pg.page') - 1) * vm.pg.perpage),
              sort: vm.getReactively('pg.sort')
            }
          ]
        ,{
          onReady: ()->
            # arguments == []
            console.info ["EventsCtrl subscribe: Events onReady"]
        }
      vm.helpers {
        'rows': ()->
          return mcEvents.find(
            vm.getReactively('filter.filterBy')
            , {
              sort : vm.getReactively('pg.sort')
            })
        'rowcount': ()->
          # TODO: bug: vm.rowcount is not getting updated on client when filterBy changes
          return Counts.get('countEvents')

      }
      vm.autorun ()->
        filterBy = vm.getReactively('filter.filterBy', true)
        console.log ['autorun', filterBy]
        return
      # exportDebug.set 'vm', vm
      return


    activate = ()->
      return $q.when()
      .then ()->
        # vm.settings.viewId = ["events-view",$scope.$id].join('-')
        # vm.listItemDelegate = $listItemDelegate.getByHandle('events-list-scroll', $scope)
        eventFilter = $stateParams.filter || 'all'
        location = locationHelpers.asLonLat Meteor.user()?.profile.location
        switch eventFilter
          when 'nearby'
            return {eventFilter: eventFilter, location: location} if location
            return locationHelpers.getCurrentPosition('loading')
            .then (result)->
              lonlat = result.latlon.reverse()
              vm.call 'Profile.saveLocation', lonlat, (err, retval)->
                'check'
              return {eventFilter: eventFilter, location: lonlat}
            , (err)->
              console.warn ["WARNING: getCurrentPosition", err]

          else
            return {eventFilter: eventFilter}
      .then (result)->
        vm.filter = _filters[ result.eventFilter ](result.location)
        # exportDebug.set('filter', vm.filter)
        vm.title = vm.filter.label
        vm.pg.sort = vm.filter.sortBy
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return

    resetMaterialMotion = (motion, parentId)->
      className = {
        'fadeSlideInRight': '.animate-fade-slide-in-right'
        'blinds': '.animate-blinds'
        'ripple': '.animate-ripple'
      }
      selector = '{aniClass} .item'.replace('{aniClass}', className[motion] )
      selector = '#'+ parentId + ' ' + selector if parentId?
      angular.element(document.querySelectorAll(selector))
        .removeClass('in')
        .removeClass('done')

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for EventCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for EventCtrl"
      activate()

    return vm  # end EventCtrl


EventCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc', 'eventUtils'
  'AAAHelpers', 'locationHelpers'
  '$reactive', 'UsersResource', 'EventsResource'
  'utils', 'devConfig', 'exportDebug'
]





angular.module 'starter.events'
  .controller 'EventCtrl', EventCtrl
