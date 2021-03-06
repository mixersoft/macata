'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      displayName: 1
      face: 1
  'menuItem':
    limit: 10
}
###
# see models.0.coffee
# usage:
#   hEvents.get().fetchHost($item)
#   hEvents.get().between(-20, 7, {iso:false})
###
global['hEvents'] = class EventHelper extends global['hModel']
  constructor: ->
    [@arg] = super

  'fetchHost': (event, options)->
    return @fetchOwner event, options

  'isModerator': (event, userId)->
    return false if !event
    userId ?= if Meteor.isServer then @userId else Meteor.userId()
    return false if !userId
    return true if event.moderatorIds && ~event.moderatorIds.indexOf userId
    return true if event.ownerId == userId
    return false

  'isParticipant': (event, userId)->
    return false if !event
    userId ?= if Meteor.isServer then @userId else Meteor.userId()
    return false if !userId
    return true if event.participantIds && ~event.participantIds.indexOf userId
    return true if event.ownerId == userId
    return false

  'findParticipants': (event)->
    return Meteor.users.find({
      _id:
        $in: [event.ownerId].concat(event.participantIds)
      }
      , options['profile'])

  'findMenuItems': (event)->
    return global['mcRecipes'].find({
      _id:
        $in: event.menuItemIds || []
      }
      , options['menuItem'])

  'recent': (days, options)->
    after = moment().subtract(days,'d')
    before = moment().subtract(1,'h')
    return @between(after, before, options)

  'between': (after, before, options={})->
    after = moment().add(after,'d') if _.isNumber after
    before = moment().add(before,'d') if _.isNumber before
    selector = {'startTime':{}}
    selector['startTime']['$gt'] = after if after
    selector['startTime']['$lt'] = before if before
    method = if options.iso then 'toISOString' else 'toDate'
    _.each selector['startTime'], (v,k,o)->
      o[k] = v[method]()

    fields = ['_id', 'startTime', 'duration']
    fields = fields.concat(options.fields) if options.fields
    fields = _.chain(fields)
      .zipObject()
      .each( (v,k,o)-> return o[k]=1 )
      .value()
    return {
      selector: selector
      projection: {fields: fields}
    } if options.selector
    return mcEvents.find( selector , {fields: fields}).fetch()



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

EVENT_ATTRIBUTES = {
  all: [
    "_id", "className"
    "type"
    # see <filtered-feed.inviteActions()>
    # <table-create-wizard.beginTableWizard()>
    # values = [progressive-invite, kickstarter, booking, standard]
    "ownerId", "title", "description", "image"
    "seatsOpen", "seatsTotal"
    "startTime", "duration"
    "isPublic", "locationName", "address", "neighborhood", "geojson"
    "settings"
    # see:
    #   eventUtils.mockData(),
    #   EventDetailCtrl:callbacks.onChange()
    #   BookingCtrl.createParticipation()
    "participations"
    # TODO: ???: get participations from event.Feed?
    # participations = [{
    #   id: Date.now()
    #   ownerId: mi.ownerId
    #   seats: _.random(3) + 1  # random seats for participation
    #   contributions: [{
    #     _id:
    #     className: [Recipe]
    #     portions:
    #     comment:
    #     sort:
    #   }]
    #   comment: []
    #   createdAt: moment(mi.createdAt).add(i, 'hours').toJSON()
    # }]
    "moderatorIds"
    # denormalized
    "menuItemIds", "participantIds"

  ]
  insert: ()->
    return _.difference EVENT_ATTRIBUTES.all, ['_id', 'className']
  update: ()->
    return _.difference EVENT_ATTRIBUTES.all, ['className', 'type', 'createdAt']
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
    #TODO: update Model.user().favorites
    modifier[action] = {"favorites": { _id: model._id, className: 'Event' }}
    Meteor.users.update({_id: meId}, modifier )
    return

  'Event.upsert': (data, fields)->
    if !data
      throw new Meteor.Error('no-data'
      , 'Expecting something to upsert', null
      )
    meId = Meteor.userId()
    data['className'] = 'Events'
    if isUpdate = data._id
      if data.ownerId != meId
        throw new Meteor.Error('no-permission'
        , 'You do not have permission to update', null
        )
      data['modifiedAt'] = new Date()
      allowedFields = EVENT_ATTRIBUTES.update()
    else
      data['ownerId'] = meId
      data['createdAt'] = new Date()
      allowedFields = EVENT_ATTRIBUTES.insert()

    hEvents.get().setAsGeoJsonPoint(data)
    allowedFields =
      if isUpdate then EVENT_ATTRIBUTES.update() else EVENT_ATTRIBUTES.insert()
    fields =
      if fields
      then _.intersection fields, allowedFields
      else allowedFields

    data = _.pick data, fields
    if isUpdate
      modifier = {}
      modifier['$set'] = _.omit data, '_id'
      return mcEvents.update(data._id, modifier)
    return mcEvents.insert( data )

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
      comment:[]
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
        participation.comment.push booking.body.message
        if !_.isEmpty booking.body.attachment
          participation.contributions.push booking.body.attachment
        else
          # TODO: show a placeholder in event.menuItems?
          console.info 'Event.updateBooking no Attachment ???:attach a placeholder?'

    if not found
      event.participations ?=[]
      event.participations.push participation
    event.modifiedAt = now

    # de-normalize certain fields
    event.participantIds = _.map event.participations, 'ownerId'
    event.menuItemIds = _.reduce event.participations, (result, p)->
      ids = _.chain(p.contributions).filter({className:'Recipe'}).map('_id').value()
      return result = result.concat ids
    ,[]
    seatsBooked = _.chain(event.participations).map('seats').sum().value()
    event.seatsOpen = event.seatsTotal - seatsBooked

    modified = _.pick event, [
      'participations', 'seatsOpen', 'modifiedAt'
      'participantIds', 'menuItemIds'
    ]
    modifier = {$set: modified}
    mcEvents.update(event._id, modifier )
    return

  'Admin.moveEventDate': (where, days, field='startTime')->
    if !where
      where = {}
      where[field] = {$exists:true}
    events = mcEvents.find(where).fetch()
    events.forEach (event)->
      modifier = { $set: {}  }
      modifier.$set[field] = moment(event.startTime).add(days,'day').toDate()
      mcEvents.update(event._id, modifier)
}



global['mcEvents'].allow allow
Meteor.methods methods


global['_admin'] = {
  moveEventDate: (days)->
    Meteor.call 'Admin.moveEventDate', days, (err, result)->
      'check'
}
