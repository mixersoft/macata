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
  'Event.updateBooking': (event, booking)->
    # save participations directly in Event
    now = new Date()
    found = _.find(event.participations, {ownerId: booking.head.ownerId})
    participation = found || {
      id: Date.now()  # for track by
      seats: 0
      createdAt: new Date()
      ownerId: booking.head.ownerId
      contributions: []
    }
    participation.seats += booking.body.seats
    participation.modifiedAt = now

    attachment = booking.body.attachment
    switch attachment?.type
      when 'Recipe'
        found2 = _.find(participation.contributions, {_id: attachment._id})
        contrib = found2 || {
          _id: booking.body.attachment._id
          className: booking.body.attachment.type
          portions: 'todo'
          sort: 'todo'
          comment: []
        }
        # update portions, comment
        contrib.comment = [contrib.comment] if _.isString contrib.comment
        contrib.comment.push booking.body.message
        if not found2
          participation.contributions.push contrib
      else
        if !_.isEmpty booking.body.attachment
          participation.contributions.push booking.body.attachment
        else
          # TODO: show a placeholder in event.menuItems?
          console.info 'Event.updateBooking ???:attach a placeholder?'

    if not found
      event.participations ?=[]
      event.participations.push participation
    event.modifiedAt = now

    # de-normalize certain fields
    event.participantIds = _.pluck event.participations, 'ownerId'
    event.menuItemIds = _.reduce event.participations, (result, p)->
      ids = _.chain(p.contributions).filter({className:'Recipe'}).pluck('_id').value()
      return result = result.concat ids
    ,[]
    seatsBooked = _.sum event.participations, 'seats'
    event.seatsOpen = event.seatsTotal - seatsBooked

    modified = _.pick event, [
      'participations', 'seatsOpen', 'modifiedAt'
      'participantIds', 'menuItemIds'
    ]
    modifier = {$set: modified}
    mcEvents.update(event._id, modifier )
    return

}


global['mcEvents'].allow allow
Meteor.methods methods
