'use strict'

EventCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  UsersResource, EventsResource
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.title = "Events"
    vm.viewId = ["events-view",$scope.$id].join('-')
    vm.me = null      # current user, set in initialize()
    vm.listItemDelegate = null


    vm.filter = {}
    _filters = {
      'comingSoon':
        label: "Coming Soon"
        sortBy: 'startTime'  # ASC
        filterBy: (o)->
          return o.startTime > new Date().toJSON()
      'nearby':
        label: "Events Near Me"
        sortBy: 'location'
        filterBy: (o)->
          return o.startTime > new Date().toJSON()
      'recent':
        label: "Recent Events"
        sortBy: (o)->
          return -1 * o.startTime  # DESC
        filterBy: (o)->
          return o.startTime < new Date().toJSON()
      'all':
        label: "Events"
    }


    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        newTile: false
        spinner:
          newTile: false
        fabIcon: 'ion-plus'
    }

    vm.lookup = {}


    getData = ()->
      vm.rows = []
      return $q.when()
      .then ()->
        return UsersResource.query()
      .then (users)->
        vm.lookup.users = users
      .then ()->
        return EventsResource.query()
      .then (events)->
        events = sortEvents(events, vm.filter)
        _.each events, (o, i)->
          o['image'] = o['heroPic']
          return
        vm.rows = events
        return vm.rows

    sortEvents = (items, options)->
      collection = _.chain(items)
      collection = collection.filter(options.filterBy) if options.filterBy
      collection = collection.sortBy(options.sortBy) if options.sortBy
      return items = collection.value()

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



    }

    initialize = ()->
      return

    activate = ()->
      vm.listItemDelegate = $listItemDelegate.getByHandle('events-list-scroll', $scope)
      vm.filter = _filters[ $stateParams.filter ] || _filters[ 'all' ]
      vm.title = vm.filter.label
      return $q.when()
      .then ()->
        return devConfig.getDevUser("0").then (user)->
          return vm.me = user
      .then ()->
        return getData()
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return
      .then ()->
        if index = $stateParams.filter
          console.warn 'TODO: set filter on viewEnter'

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
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'UsersResource', 'EventsResource'
  'utils', 'devConfig', 'exportDebug'
]





angular.module 'starter.events'
  .controller 'EventCtrl', EventCtrl
