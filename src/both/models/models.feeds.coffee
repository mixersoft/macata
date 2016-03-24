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
_omit$keys = (o)->
  return o if not _.isObject o
  omitKeys = _.filter(_.keys(o), (k)->return k[0]=='$')
  return clean = _.omit o, omitKeys
_getUserId = (context)->
  return if Meteor.isServer then context.userId else Meteor.userId()


global['FeedModel'] = class FeedModel
  constructor: (@context)->
  set: (@context)->
  release: ()->
    delete @context


FeedModel::isAdmin = (model, userId)->
  if @context
    model = @context
    [userid] = arguments
  return false if !model
  userId ?= _getUserId(this)
  return true if model.head.ownerId == userId
  return false

FeedModel::isModerator = (model, userId, event)->
  if @context
    model = @context
    [userid, event] = arguments
  return false if !event
  userId ?= _getUserId(this)
  return true if model.head.moderatorIds && ~model.head.moderatorIds.indexOf userId
  return true if model.head.ownerId == userId
  return true if event?.moderatorIds && ~event.moderatorIds.indexOf userId
  return false

FeedModel::fetchOwner = (model={})->
  if @context
    model = @context
  return Meteor.users.findOne(model.head.ownerId, options['profile'])

FeedModel::findEvent = (model={})->
  if @context
    model = @context
  # return global['mcEvents'].find({_id: model._id})
  found = global['mcEvents'].find({_id: model._id})
  console.log ["Feed belongsTo Event, event=", found.fetch()]
  return found

FeedModel::findAttachment = (model={})-> # for publishComposite
  if @context
    model = @context
  return if not model.body.attachment
  # TODO: standardize form, use type(?), see message-composer
  type = model.body.attachment.type || model.body.attachment.className
  switch type
    when 'Recipe'
      return global['mcRecipes'].find(model.body.attachment._id)

FeedModel::fetchAttachment = (model={})-> # for publishComposite
  if @context
    model = @context
  switch model.body.attachment.type
    when 'Recipe'
      return global['mcRecipes'].findOne(model.body.attachment._id).fetch()

FeedModel::fetchProfiles = (model={})->
  if @context
    model = @context
  return if model.type != 'Invitation'
  userIds = [model.head.ownerId].concat model.head.recipiendIds
  return Meteor.users.find(_getByIds(userIds), options['profile']).fetch()


global['mcFeeds'] = mcFeeds = new Mongo.Collection('feeds', {
  # transform: null
})



allow = {
  insert: (userId, feed)->
    return userId && feed.head.ownerId == userId
  update: (userId, feed, fields, modifier)->
    console.log ["allow update", fields, modifier]
    allow = {
      'head.likes':
        $addToSet: true
        $pull: 'same as userId'
      'head.dismissedBy': 'same as userId'
    }
    return true
    return userId && feed.head.ownerId == userId
  remove: (userId, feed)->
    return userId && feed.head.ownerId == userId
}


methods = {
  # user this.userId inside Meteor.methods
  'Post.toggleLike': (model)->
    # userId = userId._id if userId?.hasOwnProperty('_id')
    return if model.type == 'Notification'
    meId = this.userId
    model.head.likes ?= []
    found = model.head.likes.indexOf meId

    switch model.type
      when 'PostComment'
        if found == -1
          modifier = { $addToSet: {"body.comments.$.head.likes": meId} }
        else
          modifier = { $pull: {"body.comments.$.head.likes": meId} }
        mcFeeds.update({_id: model.head.target._id, "body.comments.id": model.id}, modifier )

      else
        if found == -1
          modifier = { $addToSet: {"head.likes": meId} }
        else
          modifier = { $pull: {"head.likes": meId} }
        mcFeeds.update(model._id, modifier )
    return

  'Post.dismiss': (model)->
    meId = this.userId
    modifier = { $addToSet: {"head.dismissedBy": meId} }
    mcFeeds.update(model._id, modifier)

  # comment for a Feed
  'Post.postFeedPost': (feedId, options)->

    meId = this.userId
    post = {
      # _id: null   # this is a top-level doc
      type: options.type || 'Comment'
      head:
        ownerId: null
        eventId: feedId
        createdAt: new Date()
      body: {}
    }
    _.extend(post.head, options.head)
    _.extend(post.body, options.body)

    if post.type != "Notification"
      post.head.ownerId = meId  # force ownership

    # post.head = _omit$keys(post.head)
    switch post.body.attachment?.className
      when 'Recipe'
        post.body.attachment = {
          _id: post.body.attachment._id
          type: post.body.attachment.className
        }
      else
        post.body.attachment = _omit$keys(post.body.attachment) if post.body.attachment




    if _.isArray post.body.message
      post.body.message = post.body.message.join(' ')

    if post.type == "Notification"
      # TODO: demo only
      if not _.isEmpty post.head.recipientIds
        post.body.message += ' (This should be a private notification.)'

    mcFeeds.insert post



  # comment on a Post
  'Post.postPostComment': (post, comment, from)->

    comment = _omit$keys(comment)
    postComment = {
      id: Date.now()    # not a top-level doc
      type: "PostComment"
      head:
        ownerId: from._id + ''
        target: # parent post for this comment
          _id: post._id
          class: post.type
        createdAt: new Date()
        # likes: []
      body:
        # TODO: use body.message instead(?)
        comment: comment
    }
    modifier = { $addToSet: {"body.comments": postComment} }
    mcFeeds.update(post._id, modifier )


  #  called by both respondToInvite and respondToBooking
  'Post.respondToInvite': (invite, action, options = {})->
    modifier = {
      $set:
        'head.modifiedAt': new Date()
    }
    switch action
      when 'accept'
        modifier.$set['body.response'] = 'accepted'
        modifier.$set['body.status'] = 'closed'
        modifier.$set['body.seats'] = options.seats if options.seats
      when 'decline'
        modifier.$set['body.response'] = 'declined'
        modifier.$set['body.status'] = 'closed'
      when 'viewed'
        modifier.$set['body.status'] = 'viewed'
      when 'pending'  # TODO: participation status=pending, not viewed??
        modifier.$set['body.status'] = 'pending'

    mcFeeds.update(invite._id, modifier)


  'DEV.Post.resetFeed': ()->
    mcFeeds.remove({"head.createdAt": { $gt:moment().subtract(3,'day').toDate()} })


}


global['mcFeeds'].allow allow
Meteor.methods methods
