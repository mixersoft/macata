'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  uiGmapGoogleMapApi, geocodeSvc, unsplashItSvc, eventUtils
  $reactive, ReactiveTransformSvc, $auth
  UsersResource, EventsResource, IdeasResource, FeedResource, TokensResource
  EventActionHelpers, $filter, notificationTemplates, FeedHelpers, RecipeHelpers
  utils, devConfig, exportDebug
  )->
    # coffeelint: disable=max_line_length
    # coffeelint: enable=max_line_length
    vm = this
    vm.title = "Event Detail"
    vm.viewId = ["event-detail-view",$scope.$id].join('-')
    vm.hEvents = hEvents
    vm.feedHelpers = new FeedHelpers(vm)

    vm.recipeHelpers = new RecipeHelpers(vm)  # for on.favorite()

    vm.settings = {
      view:
        show: 'grid'
        'xxx-new': false
      show:
        'hideDetails': false
        'hideMap':true
        'hideParticipants': false
        'hideInvitations': true
        'hideControlPanel': true
        'fabIcon': 'ion-plus'
    }

    vm.lookup = {
      colors: ['royal', 'positive', 'calm', 'balanced', 'energized', 'assertive']
    }

    vm.isInvitation = ()->
      return !!$state.params.invitation

    isInvitationRequired = (event)->
      return $q.when()
      .then ()->
        return true if $state.is('app.invitation')
        if event.settings['isExclusive'] || $state.params.invitation
          return TokensResource.isValid($state.params.invitation, 'Event', event._id)
      .catch (result)->
        $log.info "Token check, value="+result
        toastr.info "Sorry, this event is by invitation only." if result=='INVALID'
        if result=='EXPIRED'
          toastr.warning "Sorry, this invitation has expired. Please contact the host for another."
        return $q.reject(result)



    vm.location = {
      GRID_RESPONSIVE_SM_BREAK: 680
      gMap:  # controls
        Control: {}
        MarkersControl: {}
      map: null
      prepareMap: (event, options)->
        return $q.reject('use setVisibleLocation()') if !event.visible

        return $q.when() if !event.visible.marker
        return uiGmapGoogleMapApi
        .then ()->
          keymap = {
            id: '_id'
            location: 'visible.marker'
            label: 'title'
          }
          # markerCount==1
          mapOptions = {
            type: event.visible.type
            marker: geocodeSvc.mapLocations(event, keymap)
            # draggableMap: true  # set in activate()
            draggableMarker: false
            dragendMarker: (marker, eventName, args)->
              return
          }
          mapOptions = _.extend mapOptions, {
            # 'control' : {}
            'mapReady' : (map, eventName)->
              $scope.$broadcast 'map-ready', map
          }, options
          mapConfig = geocodeSvc.getMapConfig mapOptions
          # mapConfig.zoom = 11
          return mapConfig
      showOnMap: (event, options)->
        return vm.location.prepareMap(event, options)
        .then (config)->
          vm.location.map = config
          vm.settings.show.hideMap = false if options.visible
          exportDebug.set 'mapConfig', config
          return

    }

    vm.dev = {
      loginByRole : (event, forceRole)->
        userId = null
        $rootScope.demoRole = forceRole if forceRole
        switch $rootScope.demoRole
          when 'host'
            userId = event.ownerId
          when 'participant' # userId < 4
            userId = _.sample event.participantIds[1...event.participantIds.length]
          when 'booking'
            userId = '5'
          when 'invited'
            userId = '6'
          when 'visitor'
            userId = '7'
        return $q.when() if !userId
        return devConfig.loginUser(userId, 'force')
        .then (user)->
          vm.me = user
          $scope.$broadcast 'demo-role:changed', $rootScope.demoRole if forceRole
          return user
        .finally ()->
          toastr.info [
            "You are now "
            vm.me.displayName
            ", role="
            $rootScope.demoRole.toUpperCase()
          ].join('')

      addRoleToUser : (user, event)->
        $auth.waitForUser.then ()->
          return if !user
          if user._id == event.ownerId
            role = 'host'
          else if ~event.participantIds?.indexOf user._id
            role = 'participant'
          else if user._id == '5'
            role = 'booking'
          else if user._id == '6'
            role = 'invitation'
          else
            role = 'visitor'
          user.role = role
          console.info "addRoleToUser(), role="+role
          setFabIcon(event)
    }




    setFabIcon = (event)->
      if hEvents.get().isParticipant(event)
        icon = 'ion-chatbox'
      else
        icon = 'ion-plus'
      vm.settings.show.fabIcon = icon

    vm.on = {

      'favorite': vm.recipeHelpers['favorite']

      scrollTo: (anchor)->
        $location.hash(anchor)
        $ionicScrollDelegate.anchorScroll(true)
        return

      setView: (value)->
        if 'value==null'
          next = if vm.settings.show == 'grid' then 'list' else 'grid'
          return vm.settings.view.show = next
        return vm.settings.view.show = value

      fabClick: ($event)->
        if hEvents.get().isParticipant(vm.event)

          parent = ionic.DomUtil.getParentWithClass($event.target, 'event-detail')
          el = parent.querySelector('filtered-feed')
          return vm.feedHelpers.showMessageComposer({target:el})
        else
          return vm.on['beginBooking']($rootScope.currentUser, vm.event)

      'updateSettings': (setting, isPublic)->
        fields = []
        fields.push 'setting' if setting?
        fields.push 'isPublic' if isPublic?
        data = _.pick vm.event, fields
        EventsResource.update(vm.event._id, data).then (result)->
          $log.info "Event updated, result=" + JSON.stringify _.pick result, fields

      # TODO: change params to (event, person)
      # see also: filteredFeed.inviteActions.accept()
      'beginBooking': (person, event)->
        # return AAAHelpers.showSignInRegister('sign-in') if !Meteor.userId()
        return EventActionHelpers.bookingWizard(vm.event)
        .then (participation)->
          return $q.reject('CANCELED') if participation == 'CANCELED'
          return participation
        .then (participation)->
          switch vm.event.type
            when 'progressive-invite'
              participation.head['recipientIds'] = [vm.event.ownerId]
              # invite owner responds to booking request
              participation.head['moderatorIds'] = [vm.event.ownerId]
              participation.head['nextActionBy'] = 'moderator'
              participation.head['isPublic'] = false
              return participation
              break
            when 'kickstarter', 'booking'
              break
            else
              ~["standard"].indexOf(vm.event.type)
              # post Booking/Participation, appears on Moderator's feed
              # return EventActionHelpers.FeedHelpers.post(event, participation, vm)
              participation.head['recipientIds'] = [vm.event.ownerId]
              # event owner responds to booking request
              participation.head['moderatorIds'] = [vm.event.ownerId]
              participation.head['nextActionBy'] = 'moderator'
              participation.head['isPublic'] = false
              return participation
        .then (participation)->
          cont = vm.feedHelpers.postToFeed( participation
          ,{
            onSuccess: ()->
              'skip'
            })
          return participation
        .then (participation)->
          # scroll to Participation in Feed
          # TODO: save participation to Event. see
          # participations = [{
          #   id: Date.now()
          #   ownerId: mi.ownerId
          #   seats: _.random(3) + 1  # random seats for participation
          #   contributions: [contribution]
          #   createdAt: moment(mi.createdAt).add(i, 'hours').toJSON()
          # }]
          return

      'postToFeed': (comment)->
        vm.feedHelpers.postCommentToFeed(comment)
        return $q.when()


      'toggleMap': ($event)->
        # $event.preventDefault()
        $event.stopImmediatePropagation()
        vm.settings.show.hideMap = !vm.settings.show.hideMap
        # if not vm.settings.show.hideMap
        #   $timeout(0).then ()->
        #     # vm.location.gMap.Control.refresh()
        #     console.info "Map refresh called"

      'createInvitation': ($event)->
        vm.event.invitations ?= []
        now = Date.now()
        baseurl =
          if $location.host() == 'localhost'
          then $location.absUrl().split('#').shift()
          else 'http://app.snaphappi.com/foodie.App/'
        vm.event.invitations.push {
          id: now
          owner: $rootScope.currentUser.displayName
          ownerId: $rootScope.currentUser._id
          link: [
            baseurl
            '#/app/invitation/'
            now
          ].join('')
          description: null
          views: 0
        }
        return

      'getShareLink': ()->EventActionHelpers.getShareLink.apply(vm, arguments)
      'showShareLink': ()->EventActionHelpers.showShareLink.apply(vm, arguments)
      'goShareLink': ()->EventActionHelpers.goShareLink.apply(vm, arguments)

      'notReady': (value)->
        toastr.info "Sorry, " + value + " is not available yet"
        return false




    }
    _getByIds = (ids=[])-> return {_id: {$in: ids}}
    callbacks = {
      'Feed':
        onChange: (feed)->
          filtered = $filter('feedFilter')(feed, $rootScope.currentUser)
          return filtered
      'Event':
        onLoad: (event)->
          return $q.when(event)
          .then (event)->
            console.info ["load once for event=", event._id]
            exportDebug.set 'vm', vm
            exportDebug.set 'event', event
            return event

        onChange: (event)->
          ## NOTE: run in onChange because event properties reset on vm.getReactively()
          # eventUtils.mockData(event, vm)

          return $q.when(event)
          .then (event)->
            return $q.reject() if !event
            _lookups = {
              '$$participants': (event)->
                # TODO: get participantIds from event.participations
                participantIds = [event['ownerId']].concat event['participantIds']
                return if !participantIds
                Meteor.users.find(_getByIds(participantIds)).fetch()
              # '$$participations': mcRecipes.find(_getByIds(event['participationIds'])).fetch()
            }
            _.each _lookups, (get,key)->
              vm[key] = get(event)
              return
            return event

          .then (event)->
            if vm.event != event
              console.warn ['vm.event != event, reset']
              vm.event = event

            # render participations/participants
            vm['$$paddedParticipants'] = $filter('eventParticipantsFilter')(event, vm)
            return event
          .then (event)->
            # render Map
            eventUtils.setVisibleLocation(event)
            deviceW = $window.innerWidth < vm.location.GRID_RESPONSIVE_SM_BREAK
            mapOptions = {
              visible: not deviceW
              draggableMap: not deviceW  # can't scroll in mobile view
            }
            promise = vm.location.showOnMap(event, mapOptions)
            return event
          .then (event)->
            # render shareLinks
            if event.isPublic == false || event.settings['isExclusive']
              return event if not hEvents.get().isParticipant(event)
            EventActionHelpers.getShareLinks(event, vm)
            .then (sharelinks)->
              event.shareLinks = sharelinks
            return event
          .then (event)->
            setFabIcon(event)
            # NOTE: $timeout required when using getReactively with deep watch
            $timeout().then ()->
              callbacks['Event'].isRendering = false
            return event

    }

    vm.findOne = (className, id, fields)->
      switch className
        when 'User', 'user'
          collection = Meteor.users
        else
          collName = ['mc' + className + 's'].join('')
          collection = $window[collName]
      return collection.findOne(id)

    initialize = ()->
      $reactive(vm).attach($scope)
      vm.subscribe 'myProfile'
      vm.subscribe 'userProfiles'
      # $ionicView.loaded: called once for EACH cached $ionicView,
      #   i.e. each instance of vm
      vm.subscribe 'myVisibleEvents'
        ,()->
          return [
            { _id: $stateParams.id}
            ,{} # options
          ]
        ,{
          onReady: ()->
            console.info ["EventDetailCtrl subscribe: Events onReady"]
        }

      vm.subscribe 'myEventFeeds'
        ,()->
          eventId = vm.getReactively('eventId')
          myUserId = Meteor.userId()
          params = [
            {
              eventId: eventId
              $or:[
                {'head.isPublic': true}
                {'head.ownerId': myUserId}
                {'head.recipientIds': myUserId}
              ]
            }
            ,{} # paginate options
          ]
          console.log ["subscribe.feed", params]
          return params


      eventTransforms = new ReactiveTransformSvc(vm, callbacks['Event'])


      vm.helpers {
        'event': ()->
          return mcEvents.findOne( vm.getReactively('eventId') )
        '$$host': ()->
          return Meteor.users.findOne( vm.getReactively('event.ownerId') )
        '$$menuItems': ()->
          menuItemIds = vm.getReactively('event.menuItemIds')
          return [] if !menuItemIds
          return mcRecipes.find( { _id: {$in: menuItemIds }} )
        '$$feed': ()->
          return mcFeeds.find({})
      }

      vm.autorun (tracker)->
        event = vm.getReactively('event' , true)
        eventTransforms.onChange(event).catch (err)->console.warn err
        return

      feedTransforms = new ReactiveTransformSvc(vm, callbacks['Feed'])
      vm.autorun (tracker)->
        feed = vm.getReactively('$$feed', true)
        if vm.token
          feed = _.reject feed, {type:"Invitation"}
          feed.unshift(renderInvitationInFeed(vm.token))
        feedTransforms.onChange(feed)
        .then (filteredFeed)->
          vm['$$filteredFeed'] = filteredFeed

    renderInvitationInFeed = (invite)->
      $postHead = {
        ownerId: invite.ownerId
        eventId: invite.target.split(':').pop()
        recipientIds: []
        nextActionBy: 'recipient'
        tokenId: invite._id || invite.id
      }
      if Meteor.userId() != invite.ownerId
        recipientId = Meteor.userId() || $postHead.tokenId
        $postHead.recipientIds.push recipientId

      message = invite.comment ||
        "Welcome! Please accept this invitation to join our event."
      $postBody = {
        "createdAt": new Date()
        "type":"Invitation"
        "status":"new"      # [new, viewed, closed, hide]
        "message": message
        "comments":[]       #$postBody.comments, show msg, regrets here
      }
      post = {
        "type":"Invitation"
        head: $postHead
        body: $postBody
      }

      return post


    activate = ()->
      return $q.when()
      # .then ()->
        # getData()
      .then ()->
        if $state.is('app.invitation')
          if !$stateParams.invitation
            toastr.warning "Sorry, that invitation was not found."
            return $q.reject('MISSING_INVITATION')

          eventId = null
          # BUG: $stateParams.invitation != $state.params.invitation
          return TokensResource.get($stateParams.invitation)
          .then (token)->
            # return $q.reject('INVALID') if !token
            [className, eventId] = token?.target.split(':')
            valid = TokensResource.isValid(token, 'Event', eventId)
            return token if valid
            return $q.reject(valid)
          .then (token)->
            vm.token = token
            return eventId
          .catch (err)->
            if err=='EXPIRED'
              toastr.warning "Sorry, this invitation has expired. " +
              "Please contact the host for another."
            if err=='INVALID'
              toastr.warning "Sorry, this event is by invitation only"
            return $q.reject(err)

        else if $state.is('app.event-detail')
          if !$stateParams.id
            toastr.warning "Sorry, that event was not found."
            return $q.reject('MISSING_ID')
          return $stateParams.id

        else
          toastr.warning "Sorry, something went wrong..."
          return $q.reject('INVALID')

      .catch (err)->
        $rootScope.goBack()
        return $q.reject(err)

      .then (eventId)->
        vm.eventId = eventId
        console.info ["Event.id", eventId]
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return




    # TODO: deprecate
    getData = ()->
      deprecate = "DEPRECATE EventDetailCtrl.getData()"
      throw new Error deprecate

      $q.when()
      .then ()->
        users = UsersResource.query()
        menuItems = IdeasResource.query()
        feed = FeedResource.query()
        return $q.all([users, menuItems, feed])
      .then (result)->
        [users, menuItems, feed] = result
        vm.lookup.users = users
        vm.lookup.menuItems = menuItems
        vm.lookup.feed = feed
      .then ()->
        # $filter('feedFilter')(event,$rootScope.currentUser)
        _.each vm.lookup.feed, (post)->
          # add $$owner to FEED posts
          post.head ?= {}
          post.head.$$owner = _.find(vm.lookup.users, {id: post.head.ownerId})
          if _.isEmpty post.head.recipientIds
            post.head.likes = [_.sample(vm.lookup.users)]

          # chatWith
          if post.head.recipientIds?[0]
            post.head.$$chatWith = _.find(vm.lookup.users, {id: post.head.recipientIds[0]})
          return

    # TODO: deprecate
    activate0 = ()->
      deprecate = "DEPRECATE EventDetailCtrl.activate0()"
      throw new Error deprecate
      # # return $q.reject("ERROR: expecting event._id") if not $stateParams.id
      return devConfig.dataReady
      .then (eventId)->
        vm.event = _.find vm.events, {id: eventId}
        if !$rootScope.demoRole
          $rootScope.demoRole = 'invited'
        return vm.dev.loginByRole(vm.event)
        .then ()->
          vm.dev.addRoleToUser $rootScope.currentUser, vm.event
          $scope.$emit 'user:event-role-changed', null, event
          return event


    resetMaterialMotion = (motion, parentId)->
      className = {
        'fadeSlideInRight': '.animate-fade-slide-in-right'
        'blinds': '.animate-blinds'
        'ripple': '.animate-ripple'
      }
      selector = '{aniClass} .item'.replace('{aniClass}', className[motion] )
      selector = '#'+ parentId + ' ' + selector if parentId?
      angular.element(document.querySelectorAll(selector))
        .removeClass('in')
        .removeClass('done')

    # TODO: deprecate
    $scope.$watch $rootScope.currentUser, (newV)->
      return if !newV
      $rootScope.currentUser.role = null
      vm.dev.addRoleToUser($rootScope.currentUser, vm.event)

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for EventDetailCtrl, $scope.$id=" + e.currentScope.$id
      initialize()


    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for EventDetailCtrl"
      activate()

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')

    $scope.$on 'demo-role:changed', (ev, newV)->
      console.info ['demo-role:changed', newV]
      return if !newV
      # $rootScope.demoRole = newV
      # ev.stopPropagation()
      # ev.preventDefault()
      if vm.event
        return vm.dev.loginByRole(vm.event)
        .then activate

    $scope.$on 'user:event-role-changed', (ev, user, event)->
      return !user
      console.info ['user:event-role-changed', user._id]
      # ev.stopPropagation()
      ev.preventDefault()
      return vm.dev.addRoleToUser()
      .then activate



    loadOnce = ()->
      return if ~$rootScope['loadOnce'].indexOf 'EventDetailCtrl'
      $rootScope['loadOnce'].push 'EventDetailCtrl'
      # load $rootScope listeners only once

    loadOnce()

    return vm  # end EventDetailCtrl


EventDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'uiGmapGoogleMapApi', 'geocodeSvc', 'unsplashItSvc', 'eventUtils'
  '$reactive', 'ReactiveTransformSvc', '$auth'
  'UsersResource', 'EventsResource', 'IdeasResource', 'FeedResource', 'TokensResource'
  'EventActionHelpers', '$filter', 'notificationTemplates', 'FeedHelpers', 'RecipeHelpers'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
