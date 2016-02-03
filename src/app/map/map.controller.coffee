'use strict'

MapCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  uiGmapGoogleMapApi, openGraphSvc, geocodeSvc
  utils, devConfig, exportDebug
  )->

    viewLoaded = null   # promise

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
    vm.listItemDelegate = null
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

      #  list-item-container[on-select]
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
        , {id: $item && $item.id || $index}
        , {notify:false}
        )
        console.log ["selected", $index, $item]
        return if silent

        config = vm['map'].options.manyMarkers
        if _.isEmpty config.control
          return console.warn ["markers.control NOT AVAILABLE yet"]
        markers = config.control.getGMarkers()
        marker = markers[$index]
        config.events.click marker, null, null, null, 'silent'
        return
    }

    _getAsGeocodeResult = (rows)->
      rows ?= vm.rows
      return _.map rows, (o, i, rows)->
        o.geometry = {
          location:
            lat: ()->return o.location.lat
            lng: ()->return o.location.lon
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
        #map-view-map .wrap {height: %height%px;}
        #map-view-map .angular-google-map-container {height: %height%px;}
      """
      styleH = styleH.replace(/%height%/g, mapH)
      # .has-header offset
      mapBot = mapH + 44
      styleH += "#map-view-list {top: %top%px;}".replace('%top%', mapBot)

      angular.element(document.getElementById('map-view-style')).append(styleH)
      return mapH


    setupMap = (rows)->
      rows ?= vm.rows
      markerCount = rows.length
      return uiGmapGoogleMapApi
      .then ()->

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
            options:
              icon: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
              labelClass: 'map-marker-label-class'
              labelVisible: false
              # labelStyle:
              #   color: 'white'
              # labelContent: 'title'
            control: {}
            clickMarker: (marker, eventName, model, skip, silent)->
              # console.log ["clicked, i="+index, vm.rows[index]]
              # reset markers
              markers = mapOptions.control.getGMarkers()
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

              # silent if called by list-summary-detail: $listItemDelegate.selected()
              if silent
                # scrollIntoView if out of bounds
                _setMapBounds = (map, markers)->
                  latlngbounds = new google.maps.LatLngBounds()
                  markers.forEach (m)->
                    latlngbounds.extend(m.getPosition())
                    return
                  map.fitBounds(latlngbounds)
                  return

                map = vm.map.control.getGMap()
                markerPosition = marker.getPosition()
                if not map.getBounds().contains markerPosition
                  _setMapBounds(map, markers)
                # map.panTo(markerPosition)
                return

              # select matching item in list-summary-detail
              vm.listItemDelegate.select(null, vm.rows[index], index, 'silent')

          }
        mapOptions = _.extend mapOptions, {
          'control' : {}
          'mapReady' : (map, eventName)->
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
        exportDebug.set 'mapConfig', config
        return


    getData = ()->
      vm.rows = []
      return devConfig.getData()
      .then (data)->
        vm.rows = data
        exportDebug.set('rows', vm.rows)
        return vm.rows

    initialize = ()->
      return viewLoaded = $q.when()
      .then ()->
        if $rootScope.user?
          vm.me = $rootScope.user
        else
          DEV_USER_ID = '0'
          devConfig.loginUser( DEV_USER_ID ).then (user)->
            # loginUser() sets $rootScope.user
            vm.me = $rootScope.user
            toastr.info "Login as userId=0"
            return vm.me
      .then ()->
        vm.listItemDelegate = $listItemDelegate.getByHandle('map-list-scroll')
        setMapHeight()
        return
      .then ()->
        return getData()

    activate = ()->
      if index = $stateParams.id
        stop = $scope.$on 'map-ready', (ev)->
          vm.listItemDelegate.select(null, vm.rows[index], index)
          stop?()
          return
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
      return viewLoaded.finally ()->
        activate()

    return vm  # end MapCtrl


MapCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'uiGmapGoogleMapApi', 'openGraphSvc', 'geocodeSvc'
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
