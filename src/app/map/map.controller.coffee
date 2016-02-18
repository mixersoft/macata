'use strict'

MapCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  uiGmapGoogleMapApi, geocodeSvc
  EventsResource, IdeasResource
  utils, devConfig, exportDebug
  )->

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
    vm.viewId = ["map-view",$scope.$id].join('-')
    vm.me = null      # current user, set in initialize()
    vm.listItemDelegate = null

    # gMap initialization & methods
    # vm.gMap.Control, vm.gMap.MarkersControl:
    #   set on each controller load
    #   see: map.jade, angular-google-maps
    # map-ready on each $ionicView.load, but NOT $ionicView.enter
    vm.gMap = {
      Control : {}
      MarkersControl : {}
      Dfd : $q.defer()
      ControlsReady : 'promise'
      renderSelectedMarker: (marker, markers)->
        _.each markers, (m)->
          if m.resetIcon?
            m.setIcon(m.resetIcon)
            # m.set('labelContent', ' ' )
            m.set('labelVisible', false)
            delete m.resetIcon
          return
        # set selected marker
        index = marker.model.id
        label = marker.model.title[0...20]
        label += '...' if marker.model.title.length>20
        marker.set('labelContent', label )
        marker.set('labelVisible', true)
        # marker.set('labelStyle', {color: 'white'})
        marker.resetIcon = marker.getIcon()
        marker.setIcon('http://maps.google.com/mapfiles/ms/icons/green-dot.png')

      setMapBounds: (map, markers)->
        # console.info ["setMapBounds for ", markers]
        latlngbounds = new google.maps.LatLngBounds()
        markers.forEach (m)->
          latlngbounds.extend(m.getPosition())
          return
        map.fitBounds(latlngbounds)
        return
    }
    vm.gMap['ControlsReady'] = vm.gMap['Dfd'].promise

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

    vm.lookup = {}

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

      # list-item-container[on-select='&']
      # called by: vm.listItemDelegate.select()
      select: ($item, $index, silent)->
        # if $item == null
        #   $item = vm.listItemDelegate.selected()
        #   return vm.on['gotoTarget']($item)

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
        console.log ["selected", $index, $item]
        return if silent

        $timeout(0).then ()->
          # select marker by $index
          markers = vm.gMap.MarkersControl.getGMarkers()
          marker = markers[$index]
          vm.gMap.renderSelectedMarker(marker, markers)

          map = vm.gMap.Control.getGMap()
          markerPosition = marker.getPosition()
          if not map.getBounds().contains markerPosition
            # scrollIntoView if out of bounds
            vm.gMap.setMapBounds(map, markers)
          # map.panTo(markerPosition)
          return
        return
    }

    _getAsGeocodeResult = (rows)->
      rows ?= vm.rows
      return _.map rows, (o, i, rows)->
        if _.isArray o.location
          [lat,lon] = o.location
        else if o.location?.lat
          lat = o.location.lat?() || o.location.lat
          lon = o.location.lng?() || o.location.lon

        o.geometry = {
          location:
            lat: ()->return lat
            lng: ()->return lon
        }
        o.formatted_address = o.address
        return o

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
        #%viewId% .map-view-search { min-width:32.5px; }
        #%viewId% .map-view-search svg {width: 26px; height: 26px; margin: 5px 0;}
        #%viewId% .map-view-map .wrap {height: %height%px;}
        #%viewId% .map-view-map .angular-google-map-container {height: %height%px;}
      """
      styleH = styleH.replace(/%height%/g, mapH)
      # .has-header offset
      mapBot = mapH + 44
      styleH += "#%viewId% .map-view-list {top: %top%px;}".replace('%top%', mapBot)
      styleH = styleH.replace(/%viewId%/g, vm.viewId)
      angular.element(document.querySelector('#'+vm.viewId+' .map-view-style')).html(styleH)
      return mapH


    setupMap = (rows)->
      rows ?= vm.rows
      markerCount = rows.length
      return uiGmapGoogleMapApi
      .then ()->

        # if markerCount == 0
        #   return
        #
        # if markerCount == 1
        #   selectedLocation = rows[0]
        #   mapOptions = {
        #     type: 'oneMarker'
        #     location: [selectedLocation.lat, selectedLocation.lon]
        #     draggableMarker: false
        #     dragendMarker: (marker, eventName, args)->
        #       return
        #   }

        if markerCount > 1
          mapOptions = {
            type: 'manyMarkers'
            draggableMarker: true     # BUG? click event doesn't work unless true
            markers: _getAsGeocodeResult(rows)
            options:
              icon: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
              labelClass: 'map-marker-label-class'
              labelVisible: false
              # labelStyle:
              #   color: 'white'
              # labelContent: 'title'
            # control: {}   # see: vm.gMap.MarkersControl
            clickMarker: (marker, eventName, model, skip, silent)->
              # console.log ["clicked, i="+index, vm.rows[index]]
              # render selected marker, reset others
              markers = vm.gMap.MarkersControl.getGMarkers()
              vm.gMap.renderSelectedMarker(marker, markers)

              # silent if called by list-summary-detail: $listItemDelegate.selected()
              # not silent if marker was clicked by user
              if not silent
                # select matching item in list-summary-detail
                index = marker.model.id
                vm.listItemDelegate.select(null, vm.rows[index], index, 'silent')
                return

          }
        mapOptions = _.extend mapOptions, {
          # 'control' : {}  # see: vm.gMap.Control
          'mapReady' : (map, eventName)->
            # TODO: deprecate
            # NOTE: 'tilesloaded/map-ready' event does NOT fire from a cached $ionicView
            $scope.$broadcast 'map-ready', map
        }
        mapConfig = geocodeSvc.getMapConfig mapOptions
        # mapConfig.zoom = 11
        return mapConfig


    showMap = ()->
      return $q.when()
      .then ()->
        if vm.rows?.length
          return vm.rows
        return getData()
      .then (rows)->
        setupMap(vm.rows)
      .then (config)->
        vm['map'] = config
        # exportDebug.set 'mapConfig', config
        return


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
          data = _.map data, (o)->
            return _.omit o, (v,k)->
              return true if k.slice(0,2)=='$$'
        return data
      .then (data)->
        vm.rows = data
        # exportDebug.set('mapData', vm.rows)
        return vm.rows

    initialize = ()->
      # $ionicView.loaded: called once for EACH cached $ionicView,
      #   i.e. each instance of vm
      unwatch_gMapMarkersControl = $scope.$watch 'vm.gMap.MarkersControl.getGMarkers', (newV)->
        if newV && vm.gMap['Control'].getGMap
          unwatch_gMapMarkersControl?()
          console.log "gMap && gMap Markers ready"
          vm.gMap.Dfd.resolve('gMapControls ready')
      # NOTE: 'map-ready' fired once for each $ionicView.loaded ONLY
      # NOTE: 'tilesloaded/map-ready' event does NOT fire from a cached $ionicView

    activate = ()->
      # $ionicView.enter
      vm.listItemDelegate = $listItemDelegate.getByHandle('map-list-scroll', $scope)
      return $q.when()
      .then ()->
        return devConfig.getDevUser("0").then (user)->
          return vm.me = user
      .then getData
      .then ()->
        setMapHeight()
        showMap()
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return
      .then ()->
        return if not $stateParams.id
        index = _.findIndex vm.rows, (o)->
          return true if [o.id,o.className].join(':') == $stateParams.id
        return if not ~index

        # select active marker
        vm.gMap.ControlsReady.finally ()->
          # need to wait for a non-existent 'markers-ready' event
          # on $ionicView.load, using $watch + promise instead
          $timeout(0).then ()->
            # NOTE: 'tilesloaded/map-ready' event does NOT fire from a cached $ionicView
            # using $timeout(0) instead
            vm.listItemDelegate.select(null, vm.rows[index], index)
          return
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
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'uiGmapGoogleMapApi', 'geocodeSvc'
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
