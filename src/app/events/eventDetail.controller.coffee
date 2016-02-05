'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  uiGmapGoogleMapApi, geocodeSvc
  UsersResource, EventsResource, IdeasResource, EventActionHelpers, $filter
  utils, devConfig, exportDebug
  )->
    # coffeelint: disable=max_line_length
    FEED = [
      {
        "type":"Participation"
        head:
          "id":"1453967670695"
          "createdAt": moment().subtract(23, 'minutes').toJSON()
          "eventId":"1"
          "ownerId": "4"
        body:
          "type":"Participation"
          "status":"new"
          "response":"Yes"
          "seats":2,
          "message":"Exciting. I'll take 2 and bring the White Stork."
          "attachment":
            "id":6
            "url":"http://whitestorkco.com/"
            "title":"White Stork","description":"At White Stork, we are passionate about taste and the need to have more good beer in Bulgaria. After extensive research, testing, tasting, tweaking and experimentation since 2011, we hatched our first Pale Ale in December 2013 and wanted to show you the wonders of the Citra hop in our Summer Pale Ale in July 2014. Although our beers are currently made by our amazing master brewer in Belgium, we are building our brewery in Sofia which will hopefully be operational soon."
            "image":"https://pbs.twimg.com/profile_images/691694111468945408/H8VRdkNg.jpg"
          "address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria",
          "location":{"latlon":[42.69448,23.342364],"address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria"}
      }
      {
        "type":"Comment"
        head:
          "id":"1453991861983",
          "createdAt":"2016-01-28T14:37:41.983Z",
          "ownerId": "0"
          "eventId":"1",
        body:
          "type":"Comment"
          "message":"This is what I've been waiting for. I'm on it.",
          "attachment":{"id":4,"url":"http://www.yummly.com/recipe/My-classic-caesar-318835","title":"My Classic Caesar Recipe","description":"My Classic Caesar Recipe Salads with garlic, anchovy filets, sea salt flakes, egg yolks, lemon, extra-virgin olive oil, country bread, garlic, extra-virgin olive oil, sea salt, romaine lettuce, caesar salad dressing, parmagiano reggiano, ground black pepper, anchovies","image":"http://lh3.ggpht.com/J8bTX6MuGC-8y87DHlxxagqShmJLlPjXff28hN8gksOpLp3fZJ5XaLCGrkZLYMer3YlNAEoOfl6FyrSsl9uGcw=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:course":"Salads","yummlyfood:ingredients":"anchovies","yummlyfood:time":"40 min","yummlyfood:source":"Food52"},"$$hashKey":"object:258"},
          "location":null
      }
    ]
    # coffeelint: enable=max_line_length

    viewLoaded = null   # promise

    vm = this
    vm.title = "Event Detail"
    vm.me = null      # current user, set in initialize()
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
      show:
        'expandEventDetails': false
        'map':false
    }

    vm.lookup = {}

    vm.event = {}

    vm.moderator = {
      requiresAction: (participation)->
        check = {
          type: participation.type == 'Participation'
          status: ~['new', 'pending'].indexOf(participation.body.status)
          response: participation.body.response == 'Yes'
        }
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
          return vm.moderator._logAction(event, participation, vm)

      reject: ($event, event, participation)->
        return $q.when()
        .then ()->
          return if participation.type != 'Participation'

          participation.body.status='rejected'
          # update participation, post to Server
          return participation
        .then (participation)->
          return vm.moderator._logAction(event, participation, vm)

      _logAction: (event, participation, vm)->
        # log ParticipationResponse
        action = {
          head:
            reviewerId: vm.me.id
          body:
            type: 'ParticipationResponse'
            action: participation.body.status  # ['accepted', 'rejected']
            participationId: participation.id
            $$participation: participation
            comment: ''
        }
        $scope.$emit 'event:feed-changed', [event, action]
        return EventActionHelpers.FeedHelpers.log(event, action, vm)
        # .then (feed)->
        #   return event.feed = $filter('feedFilter')(event, FEED)

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
        return
    }

    # TODO: make directive
    vm.post = {
      acl : {
        isModerator: (event, post)->
          return true if event.moderatorId == vm.me.id
          return true if post.head.moderatorIds? && ~post.head.moderatorIds.indexOf vm.me.id
          return true if event.ownerId == vm.me.id
      }
      like: ($event, post)->
        post.head.likes ?= []
        #TODO: should add Ids to the array, not object
        found = post.head.likes.indexOf(vm.me)
        if ~found
          post.head.likes.splice(found,1) # unlike
        else
          post.head.likes.push(vm.me)

      showCommentForm: ($event)->
        target = $event.currentTarget
        # parent = ionic.DomUtil.getParentWithClass(target,'item-post')
        # $wrap = angular.element parent.querySelector('.post-comments')
        $wrap = angular.element utils.getChildOfParent(target, 'item-post', '.post-comments')
        $wrap.removeClass('hide')
        $timeout().then ()->
          textbox = $wrap[0].querySelector('textarea.comment')
          textbox.focus()
          textbox.scrollIntoViewIfNeeded()

      ###
      # @description Post comment to a Feed Post
      ###
      postComment: ($event, post)->
        target = $event.currentTarget
        # parent = ionic.DomUtil.getParentWithClass(target, 'comment-form')
        # commentField = parent.querySelector('textarea.comment')
        commentField = utils.getChildOfParent(target, 'comment-form', 'textarea.comment')
        return $q.when() if not commentField.value

        return $q.when()
        .then ()->
          postComment = {
            type: "PostComment"
            head:
              id: Date.now()
              ownerId: vm.me.id + ''
              $$owner: vm.me
              target:
                id: post.head.id
                class: post.type
              createdAt: new Date()
              likes: []
            body:
              comment: angular.copy commentField.value
          }
          commentField.value = ''
          return [post, postComment]
        .then (result)->
          [post, postComment] = result
          post.body.comments ?= []
          post.body.comments.unshift postComment

    }

    vm.location = {
      GRID_RESPONSIVE_SM_BREAK: 680
      map: null
      prepareMap: (event, options)->
        return $q.when() if !event.location

        return uiGmapGoogleMapApi
        .then ()->
          # markerCount==1
          mapOptions = {
            type: 'oneMarker'
            location: event.location
            draggableMarker: false
            dragendMarker: (marker, eventName, args)->
              return
          }
          mapOptions = _.extend mapOptions, {
            'control' : {}
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
          vm.settings.show.map = true if options.visible
          exportDebug.set 'mapConfig', config
          return

    }

    loginByRole = (event)->
      userId = null
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
        return user
      .finally ()->
        toastr.info [
          "You are now "
          vm.me.displayName
          ", role="
          $rootScope.demoRole.toUpperCase()
        ].join('')


    getData = ()->
      $q.when()
      .then ()->
        return UsersResource.query()
      .then (users)->
        vm.lookup.users = users
      .then ()->
        return IdeasResource.query()
      .then (data)->
        vm.lookup.menuItems = data
      .then ()->
        _.each FEED, (post)->
          # add $$owner to FEED posts
          post.head ?= {}
          post.head.$$owner = _.find(vm.lookup.users, {id: post.head.ownerId})
          post.head.likes = [_.sample(vm.lookup.users)]
          return
      .then ()->
        return EventsResource.query()
      .then (events)->
        vm.events = []
        _.each events, (event, i)->
          console.warn("TESTDATA: using currentUser as event Moderator")
          event.visibleAddress = event.address
          event.isPostModerator = vm.post.acl.isModerator
          event.moderatorId = event.ownerId
          vm.events.push event
          return
        return events

    addRoleToUser = ()->
      return devConfig.dataReady.finally ()->
        return if !vm.event.participantIds
        if vm.me.id == vm.event.ownerId
          role = 'host'
        else if ~vm.event.participantIds.indexOf vm.me.id
          role = 'participant'
        else if vm.me.id == '5'
          role = 'booking'
        else if vm.me.id == '6'
          role = 'invitation'
        else
          role = 'visitor'
        vm.me.role = role
        console.log "addRoleToUser(), role="+role




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

      'beginBooking': (person, event)->
        return EventActionHelpers.bookingWizard(person, event, vm)
        .then (participation)->
          return if participation == 'CANCELED'
          return EventActionHelpers.FeedHelpers.post(event, participation.body, vm)

      'postCommentToFeed': (comment)->
        data = {
          type: 'Comment'
          body: comment
        }
        return EventActionHelpers.FeedHelpers.post(vm.event, data, vm)
        .then ()->
          console.log ['postToFeed', comment]
          # reset message-console and hide
          vm.feed.show.messageComposer = false
          vm.feed.post={}
      'toggleMap': ($event)->
        $event.preventDefault()
        event.stopImmediatePropagation()
        vm.settings.show.map = !vm.settings.show.map

        # console.log ['toggleMap', vm.settings.show.map]
      notReady: (value)->
        toastr.info "Sorry, " + value + " is not available yet"
        return false


    }

    initialize = ()->
      return viewLoaded = $q.when()
      .then ()->
        if $rootScope.user?
          vm.me = $rootScope.user
        else
          DEV_USER_ID = '5'
          devConfig.loginUser( DEV_USER_ID ).then (user)->
            # loginUser() sets $rootScope.user
            vm.me = $rootScope.user
            toastr.info "Login as userId="+vm.me.id
            return vm.me
      .then ()->
        getData()


    activate = ()->
      return $q.reject("ERROR: expecting event.id") if not $stateParams.id
      return devConfig.dataReady
      .finally ()->
        index = $stateParams.id
        vm.event = vm.events[index]
        loginByRole(vm.event).then addRoleToUser
      .then ()->
        event = vm.event
        event.feed = FEED
        # event.feed = $filter('feedFilter')(event, FEED)
        event.$$paddedParticipants = $filter('eventParticipantsFilter')(event)

        deviceW = $window.innerWidth < vm.location.GRID_RESPONSIVE_SM_BREAK
        mapOptions = {
          visible: not deviceW
          draggableMap: not deviceW  # can't scroll in mobile view
        }
        promise = vm.location.showOnMap(event, mapOptions)
        return event
      .then (event)->
        exportDebug.set('event', event)
        # // Set Ink
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
          })
        return

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

    $rootScope.$on 'demo-role:changed', (ev, newV)->
      return if !newV
      # $rootScope.demoRole = newV
      return loginByRole(vm.event) if vm.event

    $scope.$watch 'vm.me', (newV)->
      return if !newV
      vm.me.role = null
      addRoleToUser()

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for EventDetailCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for EventDetailCtrl"
      return viewLoaded.finally ()->
        activate()

    return vm  # end EventDetailCtrl


EventDetailCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc'
  'uiGmapGoogleMapApi', 'geocodeSvc'
  'UsersResource', 'EventsResource', 'IdeasResource', 'EventActionHelpers', '$filter'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
