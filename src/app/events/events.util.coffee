'use strict'

EventsUtil = (utils, $document, amMoment) ->

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
        }
      else
        event.visible = {
          address: event.neighborhood
          marker: utils.maskLatLon(event.location, event.neighborhood)
        }
      return event
  }
  return self


EventsUtil.$inject = ['utils', '$document', 'amMoment']

angular.module 'starter.events'
  .factory 'eventUtils', EventsUtil
