'use strict'

# angular-meteor controller notes
#
#
### lifecycle:
  vm.feedId will trigger
    -> vm.getReactively('feedId')
    -> vm.helpers()
    -> vm.$$feed
###
FeedCtrl = (
  $scope, $rootScope, $stateParams, $q, $window
  $reactive, ReactiveTransformSvc, $auth
  $filter, $ionicHistory, $state
  CollectionHelpers, FeedHelpers, PostHelpers
  exportDebug
  eventUtils
  )->
    # add angular-meteor reactivity
    $reactive(this).attach($scope)
    global = $window
    vm = this

    vm.title = 'Feed'
    vm.feedId = null
    vm.collHelpers = new CollectionHelpers(vm)
    vm.feedHelpers = new FeedHelpers(vm)
    vm.postHelpers = new PostHelpers(vm)

    vm.settings = {
      view:
        show: 'grid'
      show:
        fabicon: null
    }


    vm.DEV = {
      resetFeed: ()->
        vm.call 'DEV.Post.resetFeed'
    }

    callbacks = {
      'Feed':
        onLoad: (feed)->
          # initial on ionicView.loaded
          return

        onChange: (feed)->
          # use vm.getReactively() with deep watch
          # handle side-effects on change
          #   i.e. update lookups with multiple dependencies
          # for simple lookups with a single reactive dependency,
          #     use vm.helpers()

          filtered = $filter('feedFilter')(feed, $rootScope.currentUser)
          return filtered
    }

    feedTransforms = new ReactiveTransformSvc(vm, callbacks['Feed'])

    initialize = ()->
      exportDebug.set('vm', vm)
      vm.subscribe 'userProfiles'
      vm.subscribe 'myVisibleEvents' # , {_id: vm.getReactively('feedId')}
      vm.subscribe 'myEventFeeds'
      ,()->
        eventId = vm.getReactively('feedId')
        myUserId = Meteor.userId()
        params = [
          {
            eventId: eventId
            $or:[
              {'head.isPublic': true}
              {'head.ownerId': myUserId}
              {'head.recipientIds': myUserId}
              {'head.moderatorIds': myUserId} # moderators if action required
            ]
          }
          ,{} # paginate options
        ]
        console.log ["subscribe.feed", params]
        return params

      vm.helpers {
        'feed': ()->
          # NOTE: vm.getReactively('feedId') -> vm.$$feed
          return global['mcFeeds'].find( {'head.eventId': vm.getReactively('feedId')} )
        'event': ()->
          return global['mcEvents'].findOne( vm.getReactively('feedId') )

      }

      vm.autorun (tracker)->
        feed = vm.getReactively('feed', true)
        feedTransforms.onChange(feed)
        .then (filteredFeed)->
          vm['$$filteredFeed'] = filteredFeed



      eventTransforms = new ReactiveTransformSvc(vm)
      vm.autorun (tracker)->
        event = vm.getReactively('event' , true)
        eventTransforms.onChange(event)
        .then (event)->
          eventUtils.mockData(event, vm)
          setFabIcon(event)


        return

      return # initialize



    activate = ()->  # rename to render?
      if !$stateParams.id
        $rootScope.goBack()
        return $q.reject('MISSING_FEED_ID')
      return $q.when $stateParams.id
        .then (feedId)->
          # NOTE: vm.feedId -> vm.getReactively('feedId') -> vm.helpers()
          vm.feedId = feedId

    setFabIcon = (event)->
      if EventModel::isParticipant(event)
        icon = 'ion-chatbox'
      else
        icon = 'ion-plus'
      vm.settings.show.fabIcon = icon

    vm.on = {
      gotoEvent: ($event)->
        $ionicHistory.nextViewOptions({
          disableBack: true
        })
        $state.go('app.event-detail', {id: vm.feedId}) # same as eventId

      postToFeed: (comment)->
        vm.feedHelpers.postCommentToFeed(comment)
        return $q.when()    # TODO: fix in message-composer.on.post()

      fabClick: ($event)->
        return vm.feedHelpers.showMessageComposer($event)

    }

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for EventDetailCtrl, $scope.$id=" + e.currentScope.$id
      initialize()


    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for EventDetailCtrl"
      activate()

    return vm


FeedCtrl.$inject = [
  '$scope', '$rootScope', '$stateParams', '$q', '$window'
  '$reactive', 'ReactiveTransformSvc', '$auth'
  '$filter', '$ionicHistory', '$state'
  'CollectionHelpers', 'FeedHelpers', 'PostHelpers'
  'exportDebug'
  'eventUtils'
]


angular.module 'starter.feed'
  # .factory 'CollectionHelpers', CollectionHelpers
  # .factory 'FeedHelpers', FeedHelpers
  # .factory 'PostHelpers', PostHelpers
  .controller 'FeedCtrl', FeedCtrl
