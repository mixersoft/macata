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
  MARKER_KEYMAP:
    id: '_id'
    location: 'location'
    label: 'title'
  MAP_HANDLE_DEFAULT:  # default struct for managing angular-google-maps
    mapReady: 'promise'
    map: null   # angular-google-maps
    gMap: null  # google.maps
    controls:   # gMap controls
      map: {}
      markers: {}
  CSS_STYLE_TEMPLATE: """
    #%id% .map-view-map .angular-google-map-container {height: %height%px;}
    #%rootId% .map-view-list.has-map {top: %bottom%px;}
    """
}




#
# directive: <map-view>
# @description render a collection as markers on a google map
#   works together with the list view
#   lifecycle:
#     - set mv.rows, i.e. <map-view rows="{{}}">
#     - setupMap(), resolve( mapConfig )
#     - $watch mv.show to toggle map visibility
#     - on _showMap(true), loadMap(mapConfig)
#     - <ui-gmap-google-map ng-show="{{mapConfig}}"> from angular-google-maps
#     - wait for geocodeSvc.loadAngularGoogleMap(), resolve(gMap)
#     - set map-view.id, scoped CSS styles for map+list, see <style-scoped>
#     - 'resize' gMap and set bounds, _setMapBounds()
#
#

MapView = ( )->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'rows': '='
      'keymap': '<'
      'selectedId': '='
      'show': '='
      'markerType': '='
    }
    templateUrl: (elem, attr)->
      return 'map/map-view.html'
    controllerAs: 'mv'
    controller: [
      '$scope', '$element', '$q', '$state', '$timeout', '$window'
      'uiGmapGoogleMapApi', 'geocodeSvc'
      'uiGmapIsReady'
      # http://angular-ui.github.io/angular-google-maps/#!/api/IsReady

      # 'FEED_DB_TRIGGERS', 'EventActionHelpers'
      'utils', 'toastr'
      ($scope, $element, $q, $state, $timeout, $window
      uiGmapGoogleMapApi, geocodeSvc
      uiGmapIsReady
      # FEED_DB_TRIGGERS, EventActionHelpers
      utils, toastr)->
        mv = this

        # scope
        mv.mapViewId = null

        # manage mapConfig + gMap object
        # set in $watchCollection 'mv.rows'

        mv.mapHandle = _.cloneDeep MAP_VIEW.MAP_HANDLE_DEFAULT

        mv.$onInit = ()->
          return

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

          # update <style-scoped> css
          mv.cssStyle = MAP_VIEW.CSS_STYLE_TEMPLATE
            .replace(/%id%/g, mv.mapViewId)
            .replace(/%height%/g, mapH)
            .replace(/%bottom%/g, mapBot)
          return mapH

        $scope.$watchCollection 'mv.rows', (newV, oldV)->
          return if !newV
          rows = newV
          debounced_setupMap(rows)

        $scope.$watch 'mv.show', (newV, oldV)->
          return if newV == oldV
          _showMap(newV)

        # update <style-scoped> when mapId changes
        $scope.$watch 'mv.mapViewId', (newV, oldV)->
          return if !newV || newV == oldV
          # console.log ["mapId changed, =", mv.mapViewId]
          _setMapHeight()
          return

        # select marker when listItem clicked
        $scope.$watch 'mv.selectedId', (newV, oldV)->
          return if !newV || newV == oldV
          _renderSelectedMarker mv.selectedId
          return



        setupMap = (rows)->
          mv.keymap = _.defaults mv.keymap, MAP_VIEW.MARKER_KEYMAP
          rows ?= mv.rows
          markerCount = rows.length
          return uiGmapGoogleMapApi
          .then ()->

            if markerCount == 0
              return

            if markerCount == 1
              marker = geocodeSvc.mapLocations(rows[0], mv.keymap)
              mapOptions = {
                type: mv.markerType || 'oneMarker'
                # type: 'oneMarker'
                marker: marker
                location: [marker.latitude, marker.longitude]
                draggableMarker: false
                dragendMarker: (marker, eventName, args)->
                  return
              }

            if markerCount > 1
              mapOptions = {
                type: 'manyMarkers'
                draggableMarker: false     # BUG? click event doesn't work unless true
                markers: geocodeSvc.mapLocations(rows, mv.keymap)
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
                  mv.selectedId = marker.model[ 'id' ]
                  return
              }
            mapOptions['markerKeymap'] = mv.keymap
            mapConfig = geocodeSvc.getMapConfig mapOptions
            # mapConfig.zoom = 11
            return mapConfig
          .then (mapConfig)->
            # add support for map Controls
            mapConfig['controls'] = {
              map: {}
              markers: {}
            }
            return mapConfig

        debounced_setupMap = _.debounce (rows)->
          setupMap(rows)
          .then (mapConfig)->
            mv.mapHandle = _.cloneDeep MAP_VIEW.MAP_HANDLE_DEFAULT
            mv.mapHandle['map'] = mapConfig
            return _showMap(mv.show)
          return
        , 100
        , {
          leading: false
          maxWait: 1000
          trailing: true
        }

        loadMap = (mapHandle)->
          return $q.when() if !mapHandle.map
          return $q.when()
          .then ()->
            return mapHandle.map if mapHandle.gMap
            mv.map = mapHandle.map    # this begins the load!!!
            mv.mapHandle.mapReady = geocodeSvc.loadAngularGoogleMap( mapHandle.map, mv.mapHandle)
            return mv.mapHandle.mapReady
          .then (mapConfig)->
            mv.mapViewId = 'gMap-' + mv.mapHandle.gMap.uiGmap_id
            # $window.gMap = mv.gMap
            return mv.mapHandle.gMap

        _showMap = (show)->
          mapListEl = $element.parent()[0].querySelector('.map-view-list')
          loadMap(mv.mapHandle)
          .then ()->
            if show && mv.mapHandle.gMap
              # refresh, recenter map
              $timeout().then ()->
                gMap = mv.mapHandle.gMap
                google.maps.event.trigger(gMap, 'resize')
                _setMapBounds()
                # mv.mapHandle.controls.map.refresh()
            return show
          .then (show)->
            mapListEl = $element.parent()[0].querySelector('.map-view-list')
            # toggle show .map-view-list if found
            action = if show then 'add' else 'remove'
            mapListEl.classList[action]('has-map')
            return

        _renderSelectedMarker = (marker, markers)->
          gMap = null
          markersCtrl = null
          return mv.mapHandle.mapReady
          .then ()->
            gMap = mv.mapHandle.gMap
            markersCtrl = mv.mapHandle.controls.markers
          .then ()->
            markers ?= markersCtrl.getGMarkers()
            if _.isString marker
              marker = _.find markers, (o)-> return o.model.id == marker

            _.each markers, (m)->
              if m.resetIcon?
                m.setIcon(m.resetIcon)
                # m.set('labelContent', ' ' )
                m.set('labelVisible', false)
                delete m.resetIcon
              return

            # set selected marker
            label = marker.model['label'][0...20]
            label += '...' if marker.model['label'].length>20
            marker.set('labelContent', label )
            marker.set('labelVisible', true)
            # marker.set('labelStyle', {color: 'white'})
            marker.resetIcon = marker.getIcon()
            marker.setIcon('http://maps.google.com/mapfiles/ms/icons/green-dot.png')
            return marker
          .then (marker)->
            markerPosition = marker.getPosition()
            if not gMap.getBounds().contains markerPosition
              # scrollIntoView if out of bounds
              _setMapBounds(gMap, markers)
            # else
            #   map.panTo(markerPosition)
            return marker

        _setMapBounds = (map, markers)->
          return mv.mapHandle.mapReady
          .then ()->
            map ?= mv.mapHandle.gMap
            markersCtrl = mv.mapHandle.controls.markers
            return if !markersCtrl
            markers ?= markersCtrl.getGMarkers()
            # console.info ["_setMapBounds for ", markers]
            latlngbounds = new google.maps.LatLngBounds()
            markers.forEach (m)->
              latlngbounds.extend(m.getPosition())
              return
            map.fitBounds(latlngbounds)
            return

        mv.$onInit()
        return mv
      ]

  }



MapView.$inject = [ ]

angular.module 'starter.map'
  .directive 'mapView', MapView
