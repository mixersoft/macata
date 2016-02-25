'use strict'

###
# @description These are templates used for system notifications that are issued from various actions
###

# coffeelint: disable=max_line_length
ACTION = {
  'invitation': # invitations sent by moderator to one or more people
    accepted: # done
      ownerId: """
        <b>%post.head.$$chatWith.displayName%</b> has accepted your <a href="/#/app/feed/%post.head.id%">invitation</a>,
        and requested %post.body.seats% seats at the table.
        """
      participantIds: """
        <b>%post.head.$$chatWith.displayName%</b> has accepted an <a href="/#/app/feed/%post.head.id%">invitation</a>,
        and requested %post.body.seats% seats at the table.
        """
      recipientIds: """
        Welcome. <b>%post.head.$$owner.displayName%</b> has been notified of your request %post.body.seats% seats
        and will respond shortly.
        If you haven't already done so, please tell your table-mates what you bring to the table.
        """
    message:
      subscribers:  # omit message sender, vm.me.id, either $$owner or $$chatWith
        """
        <b>%vm.me.displayName%</b> commented on a post you are following. <a href="/#/app/feed/%post.head.id%">more...</a>
        """
    declined:  # done
      # rejections should be visible only by the invitation owner
      ownerId: '<b>%post.head.$$chatWith.displayName%</b> has declined your <a href="/#/app/feed/%post.head.id%">invitation</a>.'
      # participantIds: no message
  'booking':
    accepted: # done
      ownerId: """
        Welcome <b>%post.head.$$owner.displayName%</b>. Your request was accepted, and you have booked %post.body.seats% seats at the table.
        """
      participantIds:"""
        <b>%post.head.$$owner.displayName%</b> has booked %post.body.seats% seats at this table.
        """

    message:
      subscribers:  # omit message sender, vm.me.id, either $$owner or $$chatWith
        """
        <b>%vm.me.displayName%</b> commented on a post you are following. <a href="/#/app/feed/%post.head.id%">more...</a>
        """
    declined: # done
      # rejections should not be public
      ownerId: """
        Sorry <b>%post.head.$$owner.displayName%</b>, your booking was declined. <a href="/#/app/feed/%post.head.id%">more...</a>
        """
  'event':
    booking: # done
      sendInvites: """
        <b>%post.displayName%</b>&mdash;Congratulations, you are now in control of the invites.
        There are <b>%post.seatsOpen%</b> seats remaining and the event begins <b>%post.toNow%</b>. Remember, with great power comes great responsibility.
        <br /><br />Now go send some invitations.
        """
      shareEvent: """
        <b>%post.displayName%</b>&mdash;Congratulations, you are now in control of the guest list.
        There are <b>%post.seatsOpen%</b> seats remaining and the event begins <b>%post.toNow%</b>. Remember, with great power comes great responsibility.
        <br /><br />Now go share this Table with your friends.
        """
      fullyBooked: """
        All right! This event is now fully booked&mdash;take a moment to see who's coming! <b>&mdash;%post.hostName%</b>
        """
    contributions:
      reminder: """
        Remember bring something to the table. If you are stuck, our <a href="/#/app/recipe">Ideas</a> page is a great place to start.
        """
      notify: """
        <b>%post.head.$$owner.displayName%</b> brings <a href="/#/app/recipe?id=%post.body.attachment.id%">%post.body.attachment.title%</a> to the table.
        """




}
# coffeelint: enable=max_line_length
#

NotificationTemplates = ()->

  return {
    get: (path, post)->
      markup = _.get ACTION, path
      return markup if _.isObject markup
      substitutions = markup.match(/%(.*?)%/g)
      _.each substitutions, (match)->
        return if !match
        if match.slice(1,6) == 'post.'
          path = match.slice(6,-1)
          value = _.get( post, path ) || ''
          re = RegExp(match.replace(/\$/g,'\\$'), 'g')
          markup = markup.replace(re, value) if value
          return
        if match.slice(1,4) == 'vm.'
          path = match.slice(4,-1)
          value = _.get vm, path
          markup = markup.replace(RegExp(match, 'g'), value) if value
          return
        return
      return markup
  }


NotificationTemplates.$inject = []

angular.module 'starter.core'
  .factory 'notificationTemplates', NotificationTemplates
