'use strict'

###
# @description filter event.feed for demo data
###
EventFeedFilter = ()->
  return (event, feed, me)->
    feed ?= event.feed

    # check moderator status
    feed = _.reduce feed, (result, post)->

      if "OK-for-demo"
        post.head.eventId = event.id

      check = {
        eventId: post.head.eventId == event.id
      }
      switch post.type
        when 'Participation'
          check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
          check['acl'] = event.isPostModerator(event, post)
        when 'ParticipationResponse'
          head = post.head
          # hide private from feed
          check['private'] = true || head.ownerId == me.id || not head.private
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
    return [] if not (event.$$participants && event.$$host)
    MAX_VISIBLE_PARTICIPANTS = 12
    total = Math.min event.seatsTotal, MAX_VISIBLE_PARTICIPANTS
    padded = []
    hostId = event.$$host.id
    participantList = event.$$participants
    #move host to front
    h = _.findIndex participantList, {id: hostId}
    if h > 0
      host = participantList.splice(h,1)
      participantList.unshift(host[0])

    _.each [0...total], (i)->
      person = participantList[i]
      if person?
        padded.push person
        return
      padded.push {
        id: Date.now() + '' + i
        value: 'placeholder'
      }
      return
    return padded

EventParticipantsFilter.$inject = []


angular.module 'starter.events'
    .filter 'eventFeedFilter', EventFeedFilter
    .filter 'eventParticipantsFilter', EventParticipantsFilter
