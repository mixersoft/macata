'use strict'

MapCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate
  $log, toastr
  appModalSvc, tileHelpers, geocodeSvc
  utils, devConfig, exportDebug
  )->

    # coffeelint: disable=max_line_length
    sampleData = [
      {"lat":42.6700528,"lon":23.314167099999963},
      {"lat":42.6737483,"lon":23.325192799999968},
      {"lat":42.6977082,"lon":23.321867500000053},
      {"lat":42.6599319,"lon":23.31657610000002},
      {"lat":42.6743583,"lon":23.32824210000001},
      {"lat":42.7570109,"lon":23.45046830000001},
      {"lat":42.7570109,"lon":23.45046830000001},
      {"lat":42.733883,"lon":25.485829999999964}
    ]
    # coffeelint: enable=max_line_length

    MAP_VIEW = {
      DISPLAY_LIMIT: 20                # limit multiple results
      OFFSET_HEIGHT: 420              # offsetH = ion-modal-view.modal.height - mapH
      GRID_RESPONSIVE_SM_BREAK: 680   # sass: $grid-responsive-sm-break
      MARGIN_TOP_BOTTOM: 0.1 + 0.1    # ion-modal-view.modal(style="margin: 10% auto")
      MAP_MIN_HEIGHT: 200
      MESSAGE:
        ZERO_RESULTS_ERROR: "No results found, please try again."
        VERIFY_LABEL:       "This is how the location will be displayed"
        MULTIPLE_RESULTS:   "[multiple results]"
        ZERO_RESULTS:       "[location not found]"
    }

    vm = this
    vm.title = "Map View"
    vm.me = null      # current user, set in initialize()
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
    }

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }

    _getAsGeocodeResult = (rows)->
      rows ?= vm.rows
      return _.map rows, (o, i, rows)->
        return {
          formatted_address: o.address
          geometry:
            location:
              lat: ()->return o.lat
              lng: ()->return o.lon
        }

    setMapHeight = ()->
      # calculate mapHeight

      contentH =
        # same as @media(max-width: 680)
        if $window.innerWidth <= MAP_VIEW.GRID_RESPONSIVE_SM_BREAK
        then $window.innerHeight
        # margin: 10% auto
        else $window.innerHeight * (1 - MAP_VIEW.MARGIN_TOP_BOTTOM)

      mapH = contentH - MAP_VIEW.OFFSET_HEIGHT
      mapH = Math.max( MAP_VIEW.MAP_MIN_HEIGHT , mapH)
      # console.log ["height=",$window.innerHeight , contentH,mapH]

      styleH = """
        #map-view-map .wrap {height: %height%px;}
        #map-view-map .angular-google-map-container {height: %height%px;}
      """
      styleH = styleH.replace(/%height%/g, mapH)
      angular.element(document.getElementById('map-view-style')).append(styleH)
      return mapH


    setupMap = (rows)->
      rows ?= vm.rows
      markerCount = rows.length

      if markerCount == 0
        return

      if markerCount == 1
        selectedLocation = rows[0]
        mapOptions = {
          type: 'oneMarker'
          location: [selectedLocation.lat, selectedLocation.lon]
          draggableMarker: false
          dragendMarker: (marker, eventName, args)->
            return
        }

      if markerCount > 1
        mapOptions = {
          type: 'manyMarkers'
          draggableMarker: true     # BUG? click event doesn't work unless true
          markers: _getAsGeocodeResult(rows)
          clickMarker: (marker, eventName, model)->
            index = model.id
            console.log ["clicked", vm.rows[index]]
        }

      mapConfig = geocodeSvc.getMapConfig mapOptions
      mapConfig.zoom = 11
      return mapConfig


    showMap = ()->
      return $q.when()
      .then ()->
        if vm.rows?.length
          return vm.rows
        return getData()
      .then (rows)->
        vm['map'] = setupMap(vm.rows)
        return

    getData = ()->
      if usePromise = true
        vm.rows = []
        return $q.when().then ()->
          vm.rows = sampleData
          console.log "vm.rows set by $q"
          exportDebug.set('rows', vm.rows)
          return vm.rows
      else
        vm.rows = sampleData

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

    }

    initialize = ()->
      # return
      if $rootScope.user?
        vm.me = $rootScope.user
      else
        DEV_USER_ID = '0'
        devConfig.loginUser( DEV_USER_ID ).then (user)->
          # loginUser() sets $rootScope.user
          vm.me = $rootScope.user
          toastr.info "Login as userId=0"
          return vm.me
      setMapHeight()
      getData()
      return

    activate = ()->
      showMap()
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
      $log.info "viewLoaded for MapCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for MapCtrl"
      activate()

    return vm  # end MapCtrl


MapCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'geocodeSvc'
  'utils', 'devConfig', 'exportDebug'
]



###
# @description  MapDetailCtrl, controller for directive:list-item-detail
###

MapDetailCtrl = (
  $scope, $rootScope, $q
  tileHelpers, openGraphSvc
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
  'tileHelpers', 'openGraphSvc'
  '$log', 'toastr'
]


angular.module 'starter.map'
  .controller 'MapCtrl', MapCtrl
  .controller 'MapDetailCtrl', MapDetailCtrl
