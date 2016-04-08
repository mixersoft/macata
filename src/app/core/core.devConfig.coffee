'use strict'

# helper functions to set up dev testing
DevConfig = ($rootScope, $q, $log, openGraphSvc, exportDebug, toastr
  UsersResource, EventsResource, IdeasResource
)->

  self = {
    _backwardCompatibleMeteorUser: (user)->
      return if !user
      # backward compatibility for Meteor.user
      angular.extend user, _.pick user.profile, ['displayName', 'face']
      user.id = user._id

    loginUser : (id, force=true)->
      # manually set current user for testing
      return $q.when( $rootScope.user ) if $rootScope.user? && !force
      return UsersResource.get( id ).then (user)->
        if !_.isEmpty(user) && !user.displayName
          $log.info "Sign-in for id=" + user.id
          displayName = []
          displayName.push user.firstname if user.firstname
          displayName.push user.lastname if user.lastname
          displayName = [user.username] if user.username
          user.displayName = displayName.join(' ')
        $rootScope['user'] = user
        $rootScope.$emit 'user:sign-in', $rootScope['user']
        return $rootScope['user']

    getDevUser : (defaultUserId)->

      return $q.when()
      .then ()->
        if Meteor.user()
          $rootScope.user = Meteor.user()
          self._backwardCompatibleMeteorUser($rootScope.user)
          return $rootScope.user
        return $rootScope['user'] if $rootScope['user']?
        return self.loginUser( defaultUserId || "0" )
        .then (user)->
          toastr.info "Login as userId="+$rootScope['user'].id
          return $rootScope['user']


    dataReady: null # promise

    loadData: ()->
      users = []
      ideas = []
      events = []
      return self.dataReady = $q.when()
      .then ()->
        return UsersResource.query()
      .then (result)->
        users = result
      .then ()->
        return IdeasResource.query()
      .then (result)->
        ideas = result
        _.each ideas, (idea, i)->
          idea.createdAt = moment().subtract(i, 'days').toJSON()
          idea.$$owner = users[ i % 4 ]  # only userId < 4
          idea.ownerId = idea.$$owner.id
          IdeasResource.put(idea.id, idea)
        return ideas
      .then ()->
        return EventsResource.query()
      .then (result)->
        events = result
        _.each events, (event, i)->
          event.createdAt = moment().subtract(i, 'days').toJSON()
          event.$$host = _.find users, {id: event.ownerId}
          event.visibleAddress = event.address
          # console.warn("TESTDATA: using currentUser as event Moderator")
          # event.moderatorId = vm.me.id  # force for demo data
          console.warn("TESTDATA: using random menuItems")
          fromHost = _.find ideas, {ownerId: event.ownerId}
          event.$$menuItems = [fromHost]
          event.$$menuItems = event.$$menuItems.concat( _.sample ideas[0...3], 3 )
          event.$$menuItems = _.unique(event.$$menuItems)
          event.menuItemIds = _.pluck event.$$menuItems, 'id'

          event.seatsOpen = event.seatsTotal
          event.$$participations ?= []
          event.participationIds ?= []
          event.participantIds ?= []
          _.each event.$$menuItems, (mi, i)->
            return if ~event.participantIds.indexOf mi.ownerId
            p = {
              id: Date.now()
              seats: _.random(3) + 1  # random seats for participation
              createdAt: moment(mi.createdAt).add(i, 'hours').toJSON()
              ownerId: mi.ownerId
              $$owner: mi.$$owner
            }
            event.participationIds.push p.id
            event.$$participations.push p
            event.participantIds.push mi.ownerId
            event.seatsOpen -= p.seats
            # TODO: participation hasMany contributions
            return
          EventsResource.put(event.id, event)
          return
      .then ()->
        exportDebug.set('users',users)
        exportDebug.set('ideas',ideas)
        exportDebug.set('events',events)

  }

  return self # DevConfig


DevConfig.$inject = ['$rootScope', '$q', '$log', 'openGraphSvc', 'exportDebug', 'toastr'
  'UsersResource', 'EventsResource', 'IdeasResource'
]



ExportDebug = ($window)->
  # export as JS global for introspection
  $window._debug = _debug = {}

  self = {
    set: (label, value) ->
      return if !label
      return _debug[label] = value
    clear: (label)->
      delete _debug[label]
  }
  return self

ExportDebug.$inject = ['$window']


angular.module 'starter.core'
  .factory 'devConfig', DevConfig
  .factory 'exportDebug', ExportDebug
