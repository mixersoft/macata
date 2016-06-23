'use strict'

HandyStuff = ($window, $document, amMoment) ->
  self = {
    # format img.src as background img
    # usage: img.hero(ng-style="{{imgInBg(url)}}")
    imgAsBg: (url)->
      return {
        'background': "url({src}) center center".replace('{src}', url)
        'background-size': 'cover'
      }
    getChildOfParent: (el, parentClass, childSelector)->
      el = el[0] if el instanceof angular.element
      parent = ionic.DomUtil.getParentWithClass(el, parentClass)
      return child = parent.querySelector(childSelector)

    ###
    # @description: bind instance methods to a specific context
    #   e.g. constructor:
    #         utils.bindInstanceMethods(@)
    ###
    bindInstanceMethods: (instance, context)->
      context ?= instance.context
      _.forOwn instance.__proto__, (val, key)->
        instance[key] = val.bind(context)
      ,instance

    range: (min, max, step)->
      step ?= 1
      range = (x for x in [min..max] by step)
      return range

    ###
    # @description convert string to 32 bit signed integer
    ###
    a2nHash: (str)->
      hash = 0
      return hash if str.length == 0
      for i in [0...str.length]
        char = str.charCodeAt(i)
        hash = ((hash<<5) - hash) + char
        hash = hash & hash # Convert to 32bit signed integer
      return hash


    ###
    # @description add a random offset to latlon to mask exact location
    # @param location mixed,
    #         [lat,lon] expressed as decimal, or
    #         geojson Point Object
    # @return location mixed, same format as location
    ###
    maskLatLon: (location, key)->
      isGeoJsonPoint = location?.type == 'Point' && location.coordinates
      if isGeoJsonPoint
        [lon,lat] = location['coordinates']
        latlon = [lat, lon]
      else
        latlon = location
      # +- .0025 to lat/lon
      key = key[0..10]
      offset = {
        lat: (self.a2nHash( latlon[0] + key ) % 25) / 10000
        lon: (self.a2nHash( latlon[1] + key ) % 25) / 10000
      }
      [lat, lon] = [latlon[0]+offset.lat, latlon[1]+offset.lon]
      if isGeoJsonPoint
        return {
          type: "Point"
          'coordinates': [lon,lat]    # reversed
        }
      # console.log offset
      return [lat,lon]

  }
  return self


HandyStuff.$inject = ['$window', '$document', 'amMoment']

angular.module 'starter.core'
  .factory 'utils', HandyStuff
