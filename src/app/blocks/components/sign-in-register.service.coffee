# sign-in-register.service.coffee
'use strict'

CALLBACKS = {
  signIn: (data)-> return [data]
  checkIfUserExists: (username)->
    return []
  register: (data)-> return data
  notImplemented: (label)->
    console.log ["Sorry,", label, "is not available yet."].join(' ')
}

MODAL_VIEW = {
  TEMPLATE: 'blocks/components/sign-in-register.template.html'
  CONTENT_HEIGHT: 424             # ion-modal-view.modal.height
  GRID_RESPONSIVE_SM_BREAK: 680   # sass: $grid-responsive-sm-break
  MESSAGE: {}
  ERROR:
    REQURIED: 'Please enter a value.'
    USERNAME_EXISTS: 'Sorry, that username is already taken.'
    USERNAME_INVALID: 'Please use only letters and numbers in your username.'
    USERNAME_LENGTH: "Username must be between 3-15 characters long."
    PASSWORD_LENGTH: "Password must be at least 5 characters long."
    PASSWORD_EMPTY: 'Please enter a password.'
    PASSWORD_NO_MATCH: 'Sorry, your passwords do not match.'
    EMAIL_INVALID: "Email must be a valid e-mail address."
    USER_NOT_FOUND: 'Sorry, the username and password combination was not found.'
    EMAIL_NOT_FOUND: 'Sorry, the email you provided was not found.'

  DEFAULT_SLIDE: 'signin'         # ['signup', 'signin']
}

signInRegisterSvcConfig = (fnSignIn, fnRegister, fnNotImplemented)->
  return

signInRegisterSvcConfig.$inject = []



###
# @description Sign-in or Register modal service
# shows $ionicModal for allowing user sign-in or register
###
SignInRegister = ($q, appModalSvc)->

  self = {

    # entry point for this service
    showSignInRegister: (initialSlide, callbacks)->
      CALLBACKS.signIn = callbacks.signIn if _.isFunction callbacks.signIn
      if _.isFunction callbacks.checkIfUserExists
        CALLBACKS.checkIfUserExists = callbacks.checkIfUserExists
      CALLBACKS.register = callbacks.register if _.isFunction callbacks.register
      CALLBACKS.notImplemented = callbacks.notImplemented if _.isFunction callbacks.notImplemented
      return appModalSvc.show(
        MODAL_VIEW.TEMPLATE
        'SignInRegisterCtrl as sir'
        {
          initialSlide: initialSlide
          person: {}
        }
      ).then (result)->
        console.log ['showSignInRegister', result]
        result ?= 'CANCELED'
        return $q.reject('CANCELED') if result == 'CANCELED'
        return $q.reject(result) if result?['isError']
        return result

  }
  return self

SignInRegister.$inject = ['$q', 'appModalSvc']



###
# @description controller for appModalSvc $ionicModal
#
###
SignInRegisterCtrl = ($scope, parameters, $q, $timeout, $window)->
  sir = this
  sir.isBrowser = not ionic.Platform.isWebView()
  sir.MESSAGE = MODAL_VIEW.MESSAGE

  sir['ionSlidesCtrl'] = {
    options:
      initialSlide: 0
      direction: 'horizontal'
      pager: false  # not working
      loop: false
      # autoplay: true
      # keyboardControl: true
      # width: 375
      # height: 667

    slider: null
    setSlide: (name, $ev)->
      $ev.preventDefault() if $ev
      self = sir['ionSlidesCtrl']
      console.log ["slideTo=",name]
      switch name
        when 'register', 'sign-up', 'signup'
          index = 0
        when 'sign-in', 'signin'
          index = 1
          # selector = '#' + vm.viewId + ' input'
          # setTimeout ()->return document.querySelector(selector ).focus()
        when 'password-reset'
          index = 2
        when 'default'
          index = self.options.initialSlide
        else
          index = self.options.initialSlide
      self.slider.slideTo(index)

  }
  sir['error'] = {}
  sir['on'] = {
    signIn: (data={}, fnComplete)->
      sir['error'] = {}
      return $q.when()
      .then ()->
        return $q.reject('NOT FOUND') if !data.username
        data.username = data.username.toLowerCase().trim()
        return CALLBACKS.signIn(data) # from AAAHelpers
      .then (results)->
        person =
          if _.isArray results
          then results.shift()
          else results
        return $q.reject('NOT FOUND') if _.isEmpty person
        return person
      .then (result)->
        # success
        sir.closeModal(result)
        return result
      .catch (err)->
        if err.errorType == "Meteor.Error"
          switch err.reason
            when 'User not found' # err.error==403
              sir['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
              data.password = null

        if err == 'NOT FOUND'
          sir['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
          data.password = null

        return $q.reject(err)

    'AP': # accounts-password
      # case-insensitive Meteor.find()
      findByUsername: (username)->
        dfd = $q.defer()
        Meteor.call('User.findByUsername', username
        , (err, user)->
          return dfd.reject(err) if err
          console.info ['findByUsername', user]
          return dfd.resolve( user )
        )
        return dfd.promise

      # case-insensitive Meteor.find()
      findByEmail: (username)->
        dfd = $q.defer()
        Meteor.call('User.findByEmail', username
        , (err, user)->
          return dfd.reject(err) if err
          console.info ['findByEmail', user]
          return dfd.resolve( user )
        )
        return dfd.promise

      #TODO: move to AAAHelpers??
      'loginWithPassword': (credentials)->
        dfd = $q.defer()
        Meteor.loginWithPassword( credentials.username, credentials.password
        , (err)->
          return dfd.reject(err) if err
          return dfd.resolve( "SUCCESS" )
        )
        return dfd.promise
        .catch (err)->
          if err.errorType == "Meteor.Error"
            switch err.reason
              when 'User not found', 'Incorrect password'
                sir['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
                credentials.password = null


          console.warn ['ERROR: loginWithPassword', err.message]
          return $q.reject(err)
        .then ()->
          console.info ['loginWithPassword SUCCESS']
          user = Meteor.user()
          sir.closeModal(user)
          return user


      'loginWithFacebook': ()->
        dfd = $q.defer()
        fbOptions = {
          loginStyle: 'popup'
          requestPermissions: ['public_profile','email','user_friends']
        }
        # TODO: pass requestPermissions to accounts-password-cordova plugin
        Meteor.loginWithFacebook fbOptions
        , (err)->
          # handle these errors
          # if err instanceof Accounts.LoginCancelledError
          # if err instanceof ServiceConfiguration.ConfigError
          return dfd.reject(err) if err
          return dfd.resolve( 'SUCCESS' )
        return dfd.promise
        .catch (err)->
          # if err.errorType == "Meteor.Error"
          #   switch err.reason
          #     when 'User not found' # err.error==403
          #       sir['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
          #       data.password = null

          console.warn ['ERROR: loginWithFacebook', err.message]
          return $q.reject(err)
        .then ()->
          console.info ['loginWithFacebook SUCCESS']
          user = Meteor.user()
          sir.closeModal(user)
          return user

      # borrowed from accounts-ui-unstyled.js
      clientSideValidation: (credentials)->
        errorMsgs = {}

        # username
        if credentials.username.length < 3 || credentials.username.length > 15
          errorMsgs['username'] = MODAL_VIEW.ERROR.USERNAME_LENGTH

        # password
        if credentials.password.length < 5
          errorMsgs['password'] = MODAL_VIEW.ERROR.PASSWORD_LENGTH

        #  email optional
        if credentials.email
          if credentials.email.indexOf('@') == -1
            errorMsgs['email'] = MODAL_VIEW.ERROR.EMAIL_INVALID

        return errorMsgs

      'register': (data={}, fnComplete)->
        credentials = _.pick data, ['username','email','password', 'profile']
        credentials.password ?= ''  # Accounts.createUser() fails on undefined

        errorMsgs = this.clientSideValidation(credentials)
        if not _.isEmpty errorMsgs
          sir.error = errorMsgs
          return

        dfd = $q.defer()
        sendEnrollmentEmail = credentials.email && not credentials.password

        Accounts.createUser( credentials, (err)->
          return dfd.reject(err) if err
          return dfd.resolve( Meteor.user() )
        )
        return dfd.promise
        .catch (err)->
          console.warn err
          if err.errorType == "Meteor.Error"
            switch err.reason
              when 'Username already exists.' # err.error==403
                sir['error']['username'] = MODAL_VIEW.ERROR.USERNAME_EXISTS
              when "Username failed regular expression validation"
                sir['error']['username'] = MODAL_VIEW.ERROR.USERNAME_INVALID
              when 'Password may not be empty'
                sir['error']['password'] = MODAL_VIEW.ERROR.REQUIRED
              when "Address must be a valid e-mail address"
                sir['error']['email'] = MODAL_VIEW.ERROR.EMAIL_INVALID
              when 'REQUIRED VALUE'
                sir['error']['username'] = MODAL_VIEW.ERROR.REQUIRED
            return $q.reject(err)
        .then (user)->
          if sendEnrollmentEmail
            Accounts.sendEnrollmentEmail?(user._id)
          else if credentials.email
            Accounts.sendVerificationEmail?(user._id)
          sir.closeModal(user)
          return user

      'resetPassword': (token, newPwd, cb)->
        return

      'changePassword': (oldPwd, newPwd, cb)->
        return

    register: (data={}, fnComplete)->
      sir['error'] = {}
      return $q.when()
      .then ()->
        return $q.reject('REQUIRED VALUE') if !data.username
        data.username = data.username.toLowerCase().trim()

        return CALLBACKS.checkIfUserExists(data)
      .then (results)->
        found =
          if _.isArray results
          then results.shift()
          else results
        return $q.reject('DUPLICATE USERNAME') if !_.isEmpty( found )
        return CALLBACKS.register(data) # from AAAHelpers
      .then (result)->
        # success
        sir.closeModal(result)
        return result
      .catch (err)->
        if err.errorType == "Meteor.Error"
          switch err.reason
            when 'Username already exists.' # err.error==403
              sir['error']['username'] = MODAL_VIEW.ERROR.USERNAME_EXISTS

        if err == 'REQUIRED VALUE'
          sir['error']['username'] = MODAL_VIEW.ERROR.REQUIRED
        if err == 'DUPLICATE USERNAME'
          sir['error']['username'] = MODAL_VIEW.ERROR.USERNAME_EXISTS
        return $q.reject(err)
    notImplemented: (value)->
      return CALLBACKS.notImplemented(value)
  }

  init = ()->
    stop = $scope.$on 'modal.afterShow', (ev)->
      # h = setModalHeight()
      stop?()
      return
    return

  setModalHeight = ()->
    # calculate modalHeight and set margin-top/bottom

    contentH =
      if $window.innerWidth <= MODAL_VIEW.GRID_RESPONSIVE_SM_BREAK  # same as @media(max-width: 680)
      then $window.innerHeight
      else Math.max( MODAL_VIEW.CONTENT_HEIGHT, $window.innerHeight)

    marginH = ($window.innerHeight - contentH)/2
    modalH = Math.max( MODAL_VIEW.MAP_MIN_HEIGHT , modalH)
    # console.log ["height=",$window.innerHeight , contentH,modalH]

    styleH = """
      #sign-in-register-modal-view.modal {top:%marginH%px; bottom:%marginH%px; height:%modalH%px}
    """
    styleH = styleH.replace(/%marginH%/g, marginH).replace(/%modalH%/g, modalH)
    angular.element(document.getElementById('address-lookup-style')).append(styleH)
    return modalH

  init()
  return sir

SignInRegisterCtrl.$inject = ['$scope', 'parameters', '$q', '$timeout', '$window']


angular.module 'blocks.components'
  .config signInRegisterSvcConfig
  .factory 'signInRegisterSvc', SignInRegister
  # .directive 'clearField', ClearFieldDirective
  .controller 'SignInRegisterCtrl', SignInRegisterCtrl
