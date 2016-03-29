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

###
# Example:
    vm.EventM = new EventModel()
    vm.EventM.set(event)
    vm.EventM.isParticipant()
    or
    vm.EventModel = EventModel::
    vm.EventModel.isParticipant(event)
    or from publish:
    EventModel::isParticipant(event, this.userId)
###

###
#  NOTE: when calling from publish, set Meteor.userId() Meteor.user() explicitly
###
global['EventModel'] = class EventModel
  constructor: (@context)->
  set: (@context)->
  release: ()->
    delete @context


EventModel::isAdmin = (event, userId)->
  if @context
    event = @context
    [userid] = arguments
  return false if !event
  userId ?= Meteor.userId()   # available in Meteor.methods
  return false if !userId
  return true if event.ownerId == userId
  return false

EventModel::isModerator = (event, userId)->
  if @context
    event = @context
    [userid] = arguments
  return false if !event
  userId ?= Meteor.userId()   # available in Meteor.methods
  return false if !userId
  return true if event.moderatorIds && ~event.moderatorIds.indexOf userId
  return true if event.ownerId == userId
  return false

EventModel::isParticipant = (event, userId)->
  if @context
    event = @context
    [userid] = arguments
  return false if !event
  userId ?= Meteor.userId()   # available in Meteor.methods
  return false if !userId
  return true if event.participantIds && ~event.participantIds.indexOf userId
  return true if event.ownerId == userId
  return false

EventModel::fetchHost = (event={})->
  if @context
    event = @context
  return Meteor.users.findOne(event.ownerId, options['profile'])

EventModel::findParticipants = (event={})->
  if @context
    event = @context
  return Meteor.users.find({
    _id:
      $in: [event.ownerId].concat(event.participantIds)
    }
    , options['profile'])

EventModel::findMenuItems = (event={})->
  if @context
    event = @context
  return global['mcRecipes'].find({
    _id:
      $in: event.menuItemIds || []
    }
    , options['menuItem'])



global['mcEvents'] = mcEvents = new Mongo.Collection('events', {
  # transform: null
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
  'Event.toggleFavorite': (model)->
    return if model.className != 'Event'
    meId = Meteor.userId()

    model.favorites ?= []
    found = model.favorites.indexOf meId
    action =
      if found == -1
      then '$addToSet'   # TODO: this is not scalable
      else '$pull'
    modifier = {}
    modifier[action] = {"favorites": meId}  # e.g.  { $addToSet: {"likes": meId} }
    mcEvents.update(model._id, modifier )
    #TODO: update Model.user().profile.favorites
    profileFavorite = {"profile.favorites": { _id: model._id, className: 'Event' }}
    modifier[action] = profileFavorite
    Meteor.users.update({_id: meId}, modifier )
    return

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
