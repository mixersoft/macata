'use strict'

global = @


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
          .pick ['_id', 'username', 'displayName', 'face']
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
    .filter 'eventParticipantsFilter', EventParticipantsFilter
