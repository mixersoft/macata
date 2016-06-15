# geocode.service.coffee
'use strict'


###
#  Module globals
###
GEOCODER = {
  instance: null                            # new maps.Geocoder()
  STATUS: {}                                # google.maps.GeocoderStatus
  ZERO_RESULT_LOC: [37.77493, -122.419416]  # san francisco, show on zero results
  getPlaceholderDefault: ()->
    # return an object which mimics geocode().then (result)->
    return geoCodeResult = {
      geometry:
        location:
          lat: ()-> return GEOCODER.ZERO_RESULT_LOC[0]
          lng: ()-> return GEOCODER.ZERO_RESULT_LOC[1]
      formatted_address: MODAL_VIEW.MESSAGE.ZERO_RESULTS
      status: GEOCODER.STATUS.ZERO_RESULTS
    }
}

MODAL_VIEW = {
  TEMPLATE: 'blocks/components/geocode.template.html'
  DISPLAY_LIMIT: 5                # limit multiple results
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


geocodeSvcConfig = (uiGmapGoogleMapApiProvider, API_KEY)->
  # return
  # API_KEY = null
  cfg = {
    v: '3.20'
    # libraries: ''
  }
  cfg.key = API_KEY if API_KEY
  uiGmapGoogleMapApiProvider.configure cfg
  return

geocodeSvcConfig.$inject = ['uiGmapGoogleMapApiProvider', 'API_KEY']

###
# @description Google Maps Geocode Service v3
# see https://developers.google.com/maps/documentation/geocoding/intro
###

Geocoder = ($q, $ionicPlatform, appModalSvc, uiGmapGoogleMapApi, uiGmapIsReady)->

  ## private methods & attributes
  init = (maps)->
    GEOCODER.STATUS = maps.GeocoderStatus
    GEOCODER.instance = new maps.Geocoder()
    # console.log GEOCODER
    return

  mathRound6 = (v)->
    return Math.round( v * 1000000 )/1000000 if _.isNumber v
    return v

  normalizeGeocodeOptions = (options)->
    # normalized example: options = {
    #   address: String
    #   location: [lat,lon] as Array or String
    #   latlng: google.maps.LatLng class
    # }
    isLatLon = /^(\d+\.*\d*),(\d*\.*\d*)$/
    # check if address is a latlon
    if latlon = options.address?.match(isLatLon)
      #  use address as latlon instead, legacy, deprecate
      options.location = option.address
      delete options.address

    # geocode a location
    if options.location?.type == 'Point'
      #  geojson
      options.latlng = {
        lat: options.location.coordinates[1]
        lng: options.location.coordinates[0]
      }
    else if latlon = options.location?.match?(isLatLon)
      # [lat,lon] as Array or String
      options.latlng = {
        lat: parseFloat(latlon[1])
        lng: parseFloat(latlon[2])
      }
    else if options.location?.length == 2
      latlon = options.location
      # [lat,lon] as Array
      options.latlng = {
        lat: parseFloat(latlon[0])
        lng: parseFloat(latlon[1])
      }
    return options




  # wait for google JS libs to load
  uiGmapGoogleMapApi.then (maps)->
    console.log "uiGmapGoogleMapApi promise resolved"
    init(maps)
    return


  ## factory object
  geocoder = {

    ###
    @description an Entry Point for this service, returns an object with a geocode location
    @param options Object,
      {
        location: [lat,lon] as a string of 2 comma-separated floats
            or geojson point
        address: String, preserve existing address string if location also given
      }
    @resolve object { address: location: place_id:(optional) } or null if canceled
    @reject ['ERROR', err]
    ###
    getLatLon: (options)->
      options = normalizeGeocodeOptions(options)
      return geocoder.geocode(options)
      .then (results)->
        # console.log ["Geocode results, count=", results.length] if _.isArray results
        if results == GEOCODER.STATUS.ZERO_RESULTS
          results = [GEOCODER.getPlaceholderDefault()]
        if options.latlng && options.address
          options.useOriginalAddress = true
        return results
      , (err)->
        console.warn ["geocoder.geocode()", err]
        throw err
      .then (results)->
        return geocoder.showResultsAsMap(options, results)
        # @resolve result, one geocode result or CANCELED, ZERO_RESULTS

        # same as: geocoder.displayGeocode(options)
      .then (result)->
        return null if !result || result == 'CANCELED'
        return result if _.isString result  # NOT FOUND, ERROR?

        if result.override?.location
          latlon = result.override?.location
        else
          location = result['geometry']['location']
          latlon = [location.lat() , location.lng()]

        # round to 6 significant digits
        latlon = _.map latlon, (v)->
          return mathRound6 v

        # console.log ['getLatLon location', location]
        lonlat = angular.copy(latlon).reverse()

        resp = {
          address: result.override?.address || result['formatted_address']
          location: latlon  # resolve [lat,lon]
          geojson:
            type: 'Point'
            coordinates: lonlat
          lonlat: lonlat
          geoCodeResult: result
        }
        resp['place_id'] = result['place_id'] if !result.override
        return resp
      .catch (err)->
        return ['ERROR: geocodeSvc.getLatLon()', err]



    ###
    # called by geocoder.displayGeocode() and GeocodeModalCtrl.updateGeocode()
    @param options Object,
      {
        address: String, preserve existing address string if location also given
        latlng: google.maps.LatLng class
        location: [lat,lon] as a string of 2 comma-separated floats
            or geojson point
      }
    ###
    geocode: (options)->
      return $q.reject("Geocoder JS lib not ready") if !GEOCODER.instance?

      find = {}  # {address: location: placeId:}
      if options.latlng
        find['location'] = options.latlng
      else
        find['address'] = options.address

      dfd = $q.defer()
      GEOCODER.instance.geocode( find, (result, status)->
        # result['geocodeOptions'] = options
        switch status
          when 'OK'
            if find.location
              # filter out approximate results
              result = _.filter result, (o)->
                return true if o.geometry.location_type != 'APPROXIMATE'
            return dfd.resolve result
          when GEOCODER.STATUS.ZERO_RESULTS
            return dfd.resolve GEOCODER.STATUS.ZERO_RESULTS
          else
            console.error ['geocodeSvc.geocode()', status]
            return dfd.reject {
              status: status
              result: result
            }
      )
      return dfd.promise



    ###
    # Utility Methods
    ###

    ###
    # @description show geocodeResults as marker(s) on a map in a modal
    # @param options Object, {address: latlng:}
        address String, the geocode search string
    # @param geocodeResults array of results, e.g. geocode().then (results)->
    ###
    showResultsAsMap: (options, geocodeResults)->
      return appModalSvc.show(
        MODAL_VIEW.TEMPLATE
        'GeocodeModalCtrl as gmc'
        {
          geocodeOptions: options
          geocodeResults: geocodeResults
        })
      .then (modalResult)->
        # console.log ["showResultsAsMap:", geoCodeResult]
        return modalResult if _.isString modalResult || !modalResult

        mm = modalResult
        # TODO: need to choose 1 result from geocodeResults, move to head
        geoCodeResult = modalResult['geocodeResults'][0]
        geoCodeResult.override = {}
        if modalResult['marker-moved']
          geoCodeResult.override['location'] = modalResult['location']
        if modalResult['address-changed']
          geoCodeResult.override['address'] = modalResult['addressDisplay']

        return geoCodeResult
      .catch (err)->
        return $q.reject(err)


    ###
    # @description get a location array from an array of objects
    #     GEOCODER.instance.geocode() result
    #     marker from ui-gmap-marker dragend event on map
    #     model from ui-gmap-markers click event
    #       {id: latitude: longitude: formatted_address:}
    # @param rows array or object, array of object with location attrs
    #   objects will be converted to array
    # @param keymap object, dictionary of location attr keys
    # @return [lat,lon] round to 6 decimals for google Maps API
    ###
    mapLocations : (rows, keymap={})->
      # angular-google-maps api expecting { latitude: longitude: formatted_address: }
      return [] if !rows
      if not _.isArray rows
        rows = [rows]
        unwrap = true
      keymap = _.defaults keymap, {
        id: '_id'
        location: 'location'
        label: 'title'
      }
      result = _.map rows, (o, i, rows)->

        result = {}
        value = _.get( o, keymap['location']) if keymap
        value ?= o['geojson'] || o['location'] # deprecate
        if value?.type == 'Point'
          # result = value  # geojsonPoint is acceptable
          angular.extend result, {
            latitude: mathRound6 value.coordinates[1]
            longitude: mathRound6 value.coordinates[0]
          }
        else if _.isArray value
          [lat,lon] = value
          angular.extend result, {
            latitude: mathRound6 lat
            longitude: mathRound6 lon
          }
        else if value?.lat
          lat = value.lat?() || value.lat
          lon = value.lng?() || value.lon
          angular.extend result, {
            latitude: mathRound6 lat
            longitude: mathRound6 lon
          }

        angular.extend result, {
          id: _.get( o, keymap['id']) + ''
          formatted_address: o.formatted_address || o.address
          label: _.get( o, keymap['label'])
        }

        return result
        # return angular.extend o, result
      return result[0] if unwrap
      return result


    ###
    # @description get a location array from an object
    # @param point object of type
    #     GEOCODER.instance.geocode() result
    #     marker from ui-gmap-marker dragend event on map
    #     model from ui-gmap-markers click event
    #       {id: latitude: longitude: formatted_address:}
    # @return [lat,lon] round to 6 decimals for google Maps API
    ###
    # TODO: refactor, return as lonlat
    getLatLonFromObj : (point={})->
      if point['geometry']?.location?
        # geocode result
        return [
          mathRound6 point['geometry']['location'].lat()
          mathRound6 point['geometry']['location'].lng()
        ]
      if point.getPosition?
        # marker position
        return [
          mathRound6 point.getPosition().lat()
          mathRound6 point.getPosition().lng()
        ]
      if point.longitude?
        return [
          mathRound6 point.latitude
          mathRound6 point.longitude
        ]
      return null

    mathRound6: mathRound6

    ###
    # @description load a new <angular-google-map> from mapConfig
    #   initializes promises to wait for uiGmapIsReady & map controls
    # @param mapConfig Object, result from geocodeSvc.getMapConfig()
    # @param mapHandle Object, sets mapHandle.map and mapHandle.gMap with
    #     appropriate values
    # example:
      ui-gmap-google-map(
        center='mapHandle.map.center'
        zoom='mapHandle.map.zoom'
        options='mapHandle.map.options.map.options'
        control='mapHandle.map.control'
        events='mapHandle.map.events'
      )
        ui-gmap-circle(
          ng-if="map.type=='circle'"
          center="mapHandle.map.options.circle.center"
          radius="mapHandle.map.options.circle.radius"
          stroke="mapHandle.map.options.circle.stroke"
          )
        ui-gmap-marker(
          idKey="mapHandle.map.options.oneMarker.idKey"
          coords="mapHandle.map.options.oneMarker.coords"
          options="mapHandle.map.options.oneMarker.options"
          events="mapHandle.map.options.oneMarker.events"
          )
    ###
    loadAngularGoogleMap: (mapConfig, mapHandle)->
      return {} if _.isEmpty mapConfig
      if _.chain(mapHandle).pick(['map','gMap']).keys().value().length != 2
        throw new Error("Expecting attributes ['map','gMap'] on mapHandle")

      # TODO: do we need to release old map resources?
      toDestroy = _.pick mapHandle, ['map','gMap']

      self = mapHandle
      uiGmapIsReady.reset()
      mapInstanceCount = 1
      retries = 50
      mapHandle['map'] = mapConfig
      return uiGmapIsReady.promise(mapInstanceCount, retries)
      .then (instances)->
        console.log ['uiGmapIsReady', instances]
        mapHandle['gMap'] = gMap = instances[0].map
        google.maps.event.trigger(gMap, 'resize')
        return if !mapConfig.center
        center = {
          lat: mapConfig.center.latitude
          lng: mapConfig.center.longitude
        }
        # console.log 'setCenter', center
        gMap.setCenter(center)
        return mapConfig
      .catch (err)->
        console.warn ['loadAngularGoogleMap', err]




    ###
    @description: get google Map object for angular-google-maps,
      configured map places marker or circle at location
    @params: options
      id: string optional
      location: [lat,lon]  or [ [lat,lon], [lat,lon] ], render circle or marker at location
      markers: array of geocodeResults
      type: [circle, oneMarker, manyMarkers]
      circleRadius: 500, in meters
      draggableMap: true
      draggableMarker: true
      dragendMarker: Fn
      clickMarker: Fn
    ###
    getMapConfig: (options={}, markerKeymap={})->

      keymap = _.defaults markerKeymap, {
        id: 'id'
        location: 'location'
        label: 'title'
      }

      _.defaults options, {
        location: GEOCODER.ZERO_RESULT_LOC
        markers:[]
        type: 'oneMarker'
        circleRadius: 500
        draggableMap: true
        draggableMarker: true
      }
      # if useStaticMap=false
      #   mapSrc = "https://maps.googleapis.com/maps/api/staticmap?"
      #   params = {}
      #   params['size'] = "400x400"
      #   params['markers'] = options.markerLocation.join(',') if options.markerLocation?
      #   qs = _.map (v, k)-> [k,v].join("=")
      #   mapSrc += encodeURIComponent(qs.join('&'))
      #   $log.info("Static Map=" + mapSrc)

      mapConfigOptions = {
        'map':
          options:
            draggable: options.draggableMap
      }
      switch options.type
        when 'circle'
          gMapPoint = _.pick options.marker, ['latitude', 'longitude']
          mapConfigOptions['circle'] = {
            center: gMapPoint
            stroke:
              color: '#FF0000'
              weight: 1
            radius: options.circleRadius
            fill:
              color: '#FF0000'
              opacity: '0.2'
          }
        when 'oneMarker'
          gMapPoint = _.pick options.marker, ['latitude', 'longitude']
          mapConfigOptions['oneMarker'] = {
            idKey: options.marker.id
            coords: gMapPoint
            options: {
              draggable: options.draggableMarker
              icon: 'http://maps.google.com/mapfiles/ms/icons/green-dot.png'
            }
          }
          if options.draggableMarker
            mapConfigOptions['oneMarker']['events'] = {
              'dragend': options.dragendMarker
            }
        when 'manyMarkers'
          markers = options.markers
          mapConfigOptions['manyMarkers'] = {
            models: markers
            options: _.extend options.options, {
              draggable: options.draggableMarker
            }
            events:
              'click': options.clickMarker
            control: options.control
          }
          if options.draggableMarker
            mapConfigOptions['manyMarkers']['events']['dragend'] = options.dragendMarker
          gMapPoint = markers[0]



      return mapConfig = {
        type: options.type
        center: _.pick gMapPoint, ['latitude','longitude']
        zoom: 14
        scrollwheel: false
        control: {}
        events: {
          'tilesloaded': options.mapReady
        }
        # event.map.options
        options: mapConfigOptions
      }

  }

  return geocoder

Geocoder.$inject = ['$q', '$ionicPlatform', 'appModalSvc', 'uiGmapGoogleMapApi', 'uiGmapIsReady']






###
@description Controller for geocodeSvc.showResultsAsMap() Modal
  This controller is internal to the geocodeSvc and should not be used outside this module
@param parameters.geoCodeResult Array of geocode results
       parameters.address String, the original search string
###
GeocodeModalCtrl = ($scope, parameters, $q, $timeout, $window, geocodeSvc)->
  gmc = this
  gmc.isBrowser = not ionic.Platform.isWebView()
  gmc.MESSAGE = MODAL_VIEW.MESSAGE
  gmc.map = null    # angular-google-maps
  gmc.gMap = null   # google.maps
  gmc.mapId = null
  gmc.fields = {
    'geocodeResults': null  # [geocodeResult,] array
    'location': null        # [lat,lon] array
    'latlon': null
    'address0': null
    'addressFormatted': null
    'addressDisplay': null
    'error-address0': null
  }
  gmc.state = {
    'marker-moved': false
    'address-changed': false
  }
  gmc.exportResults = ()->
    results = _.extend {}, gmc.fields, _.pick gmc, [
      'marker-moved', 'address-changed'
    ]
    return results
  gmc.isValidMarker = ()->
    return false if gmc['error-address0']
    return true if gmc.map.type == 'oneMarker'
    return false

  init = (params)->
    # calculate mapHeight based on window.innerWidth
    contentH =
      if $window.innerWidth <= MODAL_VIEW.GRID_RESPONSIVE_SM_BREAK  # same as @media(max-width: 680)
      then $window.innerHeight
      else $window.innerHeight * (1 - MODAL_VIEW.MARGIN_TOP_BOTTOM) # margin: 10% auto
    mapH = contentH - MODAL_VIEW.OFFSET_HEIGHT
    mapH = Math.max( MODAL_VIEW.MAP_MIN_HEIGHT , mapH)
    # console.log ["height=",$window.innerHeight , contentH,mapH]
    stop = $scope.$on 'modal.afterShow', (ev)->
      h = setMapHeight(mapH)
      stop?()

    # {geocodeResults:, geoCodeOptions:} = params
    gmc.fields['geocodeResults'] = params.geocodeResults[0...MODAL_VIEW.DISPLAY_LIMIT]
    options = params['geocodeOptions']
    options.useOriginalAddress = !!options.latlng
    return prepareMap(options, gmc.fields['geocodeResults'],null)
    .then (mapConfig)->
      gmc['map'] = gmc['gMap'] = null
      return geocodeSvc.loadAngularGoogleMap(mapConfig, gmc)
    .then (mapConfig)->
      gmc.mapId = 'gMap-' + gmc['gMap'].uiGmap_id
      # $window.gMap = mv.gMap
      gmc.centerMap(gmc)



  setMapHeight = (mapH)->
    styleH = """
      #address-lookup-map .wrap {height: %height%px;}
      #address-lookup-map .angular-google-map-container {height: %height%px;}
    """
    styleH = styleH.replace(/%height%/g, mapH)
    gmc['cssStyle'] = styleH  # <style-scoped>
    return mapH



  prepareMap = (options, geocodeResults, markerModel)->
    return $q.when()
    .then ()->
      address = options if _.isString options
      address ?= options.address
      gmc.fields['address0'] = address       # search address
      gmc.fields['addressDisplay'] = address if options.useOriginalAddress

      if isZeroResult = geocodeResults==GEOCODER.STATUS.ZERO_RESULTS
        geocodeResults = [GEOCODER.getPlaceholderDefault()]

      markerCount = if markerModel? then 1 else geocodeResults.length

      if markerCount == 0
        return null

      # type=oneMarker
      if markerCount == 1
        selectedLocation = markerModel || geocodeResults[0]
        _.extend gmc.fields, parseFieldsFromGeocodeResult( selectedLocation
        , gmc.fields
        , options.useOriginalAddress
        )
        gmc['marker-moved'] = false
        mapOptions = {
          type: if isZeroResult then 'none' else 'oneMarker'
          location: gmc.fields['location']
          marker:
            id: '1'
            latitude: gmc.fields['location'][0]
            longitude: gmc.fields['location'][1]
            label: null
            formatted_address: gmc.fields['addressFormatted']
          draggableMarker: true
          dragendMarker: gmc['on']['oneMarkerDragend']
        }
        return mapConfig = geocodeSvc.getMapConfig mapOptions

      # type=manyMarkers, markerCount > 1
      gmc.fields['latlon'] = null
      gmc.fields['addressFormatted'] = gmc.MESSAGE.MULTIPLE_RESULTS
      gmc.fields['addressDisplay'] = ''
      gmc.fields['error-address0'] = null
      _.each geocodeResults, (o)->
        o['location'] = o.geometry.location
      models = geocodeSvc.mapLocations geocodeResults, {
        id: 'place_id'
        label: 'formatted_address'
      }
      mapOptions = {
        type: 'manyMarkers'
        draggableMarker: true     # BUG? click event doesn't work unless true
        markers: models
        clickMarker: gmc['on']['clickMarkerManyMarkers']
        dragendMarker: (marker, eventName, model)->
          # for type=oneMarker
          mapOptions.clickMarker(marker, eventName, model)
          return
      }
      return mapConfig = geocodeSvc.getMapConfig mapOptions

  parseFieldsFromGeocodeResult = (geocodeResultOrModel, viewData, useOriginalAddress)->
    return {} if _.isEmpty geocodeResultOrModel
    location0 = geocodeSvc.getLatLonFromObj( geocodeResultOrModel )
    resp = {
      'location': location0
      'latlon': location0.join(', ')
      'addressFormatted': geocodeResultOrModel.formatted_address
      'addressDisplay':
        if useOriginalAddress
        then viewData.address0
        else angular.copy geocodeResultOrModel.formatted_address
      'error-address0': null
    }
    # add error message, as necessary
    switch geocodeResultOrModel.status
      when GEOCODER.STATUS.ZERO_RESULTS
        resp['error-address0'] = gmc.MESSAGE.ZERO_RESULTS_ERROR
        resp['latlon'] = null
        resp['addressDisplay'] = null

    # _.extend viewData, resp     # copy attributes to view model
    return resp


  gmc.centerMap = (mapHandle)->
    # mv.gMap.isReady = true
    gMap = mapHandle['gMap']
    mapConfig = mapHandle['map']
    google.maps.event.trigger(gMap, 'resize')

    # console.log 'getCenter', mapConfig.gMap.getCenter().toString()
    return if _.isEmpty mapConfig.center
    center = {
      lat: mapConfig.center.latitude
      lng: mapConfig.center.longitude
    }
    # console.log 'setCenter', center
    gMap.setCenter(center)
    return

  gmc.on = {
    oneMarkerDragend: (marker, eventName, args)->
      # for type=oneMarker
      gmc.fields['location'] = geocodeSvc.getLatLonFromObj marker
      gmc.fields['latlon'] = gmc.fields['location'].join(', ')
      gmc['marker-moved'] = true
      gmc.fields['addressFormatted'] = ''
    clickMarkerManyMarkers: (marker, eventName, model)->
      gmc.fields['geocodeResults'] = _.filter( gmc.fields.geocodeResults
      , {'place_id': model.id}
      )
      return prepareMap(model.formatted_address, null, model)
      .then (mapConfig)->
        console.log mapConfig
        console.log ['click location', gmc['location']]

        gmc['address-changed'] = true
        gmc['marker-moved'] = true
        gmc['map'] = gmc['gMap'] = null
        return geocodeSvc.loadAngularGoogleMap(mapConfig, gmc)
      .then (mapConfig)->
        gmc.mapId = 'gMap-' + gmc['gMap'].uiGmap_id
        gmc.centerMap(gmc)


      return
  }
  # gmc.geocode = geocodeSvc.geocode
  # geocode a new address
  gmc.updateGeocode = (address)->
    gmc.loading = true
    return geocodeSvc.geocode({address:address})
    .then (results)->
      if results == GEOCODER.STATUS.ZERO_RESULTS
        console.log "ZERO_RESULTS FOUND"
        results = [GEOCODER.getPlaceholderDefault()]
      return results
    .then (results)->
      gmc.fields['geocodeResults'] = results
      return prepareMap(address, gmc.fields['geocodeResults'])
    .then (mapConfig)->
      gmc['address-changed'] = false
      gmc['map'] = gmc['gMap'] = null
      return geocodeSvc.loadAngularGoogleMap(mapConfig, gmc)
    .then (mapConfig)->
      gmc.centerMap(gmc)
    , (err)->
      return $q.reject err
    .finally ()->
      $timeout(250).then ()->
        gmc.loading = false


  $scope.$watch 'gmc.fields.addressDisplay', (newV)->
    gmc['address-changed'] = true
    return

  init(parameters)
  return gmc

GeocodeModalCtrl.$inject = ['$scope', 'parameters', '$q', '$timeout', '$window', 'geocodeSvc']





LocationHelpers = (geocodeSvc, $q, $ionicPopup, $ionicLoading, $cordovaGeolocation)->

  _lastLocation = {}
  _lastKnownLonLat = null

  ERROR_CODES = { # err.code
    1: 'PERMISSION_DENIED'
    2: 'POSITION_UNAVAILABLE'
    3: 'TIMEOUT'
  }
  self = {
    hasGeolocation: null  # set in init
    errorLookup:
      'PERMISSION_DENIED':
        "Permission Denied. Please check your privacy settings and try again."
      'POSITION_UNAVAILABLE':
        "Your current position unavailable."
      'TIMEOUT':
        "Sorry, we didn't get an answer. Please try later."
    messages:
      'CHECKING_LOCATION': "Checking current location"

    setErrorMsg: (keyOrObj, value)->
      return angular.extend self.errorLookup, keyOrObj if _.isObject(keyOrObj)
      key = ERROR_CODES[keyOrObj] if _.isNumber keyOrObj
      self.errorLookup[key] = value
      return self.errorLookup

    ###
    # @description preferred format for storing location in mongoDB
    # @params lonlat array [lon, lat], or object {lat: lon:}
    #         isLatLon boolean, reverse array if true, [lat,lon] deprecate
    ###
    asGeoJsonPoint: (lonlat, isLatLon=false)->
      lonlat = lonlat.reverse?() if isLatLon
      lonlat = [lonlat['lon'], lonlat['lat']] if lonlat['lat']?
      lonlat ?= []
      return {
        type: "Point"
        coordinates: lonlat # [lon,lat]
      }


    ###
    @params location, object, resolve from geocodeSvc.geocode( result.latlon.join(','))
    ###
    lastKnownLocation: (location)->
      return _lastLocation if typeof location == 'undefined'
      return _lastLocation = {} if _.isEmpty location
      _lastLocation = angular.copy location
      if _lastLocation.latlon && !_lastLocation.lonlat
        console.warn "WARN: lastKnownLocation() deprecate use of latlon"
        _lastLocation.lonlat = angular.copy(_lastLocation.latlon).reverse()
      return _lastLocation

    # save location if User is not registered
    lastKnownLonLat: (lonlat)->
      return _lastKnownLonLat if typeof lonlat == 'undefined'
      return _lastKnownLonLat = null if _.isEmpty lonlat
      return _lastKnownLonLat = angular.copy lonlat

    asLonLat: (geojsonPoint, isLatLon=false)->
      check = geojsonPoint?.type == 'Point'
      return if not check
      lonlat = angular.copy geojsonPoint['coordinates']
      lonlat.reverse() if isLatLon
      return lonlat

    ###
    @description geocode Address and save to self.lastKnownLocation()
    @return promise
      resolve: result object {address:String, latlon:[], isCurrentLocation: boolean}
      reject: err, err.humanize is the humanized error message
    ###
    getLocationFromAddress:(address)->
      return self.geocodeAddress({address: address}, 'force')
      .then (result)->
        self.lastKnownLocation(result)
        self.lastKnownLonLat(self.lastKnownLocation().lonlat)
        return result

    ###
    @description get [lat,lon] from current Position, and geocode=true shows location
      in modal-view to allow manual verify of location & address string before
      returning result
    @params confirm boolean, show position on map (modal) to confirm
    @return promise
      resolve: result object {address:String, latlon:[], isCurrentLocation: boolean}
      reject: err, err.humanize is the humanized error message
    ###
    getCurrentPosition: (loading=false, confirm=false)->
      return $q.when()
      .then ()->
        if loading
          $ionicLoading.show {
            template: [
              self.messages['CHECKING_LOCATION']
              "<br /><br />"
              "<div><ion-spinner></ion-spinner></div>"
            ].join('')
            hideOnStateChange: true
            duration: 5000
          }
      .then ()->
        if ionic.Platform.isWebView()
          console.info ['WebView: getCurrentPosition() with plugin $cordovaGeolocation']
          options = {timeout: 10000, enableHighAccuracy: false}
          return $cordovaGeolocation.getCurrentPosition( options )
        else
          dfd = $q.defer()
          console.info ['Browser: getCurrentPosition() with navigator.geolocation']
          navigator.geolocation.getCurrentPosition(
            (result)-> return dfd.resolve(result)
          , (err)-> return dfd.reject(err)
          )
          return dfd.promise.finally ()->
            $ionicLoading.hide()
      .then (result)->
        gMapPoint = _.chain result.coords
          .pick ['latitude','longitude']
          # .each (v,k,o)-> return o[k]=geocodeSvc.mathRound6(v)
          .value()
        retval = {}
        retval.latlon = [gMapPoint.latitude, gMapPoint.longitude]
        retval.isCurrentLocation = true
        retval.address = [
          'lat:', gMapPoint.latitude
          'lon:', gMapPoint.longitude
        ].join(' ')
        console.log ['with location',retval]
        return retval
      .then (result)->
        return geocodeSvc.geocode( {location: result.latlon.join(',')})
        .then (results)->
          if results == GEOCODER.STATUS.ZERO_RESULTS
            console.warn "ZERO_RESULTS FOUND"
            throw new Error (MODAL_VIEW.MESSAGE.ZERO_RESULTS_ERROR)
          firstResult = results[0]
          location = firstResult['geometry']['location']
          retval = {
            latlon: [location.lat() , location.lng()]
            address: firstResult.formatted_address
            geoCodeResult: firstResult
            isCurrentLocation: result.isCurrentLocation
          }
          return retval
        , (err)->
          return result # simple [lat,lon]
      .catch (err)->
        return self.handleCurrentLocationErr(err)
      .then (result)->
        # now verify current location
        if !confirm
          result.latlon = _.map result.latlon, (v)-> return geocodeSvc.mathRound6(v)
          return self.showConfirm result
        return self.geocodeAddress(result, 'force')
      .then (result)->
        self.lastKnownLocation(result)
        self.lastKnownLonLat(self.lastKnownLocation().lonlat)
        return result


    ###
    @description geocode an address string or [lat,lon] and show in modal-view
      allow user to verify location before returning result
    @params options object
      options.address, address string
      options.geojson, geojson point
      options.latlon, array [lat,lon], usually from current location
      options.isCurrentLocation boolean, set true to update address string but
          NOT latlon
    @return promise
      resolve: result object {address:String, latlon:[], isCurrentLocation: boolean}
        add geoCodeResult property
      reject: err, err.humanize is the humanized error message
    ###
    geocodeAddress: (options, force)->
      # if options.geojson
      #   options.latlon = self.asLonLat(options.geojson, 'latlon')
      #   location = options.latlon.join(',') if force
      # if options.latlon && options.isCurrentLocation && force
      #   location = options.latlon.join(',')
      # if options.latlon && !force
      #   console.log ['locationClick()', _.pick( options, ['latlon','address'] ) ]
      #   return $q.when options
      # location ?= options.address
      # return $q.reject("ERROR: Expecting Address or Location.") if !location
      #  this launches modal
      find = {
        location: options.geojson || options.latlon?.join(',') || null
        address: options.address || null
      }
      if options.latlon && !force
        console.error [
          'what do we do here? locationClick()'
          _.pick( options, ['latlon','address'] )
        ]
        return $q.when options
      if find.location == null && find.address == null
        return $q.reject("ERROR: Expecting Address or Location.")

      return geocodeSvc.getLatLon( find )
      .then (result)->
        return 'CANCELED' if !result
        console.log ['locationClick()', result]
        retval = {
          geojson: result.geojson
          lonlat: result.lonlat
          geoCodeResult: result.geoCodeResult
        }
        retval.latlon = result?.location # deprecate
        retval.address = result?.address
        retval.isCurrentLocation = true if options.isCurrentLocation
        return retval

    handleCurrentLocationErr: (err)->
      err.humanize = self.errorLookup[ ERROR_CODES[err.code] ]
      console.warn ['Err location', err]
      return self.showErrorPrompt err

    showErrorPrompt: (err)->
      popup = $ionicPopup.prompt {
        title: 'Location Unavailable'
        subTitle: err.humanize
        inputPlaceholder: 'Please enter a location'
        maxLength: 64
      }
      return popup.then (address)->
        $q.reject(err) if !address
        return self.geocodeAddress({address:address}, 'force')


    showConfirm: (result)->
      popup = $ionicPopup.confirm {
        title: 'Your Current Location'
        template: result.address
        cancelText: 'See Map'
      }
      return popup.then (ok)->
        return result if ok
        return self.geocodeAddress(result, 'force')
        .then (confirmResult)->
          return confirmResult if confirmResult?.lonlat
          return result
  }

  ionic.Platform.ready ()->
    self.hasGeolocation = navigator.geolocation
    return

  return self

LocationHelpers.$inject = ['geocodeSvc', '$q', '$ionicPopup'
  '$ionicLoading', '$cordovaGeolocation'
]

angular.module 'blocks.components'
  .constant 'API_KEY', null
  .config geocodeSvcConfig
  .factory 'geocodeSvc', Geocoder
  .factory 'locationHelpers', LocationHelpers
  .controller 'GeocodeModalCtrl', GeocodeModalCtrl
