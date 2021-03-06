'use strict'

# helper functions for user actions on events
EventActionHelpers = ($rootScope, $q, $timeout
  $location, $state, $stateParams, $ionicPopup
  $log, toastr
  # TokensResource, ParticipationsResource, ContributionsResource, MenuItemsResource
  FeedResource, IdeasResource, TokensResource
  AAAHelpers, $filter
  appModalSvc, utils, exportDebug
  )->

    passcodePopup = {
      template: '<input type="password" ng-model="passcode">',
      title: "Update Response"
      subTitle: 'Enter your passcode to update this response',
      cssClass: 'passcode-popup'
      scope: null
      buttons: [
        { text: 'Cancel' }
        {
          text: 'OK'
          type: 'button-positive'
          onTap: (e)->
            passcode = angular.element(e.currentTarget).scope().passcode
            e.preventDefault() if !passcode
              # //don't allow the user to close unless he enters passcode password
            return passcode if passcode
        }
      ]
    }

    modalOptions_ShowInkEffect = {
      modalCallback: (modal)->
        ionic.material?.ink.displayEffect()
        return
    }



    self = {
      'bookingWizard': (event)->
        # called by filteredFeed.inviteActions.accept() or EventDetailCtrl.on.beginBooking
        return $q.when()
        .then ()->
          return AAAHelpers.showSignInRegister('sign-in') if !Meteor.userId()
          return Meteor.user()
        .then (person)->
          # switch event.type
          templateName = "request-seat.modal.html"
          return self.beginBooking(templateName, person, event)
        .then (result)->
          return participation = result

      getShareLinks: (event, vm)->
        vm ?= this
        target = null
        return $q.when()
        .then ()->
          return TokensResource.get([$stateParams.invitation]) if $stateParams.invitation
          target = ['Event', event._id].join(':')
          return TokensResource.query({target: target})
        .then (results)->
          # return token if TokensResource.isTokenValid(token)
          tokens = _.filter results, (token)->
            return TokensResource.isTokenValid(token)
          return $q.reject('NONE') if _.isEmpty tokens
          return tokens
        .catch (err)->
          return $q.reject(err) if /EXPIRED|INVALID|NONE/.test(err) == false
          return $q.when [] if !$rootScope.currentUser
          # TODO: check permission to create new Token
          token = {
            ownerId: $rootScope.currentUser._id
            target: target
            views: 0
            expireCount: 100
            expireDate: event.startTime
            accessors:[]
          }
          return TokensResource.post(token).then (token)->
            return [token]
        .then (tokens)->
          baseurl = __meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL + '/#'
          eventLink = baseurl + '/app/event-detail/' + event._id
          shareLinks = {
            'event': if event.settings['isExclusive'] then false else eventLink
          }
          if event.settings['denyGuestShare'] && $rootScope.currentUser._id != vm.event.ownerId
            shareLinks['invitations'] = false
          else
            shareLinks['invitations'] = _.map tokens, (token)->
              return {
                link: baseurl + '/app/invitation/' + token.id
                id: token.id
                views: token.views
                remaining: token.expireCount - token.views
                expires: moment(token.expireDate).fromNow()
              }
          return shareLinks

      # NOTE: this method is used for display by modal
      showShareLinksByModal: (event)->
        vm = this
        return $q.when()
        .then ()->
          return self.getShareLinks.call(vm, event)
        .then (shareLinks)->
          # utils.ga_PageView('/share', '.share', 'append')
          # modalAfterShow()
          return appModalSvc.show('events/sharing.modal.html', vm, {
            mm:
              item: event
              links: shareLinks
              goto: (type, id)->
                if type.currentTarget
                  ev = type
                  target = id
                  # emulate SocialSharing with browser tab
                  label =
                    if /invitation/.test(target)
                    then 'invitation'
                    else 'event'
                  # utils.ga_Send('send'
                  #   , 'event', 'social', 'sharing', label, 20)
                  if ionic.Platform.isWebView()
                    #  we might want to open with inAppBrowser
                    ev.preventDefault()
                    window.open(target, '_system')
                    return false
                  return true




                if type == 'invitation' # goto Invite
                  state = 'app.invitation'
                  params = {invitation: id}
                  # utils.ga_Send('send'
                  #   , 'event', 'social', 'sharing', 'invitation', 20)
                if type == 'event' # goto Event
                  state = 'app.event-detail'
                  # params = {id: id}
                  # utils.ga_Send('send'
                  #   , 'event', 'social', 'sharing', 'event', 20)

                if utils.isDev()
                  $log.info "TESTING: manually transition to state=" + JSON.stringify [state,id]
                  # $state.transitionTo(state, params)
                  return true # continue

          }
          , modalOptions_ShowInkEffect
          )
        .then (result)-> # closeModal(result)
          return $q.reject('CANCELED') if `result==null` || result == 'CANCELED'
          return $q.reject(result) if result?['isError']
          return result

      goShareLink: (type, id)->
        if type.currentTarget
          ev = type
          target = id
          # emulate SocialSharing with browser tab
          label =
            if /invitation/.test(target)
            then 'invitation'
            else 'event'
          # utils.ga_Send('send'
          #   , 'event', 'social', 'sharing', label, 20)
          if ionic.Platform.isWebView()
            #  we might want to open with inAppBrowser
            ev.preventDefault()
            window.open(target, '_system')
            return false
          return true


        if type == 'invitation' # goto Invite
          state = 'app.invitation'
          params = {invitation: id}
          # utils.ga_Send('send'
          #   , 'event', 'social', 'sharing', 'invitation', 20)
        if type == 'event' # goto Event
          state = 'app.event-detail'
          params = {id: id}
          # utils.ga_Send('send'
          #   , 'event', 'social', 'sharing', 'event', 20)

        if utils.isDev()
          $log.info "TESTING: manually transition to state=" + JSON.stringify [state,id]
          # $state.transitionTo(state, params)
          return true # continue


      ###
      # @description show invitation response modal and handle response
      #     also use repsonse modal to update participation
      ###
      beginResponse: (person, event)->
        vm = this
        return $q.when()
        .then ()->
          if person && person == vm.lookup['Participations'][person.id]
            participation = person
            # recover anonymous response with passcode
            return $ionicPopup.show(passcodePopup)
            .then (response)->
              key = ParticipationsResource.setResponseId(person, response, 'peek')
              return participation if key == participation.responseId
              toastr.warning "The passcode did not match"
              return $q.reject('WARNING: The passcode did not match or records')
        .then (participation)->
          options = {}
          participation = vm.getParticipationByUser(person) if !participation
          if $state.is('app.invitation')
            # assume invitation is valid if we got this far
            return $q.reject('INVALID') if !$state.params.invitation
          if $state.is('app.event-detail')
            # return OK if there is a No/Maybe response
            return $q.reject('INVALID') if !participation

          if participation
            options['displayName'] = participation.responseName
            options['response'] = participation.response
            options['seats'] = participation.seats
            options['comment'] = participation.comment
            # TODO: shouldn't extract passcode here,
            # just offer user a chance to change passcode, and save to server
            options['passcode'] = participation.responseId?.split('~').shift()
          if person?.displayName # override
            options['displayName'] = person.displayName

          if event.settings['denyRsvpFriends']
            options['maxSeats'] = 1
            options['defaultSeats'] = 1
          else
            options['maxSeats'] = Math.min event.seatsOpen, event.settings['rsvpFriendsLimit']
            options['defaultSeats'] = 0

          return options

        .then (options={})->
          # $log.info options
          if !options
            utils.ga_PageView('/respond', '.respond', 'append')
          else
            utils.ga_PageView('/edit', '.edit', 'append')
          # modalAfterShow()
          return appModalSvc.show('events/respond.modal.html', vm, {
            mm:   # mm == "modal model" instead of view model
              placeholder:
                comment:''
              _response: options['response'] || null # response
              seats:
                max: options['maxSeats']
              isResponse: (value)->
                return value == this._response if value
                return this._response
              setResponse: (value)->
                this._response = value
                this.commentPlaceholder(value)
                return value
              isValidated: (response)->
                return false if this._response == null
                switch this._response
                  when 'Yes'
                    return true if Meteor.userId()
                    return false
                  when 'No', 'Maybe'
                    if not Meteor.userId()
                      return true if response.displayName && response.passcode
                      return false
                    return true
                  else
                    return false

              commentPlaceholder: (action)->
                switch action
                  when 'No'
                    msg = "Add a message to show you'll be there in spirit."
                  when 'Maybe'
                    msg = "Add a message to show your support."
                  else
                    msg = "Add a message to announce your participation!"
                # $log.info "placeholder=" + msg
                return this.placeholder.comment = msg

              signInRegister: (action, person)->
                # update booking user after sign in/register
                return self.showSignIn.call(vm, action)
                .then (result)->
                  _.extend person, result
                  return

              submitResponse: (ev, myResponse, onSuccess)->
                return if this.isValidated(myResponse['response']) == false
                # some sanity checks
                if vm.event._id != myResponse.event._id
                  toastr.warning("You are booking for a different event. title=" +
                    myResponse.event.title)
                if $rootScope.currentUser && myResponse.person?.id != $rootScope.currentUser._id
                  toastr.warning("You are booking for a different person. name=" +
                    myResponse.person.displayName)
                if myResponse.person?.id
                  toastr.info("You are updating your response")
                if myResponse.response.seats < 1
                  toastr.warning("You must respond for at least 1 person")

                myResponse.response['value'] = this._response

                return promise = self.saveResponse.call(vm, myResponse)
                .then (result)->
                  onSuccess?(result)
                  return result


            myResponse :
              person: person
              event: event
              response:
                value: options['response']  # set in submitResponse(), [No|Maybe|Yes]
                displayName: options['displayName'] || person?.displayName
                passcode: options['passcode']
                seats: options['seats'] || options['defaultSeats']
                comment: options['comment']
          }
          , modalOptions_ShowInkEffect
          )
        .then (result)->
          $log.info "Invitation Response Modal resolved, result=" + JSON.stringify result
        .catch (err)->
          toastr.warning "Expecting an invitation" if err == "INVALID"


      ###
      @description create/update an invitation response
      applies to Yes|Maybe|No, save to ParticipationResource
      ###
      saveResponse: (myResponse)->
        vm = this
        response = myResponse.response
        participation = vm.getParticipationByUser(myResponse.person)
        return $q.when()
        .then ()->
          data = {
            eventId: myResponse.event._id
            participantId: myResponse.person?.id || null
            response: response.value
            seats: response.seats
            comment: response.comment
            responseId: null  # set by ParticipationsResource.setResponseId()
            responseName: response.displayName
          }
          switch response.value
            when 'Yes'
              # require valid user, anonymous response not allowed
              toastr.warning "Expecting Yes response with valid user" if data.participantId==null
            when 'Maybe','No'
              ParticipationsResource.setResponseId( data, response.passcode) if !data.participantId
          if data['participantId'] # final cleanup
            data['responseName'] = data['responseId'] = null
          if participation
            return ParticipationsResource['put'](participation.id, data)

          # new response
          maxSeats =
            if myResponse.event.settings['denyRsvpFriends']
            then 1
            else myResponse.event.settings['rsvpFriendsLimit']
          return $q.reject('RSVP FRIENDS LIMIT') if data['seats'] > maxSeats

          return ParticipationsResource['post'](data)
        .then (result)->
          # google analytics event
          if participation
            utils.ga_Send('send'
              , 'event', 'participation', 'update', myResponse.response['value'], 2)
          else if result.responseId
            utils.ga_Send('send'
              , 'event', 'participation'
              , 'response-anonymous', myResponse.response['value'], 5)
          else
            utils.ga_Send('send'
              , 'event', 'participation'
              , 'response-user', myResponse.response['value'], 10)

          # for anonymous responses, look for response in
          # $rootScope.currentUser.participation, delete on sign-in
          if $rootScope.currentUser?.participation?
            _.extend( $rootScope.currentUser.participation, result )
          if _.isEmpty $rootScope.currentUser
            $rootScope.currentUser['participation'] = result

          if result.responseId
            toastr.info "Please use passcode='" + response.passcode + "' to update your response."

          $rootScope.$broadcast 'event:participant-changed', result
          return result

      ###
      # @description show booking/join event modal and handle response
      # called by EventDetailCtrl:button.JoinEvent
      ###
      beginBooking: (templateName, person, event)->
        templateName ?= 'booking.modal.html'
        template = 'events/modal-actions/' + templateName

        options = {}
        return $q.when()
        .then ()->
          return self.isInvitationValid(event)
        .then ()->
          # utils.ga_PageView('/booking', '.booking', 'append')

          if event.settings['denyRsvpFriends']
            options['maxSeats'] = 1
            options['defaultSeats'] = 1
          else
            options['maxSeats'] = Math.min( event.seatsOpen
            , event.settings['rsvpFriendsLimit'] || 999
            )
            options['defaultSeats'] = 0
          # modalAfterShow()
          return appModalSvc.show( template
          , 'EventBookingCtrl as mm'
          , {
            copyToModalViewModal :
              person: person
              event: event
              booking:
                userId: person._id
                seats: options['defaultSeats']
                maxSeats: options['maxSeats']
                message: null
                attachment: null
                address: null
                location: null
          }
          ,modalOptions_ShowInkEffect)
        .then (result)->
          $log.info ["Booking Modal resolved", result]
          return result

      ###
      # @description check event.setting to determine if invitation is required to join Event
      #   if so check for valid invitation Token
      ###
      isInvitationValid: (event)->
        return $q.when()
        .then ()->
          return true if $state.is('app.invitation')
          if event.settings['isExclusive'] || $state.params.invitation
            return TokensResource.isValid($state.params.invitation, 'Event', event._id)
        .catch (result)->
          $log.info "Token check, value="+result
          toastr.info "Sorry, this event is by invitation only." if result=='INVALID'
          if result=='EXPIRED'
            toastr.warning """
            Sorry, this invitation has expired. Please contact the host for another.
            """
          return $q.reject(result)

      showSignIn: (initialSlide, vm)->
        vm = this if !vm
        return AAAHelpers.showSignInRegister.apply(vm, arguments)
        .then (result)-> # closeModal(result)
          return $q.reject('CANCELED') if `result==null` || result == 'CANCELED'
          return $q.reject(result) if result?['isError']
          return result




      ###
      # @description show contribute to event modal and handle response
      # called by EventDetailCtrl:button Contribute
      ###
      beginContribute: (mitem, category)->
        vm = this
        modalModel = {
          menu:
            categories: vm.event.menu?.allowCategoryKeys
            selected: category
          submitContribute: (contribution, onSuccess)->
            if contribution.isNewMenuItem
              if vm.event.settings['denyAddMenu']
                return $q.reject("DENY ADD MENU")
              promise = self.createMenuItem.call(vm, contribution.menuItem)
              .then (menuItem)->
                contribution['contribution'].menuItemId = menuItem.id
                contribution.isNewMenuItem = false
                return contribution
              , (err)->
                toastr.error "Error creating NEW menuItem"
            else
              promise = $q.when contribution
            promise.then (contribution)->
              self.createContribution.call(vm, contribution).then (result)->
                # utils.ga_Send('send', 'event', 'participation', 'contribution', 'Yes', 10)
                onSuccess?(result)
                return result
            return

          # TODO: refactor, repeated in menuItem.controller.coffee
          getOpenGraph: (url, model)->
            $meteor.call( 'getOpenGraph', url )
            .then (og)->
              return if _.isEmpty og
              # TODO: change model fields to match og fields
              model.pic = og['og:image'] if og['og:image']?
              model.detail = og['og:description'] if og['og:description']?
              model.title = og['og:title'] if og['og:title']?
              model.link = og['og:url'] if openGraph['og:url']?
              model['og'] = _.omit og, ['og:title', 'og:description', 'og:image', 'og:url']
              return og

        }
        if `mitem==null`
          # utils.ga_PageView($location.path() + '/contribute/new' , 'app.event-detail.contribute')
          # modalAfterShow()
          return appModalSvc.show('events/contribute-new.modal.html', vm, {
          mm: modalModel
          myContribution :
            isNewMenuItem: true
            maxPortions: Math.min(12, vm.event.seatsTotal)
            menuItem:
              id: null
              title: ''
              detail: ''
              category: modalModel.menu.selected || null
              pic: null
              link: null
            # label: label
            contribution:
              eventId: vm.event._id
              menuItemId: null
              contributorId: $rootScope.currentUser._id
              portions: Math.min(12, vm.event.seatsTotal)
              portionsRequired: null   # TODO: allow create from to set portionsRequired
              comment: null
          },modalOptions_ShowInkEffect)

        dishes = ['Starter','Side','Main','Dessert']
        # label = if dishes.indexOf(mitem.category) > -1 then 'dish' else 'item'
        utils.ga_PageView($location.path() + '/contribute/' + mitem.id
          , 'app.event-detail.contribute')
        # modalAfterShow()
        appModalSvc.show('events/contribute.modal.html', vm, {
          mm: modalModel
          myContribution :
            menuItem: mitem
            # label: label
            contribution:
              eventId: vm.event._id
              menuItemId: mitem.id
              contributorId: $rootScope.currentUser._id
              portions: Math.min(12, mitem.summary.portionsRemaining)
              comment: null
          },modalOptions_ShowInkEffect)
        .then (result)->
          result = _.omit result, ['contributor', 'menuItem']
          $log.info "Contribute Modal resolved, result=" + JSON.stringify result
        return

      createContribution: (options, vm)->
        vm = this if !vm
        menuItem = options.menuItem
        contrib = options.contribution
        # clean up data
        contrib.portions = parseInt contrib.portions

        return $q.reject("expecting menuItem") if !menuItem
        isCreate = false
        # TODO: use Resty::methods
        found = _.filter vm.lookup['Contributions']
          , _.pick contrib, ['contributorId','menuItemId','eventId']

        if found.length > 1
          toastr.warning "Warning: same menu item contributed by same person more than once"
        if found.length == 1
          # update portion from existing contrib
          updateObj = angular.copy found[0]
          updateObj['portions'] += contrib.portions
          updateObj['comment'] =
            if updateObj.comment
            then [updateObj.comment, contrib.comment].join('; ')
            else contrib.comment
          # updateObj.sort = Date.now()
          promise = ContributionsResource.put( updateObj.id, updateObj )
        else if vm.lookup['MenuItemContributions'][menuItem.id].length > 0
          # follow-on contribution, create NEW contrib record
          isCreate = true
          updateObj = contrib
          promise = ContributionsResource.post( updateObj )
        else if !_.find(vm.lookup['Contributions'], _.pick(contrib, ['menuItemId','eventId']))
          # first contribution for NEW menuItem
          isCreate = true
          updateObj = contrib
          promise = ContributionsResource.post( updateObj )
        else if vm.lookup['MenuItemContributions'][menuItem.id].length == 0
          # first contribution to existing menuItem
          #   assign contributorId to record,
          found = _.find(vm.lookup['Contributions'], _.pick(contrib, ['menuItemId','eventId']))
          if found.contributorId
            # reset this contribution, it was not from an yesParticipationId
            # if it were, it would have appeared in vm.lookup['MenuItemContributions'][menuItem.id]
            found.portions = 0
            found.contributorId = null
          if !found
            toastr.error "Error: Expecting empty Contribution record for menuItemId="+menuItem.id
          # update portion from existing contrib
          updateObj = angular.copy found
          updateObj['contributorId'] = contrib.contributorId
          updateObj['portions'] += contrib.portions
          updateObj['comment'] =
            if updateObj.comment
            then [updateObj.comment, contrib.comment].join('; ')
            else contrib.comment
          promise = ContributionsResource.put( updateObj.id, updateObj )


        else
          toastr.error "Error: no MenuItemContributions record for id="+menuItem.id


        return promise
        .then (result)->
          # register person as contributor
          if !~vm.event['contributorIds'].indexOf( $rootScope.currentUser._id )
            vm.event['contributorIds'].push( $rootScope.currentUser._id )
          vm.lookup['Contributions'][result.id] = result # copy
          # update contrib in MenuItemContributions lookup
          contribs = vm.lookup['MenuItemContributions'][result.menuItemId]
          i = _.findIndex(contribs, {id:result.id})
          if i = -1
            vm.lookup['MenuItemContributions'][result.menuItemId].push result
          else
            vm.lookup['MenuItemContributions'][result.menuItemId][i] = result
          # update MyParticipation.contributionIds,  .contributions
          vm.lookup['MyParticipation'] = vm.getParticipationByUser($rootScope.currentUser)
          if !~vm.lookup['MyParticipation']?.contributionIds.indexOf( result.id )
            vm.lookup['MyParticipation'].contributionIds.push( result.id )
          # need to getDerivedValues()
          $rootScope.$broadcast 'lookup-data:changed', {className:'Contributions'}
          return result
        , (err)->
          toastr.error( "Error updating Contribution, o=" + updateObj)
          return
        .then (contribution)->
          $rootScope.$broadcast 'event:contribution-changed', options
          message = "Congratulations, you are signed-up to contribute " + contribution.portions
          message += " portions of " + options.menuItem.title + "."
          toastr.info message
          $timeout ()-> vm.on.scrollTo('cp-participant')
          return contribution

      createMenuItem: (menuItem, vm)->
        vm = this if !vm

        MenuItemsResource.post(menuItem)
        .then (menuItem)->
          # add to Event
          if !~vm.event['menuItemIds'].indexOf( menuItem.id)
            vm.event['menuItemIds'].push( menuItem.id)

          vm.lookup['MenuItems'][menuItem.id] = menuItem
          vm.lookup['MenuItemContributions'][menuItem.id] = []
          $rootScope.$broadcast 'lookup-data:changed', {className:'MenuItem'}
          return menuItem

    }

    return self # EventActionHelpers


EventActionHelpers.$inject = ['$rootScope', '$q', '$timeout'
'$location', '$state', '$stateParams', '$ionicPopup'
'$log', 'toastr'
# 'TokensResource', 'ParticipationsResource', 'ContributionsResource', 'MenuItemsResource'
'FeedResource', 'IdeasResource', 'TokensResource'
'AAAHelpers', '$filter'
'appModalSvc', 'utils', 'exportDebug'
]


angular.module 'starter.events'
  .factory 'EventActionHelpers', EventActionHelpers
