'use strict'

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
EventFeedFilter = ($rootScope, exportDebug)->

  getPersonalizedFeed = (feed, me)->
    me ?= $rootScope.currentUser
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
          (me && ~[head.ownerId].concat(head.recipientIds || []).indexOf me._id)
        expiration: !head.expiresAt || new Date().toJSON() <= head.expiresAt
      }

      switch post.type
        when 'Invitation'
          #  sent by ownerId: owner > [recipientId]
          check['status'] = ~['new','viewed','closed'].indexOf(post.body.status)
          # check['skip'] = false
        when 'Participation'
          # from action=[Join, ???Invitation[status=accept]  ]
          #   need to notify event.moderatorId, or head.moderatorIds
          check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
          # check['acl'] = event.isPostModerator(event, post)
          check['acl'] = post.isModerator?(me)
          check.address =  true if check.acl
        when 'ParticipationResponse'
          # from action=Participation[status='accepted']
          # ??: automatically accept from invitation[status=accept>join]
          # Participation[status='decline']
          #   check[isRecipient] will make declines private
          'none'
        when 'Comment'
          'TODO:allow recipientIds for comments' if head.recipientIds
        when 'Notification'
          check['notDismissed'] = not (head.dismissedBy && ~head.dismissedBy.indexOf me._id)
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




EventFeedFilter.$inject = ['$rootScope', 'exportDebug']


###
# @description filter event for participants, padding with 'placeholders'
#     [ host, $participant, $participant, ..., 'placeholder', 'placeholder'..]
###
EventParticipantsFilter = ()->
  return (event, vm)->
    return [] if not (event.participations && vm.$$host)
    console.info "EventParticipantsFilter"
    MAX_VISIBLE_PARTICIPANTS = 12
    total = Math.min event.seatsTotal, MAX_VISIBLE_PARTICIPANTS
    padded = []
    now = Date.now() + '-'
    h = _.findIndex event.participations, {ownerId: event.ownerId}
    #move host to front
    if h > 0
      host = event.participations.splice(h,1)
      event.participations.unshift(host[0])

    _.each event.participations, (p, i)->
      _.each [0...p.seats], (i)->
        face = _.chain vm.$$participants
          .find {_id:p.ownerId}
          .pick ['_id', 'username', 'profile']
          .value()
        face['trackBy'] = now + padded.length
        padded.push face
        return
      return
    _.each [padded.length...total], (i)->
      padded.push {
        'trackBy': now + padded.length
        value: 'placeholder'
      }
      return

    return padded

EventParticipantsFilter.$inject = []


angular.module 'starter.events'
    .filter 'eventFeedFilter', EventFeedFilter
    .filter 'eventParticipantsFilter', EventParticipantsFilter
