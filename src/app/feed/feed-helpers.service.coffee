'use strict'



CollectionHelpers = (
  $window
)->
  class CollectionHelpersClass
    global = $window
    constructor: (@context)->

    findOne: (className, id, fields)->
      return null if not (id && className)
      switch className
        when 'User', 'user'
          collection = Meteor.users
        else
          collName = ['mc' + className + 's'].join('')
          collection = global[collName]
      found = collection.findOne(id)
      if !found
        console.warn ["Warning: object not found", className, id, 'check publishing spec']
      return found

  return CollectionHelpersClass

CollectionHelpers.$inject = ['$window']



FeedHelpers = (
  $q, $timeout, AAAHelpers
)->
  class FeedHelpersClass
    constructor: (@context)->

    postDefaults: {}
    show:
      messageComposer: false

    showMessageComposer: ($event)->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->

      # return @showSignInRegister('sign-in') if !Meteor.userId()

        # template for post.body
        # for post.head: {} # see: FeedHelpers.post()
        self.postDefaults = {
          message: null
          attachment: null
          address: null
          location: null
        }
        self.show.messageComposer = true
        parent = $event.target
        while parent && parent.parentNode
          break if parent.tagName == 'FILTERED-FEED'
          parent = parent.parentNode


        $timeout().then ()->
          textbox = parent.querySelector('message-composer textarea')
          textbox.focus()
          textbox.scrollIntoViewIfNeeded()
        return

    ###
    # @description  post to Feed
    # @return promise
    ###
    postToFeed: (post, cb={})->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->
        missingKeys = _.difference ['type','head','body'], _.keys post
        return if missingKeys.length

        self.context.call 'Post.postFeedPost', self.context.eventId, post, (err, result)->
          if err
            cb['onError']?(err)
            return console.warn ['Meteor::postFeedPost WARN', err]
          cb['onSuccess']?(result)
          console.log ['Meteor::postFeedPost OK']

    ###
    # @description  use with directive message-composer
        example(jade): message-composer( post-button="postCommentToFeed(value)" )
    # @return promise
    ###
    postCommentToFeed: (comment)->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->
        post = {
          type: 'Comment'
          head:
            isPublic: true
          # @TODO: check/change to post.body.message(?)
          body: comment
        }
        dfd = $q.defer()
        return self.postToFeed(post, {
          onSuccess: (result)->
            self.show.messageComposer = false
            return dfd.resolve( mcFeeds.findOne(result) )
          })

    ###
    # @return promise
    ###
    postNotificationToFeed: (data) ->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->
      # format notification as a Post

        post = {}
        post.type = 'Notification'
        post.head = _.pick data, ['ownerId', 'recipientIds', 'role', 'expiresAt']
        post.body = {
          message: data.message
        }
        dfd = $q.defer()
        self.postToFeed(post, {
          onError: (err)-> return dfd.reject(err)
          onSuccess: (result)-> return dfd.resolve( mcFeeds.findOne(result) )
          }
        )
        return dfd.promise



  return FeedHelpersClass

FeedHelpers.$inject = ['$q', '$timeout', 'AAAHelpers']



PostHelpers = (
  $q, $timeout, utils, AAAHelpers, unsplashItSvc
)->
  class PostHelpersClass
    constructor: (@context)->

    dismissItem: ($event, post)->
      # return mcFeeds.helpers.dismiss(post)
      @context.call 'Post.dismiss', post, (err, result)->
        console.warn ['Meteor::dismiss WARN', err] if err
        console.log ['Meteor::dismiss OK']

    like: ($event, post)->
      self = @
      return AAAHelpers.requireUser('sign-in')
      .then ()->
        # return mcFeeds.helpers.toggleLike(post)
        self.context.call 'Post.toggleLike', post, (err, result)->
          console.warn ['Meteor::toggleLike WARN', err] if err
          console.log ['Meteor::toggleLike OK']

    showSignInRegister: (action)->
      return AAAHelpers.showSignInRegister.call(@context, action)
      .catch (err)->
        console.warn ['WARN:sign-in to post to Feed', err]

    respondToInvite: (invite, action, options={})->
      dfd = $q.defer()
      # NOTE: does use of $q.defer automatically wrap callback in $digest loop?
      @context.call 'Post.respondToInvite', invite, action, options, (err, result)->
        if err
          dfd.reject(err)
          return console.warn ['Meteor::respondToInvite WARN', action, err]
        dfd.resolve( mcFeeds.findOne(invite._id) )
        console.log ['Meteor::respondToInvite OK', action]
      return dfd.promise

    showCommentForm: ($event, post)->
      return if post.type == 'Notification'

      target = $event.currentTarget || $event.target
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
    # @return promise
    ###
    postComment: ($event, post, options)->
      return @showSignInRegister('sign-in') if !Meteor.userId()
      if !options
        target = $event.currentTarget
        # parent = ionic.DomUtil.getParentWithClass(target, 'comment-form')
        # commentField = parent.querySelector('textarea.comment')
        commentField = utils.getChildOfParent(target, 'comment-form', 'textarea.comment')
        comment = angular.copy commentField.value
      else
        comment = options.message
        comment = comment.join(' ') if _.isArray comment

      return $q.reject('Expecting message for comment') if not comment

      if options?['log'] == true
        # TODO: ???: has post from syslog("feed") been replaced by "Notifications"?
        from = {
          id: 'syslog'
          displayName: 'feed:'
          face: unsplashItSvc.getImgSrc(0,'syslog',{face:true})
        }
      else
        from = Meteor.user()
      return $q.reject('Expecting user for comment, not signed in?') if !from

      dfd = $q.defer()
      @context.call 'Post.postPostComment', post, comment, from, (err, result)->
        if err
          dfd.reject(err)
          return console.warn ['Meteor::postPostComment WARN', err] if err
        if commentField?
          commentField.value = ''
        # post.body.comments ?= []
        # post.body.comments.push postComment
        dfd.resolve( mcFeeds.findOne(post._id) )
        console.log ['Meteor::postPostComment OK']
      return dfd.promise

  return PostHelpersClass


PostHelpers.$inject = ['$q', '$timeout', 'utils', 'AAAHelpers', 'unsplashItSvc']


angular.module 'starter.feed'
  .factory 'CollectionHelpers', CollectionHelpers
  .factory 'FeedHelpers', FeedHelpers
  .factory 'PostHelpers', PostHelpers
