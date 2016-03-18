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
  CollectionHelpers, FeedHelpers, PostHelpers
  exportDebug
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

      postToFeed: (comment)->
        vm.feedHelpers.postCommentToFeed(comment)
        return $q.when()    # TODO: fix in message-composer.on.post()

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
]



CollectionHelpers = (
  $window
)->
  class CollectionHelpersClass
    global = $window
    constructor: (@context)->
      # NOTE: We need @context = vm to make $reactive calls
      return

    # currently not used
    ###
      call in Class::constructor, e.g. bindClassMethods(@,PostHelpersClass,@context)
      usage: vm.postHelpers = new PostHelpers(vm)
    ###
    bindClassMethods = (instance, Class, context)->
      _.each Class.prototype, (v,k)->
        # bind methods to @context
        if _.isFunction(v)
          instance[k] = ()-> return v.apply(context, arguments)
        return
      ,instance

    findOne: (className, id, fields)->
      switch className
        when 'User', 'user'
          collection = Meteor.users
        else
          collName = ['mc' + className + 's'].join('')
          collection = global[collName]
      return collection.findOne(id)

  return CollectionHelpersClass

CollectionHelpers.$inject = ['$window']



FeedHelpers = (
  $timeout
)->
  class FeedHelpersClass
    constructor: (@context)->
      return

    postDefaults: {}
    show:
      messageComposer: false

    showMessageComposer: ($event, event, post)->
      # template for post.body
      # for post.head: {} # see: FeedHelpers.post()
      @postDefaults = {
        message: null
        attachment: null
        address: null
        location: null
      }
      @show.messageComposer = true
      parent = ionic.DomUtil.getParentWithClass($event.target, 'event-feed')
      $timeout().then ()->
        textbox = parent.querySelector('message-composer textarea')
        textbox.focus()
        textbox.scrollIntoViewIfNeeded()
      return

    ###
    # @description  use with directive message-composer
        example(jade): message-composer( post-button="postCommentToFeed(value)" )
    # @return promise
    ###
    postCommentToFeed: (comment)->
      self = @
      post = {
        type: 'Comment'
        head:
          isPublic: true
        body: comment
      }
      @context.call 'Post.postFeedPost', @context.feedId, post, (err, result)->
        return console.warn ['Meteor::postFeedPost WARN', err] if err
        self.show.messageComposer = false
        console.log ['Meteor::postFeedPost OK']


  return FeedHelpersClass

FeedHelpers.$inject = ['$timeout']



PostHelpers = (
  $timeout, utils
)->
  class PostHelpersClass
    constructor: (@context)->
      # bindClassMethods(@,PostHelpersClass,@context)
      return

    dismissItem: ($event, post)->
      # return mcFeeds.helpers.dismiss(post)
      @context.call 'Post.dismiss', post, (err, result)->
        console.warn ['Meteor::dismiss WARN', err] if err
        console.log ['Meteor::dismiss OK']

    like: ($event, post)->
      # return mcFeeds.helpers.toggleLike(post)
      @context.call 'Post.toggleLike', post, (err, result)->
        console.warn ['Meteor::toggleLike WARN', err] if err
        console.log ['Meteor::toggleLike OK']

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

      return if not comment

      if options?['log'] == true
        # TODO: ???: has post from syslog("feed") been replaced by "Notifications"?
        from = {
          id: 'syslog'
          displayName: 'feed:'
          face: unsplashItSvc.getImgSrc(0,'syslog',{face:true})
        }
      else
        from = Meteor.user()
      return if !from

      @context.call 'Post.postPostComment', post, comment, from, (err, result)->
        return console.warn ['Meteor::postPostComment WARN', err] if err
        if commentField?
          commentField.value = ''
        # post.body.comments ?= []
        # post.body.comments.push postComment
        console.log ['Meteor::postPostComment OK']

  return PostHelpersClass


PostHelpers.$inject = ['$timeout', 'utils']

angular.module 'starter.feed'
  .factory 'CollectionHelpers', CollectionHelpers
  .factory 'FeedHelpers', FeedHelpers
  .factory 'PostHelpers', PostHelpers
  .controller 'FeedCtrl', FeedCtrl
