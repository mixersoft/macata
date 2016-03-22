'use strict'

###
  NOTE: using component-directives form,
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
###
FilteredFeed = ( CollectionHelpers, FeedHelpers, PostHelpers)->
  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'show': '='
      'event': '='
      'filteredFeed': '='
      'reactiveContext': '='
    }
    templateUrl: 'feed/filtered-feed.html'
    controller: [
      '$q', '$filter', 'FEED_DB_TRIGGERS'
      ($q, $filter, FEED_DB_TRIGGERS)->
        ff = this

        if not this.reactiveContext.getReactively
          throw new Error "ERROR: expecting reactiveContext"

        ff.collHelpers = new CollectionHelpers(ff.reactiveContext)
        ff.feedHelpers = new FeedHelpers(ff.reactiveContext)
        ff.postHelpers = new PostHelpers(ff.reactiveContext)
        ff.me = ff.collHelpers.findOne('User', Meteor.userId())

        ff.on = {
          edit: ()-> console.warn "attachment.edit: See RecipeHelpers"
          forkTile: ()-> console.warn "attachment.forkTile: See RecipeHelpers"
          postToFeed: (comment)->
            ff.feedHelpers.postCommentToFeed(comment)
            return $q.when()    # TODO: fix in message-composer.on.post()
        }

        DB_TRIGGERS = new FEED_DB_TRIGGERS(ff)

        ff.inviteActions = {
          requiresAction: (post, me)->
            return if post.type != 'Invitation'
            meId = me?._id || Meteor.userId()
            check = {
              type: post.type == 'Invitation'
              status: ~['new', 'viewed'].indexOf(post.body.status)
            }
            nextAction = post.head.nextActionBy
            switch nextAction
              when 'owner'
                check['nextAction'] = post.head.ownerId && post.head.ownerId == meId
                # check['nextAction'] = me && ~event.moderatorIds.indexOf me._id
              when 'recipient'
                check['nextAction'] = post.head.recipientIds && ~post.head.recipientIds.indexOf meId
            return _.reject(check).length == 0

          accept: ($event, invitation)->
            return $q.when()
            .then ()->
              return if invitation.type != 'Invitation'
              return invitation
            .then (invitation)->
              return vm.on.beginBooking($rootScope.currentUser, ff.event)
            .then (participation)->
              if !participation
                return ff.postHelpers.updateInvite invitation, 'viewed'
              return ff.postHelpers.updateInvite invitation
              ,'accept'
              ,{seats: participation.body.seats}
            .then ()->


              DB_TRIGGERS['Invitation_afterChange'](invitation, 'accept')
            .then (invitation)->
              target = $event.target
              $wrap = angular.element(
                utils.getChildOfParent(target, 'item-post', '.post-comments'))
              $wrap.removeClass('hide')
            .then (invitation)->
              toastr.info("DEMO: invitation responses will be automatically accepted.")
              return $timeout(3000)
            .then ()->
              # TODO: need to change ParticipationResponse.head.ownerId
              vm.moderatorActions.accept($event, ff.event, participation)


          message: ($event, invitation)->
            return ff.postHelpers.updateInvite invitation, 'viewed'
            .then ()->
              return ff.postHelpers.showCommentForm($event, invitation)

          decline: ($event, invitation)->
            return $q.when()
            .then ()->
              return if invitation.type != 'Invitation'
              # update "Invitation"
              return ff.postHelpers.updateInvite invitation, 'decline'
            .then ()->


              DB_TRIGGERS['Invitation_afterChange'](invitation, 'decline')

        }




        return ff
      ]
    controllerAs: 'ff'
  }



FilteredFeed.$inject = [ 'CollectionHelpers', 'FeedHelpers', 'PostHelpers']

angular.module 'starter.feed'
  .directive 'filteredFeed', FilteredFeed
