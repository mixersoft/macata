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

global['mcFeeds'] = mcFeeds = new Mongo.Collection('feeds', {
  # transform: null
})

# NOTE: these methods are attached to the global Meteor Collection
#   used on server with Meteor.publish where we don't have angular $inject
#   only add find() methods
mcFeeds.helpers = {
  isAdmin: (userId)=>
    userId ?= Meteor.userId()
    return true if @model.head.ownerId == userId
    return false

  isModerator: (userId)=>
    userId ?= Meteor.userId()
    return true if @model.head.moderatorIds && ~@model.head.moderatorIds.indexOf userId
    return true if @model.head.ownerId == userId
    return false

  fetchOwner: =>
    return Meteor.users.findOne(@model.head.ownerId, options['profile'])

  findAttachment: (model)-> # for publishComposite
    return if not model.body.attachment
    switch model.body.attachment.type
      when 'Recipe'
        return global['mcRecipes'].find(model.body.attachment._id)

  fetchAttachment: => # for publishComposite
    switch @model.body.attachment.type
      when 'Recipe'
        return global['mcRecipes'].findOne(@model.body.attachment._id).fetch()

  fetchProfiles: =>
    return if model.type != 'Invitation'
    userIds = [@model.head.ownerId].concat @model.head.recipiendIds
    return Meteor.users.find(_getByIds(userIds), options['profile']).fetch()

}



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
    omit$keys = (o)->
      omitKeys = _.filter(_.keys(o), (k)->return k[0]=='$')
      return clean = _.omit o, omitKeys

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
    post.head.ownerId = meId  # force ownership

    # post.head = omit$keys(post.head)
    post.body.attachment = omit$keys(post.body.attachment)

    if _.isArray post.body.message
      post.body.message = post.body.message.join(' ')

    if post.type != "Notification"
      # TODO: demo only
      if not _.isEmpty post.head.recipientIds
        post.body.message += ' (This should be a private notification.)'

    mcFeeds.insert post, (err, id)->
      return console.warn ['Meteor::insert post WARN', err] if err



  # comment on a Post
  'Post.postPostComment': (post, comment, from)->
    omit$keys = (o)->
      omitKeys = _.filter(_.keys(o), (k)->return k[0]=='$')
      return clean = _.omit o, omitKeys
    comment = omit$keys(comment)
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
        comment: comment
    }
    modifier = { $addToSet: {"body.comments": postComment} }
    mcFeeds.update(post._id, modifier )



}


global['mcFeeds'].allow allow
Meteor.methods methods
