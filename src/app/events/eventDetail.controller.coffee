'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  UsersResource, EventsResource, EventActionHelpers
  utils, devConfig, exportDebug
  )->
    # coffeelint: disable=max_line_length
    FEED = [
      {
        "type":"Participation"
        head:
          "id":"1453967670695"
          "createdAt":"2016-01-28T07:54:30.696Z"
          "eventId":"1"
          "ownerId": "3"
        body:
          "type":"Participation"
          "status":"new"
          "response":"Yes"
          "seats":2
          "message":"Exciting! I'll take 2"
          "attachment":{"id":"2","url":"http://newyork.seriouseats.com/2013/09/how-betony-makes-their-short-ribs.html","title":"How Betony Makes Their Short Ribs","description":"It's rare that a restaurant opening in Midtown causes much of a stir, but with Chef Bryce Shuman—the former executive Sous Chef of Eleven Madison Park—at the helm, it's no surprise that Betony is making waves. This short rib dish is one of those wave-makers.","image":"http://newyork.seriouseats.com/assets_c/2013/08/20130826-264197-behind-the-scenes-betony-short-ribs-29-thumb-625xauto-348442.jpg","extras":{}}
          "location":{"latlon":[42.670053,23.314167],"address":"Blvd \"James Bourchier\" 103, 1407 Sofia, Bulgaria","isCurrentLocation":true}
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
    }

    vm.lookup = {}

    vm.event = {
      menuItems: []
      feed: []
    }

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
        .then (feed)->
          return filterFeed(event, feed)
        .then (filteredFeed)->
          event.feed = filteredFeed

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
          return true if ~post.head.moderatorIds?.indexOf vm.me.id
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
      postComment: ($event, post)->
        target = $event.currentTarget
        # parent = ionic.DomUtil.getParentWithClass(target, 'comment-form')
        # commentField = parent.querySelector('textarea.comment')
        commentField = utils.getChildOfParent(target, 'comment-form', 'textarea.comment')
        return $q.when() if not commentField.value

        return $q.when()
        .then ()->
          #TODO: use head: body: struct
          postComment = {
            $$owner: vm.me
            ownerId: vm.me.id + ''
            createdAt: new Date()
            comment: angular.copy commentField.value
          }
          commentField.value = ''
          return [post, postComment]
        .then (result)->
          [post, postComment] = result
          post.comments ?= []
          post.comments.unshift postComment

    }

    # TODO: make $filter
    filterFeed = (event, feed)->
      feed ?= event.feed
      # check moderator status
      feed = _.reduce feed, (result, post)->
        check = {
          eventId: post.head.eventId == event.id
        }
        switch post.type
          when 'Participation'
            check['status'] = ~['new','pending','accepted'].indexOf(post.body.status)
            check['acl'] = vm.post.acl.isModerator(event, post)
          else
            'skip'
        result.push post if _.reject(check).length == 0
        return result
      , []
      return feed

    getData = ()->
      $q.when()
      .then ()->
        return UsersResource.query()
      .then (users)->
        vm.lookup.users = users
      .then ()->
        return devConfig.getData()
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

      # .then (events)->
      #   # TEST: ui-sref bug, delay until everything is ready
      #   # events = sortEvents(events, vm.filter)
      #   vm.events = events
      #   # toastr.info JSON.stringify( events)[0...50]
      #   return events
      .then (events)->
        vm.events = []
        _.each events, (event)->
          host = _.find(vm.lookup.users, {id: event.ownerId})
          event.$$host = host
          console.warn("TESTDATA: using currentUser as event Moderator")
          event.moderatorId = vm.me.id  # force for demo data
          event.menuItemIds = [0,1,4]
          console.warn("TESTDATA: using random menuItemIds")
          event.$$menuItems = _.map event.menuItemIds, (id)->
            return vm.lookup.menuItems[id]

          # fake data
          # TODO: sum participation.seats
          event.$$participants ?= []
          event.participantIds ?= []

          _.each event.$$menuItems, (mi, i, l)->
            mi.ownerId = i + ''  # assign menuItem.ownerId
            participant = _.find(vm.lookup.users, {id: mi.ownerId})
            mi.$$owner = participant
            event.participantIds.push participant.id
            event.$$participants.push( mi.$$owner )
            return
          event.seatsOpen = event.seatsTotal - event.participantIds.length
          event.$$participants = _.unique(event.$$participants)
          event.participantIds = _.unique(event.participantIds)

          vm.events.push event
          return
        return events





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
        comment.type = "Comment"
        return EventActionHelpers.FeedHelpers.post(vm.event, comment, vm)
        .then ()->
          console.log ['postToFeed', post]
          # reset message-console and hide
          vm.feed.show.messageComposer = false
          vm.feed.post={}


    }

    initialize = ()->
      return viewLoaded = $q.when()
      .then ()->
        if $rootScope.user?
          vm.me = $rootScope.user
        else
          DEV_USER_ID = '1'
          devConfig.loginUser( DEV_USER_ID ).then (user)->
            # loginUser() sets $rootScope.user
            vm.me = $rootScope.user
            toastr.info "Login as userId=0"
            return vm.me
      .then ()->
        getData()


    activate = ()->
      return $q.reject("ERROR: expecting event.id") if not $stateParams.id
      return $q.when()
      .then ()->
        index = $stateParams.id
        vm.event = vm.events[index]
        return vm.event
      .then (event)->
        event.feed = filterFeed(event, FEED)
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
  'UsersResource', 'EventsResource', 'EventActionHelpers'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
