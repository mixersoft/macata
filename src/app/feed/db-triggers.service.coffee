'use strict'

# helper functions for user actions on events
FeedDbTriggers = ( notificationTemplates )->

  class FeedDbTriggersClass
    constructor: (@context)->
      return


    Invitation_logAction: (invitation)=>
      self = @
      me = Meteor.user()
      options = {
        log: true
        message: [
          me.profile.displayName
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
      return @['Invitation_logAction'](invitation)
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

  return FeedDbTriggersClass


FeedDbTriggers.$inject = [ 'notificationTemplates']

angular.module 'starter.feed'
  .factory 'FEED_DB_TRIGGERS', FeedDbTriggers
