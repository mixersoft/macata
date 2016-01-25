###
# @description  EventBookingCtrl, controller for event booking modal form
###

EventBookingCtrl = (
  $scope, $rootScope, $q, $timeout
  AAAHelpers, tileHelpers
  $log, toastr, devConfig
  ) ->
    mm = this
    mm.afterModalShow = ()->
      # params from appModalSvc.show( template , controllerAs , params, options) available
      # mm = copyToModalViewModal = {
      #   person: person
      #   event: event
      #   booking:
      #     userId: person.id
      #     seats: options['defaultSeats']
      #     maxSeats: options['maxSeats']
      #     comment: null
      #     attachment: null
      # }
      angular.extend mm, angular.copy($scope.copyToModalViewModal), {
        isAnonymous: $scope.vm.acl.isAnonymous
        confirmEventId: $scope.vm.event.id
        confirmCurrentUserId: $scope.vm.me.id
      }

      # other init methods
      $scope['attachmentContainer'] = document.querySelector('#request-seat-modal .attachment-container')

      mm.geo.setting.hasGeolocation = navigator.geolocation?
      mm.geo.setting.show.location = false
      return



    mm.isAnonymous = ()->
      return AAAHelpers.isAnonymous()

    mm.isValidated = (booking)->
      return false if AAAHelpers.isAnonymous()
      return false if booking?.seats < 1
      return true

    mm.createParticipation = (person, event, booking, participantIds)->
      # add booking as participant to event
      # clean up data
      particip = {
        eventId: event.id
        participantId: person.id + ''
        response: 'Yes'
        seats: parseInt booking.seats
        comment: booking.comment
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

    mm.settings = {
      show:
        newTile: false
        location: false
        spinner:
          newTile: false
    }

    #  TODO: refactor
    mm.geo = {
      setting:
        hasGeolocation: null  # set in init
        show:
          spinner:
            location: false
          location: false
      errorMsg:
        location: null
    }

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
        # return $scope.vm.on?searchTiles(value)
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

      submitBooking : (person, event, booking, onSuccess)->
        # some sanity checks
        if mm.confirmEventId != event.id
          toastr.warning("You are booking for a different event. title=" +
            event.title)
        if mm.confirmCurrentUserId != person.id
          toastr.warning("You are booking for a different person. name=" +
            person.displayName)

        participantIds = _.pluck $scope.vm.lookup['Participations'], 'participantId'
        return mm.createParticipation(person, event, booking, participantIds)
        .then (participation)->
          return $scope.createBooking(participation)
        .then (result)->
          # utils.ga_Send('send', 'event', 'participation'
          #   , 'event-booking', 'Yes', 10)
          onSuccess?(result)
          return result
        .catch (err)->
          if err=="DUPLICATE KEY"
            toastr.info "You are already participating in the event."
            # $scope.vm.activate()
            $timeout ()-> $scope.vm.on.scrollTo('cp-participant')
            return onSuccess?()
          $q.reject err
        return



      ### Tile Methods ###
      TILE:
        editTile: (data)->
          return tileHelpers.modal_showTileEditor(data)
          .then (result)->
            mm.attachment = result
          return

        detachTile: (tile)->
          console.log ['detachTile', 'id='+tile.id , tile]
          mm.attachment = null

        attachTile: (result)->
          return mm.on.TILE.submitNewTile(result)
          .then (result)->
            mm.booking.attachment = mm.attachment = result

            # tile = mm.on.makeTile(result)
            # $scope['attachmentContainer'].push tile

        submitNewTile: (result)->
          console.log ['submitNewTile', result]
          mm.settings.show.newTile = false
          result = devConfig.setData(result) if result
          return $q.when result


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
  'AAAHelpers', 'tileHelpers'
  '$log', 'toastr', 'devConfig'
]


angular.module 'starter.events'
  .controller 'EventBookingCtrl', EventBookingCtrl
