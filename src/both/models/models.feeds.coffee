'use strict'
# @ adds to global namespace
global = @

options = {
  'profile':
    fields:
      username: 1
      profile: 1
}


_getByIds = (ids)-> return {_id: {$in: ids}}

class FeedModel
  constructor: (feed)->
    _.extend(@, feed)
    @head._id = feed._id if @head
    # console.log ['new FeedModel', @]

  isAdmin: (userId)=>
    userId ?= Meteor.userId()
    return true if @head.ownerId == userId
    return false

  isModerator: (userId)=>
    userId ?= Meteor.userId()
    return true if @head.moderatorIds && ~@head.moderatorIds.indexOf userId
    return true if @head.ownerId == userId
    return false

  fetchOwner: =>
    return Meteor.users.findOne(@head.ownerId, options['profile'])

  findAttachment: => # for publishComposite
    switch @body.attachment.type
      when 'Recipe'
        return global['mcRecipes'].find(@body.attachment._id)

  fetchAttachment: => # for publishComposite
    switch @body.attachment.type
      when 'Recipe'
        return global['mcRecipes'].findOne(@body.attachment._id).fetch()


class ParticipationFeedModel extends FeedModel

class InvitationFeedModel extends FeedModel
  fetchProfiles: =>
    userIds = [@head.ownerId].concat @head.recipiendIds
    return Meteor.users.find(_getByIds(userIds), options['profile']).fetch()

class NotificationFeedModel extends FeedModel


global['mcFeeds'] = mcFeeds = new Mongo.Collection('feeds', {
  transform: (feed)->
    switch feed.type
      when 'Participation'
        result = new ParticipationFeedModel(feed)
      when 'Invitation'
        result = new InvitationFeedModel(feed)
      when 'Notification'
        result = new NotificationFeedModel(feed)
      else
        result = new FeedModel(feed)
    return result
})

allow = {
  insert: (userId, feed)->
    return feed.ownerId? # userId && feed.ownerId == userId
  update: (userId, feed, fields, modifier)->
    return userId && feed.ownerId == userId
  remove: (userId, feed)->
    return userId && feed.ownerId == userId
}


methods = {
}


global['mcFeeds'].allow allow
Meteor.methods methods
