'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  uiGmapGoogleMapApi, geocodeSvc, unsplashItSvc, eventUtils
  $reactive, ReactiveTransformSvc, $auth
  UsersResource, EventsResource, IdeasResource, FeedResource, TokensResource
  EventActionHelpers, $filter, notificationTemplates
  utils, devConfig, exportDebug
  )->
    # coffeelint: disable=max_line_length
    # coffeelint: enable=max_line_length
    $reactive(this).attach($scope)
    vm = this
    vm.title = "Event Detail"
    vm.viewId = ["event-detail-view",$scope.$id].join('-')
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.currentUser
      isUser: ()->
        return true if $rootScope.currentUser

    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        'hideDetails': false
        'hideMap':true
        'hideParticipants': false
        'hideInvitations': false
        'hideControlPanel': true
        'fabIcon': 'ion-plus'
    }

    vm.lookup = {
      colors: ['royal', 'positive', 'calm', 'balanced', 'energized', 'assertive']
    }

    vm.event = {}

    vm.isInvitation = ()->
      return !!$state.params.invitation

    isInvitationRequired = (event)->
      return $q.when()
      .then ()->
        return true if $state.is('app.event-detail.invitation')
        if event.setting['isExclusive'] || $state.params.invitation
          return TokensResource.isValid($state.params.invitation, 'Event', event.id)
      .catch (result)->
        $log.info "Token check, value="+result
        toastr.info "Sorry, this event is by invitation only." if result=='INVALID'
        if result=='EXPIRED'
          toastr.warning "Sorry, this invitation has expired. Please contact the host for another."
        return $q.reject(result)

    vm.inviteActions = {
      requiresAction: (post, event, me)->
        event ?= vm.event
        me ?= $rootScope.currentUser
        check = {
          type: post.type == 'Invitation'
          status: ~['new', 'viewed'].indexOf(post.body.status)
        }
        nextAction = post.head.nextActionBy
        switch nextAction
          when 'owner'
            check['nextAction'] = me && event.$$owner == me
            # check['nextAction'] = me && ~event.moderatorIds.indexOf me.id
          when 'recipient'
            check['nextAction'] = me && ~post.head.recipientIds.indexOf me.id
        return _.reject(check).length == 0

      accept: ($event, event, invitation)->
        return $q.when()
        .then ()->
          return if invitation.type != 'Invitation'

          invitation.body.status='viewed'
          return invitation
        .then (invitation)->
          return vm.on.beginBooking($rootScope.currentUser, event)
        .then (participation)->
          return if !participation
          invitation.body.status='closed'
          invitation.body.response = 'accepted'
          # append a log as a comment to invitation
          invitation.body.seats = participation.body.seats
          return vm.inviteActions._logAction(event, invitation, vm)
          .then (invitation)->
            target = $event.target
            $wrap = angular.element utils.getChildOfParent(target, 'item-post', '.post-comments')
            $wrap.removeClass('hide')
          .then (invitation)->
            toastr.info("DEMO: invitation responses will be automatically accepted.")
            return $timeout(3000)
          .then ()->
            # TODO: need to change ParticipationResponse.head.ownerId
            vm.moderatorActions.accept($event, event, participation)


      message: ($event, event, invitation)->
        return $q.when()
        .then ()->
          invitation.body.status='viewed'
          return vm.postActions.showCommentForm($event)

      decline: ($event, event, invitation)->
        return $q.when()
        .then ()->
          return if invitation.type != 'Invitation'

          invitation.body.status='closed'
          invitation.body.response = 'declined'
          # append a log as a comment to invitation
          return vm.inviteActions._logAction(event, invitation, vm)
        .then (result)->
          message = notificationTemplates.get('invitation.declined.ownerId', invitation)
          notify = {
            ownerId: invitation.head.ownerId
            # role: 'participants'
            message: message
          }
          return EventActionHelpers.FeedHelpers.notify(event, notify, vm)

          # # show Post.comments
          # target = $event.target
          # $wrap = angular.element utils.getChildOfParent(target, 'item-post', '.post-comments')
          # $wrap.removeClass('hide')


      _logAction: (event, invitation, vm)->
        options = {
          log: true
          message: [
            $rootScope.currentUser.profile.displayName
            'has', invitation.body.response
          ]
        }
        switch invitation.body.response
          when 'declined'
            options.message.push 'this invitation.'
          when 'accepted'
            options.message = options.message.concat [
              'this invitation, and requested'
              invitation.body.seats
              'seats.'
            ]
          else
            return

        # TODO set 'moderatorIds' to new participantId
        #   log/add notification to feed (dismissable), '[person] accepted your invitation'
        return vm.postActions.postComment(null, invitation, options)



    }

    vm.moderatorActions = {
      requiresAction: (post, event, me)->
        event ?= vm.event
        me ?= $rootScope.currentUser
        check = {
          type: post.type == 'Participation'
          status: ~['new', 'pending'].indexOf(post.body.status)
          response: ~['Yes','Message'].indexOf post.body.response
        }

        nextAction = post.head.nextActionBy
        switch nextAction
          when 'moderator', 'owner'
            check['nextAction'] = me && event.ownerId == me.id
            check['nextAction'] = me && ~event.moderatorIds.indexOf me.id
          when 'recipient'
            check['nextAction'] = me && ~post.head.recipientIds.indexOf me.id
        return _.reject(check).length == 0

      accept: ($event, event, participation)->
        return $q.when()
        .then ()->
          return if participation.type != 'Participation'

          participation.body.status='accepted'
          return participation
        .then (participation)->
          # update event to include participation
          return EventActionHelpers.createBooking(event, participation, vm)
        .then (event)->
          $scope.$emit 'user:event-role-changed', participation.head.$$owner, event
          return vm.moderatorActions._logAction(event, participation, vm)
        .then ()->
          promises = []
          notify = {
            ownerId: participation.head.ownerId
            message: notificationTemplates.get('booking.accepted.ownerId', participation)
          }
          if _.isEmpty participation.body.attachment
            notify.message = [
              notify.message
              '<br /><br />'
              notificationTemplates.get('event.contributions.reminder', participation)
            ]
          promises.push notifyNewBooking = EventActionHelpers.FeedHelpers.notify(event, notify, vm)

          notify = {
            ownerId: event.ownerId
            # role: 'participants'
            recipientIds: _.difference event.participantIds, [participation.head.ownerId]
            message: notificationTemplates.get('booking.accepted.participantIds', participation)
            contribution: participation.body.attachment
          }
          if not _.isEmpty participation.body.attachment
            notify.message = [
              notify.message
              '<br /><br />'
              notificationTemplates.get('event.contributions.notify', participation)
            ]
          promises.push notifyOthers = EventActionHelpers.FeedHelpers.notify(event, notify, vm)

          return $q.all(promises)
          .then ()->
            if event.seatsOpen > 0
              event.moderatorIds = [participation.head.ownerId]
              post = {
                ownerId: participation.head.ownerId
                displayName: participation.head.$$owner.displayName
                seatsOpen: event.seatsOpen
                toNow: moment(event.startTime).fromNow()
              }

              if event.setting.isExclusive
                shareTemplate = 'event.booking.sendInvites'
                vm.settings.show.hideInvitations = false
              else
                shareTemplate = 'event.booking.shareEvent'
              post.message = notificationTemplates.get(shareTemplate, post)
              promises.push share = EventActionHelpers.FeedHelpers.notify(event, post, vm)
            else
              post = {
                hostName: event.$$host.displayName
                role: 'participants'
              }
              post.message = notificationTemplates.get('event.booking.fullyBooked', post)
              promises.push fullyBooked = EventActionHelpers.FeedHelpers.notify(event, post, vm)
            return $q.all(promises)

      message: ($event, event, participation)->
        return $q.when()
        .then ()->
          participation.body.status='pending'
          return vm.postActions.showCommentForm($event)

      decline: ($event, event, participation)->
        return $q.when()
        .then ()->
          return if participation.type != 'Participation'

          participation.body.status='declined'
          # update participation, post to Server
          return participation
        .then (participation)->
          return vm.moderatorActions._logAction(event, participation, vm)
        .then ()->
          notify = {
            ownerId: participation.head.ownerId
            # role: 'participants'
            message: notificationTemplates.get('booking.decline.ownerId', participation)
          }
          return EventActionHelpers.FeedHelpers.notify(event, notify, vm)

      _logAction: (event, participation, vm)->
        # log ParticipationResponse
        action = {
          head:
            ownerId: $rootScope.currentUser._id
          body:
            type: 'ParticipationResponse'
            action: participation.body.status  # ['accepted', 'declined']
            participationId: participation.id
            $$participation: participation
            comment: ''
        }
        if participation.body.status=='declined'
          # make rejected private (Notification?)
          action.head['recipientIds'] = [participation.head.ownerId]
        $scope.$emit 'event:feed-changed', [event, action]
        return EventActionHelpers.FeedHelpers.log(event, action, vm)

    }

    vm.feed = {
      postDefaults: {}
      show:
        messageComposer: false
      showMessageComposer: ($event, event, post)->
        # template for post.body
        # for post.head: {} # see: FeedHelpers.post()
        this.postDefaults = {
          message: null
          attachment: null
          address: null
          location: null
        }
        this.show.messageComposer = true
        parent = ionic.DomUtil.getParentWithClass($event.target, 'event-detail')
        $timeout().then ()->
          textbox = parent.querySelector('message-composer textarea')
          textbox.focus()
          textbox.scrollIntoViewIfNeeded()
        return
    }

    # TODO: make directive
    vm.postActions = {
      acl : {
        isModerator: (event, post)->
          return true if ~event.moderatorIds.indexOf $rootScope.currentUser._id
          return true if post.head.moderatorIds? &&
            ~post.head.moderatorIds.indexOf $rootScope.currentUser._id
          return true if event.ownerId == $rootScope.currentUser._id
          # console.info "DEMO: isModerator() == true"
          # return true
      }
      dismissItem: ($event, item)->
        item.head['dismissedBy'] ?= []
        item.head['dismissedBy'].push $rootScope.currentUser._id
        return FeedResource.update(item.id, item)
        .then (result)->
          # TODO: animate offscreen before removal
          found = _.findIndex vm.event.feed, {id: result.id}
          vm.event.feed[found] = result if ~found
          $rootScope.$emit 'event:feed-changed', vm.event, $rootScope.currentUser

          return
      like: ($event, post)->
        post.head.likes ?= []
        #TODO: should add Ids to the array, not object
        found = post.head.likes.indexOf($rootScope.currentUser)
        if ~found
          post.head.likes.splice(found,1) # unlike
        else
          post.head.likes.push($rootScope.currentUser)

      showCommentForm: ($event)->
        target = $event.currentTarget
        # parent = ionic.DomUtil.getParentWithClass(target,'item-post')
        # $wrap = angular.element parent.querySelector('.post-comments')
        $wrap = angular.element utils.getChildOfParent(target, 'item-post', '.post-comments')
        $wrap.toggleClass('hide')
        return if $wrap.hasClass('hide')
        $timeout().then ()->
          textbox = $wrap[0].querySelector('textarea.comment')
          textbox.focus()
          textbox.scrollIntoViewIfNeeded()

      ###
      # @description Post comment to a Feed Post
      # @params options Obj, {log:boolean, message:String}
      ###
      postComment: ($event, post, options)->
        if !options
          target = $event.currentTarget
          # parent = ionic.DomUtil.getParentWithClass(target, 'comment-form')
          # commentField = parent.querySelector('textarea.comment')
          commentField = utils.getChildOfParent(target, 'comment-form', 'textarea.comment')
          comment = angular.copy commentField.value
        else
          comment = options.message
          comment = comment.join(' ') if _.isArray comment

        return $q.when() if not comment

        return $q.when()
        .then ()->
          from = $rootScope.currentUser
          if options?['log'] == true
            # TODO: ???: has post from syslog("feed") been replaced by "Notifications"?
            from = {
              id: 'syslog'
              displayName: 'feed:'
              face: unsplashItSvc.getImgSrc(0,'syslog',{face:true})
            }

          postComment = {
            type: "PostComment"
            head:
              id: Date.now()
              ownerId: from.id + ''
              $$owner: from
              target: # parent post for this comment
                id: post.head.id
                class: post.type
              createdAt: new Date()
              likes: []
            body:
              comment: comment
          }
          if commentField?
            commentField.value = ''
          return [post, postComment]
        .then (result)->
          [post, postComment] = result
          post.body.comments ?= []
          post.body.comments.push postComment
          return post
    }

    vm.location = {
      GRID_RESPONSIVE_SM_BREAK: 680
      gMap:  # controls
        Control: {}
        MarkersControl: {}
      map: null
      prepareMap: (event, options)->
        markerLoc = event.visible?.marker || event.location
        return $q.when() if !markerLoc

        return uiGmapGoogleMapApi
        .then ()->
          # markerCount==1
          mapOptions = {
            type: 'oneMarker'
            location: markerLoc
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
            vm.me.profile.displayName
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
          setFabIcon()
    }




    setFabIcon = ()->
      vm.settings.show.fabIcon = 'ion-load-d' if !$rootScope.currentUser

      icon = null
      switch $rootScope.currentUser?.role
        when 'host', 'participant', 'booking'
          # edit event
          icon = 'ion-chatbox'
        when 'invitation','visitor'
          # join
          icon = 'ion-plus'
      # console.log ["FabIcon=" + icon, $rootScope.currentUser.role]
      vm.settings.show.fabIcon = icon



    vm.on = {
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
        switch $rootScope.currentUser.role
          when 'host', 'participant', 'booking'
            # edit event
            return vm.feed.showMessageComposer($event)

          when 'invitation','visitor'
            # join
            return vm.on['beginBooking']($rootScope.currentUser, vm.event)
        return

      'updateSettings': (setting, isPublic)->
        fields = []
        fields.push 'setting' if setting?
        fields.push 'isPublic' if isPublic?
        data = _.pick vm.event, fields
        EventsResource.update(vm.event.id, data).then (result)->
          $log.info "Event updated, result=" + JSON.stringify _.pick result, fields

      # TODO: change params to (event, person)
      'beginBooking': (person, event)->
        return EventActionHelpers.bookingWizard(person, event, vm)
        .then (participation)->
          return if participation == 'CANCELED'
          return EventActionHelpers.FeedHelpers.post(event, participation, vm)
        .then (participation)->
          return participation

      'postCommentToFeed': (comment)->
        data = {
          type: 'Comment'
          head:
            isPublic: true
          body: comment
        }
        return EventActionHelpers.FeedHelpers.post(vm.event, data, vm)
        .then ()->
          console.log ['postToFeed', comment]
          # reset message-console and hide
          vm.feed.show.messageComposer = false
          vm.feed.post={}

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
          owner: $rootScope.currentUser.profile.displayName
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

    callbacks = {
      'Event':
        onLoad: (event)->
          return $q.when(event)
          .then (event)->
            console.info ["load once for event=", event._id]
            eventUtils.mockData(event, vm)
            exportDebug.set 'vm', vm
            exportDebug.set 'event', event
            return event

        onChange: (event)->
          return $q.when(event)
          .then (event)->
            _getByIds = (ids)-> return {_id: {$in: ids}}
            _lookups = {
              '$$participants': (event)->
                participantIds = [event['ownerId']].concat event['participantIds']
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
            # mockData depends on vm.$$menuItems
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
            if event.isPublic == false || event.setting.isExclusive
              return event if not event.isParticipant()
            EventActionHelpers.getShareLinks(event, vm)
            .then (sharelinks)->
              event.shareLinks = sharelinks
            return event
          .then (event)->
            # NOTE: $timeout required when using getReactively with deep watch
            $timeout().then ()->
              callbacks['Event'].isRendering = false
            return event

    }



    initialize = ()->
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

      eventTransforms = new ReactiveTransformSvc(vm, callbacks['Event'])

      _getByIds = (ids)-> return {_id: {$in: ids}}
      vm.helpers {
        'event': ()->
          return mcEvents.findOne( vm.getReactively('eventId') )
        '$$host': ()->
          return Meteor.users.findOne( vm.getReactively('event.ownerId') )
        '$$menuItems': ()->
          menuItemIds = vm.getReactively('event.menuItemIds')
          return [] if !menuItemIds
          return mcRecipes.find( { _id: {$in: menuItemIds }} )
      }

      vm.autorun (tracker)->
        event = vm.getReactively('event' , true)
        eventTransforms.onChange(event)
        return


    activate = ()->
      return $q.when()
      .then ()->
        getData()
      .then ()->
        if $state.is('app.event-detail.invitation')
          if !$stateParams.invitation
            toastr.warning "Sorry, that invitation was not found."
            return $q.reject('MISSING_INVITATION')

          eventId = null
          # BUG: $stateParams.invitation != $state.params.invitation
          return TokensResource.get(stateParams.invitation)
          .then (token)->
            # return $q.reject('INVALID') if !token
            [className, eventId] = token?.target.split(':')
            return TokensResource.isValid(token, 'Event', eventId)
          .then ()->
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
        # return vm['event'] = mcEvents.findOne(eventId)
        # get event from eventId
        # return vm.eventId = eventId
      .then ()->
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return





    getData = ()->
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
        # $filter('eventFeedFilter')(event,$rootScope.currentUser)
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

    activate0 = ()->
      # # return $q.reject("ERROR: expecting event.id") if not $stateParams.id
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
      console.info ['user:event-role-changed', user.id]
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
  'EventActionHelpers', '$filter', 'notificationTemplates'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
