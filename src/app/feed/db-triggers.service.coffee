'use strict'

# helper functions for user actions on events
FeedDbTriggers = ( notificationTemplates )->

  class FeedDbTriggersClass
    constructor: (@context)->
      return


    Invitation_logAction: (invitation)=>
      # log action to Invitation.body.comments
      self = @
      me = Meteor.user()
      options = {
        log: true
        message: [
          me.displayName
          'has', invitation.body.response
        ]
      }
      switch invitation.body.response
        when 'declined'
          options.message.push 'this invitation.'
        when 'accepted'
          options.message = options.message.concat [
            'this invitation, and requested'
            invitation.body.seats
            'seats.'
          ]
        else
          return

      # TODO set 'moderatorIds' to new participantId
      # return vm.postActions.postComment(null, invitation, options)
      return self.context.postHelpers.postComment null, invitation, options

    Invitation_afterChange: (data, action)=>
      self = @
      # post Notification to participants feed
      invitation = angular.copy data
      invitation['$owner'] = self.context.collHelpers.findOne 'User', invitation.head.ownerId
      invitation['$chatWith'] =
        self.context.collHelpers.findOne 'User', invitation.head.recipientIds[0]
      # append a log as a comment to invitation
      return self.Invitation_logAction(invitation)
      .then (result)->
        switch action
          when 'decline', 'declined'
            template = 'invitation.declined.ownerId'
          when 'accept', 'accepted'
            template = 'invitation.accepted.ownerId'
          else
            return

        message = notificationTemplates.get(template, invitation)
        notify = {
          ownerId: invitation.head.ownerId
          # recipientIds: [invitation.head.ownerId]
          # role: 'participants'
          message: message
        }
        # return EventActionHelpers.FeedHelpers.notify(self.context.event, notify, vm)
        return self.context.feedHelpers.postNotificationToFeed(notify)

    Booking_logAction: (invitation)=>
      # log action to Booking.body.comments
      self = @
      me = Meteor.user()
      options = {
        log: true
        message: [
          me.displayName
          'has', invitation.body.response
        ]
      }
      switch invitation.body.response
        when 'declined'
          options.message.push 'this booking.'
        when 'accepted'
          options.message = options.message.concat [
            'this booking, You have reserved'
            invitation.body.seats
            'seats.'
          ]
        else
          return

      # TODO set 'moderatorIds' to new participantId
      # return vm.postActions.postComment(null, invitation, options)
      return self.context.postHelpers.postComment null, invitation, options

    Booking_afterChange: (data, action, event)=>
      self = @
      # post Notification to participants feed
      booking = angular.copy data
      booking['$owner'] = self.context.collHelpers.findOne 'User', booking.head.ownerId
      if booking.head.recipientIds
        booking['$chatWith'] =
          self.context.collHelpers.findOne 'User', booking.head.recipientIds[0]
      if booking.head.responseBy
        booking['$chatWith'] =
          self.context.collHelpers.findOne 'User', booking.head.responseBy
      # append a log as a comment to booking
      return self.Booking_logAction(booking)
      .then (result)->
        # post Notification: 'booking.accepted.ownerId'
        switch action
          when 'decline', 'declined'
            action = 'declined'
            template = 'booking.declined.ownerId'
          when 'accept', 'accepted'
            action = 'accepted'
            template = 'booking.accepted.ownerId'
          else
            return

        message = notificationTemplates.get(template, booking)
        notify = {
          ownerId: booking.head.ownerId
          # recipientIds: [booking.head.ownerId]
          # role: 'participants'
          message: message
        }
        # return EventActionHelpers.FeedHelpers.notify(self.context.event, notify, vm)
        bookingRespNotification = self.context.feedHelpers.postNotificationToFeed(notify)
      .then ()->
        return 'skip' if action != 'accepted'
        # post Notification: 'booking.accepted.participantIds'
        template = 'booking.accepted.participantIds'
        message = notificationTemplates.get(template, booking)
        notify = {
          ownerId: booking.head.responseBy
          role: 'participants'
          recipientIds: _.difference event.participantIds, [booking.head.ownerId]
          contribution: booking.body.attachment
          message: message
        }
        if not _.isEmpty notify.contribution
          if notify.contribution.type == 'Recipe'
            angular.extend notify.contribution, mcRecipes.findOne(notify.contribution._id)

          notify.message = [
            notify.message
            '<br /><br />'
            notificationTemplates.get('event.contributions.notify', booking)
          ]
        newBookingNotification = self.context.feedHelpers.postNotificationToFeed(notify)
      .then ()->
        return 'skip' if action != 'accepted'
        # post Notification: 'event.booking.sendInvites', shareEvent, or fullyBooked
        if event.seatsOpen > 0
          # event.moderatorIds = [booking.head.ownerId]
          notify = {
            ownerId: booking.head.ownerId
            message: null
            '$owner': booking['$owner']
            seatsOpen: event.seatsOpen
            toNow: moment(event.startTime).fromNow()
          }
          # TODO: handle with subclass
          switch event.type
            when 'progressive-invite'
              if event.setting.isExclusive
                shareTemplate = 'event.booking.sendInvites'
                # vm.settings.show.hideInvitations = false
              else
                shareTemplate = 'event.booking.shareEvent'
              notify.message = notificationTemplates.get(shareTemplate, notify)
              # promises.push share = EventActionHelpers.FeedHelpers.notify(event, post, vm)
              shareNotification = self.context.feedHelpers.postNotificationToFeed(notify)
        else
          notify = {
            ownerId: null
            role: 'participants'
            recipientIds: event.participantIds
            message: null
            '$host': self.context.collHelpers.findOne 'User', event.ownerId
          }
          notify.message = notificationTemplates.get('event.booking.fullyBooked', notify)
          # promises.push fullyBooked = EventActionHelpers.FeedHelpers.notify(event, post, vm)
          fullyBookedNotification = self.context.feedHelpers.postNotificationToFeed(notify)
        return



  return FeedDbTriggersClass


FeedDbTriggers.$inject = [ 'notificationTemplates']

angular.module 'starter.feed'
  .factory 'FEED_DB_TRIGGERS', FeedDbTriggers
