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
  TEMPLATE: 'blocks/components/address-map.template.html'
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

Geocoder = ($q, $ionicPlatform, appModalSvc, uiGmapGoogleMapApi)->

  ## private methods & attributes
  init = (maps)->
    GEOCODER.STATUS = maps.GeocoderStatus
    GEOCODER.instance = new maps.Geocoder()
    # console.log GEOCODER
    return

  mathRound6 = (v)->
    return Math.round( v * 1000000 )/1000000 if _.isNumber v
    return v


  # wait for google JS libs to load
  uiGmapGoogleMapApi.then (maps)->
    console.log "uiGmapGoogleMapApi promise resolved"
    init(maps)
    return


  ## factory object
  self = {

    ###
    @description an Entry Point for this service, returns an object with a geocode location
    @param address, accepts an address string, or
          [lat,lon] as a string of 2 comma-separated floats
    @resolve object { address: location: place_id:(optional) } or null if canceled
    @reject ['ERROR', err]
    ###
    getLatLon: (address)->
      self.displayGeocode(address)
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
    @description launches addressMap modal to allow user to verifiy location of address
    @param address String
    @return object, one geocode result or CANCELED, ZERO_RESULTS
    ###
    displayGeocode: (address)->
      return self.geocode(address)
      .then (results)->
        # console.log ["Geocode results, count=", results.length] if _.isArray results
        if results == GEOCODER.STATUS.ZERO_RESULTS
          results = [GEOCODER.getPlaceholderDefault()]

        return self.showResultsAsMap(address, results)
        .then (result)->
          console.log ["displayGeocode", result]
          # convert location to  geojsonPoint
          return result

      .catch (err)->
        console.warn err
        return

    # called by self.displayGeocode() and VerifyLookupCtrl.updateGeocode()
    geocode: (address)->
      return $q.reject("Geocoder JS lib not ready") if !GEOCODER.instance?

      # check if address is a latlon
      isLatLon = /^(\d+\.*\d*),(\d*\.*\d*)$/
      if latlon = address.match(isLatLon)
        # geocode a location
        option = location:
          lat: parseFloat(latlon[1])
          lng: parseFloat(latlon[2])
      else
        # geocode an address
        option = { "address": address }

      dfd = $q.defer()
      GEOCODER.instance.geocode( option, (result, status)->
        switch status
          when 'OK'
            if option.location
              # filter out approximate results
              result = _.filter result, (o)->
                return true if o.geometry.location_type != 'APPROXIMATE'
            return dfd.resolve result
          when GEOCODER.STATUS.ZERO_RESULTS
            return dfd.resolve GEOCODER.STATUS.ZERO_RESULTS
          else
            console.err ['geocodeSvc.geocode()', status]
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
    # @param address String, the geocode search string
    # @param geoCodeResults array of results, e.g. geocode().then (results)->
    ###
    showResultsAsMap: (address, geoCodeResults)->
      return appModalSvc.show(
        MODAL_VIEW.TEMPLATE
        'VerifyLookupCtrl as vm'
        {
          address: address
          geoCodeResults: geoCodeResults
        })
      .then (modalResult)->
        # console.log ["showResultsAsMap:", geoCodeResult]
        return modalResult if _.isString modalResult || !modalResult

        mm = modalResult
        # TODO: need to choose 1 result from geoCodeResults, move to head
        geoCodeResult = mm['geoCodeResults'][0]
        geoCodeResult.override = {}
        if mm['marker-moved']
          geoCodeResult.override['location'] = mm.location
        if mm['address-changed']
          geoCodeResult.override['address']= mm.addressDisplay

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

  return self

Geocoder.$inject = ['$q', '$ionicPlatform', 'appModalSvc', 'uiGmapGoogleMapApi']






###
@description Controller for geocodeSvc.showResultsAsMap() Modal
  This controller is internal to the geocodeSvc and should not be used outside this module
@param parameters.geoCodeResult Array of geocode results
       parameters.address String, the original search string
###
VerifyLookupCtrl = ($scope, parameters, $q, $timeout, $window, geocodeSvc)->
  vm = this
  vm.isBrowser = not ionic.Platform.isWebView()
  vm.MESSAGE = MODAL_VIEW.MESSAGE
  vm.isValidMarker = ()->
    return false if vm['error-address0']
    return true if vm.map.type == 'oneMarker'
    return false

  init = (parameters)->
    vm['geoCodeResults'] = parameters.geoCodeResults[0...MODAL_VIEW.DISPLAY_LIMIT]
    vm['map'] = setupMap(parameters.address, vm['geoCodeResults'])
    stop = $scope.$on 'modal.afterShow', (ev)->
      h = setMapHeight()
      stop?()
      return
    return


  setMapHeight = ()->
    # calculate mapHeight

    contentH =
      if $window.innerWidth <= MODAL_VIEW.GRID_RESPONSIVE_SM_BREAK  # same as @media(max-width: 680)
      then $window.innerHeight
      else $window.innerHeight * (1 - MODAL_VIEW.MARGIN_TOP_BOTTOM) # margin: 10% auto

    mapH = contentH - MODAL_VIEW.OFFSET_HEIGHT
    mapH = Math.max( MODAL_VIEW.MAP_MIN_HEIGHT , mapH)
    # console.log ["height=",$window.innerHeight , contentH,mapH]

    # TODO: use directive:style-scoped
    styleH = """
      #address-lookup-map .wrap {height: %height%px;}
      #address-lookup-map .angular-google-map-container {height: %height%px;}
    """
    styleH = styleH.replace(/%height%/g, mapH)
    angular.element(document.getElementById('address-lookup-style')).append(styleH)
    return mapH



  parseLocation = (geoCodeResultOrModel, target)->
    return {} if _.isEmpty geoCodeResultOrModel
    location0 = geocodeSvc.getLatLonFromObj( geoCodeResultOrModel )
    resp = {
      'location': location0
      'latlon': location0.join(', ')
      'addressFormatted': geoCodeResultOrModel.formatted_address
      'addressDisplay': angular.copy geoCodeResultOrModel.formatted_address
      'error-address0': null
    }
    # add error message, as necessary
    switch geoCodeResultOrModel.status
      when GEOCODER.STATUS.ZERO_RESULTS
        resp['error-address0'] = vm.MESSAGE.ZERO_RESULTS_ERROR
        resp['latlon'] = null
        resp['addressDisplay'] = null

    _.extend target, resp     # copy attributes to view model
    return resp

  setupMap = (address, geoCodeResults, model)->

    if isZeroResult = geoCodeResults==GEOCODER.STATUS.ZERO_RESULTS
      geoCodeResults = [GEOCODER.getPlaceholderDefault()]

    vm['address0'] = address       # search address
    markerCount = if model? then 1 else geoCodeResults.length

    if markerCount == 0
      return

    if markerCount == 1
      selectedLocation = model || vm['geoCodeResults'][0]
      retval = parseLocation( selectedLocation, vm )
      vm['marker-moved'] = false
      mapOptions = {
        type: if isZeroResult then 'none' else 'oneMarker'
        location: vm['location']
        marker:
          id: '1'
          latitude: vm['location'][0]
          longitude: vm['location'][1]
          label: null
          formatted_address: vm['addressFormatted']
        draggableMarker: true
        dragendMarker: (marker, eventName, args)->
          # for type=oneMarker
          vm['location'] = geocodeSvc.getLatLonFromObj marker
          vm['latlon'] = vm['location'].join(', ')
          vm['marker-moved'] = true
          vm['addressFormatted'] = ''
          return
      }
      mapConfig = geocodeSvc.getMapConfig mapOptions
      return mapConfig

    # markerCount > 1
    vm['latlon'] = null
    vm['addressFormatted'] = vm.MESSAGE.MULTIPLE_RESULTS
    vm['addressDisplay'] = ''
    vm['error-address0'] = null
    mapOptions = {
      type: 'manyMarkers'
      draggableMarker: true     # BUG? click event doesn't work unless true
      markers: geoCodeResults
      clickMarker: (marker, eventName, model)->
        index = model.id
        vm['geoCodeResults'] = [ vm['geoCodeResults'][index] ]
        newMapConfig = setupMap(model.formatted_address, null, model)
        vm['address-changed'] = true
        vm['marker-moved'] = true
        vm['map'] = newMapConfig
        # console.log newMapConfig
        # console.log ['click location', vm['location']]
        return
      dragendMarker: (marker, eventName, model)->
        # for type=oneMarker
        mapOptions.clickMarker(marker, eventName, model)
        return
    }
    return geocodeSvc.getMapConfig mapOptions



  # vm.geocode = geocodeSvc.geocode
  vm.updateGeocode = (address)->
    vm.loading = true
    return geocodeSvc.geocode(address)
    .then (results)->
      if results == GEOCODER.STATUS.ZERO_RESULTS
        console.log "ZERO_RESULTS FOUND"
        results = [GEOCODER.getPlaceholderDefault()]
      return results
    .then (results)->
      vm['geoCodeResults'] = results
      newMapConfig = setupMap(address, vm['geoCodeResults'])

      vm['address-changed'] = false  # check again on save event if true
      vm['map'] = newMapConfig
      return
    , (err)->
      return $q.reject err
    .finally ()->
      $timeout ()->
        vm.loading = false
      ,250

  $scope.$watch 'vm.addressDisplay', (newV)->
    vm['address-changed'] = true
    return

  init(parameters)
  return vm

VerifyLookupCtrl.$inject = ['$scope', 'parameters', '$q', '$timeout', '$window', 'geocodeSvc']






# deprecate: use <auto-input>
ClearFieldDirective = ($compile, $timeout)->
  directive = {
    restrict: 'A',
    require: 'ngModel'
    scope: {}
    link: (scope, element, attrs, ngModel) ->
      inputTypes = /text|search|tel|url|email|password/i
      if element[0].nodeName != 'INPUT'
        throw new Error "clearField is limited to input elements"
      if not inputTypes.test(attrs.type)
        throw new Error "Invalid input type for clearField" + attrs.type


      btnTemplate = """
      <i ng-show="enabled" ng-click="clear()" class="icon ion-close-circled pull-right">&nbsp;</i>
      """
      template = $compile( btnTemplate )(scope)
      element.after(template)

      scope.clear = ()->
        ngModel.$setViewValue(null)
        ngModel.$render()
        scope.enabled = false
        $timeout ()->
          return element[0].focus()
        ,150

      # element.bind 'input', (e)->
      #   scope.enabled = !ngModel.$isEmpty element.val()
      #   return

      element.bind 'focus', (e)->
        scope.enabled = !ngModel.$isEmpty element.val()
        scope.$apply()
        return

      return

  }
  return directive


ClearFieldDirective.$inject = ['$compile', '$timeout']


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
        return geocodeSvc.geocode( result.latlon.join(','))
        .then (geoCodeResults)->
          firstResult = geoCodeResults[0]
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
      options.latlon, array [lat,lon], usually from current location
      options.isCurrentLocation boolean, set true to update address string but
          NOT latlon
    @return promise
      resolve: result object {address:String, latlon:[], isCurrentLocation: boolean}
        add geoCodeResult property
      reject: err, err.humanize is the humanized error message
    ###
    geocodeAddress: (options, force)->
      if options.geojson
        options.latlon = self.asLonLat(options.geojson, 'latlon')
        location = options.latlon.join(',') if force
      if options.latlon && options.isCurrentLocation && force
        location = options.latlon.join(',')
      if options.latlon && !force
        console.log ['locationClick()', _.pick( options, ['latlon','address'] ) ]
        return $q.when options
      location ?= options.address
      return $q.reject("ERROR: Expecting Address or Location.") if !location
      #  this launches modal
      return geocodeSvc.getLatLon( location )
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
  # .directive 'clearField', ClearFieldDirective
  .controller 'VerifyLookupCtrl', VerifyLookupCtrl
