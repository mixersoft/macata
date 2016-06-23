'use strict'
#  this file is injected first
# @ adds to global namespace
global = @

DEFAULTS = {
  'profile':
    fields:
      username: 1
      displayName: 1
      face: 1
  'menuItem':
    limit: 10
}


global['hModel'] = class ModelHelper   # singleton
  @get: ->
    @_instance ?= new @(@,arguments...)

  constructor: (args...)->
    unless @constructor == args.shift()
      throw new Error('Cannot call new on a Singleton')
    return args

  'fetchProfile': (userId, options)->
    return null if !userId
    options ?= DEFAULTS['profile']
    return Meteor.users.findOne(userId, options)

  'fetchOwner': (model, options)->
    return null if !model
    options ?= DEFAULTS['profile']
    return Meteor.users.findOne(model.ownerId, options)

  'findOwner': (model, options)->
    # returns a cursor, used by publishComposite
    options ?= DEFAULTS['profile']
    ownerId = model?.ownerId || null
    return Meteor.users.find(ownerId, options)

  'isOwner': (model, userId)->
    return false if !model
    userId ?= if Meteor.isServer then @userId else Meteor.userId()
    return false if !userId
    return true if model.ownerId == userId
    return false

  'isAdmin': (model, userId)->
    return false if !model
    userId ?= if Meteor.isServer then @userId else Meteor.userId()
    return false if !userId
    return true if model.ownerId == userId
    return false

  'isFavorite': (model, me)->
    return false if !model
    me ?= if Meteor.isServer then Meteor.users.findOne(@userId) else Meteor.user()
    return false if !me
    return true if _.find me.favorites, {_id: model._id}
    return false

  'setAsGeoJsonPoint': (model)->
    if model['location']
      model['latlon'] ?= model['location']  # legacy, assume location is latlon
    if model['latlon']
      model['lonlat'] = angular.copy(model.latlon).reverse()
    if model['lonlat']
      model['geojson'] = {
        type: "Point"
        coordinates: model['lonlat']
      }
    model = _.omit model, ['lonlat','latlon', 'location']
    return model
