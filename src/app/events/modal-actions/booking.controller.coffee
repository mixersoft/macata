###
# @description  EventBookingCtrl, controller for event booking modal form
###

EventBookingCtrl = (
  $scope, $rootScope, $q, $timeout
  AAAHelpers, tileHelpers, appModalSvc
  $log, toastr, devConfig
  ) ->
    mm = this
    mm.name = "EventBookingCtrl"
    mm.afterModalShow = ()->
      # params from appModalSvc.show( template , controllerAs , params, options) available
      # mm = copyToModalViewModal = {
      #   person: person
      #   event: event
      #   booking:
      #     userId: person.id
      #     seats: options['defaultSeats']
      #     maxSeats: options['maxSeats']
      #     message: null
      #     attachment: null
      #     address: null   # addressString
      #     location: null  # {address: latlon:}
      # }
      angular.extend mm, $scope.copyToModalViewModal
      angular.extend mm , {
        confirmEventId: mm.event?.id
        confirmCurrentUserId: mm.person?.id
      }

      # other init methods
      $scope['attachmentContainer'] =
        document.querySelector('#request-seat-modal .attachment-container')

      return

    mm.isAnonymous = ()->
      return not (mm.person?.id)

    mm.isValidated = (booking)->
      return false if mm.isAnonymous()
      return false if booking?.seats < 1
      return true

    mm.createParticipation = (person, event, booking, participantIds)->
      # add booking as participant to event
      # clean up data
      particip = {
        body:
          type: 'Participation'
          status: 'new'
          response: 'Yes'
          seats: parseInt booking.seats
          message: booking.message
          attachment: booking.attachment
          address: booking.address
          location: booking.location
      }
      # check for existing participation
      if ~participantIds?.indexOf(person.id)
        return $q.reject("DUPLICATE KEY")

      # booking by definition is a new response
      maxSeats =
        if event.setting['denyRsvpFriends']
        then 1
        else event.setting['rsvpFriendsLimit']
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
            return _.unique( value?.split(' ') )
          mm.autocomplete.options = _fakeFilter(value)
          return mm.autocomplete

      ###
      #  @description validate booking modal on submit
      #   called by ng-submit
      #  @returns mm.createParticipation( participation ) as promise
      ###
      validateBooking : (person, event, booking, onSuccess)->
        # clean data
        booking.attachment =
          _.pick( booking.attachment
          , ['id', 'url','title','description','image', 'site_name', 'extras'])
        booking.seats = parseInt booking.seats

        # some sanity checks
        if mm.confirmEventId != event.id
          toastr.warning("You are booking for a different event. title=" +
            event.title)
        if mm.confirmCurrentUserId != person.id
          toastr.warning("You are booking for a different person. name=" +
            person.displayName)

        participantIds = _.pluck $scope.vm?.lookup['Participations'], 'participantId'
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
  '$log', 'toastr', 'devConfig'
]


angular.module 'starter.events'
  .controller 'EventBookingCtrl', EventBookingCtrl
