'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}

###
# @description preferred format for storing location in mongoDB
# @params lonlat array [lon, lat], or object {lat: lon:}
#         isLatLon boolean, reverse array if true, [lat,lon] deprecate
###
asGeoJsonPoint = (lonlat, isLatLon=false)->
  lonlat = lonlat.reverse?() if isLatLon
  lonlat = [lonlat['lon'], lonlat['lat']] if lonlat['lat']?
  lonlat ?= []
  return {
    type: "Point"
    coordinates: lonlat # [lon,lat]
  }


###
#  NOTE: when calling from publish, set Meteor.userId() Meteor.user() explicitly
###
global['ProfileModel'] = class ProfileModel

ProfileModel::saveLocation = (location, isLatLon=false, userId)->
  me = Meteor.users.findOne(userId) if userid
  me ?= Meteor.user()
  Meteor.call 'Profile.saveLocation', location, isLatLon, (err, result)->
    'check'


methods = {
  'Profile.saveLocation': (loc, isLatLon=false )->
    meId = Meteor.userId()
    return if !meId
    geojson = asGeoJsonPoint(loc, isLatLon)
    modifier = {
      $set:
        "profile.location": geojson
      $push:
        'profile.pastLocations':
          $each: [geojson]
          $slice: -10
    }
    Meteor.users.update(meId, modifier)

}

Meteor.methods methods
