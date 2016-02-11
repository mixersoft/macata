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
EventFeedFilter = ($rootScope)->

  getPersonalizedFeed = (event, me, feed)->

    feed ?= event.feed
    # console.info "user NOT set" if !me

    # check moderator status
    feed = _.reduce feed, (result, post)->

      if "OK-for-demo"
        post.head.eventId = event.id

      # all check properties must be truthy for true
      head = post.head
      switch head.role
        when 'participants'
          head.recipientIds = event['participantIds']
        when 'contributors'
          head.recipientIds = event['contributorIds']
        when 'moderators'
          head.recipientIds = event['moderatorIds']
      check = {
        eventId: head.eventId == event.id
        address: head.isPublic ||
          (me && ~[head.ownerId].concat(head.recipientIds || []).indexOf me.id)
        expiration: !head.expiresAt || new Date().toJSON() <= head.expiresAt
      }

      switch post.type
        when 'Invitation'
          #  sent by ownerId: owner > [recipientId]
          check['status'] = ~['new','viewed','closed'].indexOf(post.body.status)
        when 'Participation'
          # from action=[Join, ???Invitation[status=accept]  ]
          #   need to notify event.moderatorId, or head.moderatorIds
          check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
          check['acl'] = event.isPostModerator(event, post)
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
          check['notDismissed'] = not (head.dismissedBy && ~head.dismissedBy.indexOf me.id)
          # console.log ['check Notification', check]
        else
          'skip'
      result.push post if _.reject(check).length == 0
      return result
    , []
    return feed

  memoized_getPersonalizedFeed = _.memoize( getPersonalizedFeed
    , (event, me, feed)->
      return [event.id, me.id].join(':')
    )

  resetMemo = (event, me)->
    cache = memoized_getPersonalizedFeed.cache
    if !event && !me
      return cache.__data__ = {}
    if event && me
      return cache.delete([event.id, me.id].join(':'))
    toDelete = []
    if (event && !me) || (me && !event)
      _.each _.keys(cache.__data__), (k)->
        [eid, uid] = k.split(':')
        toDelete.push k if event && eid == event.id
        toDelete.push k if me && uid == me.id
        return
      toDelete.forEach (k)->
        cache.delete k


  $rootScope.$on 'event:feed-changed', (ev, event, user)->
    resetMemo event, user

  $rootScope.$on 'user:event-role-changed', (ev, user, event)->
    resetMemo event, user


  return (event, me, feed)->
    return [] if !event.feed

    return memoized_getPersonalizedFeed(event, me, feed)

EventFeedFilter.$inject = ['$rootScope']


###
# @description filter event for participants, padding with 'placeholders'
#     [ host, $participant, $participant, ..., 'placeholder', 'placeholder'..]
###
EventParticipantsFilter = ()->
  return (event, padding)->
    return [] if not (event.$$participations && event.$$host)
    MAX_VISIBLE_PARTICIPANTS = 12
    total = Math.min event.seatsTotal, MAX_VISIBLE_PARTICIPANTS
    padded = []
    hostId = event.$$host.id
    now = Date.now() + '-'
    h = _.findIndex event.$$participations, {ownerId: hostId}
    #move host to front
    if h > 0
      host = event.$$participations.splice(h,1)
      event.$$participations.unshift(host[0])

    _.each event.$$participations, (p, i)->
      _.each [0...p.seats], (i)->
        face = _.pick p.$$owner, ['id', 'face', 'displayName']
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
