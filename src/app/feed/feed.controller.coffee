'use strict'

# angular-meteor controller notes
#
#
### lifecycle:
  vm.feedId will trigger
    -> vm.getReactively('feedId')
    -> vm.helpers()
    -> vm.feed
###
FeedCtrl = (
  $scope, $rootScope, $stateParams, $q, $window
  $reactive, ReactiveTransformSvc, $auth
  $filter, $ionicHistory, $state
  feedHelpers, postHelpers
  exportDebug
  )->
    # add angular-meteor reactivity
    $reactive(this).attach($scope)
    global = $window
    vm = this

    vm.title = 'Feed'
    vm.feedId = null
    vm.feedHelpers = feedHelpers
    vm.postHelpers = postHelpers



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

          filtered = $filter('eventFeedFilter')(feed, $rootScope.currentUser)
          return filtered
    }

    feedTransforms = new ReactiveTransformSvc(vm, callbacks['Feed'])

    # TODO: move to Meteor Collection service
    vm.findOne = (className, id, fields)->
      switch className
        when 'User', 'user'
          collection = Meteor.users
        else
          collName = ['mc' + className + 's'].join('')
          collection = global[collName]
      return collection.findOne(id)

    initialize = ()->
      exportDebug.set('vm', vm)
      vm.subscribe 'userProfiles'
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
            ]
          }
          ,{} # paginate options
        ]
        console.log ["subscribe.feed", params]
        return params

      vm.helpers {
        'feed': ()->
          # NOTE: vm.getReactively('feedId') -> vm.feed
          return global['mcFeeds'].find( {'head.eventId': vm.getReactively('feedId')} )
      }

      vm.autorun (tracker)->
        feed = vm.getReactively('feed', true)
        feedTransforms.onChange(feed)
        .then (filteredFeed)->
          vm['$$filteredFeed'] = filteredFeed



    activate = ()->  # rename to render?
      if !$stateParams.id
        $rootScope.goBack()
        return $q.reject('MISSING_FEED_ID')
      return $q.when $stateParams.id
        .then (feedId)->
          # NOTE: vm.feedId -> vm.getReactively('feedId') -> vm.helpers()
          vm.feedId = feedId

    vm.on = {
      gotoEvent: ($event)->
        $ionicHistory.nextViewOptions({
          disableBack: true
        })
        $state.go('app.event-detail', {id: vm.feedId}) # same as eventId
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
  'feedHelpers', 'postHelpers'
  'exportDebug'
]

FeedHelpers = (
  $timeout
)->
  self = {
    postDefaults: {}
    show:
      messageComposer: false
    showMessageComposer: ($event, event, post)->
      # template for post.body
      # for post.head: {} # see: FeedHelpers.post()
      self.postDefaults = {
        message: null
        attachment: null
        address: null
        location: null
      }
      self.show.messageComposer = true
      parent = ionic.DomUtil.getParentWithClass($event.target, 'event-feed')
      $timeout().then ()->
        textbox = parent.querySelector('message-composer textarea')
        textbox.focus()
        textbox.scrollIntoViewIfNeeded()
      return
  }
  return self

FeedHelpers.$inject = ['$timeout']

PostHelpers = (
  $timeout, utils
)->
  self = {
    showCommentForm: ($event, post)->
      return if post.type == 'Notification'
      target = $event.currentTarget
      $wrap = angular.element utils.getChildOfParent(target, 'item-post', '.post-comments')
      $wrap.toggleClass('hide')
      return if $wrap.hasClass('hide')
      $timeout().then ()->
        textbox = $wrap[0].querySelector('textarea.comment')
        textbox.focus()
        textbox.scrollIntoViewIfNeeded()

    dismissItem: ($event, post)->
      me = Meteor.user()
      return post.dismiss?( me )
      # post.head['dismissedBy'] ?= []
      # post.head['dismissedBy'].push $rootScope.currentUser._id
      # return FeedResource.update(post._id, post)
      # .then (result)->
      #   # TODO: animate offscreen before removal
      #   found = _.findIndex vm.$$feed, {id: result._id}
      #   vm.$$feed[found] = result if ~found
      #   $rootScope.$emit 'event:feed-changed', vm.event, $rootScope.currentUser
      #   return

    like: ($event, post)->
      me = Meteor.user()
      return post.like?( me )
      # post.head.likes ?= []
      # #TODO: should add Ids to the array, not object
      # found = post.head.likes.indexOf($rootScope.currentUser)
      # if ~found
      #   post.head.likes.splice(found,1) # unlike
      # else
      #   post.head.likes.push($rootScope.currentUser)


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
            ownerId: from._id + ''
            $$owner: from
            target: # parent post for this comment
              id: post.head._id
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
  return self

PostHelpers.$inject = ['$timeout', 'utils']

angular.module 'starter.feed'
  .factory 'feedHelpers', FeedHelpers
  .factory 'postHelpers', PostHelpers
  .controller 'FeedCtrl', FeedCtrl
