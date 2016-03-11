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
          marker: utils.maskLatLon(event.location, event.title)
        }
      return event
    mockData: (event, vm)->
      # console.warn("TESTDATA: using currentUser as event Moderator")
      # event.isPostModerator = vm.postActions.acl.isModerator
      # event.moderatorId = vm.me.id  # force for demo data

      # console.warn("TESTDATA: using random menuItems")
      # ideas = mcRecipes.find({}).fetch()
      # fromHost = _.find ideas, {ownerId: event.ownerId}
      # event.$$menuItems = [fromHost]
      # event.$$menuItems = event.$$menuItems.concat( _.sample ideas[0...3], 3 )
      # event.$$menuItems = _.unique(event.$$menuItems)
      # event.menuItemIds = _.pluck event.$$menuItems, 'id'

      event.seatsOpen = event.seatsTotal
      event.participantIds ?= []    # set event.participantIds manually
      vm.$$participations ?= []
      event.participationIds ?= []

      _.each vm.$$menuItems, (mi, i)->
        mi.ownerId = _.sample [event.ownerId].concat event.participantIds
        p = {
          id: Date.now()
          seats: _.random(3) + 1  # random seats for participation
          createdAt: moment(mi.createdAt).add(i, 'hours').toJSON()
          ownerId: mi.ownerId
          $$owner: Meteor.users.findOne(mi.ownerId)
        }
        event.participationIds.push p.id
        vm.$$participations.push p
        event.seatsOpen -= p.seats
        # TODO: participation hasMany contributions
        return
      return
  }
  return self

EventsUtil.$inject = ['utils', '$document', 'amMoment']

angular.module 'starter.events'
  .factory 'eventUtils', EventsUtil
