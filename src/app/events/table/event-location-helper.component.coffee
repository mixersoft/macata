'use strict'

moments2Dates = (o)->
  return _.each o, (v,k)->
    o[k] = v.toDate() if v?.toDate
    return

EventLocationHelper = {
  bindings:
    location: "<" # {isPublic:, name:, address:, neighborhood:, geojson:}
    validateOnBlur: "<"
    onUpdate: "&"
  templateUrl: "events/table/event-location-helper.template.html"
  # require:
  controller: [
    '$scope', '$q', '$timeout', 'locationHelpers'
    'uiGmapGoogleMapApi', 'geocodeSvc'
    ($scope, $q, $timeout, locationHelpers
    uiGmapGoogleMapApi, geocodeSvc
    )->
      # $ctrl = this
      this.data = {
      }
      this.showHelper = false
      this.addressChanged = false


      this.$onInit = ()=>
        now = moment()
        this.data = _.pick( this.location, [
          'isPublic', 'name', 'address', 'neighborhood', 'geojson'
          ])
        return


      this.$onChanges = (changes)=>
        console.log ["onChanges", changes]

      this.geocodeAddress = ()=>
        self = this
        return $q.when()
        .then ()->
          if self.addressChanged == true
            #  geocode address string or latlon
            options = _.pick self.data, ['address']

            return locationHelpers.geocodeAddress(options)
          else
            # just show on map
            options = _.pick self.data, ['geojson', 'address']
            return locationHelpers.geocodeAddress(options)
          if self.data.name
            options = _.pick( self.data, ['name', 'address'])
            return locationHelpers.searchPOI( options )
            .then (result)->
              console.info ["searchPOI", result]
              return result
        .then (result)->
          return 'CANCELED' if result == 'CANCELED'
          self.data.address = result.address
          self.data.address ?= [result.lonlat[1],result.lonlat[0] ].join(', ')
          self.data.geojson = result.geojson
          self.updateLocation(self.data)
          self.addressChanged = false
          self.showHelper = false
        , (err)->
          console.warn ['geocodeAddress', err]
        .finally (result)->
          self.addressChanged = false
          done = !!self.data.geojson
          # if not done
          #   self.data.address = null


      this.updateLocation = (data)=>
        data ?= this.data
        this.onUpdate({data:data})
        this.renderMap(data)
        return

      this.renderMap = (data)=>
        self = this
        this.prepareMap(data)
        .then (mapConfig)->
          self['map'] = self['gMap'] = null
          geocodeSvc.loadAngularGoogleMap(mapConfig, self)
        .then (mapConfig)->
          return $q.reject("LOCATION_EMPTY") if _.isEmpty mapConfig


      this.prepareMap = (data, options)=>
        data ?= this.data
        #  see: eventUtils.setVisibleLocation()
        options = {
          type: 'oneMarker'
          control: {}
        }

        return $q.when() if !data.geojson
        return uiGmapGoogleMapApi
        .then ()->
          keymap = {
            id: '_id'
            location: 'geojson'
            label: 'title'
          }
          # markerCount==1
          mapOptions = {
            type: options.type
            marker: geocodeSvc.mapLocations(data, keymap)
            # draggableMap: true  # set in activate()
            draggableMarker: false
            dragendMarker: (marker, eventName, args)->
              return
          }
          mapOptions = _.extend mapOptions, {
            # 'control' : {}
            'mapReady' : (map, eventName)->
              $scope.$broadcast 'map-ready', map
          }, options
          mapConfig = geocodeSvc.getMapConfig mapOptions
          # mapConfig.zoom = 11
          return mapConfig

      this.on = {}
      this.on['showHelper'] = (ev)=>
        this.showHelper = true
        parent = ionic.DomUtil.getParentWithClass ev.currentTarget, 'event-location-helper'
        $timeout().then ()->
          nextEl = parent.querySelector('.location-input-helper input')
          nextEl.focus()
      this.on['click'] = (ev, force)=>
        this.geocodeAddress()
      this.on['focus'] = (ev)=>
        # focusEvent for button.Show on Map
        if this.addressChanged && ev.target.classList.contains('show-on-map')
          this.geocodeAddress()
        # focusEvent for input[name=address]
        this.on.showHelper(ev) if _.isEmpty this.data.geojson
      this.on['blur'] = (ev)=>
        return if !ev.relatedTarget
        stillHasFocus = ionic.DomUtil.getParentWithClass( ev.relatedTarget, 'event-location-helper')
        if !stillHasFocus && this.validateOnBlur
            this.geocodeAddress() if !this.data.geojson
      return this

  ]
}


angular.module 'starter.events'
  .component 'eventLocationHelper', EventLocationHelper
