'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
  'menuItem':
    limit: 10
}

class EventModel
  constructor: (event)->
    _.extend(@, event)

  isAdmin: (userId)=>
    userId ?= Meteor.userId()
    return true if @ownerId == userId
    return false

  isModerator: (userId)=>
    userId ?= Meteor.userId()
    return true if @moderatorIds && ~@moderatorIds.indexOf userId
    return true if @ownerId == userId
    return false

  isParticipant: (userId)=>
    userId ?= Meteor.userId()
    return true if @participantIds && ~@participantIds.indexOf userId
    return true if @ownerId == userId
    return false

  fetchHost: =>
    return Meteor.users.findOne(@ownerId, options['profile'])

  findParticipants: =>
    return Meteor.users.find({
      _id:
        $in: [@ownerId].concat(@participantIds)
      }
      , options['profile'])

  findMenuItems: =>
    return global['mcRecipes'].find({
      _id:
        $in: @menuItemIds || []
      }
      , options['menuItem'])



global['mcEvents'] = mcEvents = new Mongo.Collection('events', {
  transform: (event)->
    return new EventModel(event)
})

allow = {
  insert: (userId, event)->
    return event.ownerId? # userId && event.ownerId == userId
  update: (userId, event, fields, modifier)->
    return userId && event.ownerId == userId
  remove: (userId, event)->
    return userId && event.ownerId == userId
}


methods = {
}


global['mcEvents'].allow allow
Meteor.methods methods
