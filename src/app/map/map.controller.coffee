'use strict'

MapCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate
  $log, toastr
  uiGmapGoogleMapApi, openGraphSvc, geocodeSvc
  utils, devConfig, exportDebug
  )->

    # coffeelint: disable=max_line_length
    sampleData = {
      item: [
        {"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","og:site_name":"Yummly","og:url":"http://www.yummly.com/recipe/Thomas-Keller_s-Roast-Chicken-1286231","og:title":"Thomas Keller's Roast Chicken Recipe","og:image":"http://lh3.googleusercontent.com/h9IttHblN8tuFyHG-A4cDhqzYPNB-yM4jyT2fIgLFxg6lcxKdKCSqPyCz_c5pk0eCS3JLUPXjo2M7CU4pVsWog=s730-e365","yummlyfood:course":"Main Dishes","yummlyfood:ingredients":"butter","yummlyfood:time":"1 hr 30 min","yummlyfood:source":"TLC","og:description":"Thomas Keller's Roast Chicken Recipe Main Dishes with chicken, ground black pepper, salt, orange, lemon, carrots, onions, celery ribs, shallots, bay leaves, thyme sprigs, butter"}
        {"og:locale":"en_US","og:title":"Daniel Boulud's Short Ribs Braised in Red Wine with Celery Duo","og:type":"website","og:url":"http://www.epicurious.com/recipes/food/views/daniel-bouluds-short-ribs-braised-in-red-wine-with-celery-duo-106671","og:description":"Chef Boulud says that the success of this dish rests on browning the short ribs well at the beginning of cooking the dish to get the best flavors into the sauce. The Celery Duo starts with a celery root puree and ends with the braised ribs that top the beef. This recipe also can be found in the Café Boulud Cookbook, by Daniel Boulud and Dorie Greenspan.","og:image":"http://www.epicurious.com/static/img/misc/epicurious-social-logo.png","og:site_name":"Epicurious","fb:app_id":"1636080783276430","fb:admins":"14601235","type":"recipe"}
        {"og:locale":"en_US","og:type":"recipe","og:title":"Red Wine-Braised Short Ribs Recipe - Bon Appétit","og:description":"These Red Wine-Braised Short Ribs are even better when they're allowed to sit overnight.","og:url":"http://www.bonappetit.com/recipe/red-wine-braised-short-ribs","og:site_name":"Bon Appétit","article:publisher":"https://www.facebook.com/bonappetitmag","article:tag":"Beef,Dinner,Meat,Ribs","article:section":"Recipes","og:image":"http://www.bonappetit.com/wp-content/uploads/2011/08/red-wine-braised-short-ribs-940x560.jpg","type":"recipe"}
      ]
      location: [
        {"lat":42.6700528,"lon":23.314167099999963},
        {"lat":42.6737483,"lon":23.325192799999968},
        {"lat":42.6977082,"lon":23.321867500000053},
        {"lat":42.6599319,"lon":23.31657610000002},
        {"lat":42.6743583,"lon":23.32824210000001},
        {"lat":42.7570109,"lon":23.45046830000001},
        {"lat":42.7570109,"lon":23.45046830000001},
        {"lat":42.733883,"lon":25.485829999999964}
      ]
    }
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
          try
            $el = angular.element(document.querySelector('.list-item-wrap'))
            $listItemDelegate = $el.scope().$parent.$listItemDelegate
          catch err
            console.error "Unable to find reference to $listItemDelegate"

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
              $listItemDelegate.select(null, vm.rows[index], index, 'silent')

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
      if usePromise = true
        vm.rows = []
        return $q.when().then ()->
          # add location to recipes
          data = _.map sampleData.item, (o,i,l)->
            merged = openGraphSvc.normalize o
            merged.location = sampleData.location[i]
            return merged
          vm.rows = data
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

    $rootScope.$on '$listItemDelegate:selected', (ev, args) ->
      console.log ["selected", args.$index, args.$item]
      config = vm['map'].options.manyMarkers
      markers = config.control.getGMarkers()
      marker = markers[args.$index]
      config.events.click marker, null, null, null, 'silent'
      return



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
