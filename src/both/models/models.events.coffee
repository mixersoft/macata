'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}

class EventModel
  constructor: (event)->
    _.extend(@, event)

  isModerator: (userId)=>
    userId ?= Meteor.userId()
    return true if this.moderatorIds && ~this.moderatorIds.indexOf userId
    return true if this.ownerId == userId
    return false

  fetchHost: =>
    return Meteor.users.findOne(@ownerId, options['profile'])

  fetchParticipants: =>
    return Meteor.users.find({
      _id:
        $in: [@ownerId].concat(@participantIds)
      }
      , options['profile'])



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
