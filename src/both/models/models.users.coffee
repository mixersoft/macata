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
  'Profile.normalizeFbUser': ()->
    return  # deprecate, using Accounts.onCreateUser() instead
    # example: {
    #   "accessToken":"EAADL4PbafKMBALlvkdhK3wqIuZBZCFvV180wYK0d12wXOsCRgi9WIfFexJuekReT1lZBMZC9CfPAaHyaZC2CZCFSzi6z5hV7NgsEw5ai6mZCzVDZApuTM6ZBdwZCSfZBT4ZCgELDyf2vwSg4VHponL5zvoePOpSn7oQ8d9IZD",
    #   "expiresAt":1467959308973,
    #   "id":"10102276835949303",
    #   "email":"social@snaphappi.com",
    #   "name":"Michael Lin",
    #   "first_name":"Michael",
    #   "last_name":"Lin",
    #   "link":"https://www.facebook.com/app_scoped_user_id/10102276835949303/",
    #   "gender":"male",
    #   "locale":"en_US",
    #   "age_range":{"min":21}
    # }
    meId = Meteor.userId()
    facebook = Meteor.users.findOne(meId).services.facebook
    return if !facebook
    modifier = {}
    fbPic = ['http://graph.facebook.com',facebook.id,'picture'].join('/') + '?type=large'
    modifier['$set'] = {
      displayName: facebook.name
      face: fbPic
      gender: facebook.gender
      firstname: facebook.first_name
      lastname: facebook.last_name
    }
    if Meteor.isServer
      Meteor.users.update(meId, modifier)
      Accounts.addEmail(meId, facebook.email, true)
    else
      modifier['$addToSet'] = {
        emails:
          address: facebook.email
          verified: true
      }
      Meteor.users.update(meId, modifier)
    return

  'Profile.saveLocation': (loc, isLatLon=false )->
    meId = Meteor.userId()
    if !meId
      throw new Meteor.Error('user-not-signed-in'
      , 'Cannot save to Profile with no User', null
      )
    geojson = asGeoJsonPoint(loc, isLatLon)
    modifier = {
      $set:
        "profile.location": geojson
      $push:
        'profile.pastLocations':
          $each: [geojson]
          $slice: -10
    }
    return Meteor.users.update(meId, modifier, (err, result)->'async')

}

Meteor.methods methods
