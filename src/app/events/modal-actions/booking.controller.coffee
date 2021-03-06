###
# @description  EventBookingCtrl, controller for event booking modal form
###

EventBookingCtrl = (
  $scope, $rootScope, $q, $timeout
  AAAHelpers, tileHelpers, appModalSvc
  $reactive, CollectionHelpers
  $log, toastr, devConfig
  ) ->
    $reactive(this).attach($scope)
    mm = this
    mm.name = "EventBookingCtrl"
    mm.hEvents = hEvents
    mm.afterModalShow = ()->
      # params from appModalSvc.show( template , controllerAs , params, options) available
      # mm = copyToModalViewModal = {
      #   person: person
      #   event: event
      #   booking:
      #     userId: person._id
      #     seats: options['defaultSeats']
      #     maxSeats: options['maxSeats']
      #     message: null
      #     attachment: null
      #     address: null   # addressString
      #     location: null  # {address: latlon:}
      # }
      angular.extend mm, $scope.copyToModalViewModal
      angular.extend mm , {
        confirmEventId: mm.event?._id
        confirmCurrentUserId: mm.person?._id
      }

      # other init methods
      $scope['attachmentContainer'] =
        document.querySelector('#request-seat-modal .attachment-container')

      return

    mm.isAnonymous = ()->
      return not (mm.person?._id)

    mm.isValidated = (booking)->
      return false if mm.isAnonymous()
      return false if booking?.seats < 1
      return true

    mm.createParticipation = (person, event, booking, participantIds)->
      # add booking as participant to event
      # clean up data
      particip = {
        type: 'Participation'
        head:
          ownerId: booking.userId || Meteor.userId()
          eventId: event._id
        body:
          status: 'new'
          response: 'Yes'
          seats: parseInt booking.seats
          message: booking.message
          attachment: booking.attachment
          location: booking.location  # booking.location = {address: latlon:}
      }
      # check for existing participation
      if ~participantIds?.indexOf(person._id)
        return $q.reject("DUPLICATE KEY")

      # booking by definition is a new response
      maxSeats =
        if event.settings['denyRsvpFriends']
        then 1
        else event.settings['rsvpFriendsLimit']
      return $q.reject('RSVP FRIENDS LIMIT') if particip['seats'] > maxSeats

      return $q.when(particip)


    mm.attachment = null

    mm.on = {
      toggleShow: (show, key, selector)->
        show[key] = !show[key]
        if show[key] && selector
          # scroll into View
          scrollEl = document.getElementById('request-seat-modal')
            .querySelector(selector)
          $timeout ()->
            scrollEl.scrollIntoView()
        return show[key]

      signInRegister : (action, person)->
        # update booking user after sign in/register
        return self.showSignIn.call($scope.vm, action)
        .then (result)->
          _.extend person, result
          return

      searchTiles : (value, set)->
        mm.autocomplete ?= {
          options: []
          set: set
        }
        return $q.when()
        .then ()->
          _fakeFilter = (value)->
            return _.uniq( value?.split(' ') )
          mm.autocomplete.options = _fakeFilter(value)
          return mm.autocomplete

      ###
      #  @description validate booking modal on submit
      #   called by ng-submit
      #  @returns mm.createParticipation( participation ) as promise
      ###
      validateBooking : (person, event, booking, onSuccess)->
        # clean data
        booking.seats = parseInt booking.seats

        # some sanity checks
        if mm.confirmEventId != event._id
          toastr.warning("You are booking for a different event. title=" +
            event.title)
        if mm.confirmCurrentUserId != person._id
          toastr.warning("You are booking for a different person. name=" +
            person.displayName)

        participantIds = _.map $scope.vm?.lookup['Participations'], 'participantId'
        console.warn "TODO: submitBooking() should checking for DUPLICATE participantIds  "
        return mm.createParticipation(person, event, booking, participantIds)
        .then (participation)->
          # utils.ga_Send('send', 'event', 'participation'
          #   , 'event-booking', 'Yes', 10)
          onSuccess?(participation)
          return participation
        .catch (err)->
          if err=="DUPLICATE KEY"
            toastr.info "You are already participating in the event."
            return onSuccess?()
          $q.reject err
        return


    }

    once = $scope.$on 'modal.afterShow', (ev, modal)->
      once?()
      if modal == $scope.modal
        mm.afterModalShow()
      return

    console.log ["EventBookingCtrl initialized scope.$id=", $scope.$id]
    return mm

EventBookingCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$timeout'
  'AAAHelpers', 'tileHelpers', 'appModalSvc'
  '$reactive', 'CollectionHelpers'
  '$log', 'toastr', 'devConfig'
]


angular.module 'starter.events'
  .controller 'EventBookingCtrl', EventBookingCtrl
