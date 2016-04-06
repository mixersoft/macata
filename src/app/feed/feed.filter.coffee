'use strict'

global = @

###
# @description filter event.feed for demo data
# expecting the following attrs for "posts" to event.feed
    post:
      type: [Invitation, Participation, ParticipationResponse, Comment, Notification]
      head:
        id:
        createdAt:
        modifiedAt:  TODO
        eventId:
        ownerId:
        role: string, add recipientIds by role
        recipientIds: [userId], private chat if set, see head.$$chatWith
        isPublic: boolean
        ??moderatorIds: []  who can/should take next action???
        nextActionBy: String [owner, recipient, moderator, depending on post.type]
        token: TODO. invitation token?
        expiresAt: TODO
      body:
        # from <message-composer>
        message: Array or String
        attachment: Obj (optional),
        location:
          address:
          latlon:
        # other body attrs
        status:
        response:
        seats:

  additional Notes:
    ParticipationResponse[status='declined']
      should we make this a Notification?
    Notification:
      created by system
      can be dismissed by recipient
        ??: remove from recipientIds
      expiresAt for auto expiration
      offer hints for next Action

###
FeedFilter = ($rootScope, exportDebug)->

  getPersonalizedFeed = (feed, me)->
    meId = me?._id || Meteor.userId()
    # console.info "user NOT set" if !me

    # check moderator status
    feed = _.reduce feed, (result, post)->

      # all check properties must be truthy for true
      head = post.head

      if false && "OK-for-demo"
        head.eventId = event.id
        switch head.role
          when 'participants'
            head.recipientIds = event['participantIds']
          when 'contributors'
            head.recipientIds = event['contributorIds']
          when 'moderators'
            head.recipientIds = event['moderatorIds']
      check = {
        # eventId: head.eventId == event.id
        address: head.isPublic ||
          (meId && ~[head.ownerId].concat(head.recipientIds || []).indexOf meId)
        expiration: !head.expiresAt || new Date().toJSON() <= head.expiresAt
      }

      switch post.type
        when 'Invitation'
          #  sent by ownerId: owner > [recipientId]
          check['status'] = ~['new','viewed','closed'].indexOf(post.body.status)
          if head.tokenId == head.recipientIds[0]
            check.address = 'by-token'
          # check['skip'] = false
        when 'Participation'
          # from action=[Join, ???Invitation[status=accept]  ]
          #   need to notify event.moderatorId, or head.moderatorIds
          check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
          check['status'] = true
          if post.body.response == 'accepted'
            check['acl'] = true
          else
            check['acl'] = FeedModel::isModerator(post, meId)
          check.address =  true if check.acl
        when 'ParticipationResponse'
          # from action=Participation[response='accepted']
          # ??: automatically accept from invitation[status=accept>join]
          # Participation[response='declined']
          #   check[isRecipient] will make declines private
          'none'
        when 'Comment'
          'TODO:allow recipientIds for comments' if head.recipientIds
        when 'Notification'
          check['notDismissed'] =
            not head.dismissedBy || not (meId &&  ~head.dismissedBy?.indexOf meId)
          # console.log ['check Notification', check]
        else
          'skip'
      result.push post if _.reject(check).length == 0
      return result
    , []
    return feed

  ###
  return here if we are NOT using _.memoize
  ###
  return getPersonalizedFeed

  ###
  include this code block to use _.memoize
  ###

  cachedFeedLength = 0
  memoized_getPersonalizedFeed = _.memoize( getPersonalizedFeed
    , (feed, me)->
      if cachedFeedLength != feed.length
        memoized_getPersonalizedFeed.cache.delete(cachedFeedLength)
      return cachedFeedLength = feed.length
    )

  # TODO: put inside getCollectionReactively('event.feed')
  $rootScope.$on 'event:feed-changed', (ev, event, user)->
    cache = memoized_getPersonalizedFeed.cache
    cache.__data__ = {}
    # resetMemo event, user

  $rootScope.$on 'user:event-role-changed', (ev, user, event)->
    cache = memoized_getPersonalizedFeed.cache
    cache.__data__ = {}
    # resetMemo event, user

  exportDebug.set('memoCache',  memoized_getPersonalizedFeed.cache)

  return (feed, me)->
    return [] if _.isEmpty feed
    return memoized_getPersonalizedFeed(feed)




FeedFilter.$inject = ['$rootScope', 'exportDebug']


angular.module 'starter.feed'
    .filter 'feedFilter', FeedFilter
