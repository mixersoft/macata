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

        ff.requiresAction = (post, types)->
          return false if not ~types.indexOf post.type
          meId = Meteor.userId()
          return FeedModel::requiresAction(post, meId, ff.event)

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
                # requiresAction addressing
                switch ff.event.type
                  when "progressive-invite"
                    # post Booking/Partcipation, appears on Moderator's feed
                    # return EventActionHelpers.FeedHelpers.post(event, participation, vm)
                    participation.head['invitationId'] = invitation._id
                    participation.head['recipientIds'] = [invitation.head.ownerId]
                    participation.head['moderatorIds'] = [invitation.head.ownerId, ff.event.ownerId]
                    participation.head['nextActionBy'] = 'recipient'
                    participation.head['isPublic'] = false
                  when "kickstarter", "booking"
                  else
                    # post Booking/Partcipation, appears on Moderator's feed
                    # return EventActionHelpers.FeedHelpers.post(event, participation, vm)
                    participation.head['invitationId'] = invitation._id
                    participation.head['recipientIds'] = [invitation.head.ownerId]
                    participation.head['moderatorIds'] = [ff.event.ownerId]
                    participation.head['nextActionBy'] = 'moderator'
                    participation.head['isPublic'] = false
                return participation
              .then (participation)->
                cont = ff.feedHelpers.postToFeed( participation
                ,{
                  onSuccess: ()->
                    'skip'
                  })
                return participation
              # .then (participation)->
              #   toastr.info("DEMO: invitation responses will be automatically accepted.")
              #   return $timeout(3000)
              # .then ()->
              #   # TODO: need to change ParticipationResponse.head.ownerId
              #   vm.moderatorActions.accept($event, ff.event, participation)

            .then ()->
              target = $event.target
              $wrap = angular.element(
                utils.getChildOfParent(target, 'item-post', '.post-comments'))
              $wrap.removeClass('hide')



          message: ($event, invitation)->
            return ff.postHelpers.showSignInRegister('sign-in') if !Meteor.userId()
            return ff.postHelpers.respondToInvite invitation, 'pending'
            .then ()->
              return ff.postHelpers.showCommentForm($event, invitation)

          decline: ($event, invitation)->
            if not Meteor.userId()
              invitation.body.status = "declined"
              invitation.body.comments = [{
                  type: "PostComment"
                  head:
                    ownerId: invitation.head.tokenId
                    tokenId: invitation.head.tokenId
                  body:
                    comment: "You have declined this invitation."
                }]
              return
            return $q.when()
            .then ()->
              return if invitation.type != 'Invitation'
              # update "Invitation"
              return ff.postHelpers.respondToInvite invitation, 'decline'
            .then ()->


              DB_TRIGGERS['Invitation_afterChange'](invitation, 'declined')

        }

        ff.moderatorActions = {
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
              # NOTE: if we use $q, can we just do Meteor.call() to get back into $digest
              Meteor.call 'Event.updateBooking', ff.event, post, (err, result)->
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
