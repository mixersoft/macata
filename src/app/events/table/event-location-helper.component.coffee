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
    ($scope, $q, $timeout, locationHelpers)->
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
          if self.data.geojson && self.addressChanged == false
            # just show on map
            return locationHelpers.geocodeAddress({geojson: self.data.geojson}, 'force')
          if self.data.address
            return locationHelpers.geocodeAddress({address: self.data.address})
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
          if done
            self.data.address = null


      this.updateLocation = (data)=>
        data ?= this.data
        this.onUpdate({data:data})
        return

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
