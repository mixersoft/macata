'use strict'

# TODO: refactor as EventHelpers
EventsUtil = (utils, $document, amMoment,
  AAAHelpers
) ->

  self = {
    ###
    # @description set address & location labels by ACL, mask values for visitors
    # @param event object
    # @param user object
    # @return event.object with the following fields
    #         event.visible.address
    #         event.visible.marker
    # # TODO: hide event.address, event.location from JS introspection,
    #         reload values on `event:participant-changed`
    ###
    showExactLocation: (event, userId) ->
      return true if event.setting?['allowPublicAddress']
      return true if userId == event.ownerId
      return true if event.participantIds && ~event.participantIds.indexOf(userId)
      return false

    setVisibleLocation: (event, userId, removeTrueLocation) ->
      userId ?= Meteor.userId()
      if self.showExactLocation(event, userId)
        event.visible = {
          address: event.address
          marker: event.location
          type: 'oneMarker'
        }
      else
        event.visible = {
          address: event.neighborhood
          marker: utils.maskLatLon(event.location, event.title)
          type: 'circle'
        }
      return event

    # TODO: change to like for expiring classes?
    favorite: ($ev, model)->
      self = this
      return AAAHelpers.requireUser('sign-in')
      .then ()->
        model.className = 'Event' if !model.className
        self.call 'Event.toggleFavorite', model, (err, result)->
          console.warn ['Meteor::toggleFavorite WARN', err] if err
          console.log ['Meteor::toggleFavorite OK']


    mockData: (event, vm)->

      event.moderatorIds = [event.ownerId]

      # # @deprecated, using ng-repeat="$post in event | feedFilter:vm.$$feed
      # event.feed = vm.lookup.feed
      # event.feed = vm.$$feed
      # # event.feed = $filter('feedFilter')(event, FEED)



      event.participantIds ?= []    # set event.participantIds manually
      ## NOTE: save participations in events, not as a separate Collection
      ## NOTE: save contributions in participations[].contributions, not as a separate Collection
      event.participations ?= []

      if event.participations.length == 0
        # create mock data for event.participations
        _getByIds = (ids)-> return {_id: {$in: ids}}
        vm.$$menuItems = mcRecipes.find(_getByIds(event['menuItemIds'])).fetch()

        _.each vm.$$menuItems, (mi, i)->
          participantIds = [event.ownerId].concat( event.participantIds)
          mi.ownerId = participantIds[i % participantIds.length ]
          contribution = {
            _id: mi._id
            className: 'Recipe' # use className for object ref, type for posts
            portions: null
            comment: null
            sort: null
            }
          if found = _.find event.participations, {ownerId: mi.ownerId}
            found.contributions.push contribution
            return
          p = {
            id: Date.now()
            ownerId: mi.ownerId
            seats: _.random(3) + 1  # random seats for participation
            contributions: [contribution]
            createdAt: moment(mi.createdAt).add(i, 'hours').toJSON()
          }
          event.participations.push p
          return

      # sum seatsOpen
      seatsTaken = _.chain event.participations
        .pluck('seats')
        .sum()
        .value()
      event.seatsOpen = event.seatsTotal - seatsTaken
      return
  }
  return self

EventsUtil.$inject = ['utils', '$document', 'amMoment'
  'AAAHelpers'
]

angular.module 'starter.events'
  .factory 'eventUtils', EventsUtil
