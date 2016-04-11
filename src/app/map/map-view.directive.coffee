'use strict'

###
  NOTE: using component-directives form,
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
###

MAP_VIEW = {
  DISPLAY_LIMIT: 20                # limit multiple results
  OFFSET_HEIGHT: 420              # offsetH = ion-modal-view.modal.height - mapH
  GRID_RESPONSIVE_SM_BREAK: 680   # sass: $grid-responsive-sm-break
  MARGIN_TOP_BOTTOM: 0.1 + 0.1    # ion-modal-view.modal(style="margin: 10% auto")
  MAP_MIN_HEIGHT: 200
}


CSS_STYLE_TEMPLATE = """
  #%id% .map-view-map .wrap {height: %height%px;}
  #%id% .map-view-map .angular-google-map-container {height: %height%px;}
  #%id% .map-view-list.has-map {top: %bottom%px;}
"""


MapView = ( CollectionHelpers )->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'mapId': '='
      'rows': '='
      'keymap': '@'
      'selectedId': '='
      'show': '='
      #
      'reactiveContext': '='
    }
    templateUrl: (elem, attr)->
      return 'map/map-view.html'
    controllerAs: 'mv'
    controller: [
      '$scope', '$q', '$state', '$timeout', '$window'
      'uiGmapGoogleMapApi', 'geocodeSvc'
      'uiGmapIsReady' # doesn't seem to resolve
      # http://angular-ui.github.io/angular-google-maps/#!/api/IsReady

      # 'FEED_DB_TRIGGERS', 'EventActionHelpers'
      'exportDebug'
      'utils', 'toastr'
      ($scope, $q, $state, $timeout, $window
      uiGmapGoogleMapApi, geocodeSvc
      uiGmapIsReady
      # FEED_DB_TRIGGERS, EventActionHelpers
      exportDebug
      utils, toastr)->

        mv = this

        # mv.mapId ?= 'map-view-' + $scope.$id
        keymap = $scope.$eval(mv.keymap)
        keymap = _.defaults keymap, {
          id: '_id'
          location: 'location'
          label: 'title'
        }
        mv.minHeight = 200

        mv.cssStyle = CSS_STYLE_TEMPLATE
          .replace(/%id%/g, mv.mapId)
          .replace(/%height%/g, mv.minHeight)

        _setMapHeight = ()->
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
          # .has-header offset
          mapBot = mapH + 44

          mv.cssStyle = CSS_STYLE_TEMPLATE
            .replace(/%id%/g, mv.mapId)
            .replace(/%height%/g, mapH)
            .replace(/%bottom%/g, mapBot)
          return mapH

        _getRowsAsGeocodeResult = (rows, keymap)->
          # angular-google-maps api expecting { latitude: longitude: formatted_address: }
          rows ?= mv.rows
          return _.map rows, (o, i, rows)->
            result = {}
            value = o[ keymap['location'] ] if keymap
            value ?= o['geojson'] || o['location'] # deprecate
            if value?.type == 'Point'
              # result = value  # geojsonPoint is acceptable
              angular.extend result, {
                latitude: geocodeSvc.mathRound6 value.coordinates[1]
                longitude: geocodeSvc.mathRound6 value.coordinates[0]
              }
            if _.isArray value
              [lat,lon] = value
              angular.extend result, {
                lat: geocodeSvc.mathRound6 lat
                lon: geocodeSvc.mathRound6 lon
              }
            else if value?.lat
              lat = value.lat?() || value.lat
              lon = value.lng?() || value.lon
              angular.extend result, {lat:lat, lon:lon}

            angular.extend result, {
              id: o[ keymap['id'] ] + ''
              # formatted_address: o.formatted_address || o.address
              # label: o[ keymap['label'] ]
            }
            return result

        _selectMarker = (id)->
          mv.gMap.renderSelectedMarker(id)
          return
          $timeout(0).then ()->
            # select marker by $index
            # markers = mv.gMap.MarkersControl.getGMarkers()
            # marker = _.find markers, (o)-> return `o.model._id==id`
            mv.gMap.renderSelectedMarker(id)

        $scope.$watch 'mv.show', (newV, oldV)->
          return if newV == oldV
          selector = '#%id% .map-view-list'.replace(/%id%/g, mv.mapId)
          nextChild = document.querySelector(selector)
          action = if newV then 'addClass' else 'removeClass'
          angular.element(nextChild)[action]('has-map')
          if newV
            $timeout(300).then ()->
              console.log mv.map
              mv.gMap.Control.refresh?()
              mv.gMap.setMapBounds()
              return
          return

        # NOTE: this watch is not catching all changes to mv.mapId
        $scope.$watch 'mv.mapId', (newV, oldV)->
          return if !newV || newV == oldV
          # console.log ["mapId changed, =", mv.mapId]
          _setMapHeight()

        $scope.$watch 'mv.selectedId', (newV, oldV)->
          return if !newV || newV == oldV
          id = newV
          _selectMarker id

        $scope.$watchCollection 'mv.rows', (newV, oldV)->
          return if !newV
          rows = newV
          # console.warn ["=", mv.mapId, mv.settings.viewId]
          # mv.mapId = mv.settings.viewId if mv.settings.viewId?
          debounced_setupMap(rows)

        setupMap = (rows)->
          rows ?= mv.rows
          markerCount = rows.length
          return uiGmapGoogleMapApi
          .then ()->

            if markerCount == 0
              return

            if markerCount == 1
              rows = _getRowsAsGeocodeResult rows, keymap
              mapOptions = {
                type: 'oneMarker'
                marker: rows[0]
                # location: rows[0] # deprecate
                draggableMarker: true
                dragendMarker: (marker, eventName, args)->
                  return
              }
              console.log ['oneMarker', JSON.stringify mapOptions.marker]

            if markerCount > 1
              mapOptions = {
                type: 'manyMarkers'
                draggableMarker: true     # BUG? click event doesn't work unless true
                markers: _getRowsAsGeocodeResult(rows, keymap)
                options:
                  icon: 'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
                  labelClass: 'map-marker-label-class'
                  labelVisible: false
                  # labelStyle:
                  #   color: 'white'
                  # labelContent: 'title'
                # control: {}   # see: mv.gMap.MarkersControl
                clickMarker: (marker, eventName, model, skip, silent)->
                  # console.log ["clicked, i="+index, mv.rows[index]]
                  mv.selectedId = marker.model._id
                  return
              }
            mapOptions['markerKeymap'] = keymap
            mapConfig = geocodeSvc.getMapConfig mapOptions
            # mapConfig.zoom = 11
            return mapConfig

        debounced_setupMap = _.debounce (rows)->
          setupMap(rows).then (config)->
            return mv.map = config
          return

        , 100
        , {
          leading: false
          maxWait: 1000
          trailing: true
        }


        initialize = ()->
          exportDebug.set('mv', mv)
          # mv.gMap['ControlsReady'] = mv.gMap['Dfd'].promise
          mv.gMap['ControlsReady'] = uiGmapIsReady.promise(1)
          # Guard with jade: ui-gmap-google-map(ng-if="$map")
          mv.gMap['ControlsReady']
          .then (result)->
            return if result == 'gMapControls ready'
            instances = result
            instances.forEach (inst)->
              $window.mapInstance = inst
              map = inst.map
              uuid = map.uiGmap_id
              mapInstanceNumber = inst.instance
            console.info "uiGmapIsReady.promise resolve"
          ,(err)->
            console.warn ["uiGmapIsReady", err]
            mv.gMap['ControlsReady'] = mv.gMap['Dfd'].promise

          # wait for map controls ready by watching MarkersControl.getGMarkers
          # because uiGmapIsReady.promise(1) doesn't seem to work
          unwatch = $scope.$watch 'mv.gMap.MarkersControl.getGMarkers', (newV)->
            if newV && mv.gMap['Control'].getGMap
              unwatch?()
              console.info "gMap && gMap Markers ready"
              mv.gMap.Dfd.resolve('gMapControls ready')

              $window.gMap = mv.gMap
          # NOTE: 'map-ready' fired once for each $ionicView.loaded ONLY
          # NOTE: 'tilesloaded/map-ready' event does NOT fire from a cached $ionicView


        # if not this.reactiveContext.getReactively
        #   throw new Error "ERROR: expecting reactiveContext"

        mv.collHelpers = new CollectionHelpers(mv.reactiveContext)
        mv.me = mv.collHelpers.findOne('User', Meteor.userId())



        # gMap initialization & methods
        # mv.gMap.Control, mv.gMap.MarkersControl:
        #   set on each controller load
        #   see: map-view.jade, angular-google-maps
        # map-ready on each $ionicView.load, but NOT $ionicView.enter
        mv.gMap = {
          Control : {}
          MarkersControl : {}
          Dfd : $q.defer()
          # use uiGmapIsReady instead?
          ControlsReady : 'promise'
          renderSelectedMarker: (marker, markers)->
            return if mv.map.type != 'manyMarkers'
            return mv.gMap.ControlsReady
            .then ()->
              markers ?= mv.gMap.MarkersControl.getGMarkers?()

              if _.isString marker
                marker = _.find markers || [], (o)-> return o.model._id == marker

              return if !marker
              _.each markers, (m)->
                if m.resetIcon?
                  m.setIcon(m.resetIcon)
                  # m.set('labelContent', ' ' )
                  m.set('labelVisible', false)
                  delete m.resetIcon
                return

              # set selected marker
              label = marker.model.title[0...20]
              label += '...' if marker.model.title.length>20
              marker.set('labelContent', label )
              marker.set('labelVisible', true)
              # marker.set('labelStyle', {color: 'white'})
              marker.resetIcon = marker.getIcon()
              marker.setIcon('http://maps.google.com/mapfiles/ms/icons/green-dot.png')
              return marker
            .then (marker)->
              map = mv.gMap.Control.getGMap()
              markerPosition = marker.getPosition()
              if not map.getBounds().contains markerPosition
                # scrollIntoView if out of bounds
                mv.gMap.setMapBounds(map, markers)
              # else
              #   map.panTo(markerPosition)
              return marker

          setMapBounds: (map, markers)->
            return
            return if mv.map.type != 'manyMarkers'
            return mv.gMap.ControlsReady
            .then ()->
              map ?= mv.gMap.Control.getGMap()
              markers ?= mv.gMap.MarkersControl.getGMarkers()
              # console.info ["setMapBounds for ", markers]
              latlngbounds = new google.maps.LatLngBounds()
              markers.forEach (m)->
                latlngbounds.extend(m.getPosition())
                return
              map.fitBounds(latlngbounds)
              return
        }


        mv.on = {
          isValidMarker: ()->
            return

        }

        initialize()
        return mv
      ]

  }



MapView.$inject = [ 'CollectionHelpers']

angular.module 'starter.map'
  .directive 'mapView', MapView
