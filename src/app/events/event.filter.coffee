'use strict'

###
# @description filter event.feed for demo data
###
EventFeedFilter = ()->
  return (event, me, feed)->
    return [] if !event.feed
    feed ?= event.feed
    # console.info "user NOT set" if !me

    # check moderator status
    feed = _.reduce feed, (result, post)->

      if "OK-for-demo"
        post.head.eventId = event.id

      # all check properties must be truthy for true
      head = post.head
      check = {
        eventId: head.eventId == event.id
        notPrivate: not head.private
      }
      switch post.type
        when 'Invitation'
          check['status'] = ~['new','viewed','closed'].indexOf(post.body.status)
          check['privy'] = me && ~[head.ownerId, head.recipientId].indexOf me.id
          delete check['notPrivate']
        when 'Participation'
          check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
          check['acl'] = event.isPostModerator(event, post)
        when 'ParticipationResponse'
          # hide private from feed
          check['ownerId'] = me && head.ownerId == me.id
          delete check['notPrivate']
        when 'Comment'
          if head.notPrivate==false
            check['privy'] = me && ~[head.ownerId, head.recipientId].indexOf me.id
        else
          'skip'
      result.push post if _.reject(check).length == 0
      return result
    , []
    return feed

EventFeedFilter.$inject = []


###
# @description filter event for participants, padding with 'placeholders'
#     [ host, $participant, $participant, ..., 'placeholder', 'placeholder'..]
###
EventParticipantsFilter = ()->
  return (event)->
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
