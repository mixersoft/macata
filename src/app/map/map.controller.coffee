'use strict'

MapCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  EventsResource, IdeasResource
  utils, devConfig, exportDebug
  )->


    vm = this
    vm.title = "Map View"
    vm.viewId = ["map-view",$scope.$id].join('-')
    vm.me = null      # current user, set in initialize()
    vm.listItemDelegate = null

    # required for directive:map-view
    vm.rows = []
    vm.markerKeymap = {
      id: '_id'
      location: 'location'
      label: 'title'
    }
    vm.selectedItemId = null

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

      'gotoTarget':(item)->
        switch item.className
          when 'Events'
            return $state.go('app.event-detail', {id:item.id})
            # return "app.events({id:'" + item.id + "'})"
          when 'Recipe'
            return  $state.go('app.recipe', {id:item.id})
            # return "app.recipe({id:'" + item.id + "'})"
          else
            return

      select: ($item, $index, silent)->

        if $item == null
          # unSelect
          $state.transitionTo($state.current.name
          , null
          , {notify:false}
          )
          return
        # update history url
        $state.transitionTo($state.current.name
          , {id: [$item.id,$item.className].join(':') }
          , {notify:false}
        )
        vm.selectedItemId = $item.id
        console.log ["selected", $index, $item]
        return


    }


    getData = ()->
      vm.rows = []
      return $q.when()
      .then ()->
        recipes = IdeasResource.query()  # recipes/ideas
        events = EventsResource.query().then (result)->
          return result[0...3]
        return $q.all([recipes, events])
        .then (results)->
          [recipes, events] = results
          data = [].concat recipes, events
          return data
      .then (data)->
        # strip $$ keys, searching for gMap bug
        if true
          _omit$keys = (o)->
            return o if not _.isObject o
            omitKeys = _.filter(_.keys(o), (k)->return k[0]=='$')
            return clean = _.omit o, omitKeys

          data = _.map data, (o)->
            o._id = o.id
            return _omit$keys( o )

        return data
      .then (data)->
        vm.rows = data
        # exportDebug.set('mapData', vm.rows)
        return vm.rows

    initialize = ()->
      return
    #   # $ionicView.loaded: called once for EACH cached $ionicView,
    #   #   i.e. each instance of vm
    #   unwatch_gMapMarkersControl = $scope.$watch 'vm.gMap.MarkersControl.getGMarkers', (newV)->
    #     if newV && vm.gMap['Control'].getGMap
    #       unwatch_gMapMarkersControl?()
    #       console.info "gMap && gMap Markers ready"
    #       vm.gMap.Dfd.resolve('gMapControls ready')
    #   # NOTE: 'map-ready' fired once for each $ionicView.loaded ONLY
    #   # NOTE: 'tilesloaded/map-ready' event does NOT fire from a cached $ionicView

    activate = ()->
      # $ionicView.enter
      return $q.when()
      .then ()->
        return devConfig.getDevUser("0").then (user)->
          return vm.me = user
      .then getData
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return
      .then ()->
        return if not $stateParams.id
        vm.selectedItemId = $stateParams.id.split(':').shift()
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
      $log.info "viewLoaded for MapCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for MapCtrl"
      activate()


    loadOnce = ()->
      # called once for each Controller load
      return if ~$rootScope['loadOnce'].indexOf 'MapCtrl'
      $rootScope['loadOnce'].push 'MapCtrl'
      $log.info "Controller Loaded for MapCtrl"

      ###
      # put all gmap init routines here.
      # DO NOT: init and vm attrs here, do in activate()
      ###


    loadOnce()
    return vm  # end MapCtrl


MapCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams'
  '$log', 'toastr'
  'EventsResource', 'IdeasResource'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  MapDetailCtrl, controller for directive:list-item-detail
###

MapDetailCtrl = (
  $scope, $rootScope, $q
  tileHelpers
  $log, toastr
  ) ->
    vm = this
    vm.on = {
      'click': (event, item)->
        event.stopImmediatePropagation()
        $log.info ['MapDetailCtrl.on.click', item.name]
        angular.element(
          document.querySelector('.list-item-detail')
        ).toggleClass('slide-under')
        return
      'edit': (event, item)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          console.log ["edit", data]
          data.isOwner = true
          return
      'forkTile': ($event, item)->
        data = _.pick item, ['url','title','description','image', 'site_name', 'extras']
        # from new-tile.directive fn:_showTileEditorAsModal
        return tileHelpers.modal_showTileEditor(data)
        .then (result)->
          console.log ['forkTile',result]
          # return vm.on.submitNewTile(result)
        .then ()->
          item.isOwner = true
        .catch (err)->
          console.warn ['forkTile', err]

    }
    console.log ["MapDetailCtrl initialized scope.$id=", $scope.$id]
    return vm

MapDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q'
  'tileHelpers'
  '$log', 'toastr'
]


angular.module 'starter.map'
  .controller 'MapCtrl', MapCtrl
  .controller 'MapDetailCtrl', MapDetailCtrl
