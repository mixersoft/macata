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
      '$q', '$state', '$filter', 'FEED_DB_TRIGGERS', 'EventActionHelpers'
      'utils', 'toastr'
      ($q, $state, $filter, FEED_DB_TRIGGERS, EventActionHelpers
      utils, toastr)->
        ###
        TODO: ???: should we just make this controller $reactive?
        ###

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
          headerClick: ($event)->
            return if $state.includes('app.feed')
            $state.go('app.feed', {id: $state.params.id})
            console.info ["state=", $state.current.name, $state.params]
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
              return $q.reject("Invitation Not Found") if invitation.type != 'Invitation'

              # return vm.on.beginBooking($rootScope.currentUser, ff.event)
              return ff.postHelpers.showSignInRegister('sign-in') if !Meteor.userId()

              return EventActionHelpers.bookingWizard(Meteor.user(), ff.event)
            .then (participation)->
              if participation == 'CANCELED'
                cont = ff.postHelpers.respondToInvite invitation, 'viewed'
                return $q.reject('CANCELED')
              return $q.when participation
              .then (participation)->
                # TODO: move to DB_TRIGGERS?
                # post accept to Invite comment
                cont = ff.postHelpers.respondToInvite( invitation
                ,'accept'
                ,{seats: participation.body.seats}
                ).then ()->
                  DB_TRIGGERS['Invitation_afterChange'](invitation, 'accepted')

                return participation
              .then (participation)->
                # post Booking/Partcipation, appears on Moderator's feed
                # return EventActionHelpers.FeedHelpers.post(event, participation, vm)
                participation.head['invitationId'] = invitation._id
                participation.head['moderatorIds'].push invitation.head.ownerId
                cont = ff.feedHelpers.postToFeed( participation
                ,{
                  onSuccess: ()->
                    'skip'
                  })
                return participation
              .then (participation)->
                toastr.info("DEMO: invitation responses will be automatically accepted.")
                return $timeout(3000)
              .then ()->
                # TODO: need to change ParticipationResponse.head.ownerId
                vm.moderatorActions.accept($event, ff.event, participation)

            .then ()->
              target = $event.target
              $wrap = angular.element(
                utils.getChildOfParent(target, 'item-post', '.post-comments'))
              $wrap.removeClass('hide')



          message: ($event, invitation)->
            return ff.postHelpers.respondToInvite invitation, 'viewed'
            .then ()->
              return ff.postHelpers.showCommentForm($event, invitation)

          decline: ($event, invitation)->
            return $q.when()
            .then ()->
              return if invitation.type != 'Invitation'
              # update "Invitation"
              return ff.postHelpers.respondToInvite invitation, 'decline'
            .then ()->


              DB_TRIGGERS['Invitation_afterChange'](invitation, 'declined')

        }

        ff.moderatorActions = {

          # TODO: check
          requiresAction: (post, me)->
            return if not ff.event
            return if not ~['Participation'].indexOf post.type

            meId = me?._id || Meteor.userId()
            check = {
              type: post.type == 'Participation'
              status: ~['new', 'pending', 'viewed'].indexOf(post.body.status)
              response: ~['Yes','Message'].indexOf post.body.response
            }

            nextAction = post.head.nextActionBy
            switch nextAction
              when 'owner'
                check['nextAction'] = me && post.head.ownerId == meId
                check['nextAction'] = check['nextAction'] || ff.event.ownerId == meId
              when 'moderator'
                check['nextAction'] = me && ~post.head.moderatorIds.indexOf meId
                check['nextAction'] = check['nextAction'] ||
                  (ff.event.moderatorIds && ~ff.event.moderatorIds.indexOf meId)
              when 'recipient'
                check['nextAction'] = me && ~post.head.recipientIds.indexOf meId
            return _.reject(check).length == 0

          accept: ($event, post)->
            # confirm sign-in
            # add booking to event
            # respondToInvite, update body status, resonse
            # in DB_TRIGGERS:
            #     add comment to Booking (Participation)
            #     post Notification: 'booking.accepted.ownerId'
            #     post Notification: 'booking.accepted.participantIds'
            #     post Notification: 'event.booking.sendInvites', shareEvent, or fullyBooked
            action = 'accept'
            meId = me?._id || Meteor.userId()
            return $q.when()
            .then ()->
              return $q.reject("Participation Not Found") if post.type != 'Participation'

              # return vm.on.beginBooking($rootScope.currentUser, ff.event)
              return ff.postHelpers.showSignInRegister('sign-in') if !Meteor.userId()

            .then ()->
              # update event
              dfd = $q.defer()
              ff.reactiveContext.call 'Event.updateBooking', ff.event, post, (err, result)->
                if err
                  dfd.reject(err)
                  return console.warn ['Meteor::Event.updateBooking WARN', action, err]
                dfd.resolve( mcEvents.findOne( ff.event._id) )
                console.log ['Meteor::Event.updateBooking OK', action]
              return dfd.promise

            .then (event)->
              # TODO: move to DB_TRIGGERS?
              # post accept to Booking comment
              found = _.find(event.participations, {ownerId: post.head.ownerId})
              post.body.seats = found.seats # get updated value
              cont = ff.postHelpers.respondToInvite( post
              , action
              ,{seats: post.body.seats}
              ).then ()->
                post.head.responseBy = meId
                DB_TRIGGERS['Booking_afterChange'](post, 'accept', ff.event)





          message: ($event, participation)->
            # TODO: refactor respondToInvite to handle bookings
            return ff.postHelpers.respondToInvite participation, 'pending'
            .then ()->
              return ff.postHelpers.showCommentForm($event, participation)

          decline: ($event, participation)->
            meId = me?._id || Meteor.userId()
            return $q.when()
            .then ()->
              return if participation.type != 'Participation'
              # update "Invitation"
              return ff.postHelpers.respondToInvite participation, 'decline'
            .then (participation)->

              participation.head.responseBy = meId
              DB_TRIGGERS['Booking_afterChange'](participation, 'decline')

        }




        return ff
      ]
    controllerAs: 'ff'
  }



FilteredFeed.$inject = [ 'CollectionHelpers', 'FeedHelpers', 'PostHelpers']

angular.module 'starter.feed'
  .directive 'filteredFeed', FilteredFeed