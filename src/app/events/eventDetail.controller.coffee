'use strict'

EventDetailCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc
  EventsResource, EventActionHelpers
  utils, devConfig, exportDebug
  )->
    # coffeelint: disable=max_line_length
    FEED = [
      {
        "type":"Participation"
        "id":"1453967670695"
        "createdAt":"2016-01-28T07:54:30.696Z"
        "owner":{"firstname":"Masie","lastname":"May","username":"maymay","displayName":"maymay","face":"http://lorempixel.com/200/200/people/0","id":"0"}
        "eventId":"0"
        "participantId":"0"
        "response":"Yes"
        "seats":2
        "message":"Exciting! I'll take 2"
        "attachment":{"id":"2","url":"http://newyork.seriouseats.com/2013/09/how-betony-makes-their-short-ribs.html","title":"How Betony Makes Their Short Ribs","description":"It's rare that a restaurant opening in Midtown causes much of a stir, but with Chef Bryce Shuman—the former executive Sous Chef of Eleven Madison Park—at the helm, it's no surprise that Betony is making waves. This short rib dish is one of those wave-makers.","image":"http://newyork.seriouseats.com/assets_c/2013/08/20130826-264197-behind-the-scenes-betony-short-ribs-29-thumb-625xauto-348442.jpg","extras":{}}
        "location":{"latlon":[42.670053,23.314167],"address":"Blvd \"James Bourchier\" 103, 1407 Sofia, Bulgaria","isCurrentLocation":true}
      }
      {
        "type":"Comment",
        "id":"1453991861983",
        "createdAt":"2016-01-28T14:37:41.983Z",
        "owner":{"firstname":"Marky","lastname":"Mark","username":"marky","displayName":"marky","face":"http://lorempixel.com/200/200/people/1","id":"1"}
        "eventId":"0",
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
    }

    vm.feed = {
      showMessageComposer: ($event)->
        return
    }

    # TODO: make directive
    vm.post = {
      acl : {
        isModerator: (event, post)->
          return true if event.owner = vm.me
      }
      showCommentForm: ($event)->
        target = $event.currentTarget;
        parent = ionic.DomUtil.getParentWithClass(target,'item-post')
        $wrap = angular.element parent.querySelector('.post-comments')
        $wrap.removeClass('hide')
        $timeout().then ()->
          textbox = $wrap[0].querySelector('textarea.comment')
          textbox.focus()
          textbox.scrollIntoViewIfNeeded()
      postComment: ($event, post)->
        target = $event.currentTarget
        return if not target.value
        postComment = {
          owner: vm.me
          createdAt: new Date()
          comment: angular.copy target.value
        }
        target.value = ''
        return $q.when([post, postComment])
        .then (result)->
          [post, postComment] = result
          post.comments ?= []
          post.comments.unshift postComment

    }

    getData = ()->
      vm.event.menuItems = []
      $q.when()
      .then ()->
        return EventsResource.query()
        .then (events)->
          # events = sortEvents(events, vm.filter)
          vm.events = events
          # toastr.info JSON.stringify( events)[0...50]
          return events
      .then ()->
        return devConfig.getData()
      .then (data)->
        vm.lookup.menuItems = _.chain data
          .reduce (result, o, i)->
            if ~[0,1,4].indexOf(i)
              o.id = i
              result.push o
            return result
          , []
          .value()
        return data

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
        .then (result)->
          result.type = "Participation"
          return EventActionHelpers.post(event, result, vm)

    }

    initialize = ()->
      return viewLoaded = $q.when()
      .then ()->
        if $rootScope.user?
          vm.me = $rootScope.user
        else
          DEV_USER_ID = '0'
          devConfig.loginUser( DEV_USER_ID ).then (user)->
            # loginUser() sets $rootScope.user
            vm.me = $rootScope.user
            toastr.info "Login as userId=0"
            return vm.me
      .then ()->
        getData()

    activate = ()->
      if index = $stateParams.id
        vm.event = vm.events[index]
        vm.event.menuItems = vm.lookup.menuItems
        vm.event.feed = FEED
        exportDebug.set('event', vm.event)
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
  'EventsResource', 'EventActionHelpers'
  'utils', 'devConfig', 'exportDebug'
]


angular.module 'starter.events'
  .controller 'EventDetailCtrl', EventDetailCtrl
