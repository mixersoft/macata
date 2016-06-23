# new-tile.directive.coffee
'use strict'

# directive:newTile
#   - create a new tile from a url parsing open-graph meta tags
#   - use appModalSvc modals for detail view
#   - allow manual editing of open-graph delegate-handle
#   - usage: <new-tile></new-tile>
#     example usage in header:
###
    div.bar.has-header.bar-inset-wrap.bar-subheader
      div.item-input-inset.no-padding
        div.item-input-wrapper
          i.icon.ion-link.larger
          new-tile(
            style="width:100%;"
            return-close="true"
            is-fetching="$show.spinner.newTile"
            on-complete="vm.on.submitNewTile(result)"
          )
        button.button.button-dark.button-clear
          i.icon.ion-ios-arrow-forward(
            ng-show="!$show.spinner.newTile"
          )
          ion-spinner.spinner-white(
            icon="ios-small"
            ng-show="$show.spinner.newTile"
          )
###
#
#
#


MARKUP = {
  INPUT: """
  <input auto-input ng-model="dm.field" style="width:100%;" type="text" placeholder="Enter Title or Url"/>
  """
  WRAP: """
  <div class="auto-input-wrapper" style="width:100%;"></div>
  """
  MODAL:
    newTileUrl: "blocks/components/new-tile.template.html"
}


OpenGraph = ($q, $http )->
  OG_API_ENDPOINT ={
    active: null
    local: __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL + 'methods/' + 'get-open-graph'
    remote: 'http://app.snaphappi.com:3333/methods/' + 'get-open-graph'
  }

  OG_API_ENDPOINT.active =
    if window.location.hostname == "localhost"
    then OG_API_ENDPOINT.local
    else OG_API_ENDPOINT.remote

  self = {
    matchUrl : (value)->
      # match a url inside a string
      # reMatchUrl = /(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?$/i
      # coffeelint: disable=max_line_length
      reMatchUrl = /(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?/i
      # coffeelint: enable=max_line_length
      found = value.match(reMatchUrl)
      return found?[0]
    get : (url)->
      return $http.get(OG_API_ENDPOINT.active, {
        params: {url: url}
      })
      .then (resp)->
        return $q.reject(resp) if resp.statusText != 'OK'
        return $q.reject('NOT FOUND') if _.isEmpty resp.data
        og = resp.data
        return og
      , (err)->
        if OG_API_ENDPOINT.active != OG_API_ENDPOINT.remote
          OG_API_ENDPOINT.active = OG_API_ENDPOINT.remote
          console.log(['open-graph.get',err])
          return self.get(url)

    normalize : (og)->
      primaryFields = ['og:url', 'og:title', 'og:description', 'og:image', 'og:site_name']
      normalized = {}
      _.each _.pick( og, primaryFields ), (v,k)->
        normalized[ k.replace('og:','') ] = v
        return
      return og if _.isEmpty normalized

      normalized['extras'] = _.omit og, primaryFields
      normalized['extras'] = self.sanitizeKeys normalized['extras']
      return normalized

    sanitizeKeys: (o)->
      # Mongo keys must not contain '.'
      _.reduce o, (result, v,k)->
        if ~k.indexOf('.')
          k = k.replace(/\./g, '_')
        result[k] = v
        return result
      ,{}
  }
  return self
OpenGraph.$inject = ['$q', '$http']

TileHelpers = (appModalSvc, $q)->
  self = {
    modal_showTileEditor : (data)->
      options = {modalCallback: null}
      return appModalSvc.show(
        MARKUP.MODAL.newTileUrl
        , 'TileEditorCtrl as mm'
        , {
          data: data
        }
        , options )
      .then (result)->
        # wait for closeModal()
        result ?= 'CANCELED'
        console.log ['modal_showTileEditor()', result]
        if result == 'CANCELED'
          return $q.reject('CANCELED')
        return $q.reject(result) if result?['isError']

        return result
    isTileComplete: (data)->
      return isComplete = false if _.isEmpty data
      isComplete = _.reduce ['url', 'title', 'description', 'image'], (result, key)->
        return result = result && data[key]
      , true
      return isComplete

  }
  return self
TileHelpers.$inject = ['appModalSvc', '$q']

###
# @description TileEditorCtrl used by TileHelpers.modal_showTileEditor modal
###
TileEditorCtrl = (
  scope, $q, locationHelpers, $timeout, $ionicScrollDelegate
  deviceReady, $cordovaGeolocation, $cordovaCamera
)->
  this.id = 'TileEditorCtrl'
  mm = this

  mm.settings = {
    show:
      imageAttach: false
  }

  mm.geo = {
    setting:
      hasGeolocation: null
      show:
        spinner:
          location: false
        location: false
    errorMsg:
      location: null
    init: ()->
      mm.geo.setting.hasGeolocation = navigator.geolocation?
      mm.geo.setting.show.location = !!mm.data.address
      return
    handleGeolocationErr : (err)->
      ERROR_CODES = {
        1: 'PERMISSION_DENIED'
        2: 'POSITION_UNAVAILABLE'
        3: 'TIMEOUT'
      }
      switch ERROR_CODES[err.code]
        when 'PERMISSION_DENIED'
          mm.geo.errorMsg.location = """
          Permission Denied. Please check your privacy settings and try again.
          """
        when 'POSITION_UNAVAILABLE'
          mm.geo.errorMsg.location = "Warning: Position unavailable."
        else
          console.warn ['Err location', err]
      return
    geocodeAddress : (force)->
      if mm.data.displayLatLon && mm.data.isCurrentLocation && force
        location = mm.data.displayLatLon.join(',')
      if mm.data.displayLatLon && !force
        console.log ['locationClick()', _.pick( mm.data, ['latlon','address'] ) ]
        return $q.when mm.data
      location ?= mm.data.address
      return if !location
      return locationHelpers.getLatLon( location )
      .then (result)->
        console.log ['locationClick()', result]
        mm.data.displayLatLon = result?.location
        mm.data.address = result?.address
        return mm.data
  }

  mm.data = {
    url: null
    title: null
    description: null
    site_name: null
    image: null
    extras: null
    # use messageComposer Post format
    address: null
    location: {}
    displayLatLon: null
  }

  CAMERA_CONSTANTS = {  # Camera
    "DestinationType":
      "DATA_URL": 0,
      "FILE_URI": 1,
      "NATIVE_URI": 2
    "EncodingType":
      "JPEG": 0,
      "PNG": 1
    "MediaType":
      "PICTURE": 0,
      "VIDEO": 1,
      "ALLMEDIA": 2
    "PictureSourceType":
      "PHOTOLIBRARY": 0,
      "CAMERA": 1,
      "SAVEDPHOTOALBUM": 2
    "PopoverArrowDirection":
      "ARROW_UP": 1,
      "ARROW_DOWN": 2,
      "ARROW_LEFT": 4,
      "ARROW_RIGHT": 8,
      "ARROW_ANY": 15
    "Direction":
      "BACK": 0,
      "FRONT": 1
  }


  mm.on = {
    'toggleShow': (show, key, selector)->
      show[key] = !show[key]
      if show[key] && selector
        # scroll into by pixels
        scroll = document.querySelector('#new-tile-modal-view ion-content')
        el = scroll.querySelector(selector)
        scrollHandle = scroll?.getAttribute('delegate-handle')
        $timeout().then ()->
          el.focus()
          return $timeout(50)
        .then ()->
          _ionScroll = $ionicScrollDelegate.$getByHandle(scrollHandle)
          _ionScroll.scrollBy(0, el.clientHeight, true)

      return show[key]

    'imageAttachClick': (ev)->
      activate = mm.on.toggleShow(mm.settings.show
      , 'imageAttach'
      , 'image-attach-helper input.hero-pic-url')
      # then click
      if activate
        $timeout(100).then ()->
          selector = '#new-tile-modal-view image-attach-helper input[name=image-select]'
          el = document.querySelector selector
          angular.element(el).triggerHandler('click')




    # TODO: refactor, create directive:<item-input-location>
    locationClick: (ev, value )->
      mm.geo.errorMsg.location = null
      if value == 'CURRENT'
        mm.geo.setting.show.spinner.location = true
        promise = locationHelpers.getCurrentPosition()
        .finally ()->
          mm.geo.setting.show.spinner.location = false
      else
        if !value
          mm.geo.setting.show.location = true
          target = ev.currentTarget
          selector = '#new-tile-modal-view .location'
          $timeout ()->
            document.querySelector(selector).scrollIntoView()
          return $q.reject('ERROR: Expecting address')
        # note: geocodeSvc.geocode() will parse "lat,lon" values
        if mm.data.displayLatLon && mm.data.isCurrentLocation
          return $q.when(value) # keep current latlon, just updating address field

        if mm.data.displayLatLon
          # repeat: geocode current address
          promise = locationHelpers.geocodeAddress({address:value}, 'force')
        else
          promise = locationHelpers.geocodeAddress({address:value})

      return promise
      .then (result)->
        mm.data.displayLatLon = result.latlon
        mm.data.address = result.address
        mm.data.location = result
      , (err)->
        mm.geo.errorMsg.location = err.humanize

      return

    updateImage: (data)->
      mm.data.image = data.src

    done: (ev)->
      # post to $meteor from scope.onComplete
      delete mm.data['displayLatLon']
      mm.closeModal mm.data
  }

  ionic.Platform.ready ->
    mm.geo.init()
    return

  return
TileEditorCtrl.$inject = [
  '$scope', '$q', 'locationHelpers', '$timeout', '$ionicScrollDelegate'
  'deviceReady', '$cordovaGeolocation', '$cordovaCamera'
]



NewTileDirective = ($q, $compile, $timeout, openGraphSvc, tileHelpers)->
  directive = {
    restrict: 'E'
    # controllerAs: 'dm'
    # controller: 'TileEditorCtrl'
    # require: ['ngModel', 'newTile']
    # require: ['newTile'] # same as directive name
    scope: {
      'placeholderText': '@'
      'returnClose': '='
      'isFetching': '='
      'onReturn': '&'
      'onFocus': '&'
      'onBlur': '&'
      'onKeyDown': '&'
      'onComplete': '&'
      'cancelBlur': '='
    }
    link:
      pre: (scope, element, attrs, controllers) ->

        _reset = ()->
          dm.field = null
          dm.data = {}

        _getOpenGraph = (url)->
          scope.isFetching = true
          return openGraphSvc.get(url)
          .then (og)->

            data = openGraphSvc.normalize(og)
            angular.extend dm.data, data
            # TODO?: merge with dm.data.field?
            dm.field = null
            return data
          , (err)->
            console.warn ['openGraphSvc.get()', err]
            return $q.reject err
          .finally ()->
            scope.isFetching = false


        _showTileEditorAsModal = (data, force)->
          return $q.when()
          .then ()->
            return data if tileHelpers.isTileComplete(data) && !force
            return tileHelpers.modal_showTileEditor(data)
          .then (result)->
            # format like messageComposer
            result.location = _.omit result.location, 'latlon'
            scope.onComplete({result: result}) if attrs['onComplete']
          , (err)->
            scope.onComplete({result: null}) if attrs['onComplete']
          .finally _reset

        _getValidatedTile = (data)->
          return _getOpenGraph( data.url )
          .catch (err)->
            if err == 'NOT FOUND'
              # show "No preview" message
              return data
            return $q.reject(err)
          .then (data)->
            return _showTileEditorAsModal(data)



        return if element.children().scope()
        # already compiled/linked

        # initialize directive model (dm)
        scope.dm = dm = {
          field : null
          data :
            url: null
            title: null
        }

        dm.onBlur = (ev, value)->
          $timeout(0)
          .then ()->
            return if !value
            return if scope.cancelBlur # why???

            # console.info ['new-tile.blur', dm.field]
            if attrs['onBlur']
              return scope.onBlur({$event:ev, value:value})

            matched = openGraphSvc.matchUrl(dm.field)
            if matched
              if dm.data.url != matched
                dm.data.url = matched
                console.log "blur: "+dm.data.url
                return _getValidatedTile( dm.data )
            else
              dm.data.title = dm.field
              return _showTileEditorAsModal(dm.data, 'force')

        # $field.bind 'keydown', (e)->
        dm.onKeydown = (ev, value)->
          $timeout(0)
          .then ()->
            if attrs['onKeydown']
              return scope.onKeydown({$event:ev, value:value})

            if ev.which == 32 # space
              matched = openGraphSvc.matchUrl(dm.field)
              if matched
                dm.data.url = matched
                # console.log "keydown: "+dm.data.url
                _getValidatedTile( dm.data )

            # console.info ['new-tile.keydown', dm.field]

            return

        # input element, can be either url or title
        $field = angular.element(MARKUP.INPUT)
        $field.attr('on-keydown', "dm.onKeydown($event, value)")
        $field.attr('on-blur', "dm.onBlur($event, value)")
        if scope.returnClose
          $field.attr('return-close', "true")
        if scope.placeholderText
          $field.attr('placeholder', scope.placeholderText)

        $wrap = angular.element(MARKUP.WRAP)
        $wrap.prepend($field)
        $wrap = $compile( $wrap )(scope)

        element.append($wrap)
        return


  }
  return directive


NewTileDirective.$inject = ['$q', '$compile', '$timeout', 'openGraphSvc', 'tileHelpers']


angular.module('blocks.components')
  .factory 'openGraphSvc', OpenGraph
  .factory 'tileHelpers', TileHelpers
  .controller 'TileEditorCtrl', TileEditorCtrl
  .directive 'newTile', NewTileDirective
