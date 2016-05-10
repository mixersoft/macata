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
    PASSWORD_NO_MATCH: 'Sorry, your passwords do not match.'
    USER_NOT_FOUND: 'Sorry, the username and password combination was not found.'
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
        'SignInRegisterCtrl as vm'
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
  vm = this
  vm.isBrowser = not ionic.Platform.isWebView()
  vm.MESSAGE = MODAL_VIEW.MESSAGE
  vm['slideCtrl'] = {
    # index = null allows us to detect init, set initialSlide in $timeout()
    index: null
    slideLabels: ['signup', 'signin']
    initialSlide: parameters.initialSlide || MODAL_VIEW.DEFAULT_SLIDE
    setSlide: (label)->
      if vm['slideCtrl'].index==null
        $timeout ()->
          # ionSlideBox not yet initialized/compiled, wrap in $timeout
          # $log.info "timeout(0)"
          label = vm['slideCtrl'].initialSlide if !label
          return vm['slideCtrl'].setSlide(label)
        return vm['slideCtrl'].index = 0

      return vm['slideCtrl'].index if `label==null` # for active-slide watch

      label = vm['slideCtrl'].initialSlide if label == 'initial'
      i = vm['slideCtrl'].slideLabels.indexOf(label)
      next = if i >= 0 then i else vm['slideCtrl'].index
      vm['error'] = {}
      return vm['slideCtrl'].index = next
  }
  vm['error'] = {}
  vm['on'] = {
    signIn: (data={}, fnComplete)->
      vm['error'] = {}
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
        vm.closeModal(result)
        return result
      .catch (err)->
        if err.errorType == "Meteor.Error"
          switch err.reason
            when 'User not found' # err.error==403
              vm['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
              data.password = null

        if err == 'NOT FOUND'
          vm['error']['username'] = MODAL_VIEW.ERROR.USER_NOT_FOUND
          data.password = null

        return $q.reject(err)

    signInFacebook: ()->
      dfd = $q.defer()
      fbOptions = {
        loginStyle: 'popup'  # ['popup', 'redirect']
        requestPermissions: ['public_profile','email','user_friends']
      }
      # HACK: meteor-client-side does not pass options correctly to Meteor.absoluteUrl()
      Meteor.absoluteUrl.defaultOptions.rootUrl = window.location.href.split('#').shift()
      Meteor.loginWithFacebook fbOptions
      , (err)->
        return dfd.reject(err) if err
        return dfd.resolve( 'SUCCESS' )
      return dfd.promise
      .then ()->
        console.info ['signInFacebook SUCCESS']
        user = Meteor.user()
        vm.closeModal(user)
        return user
      , (err)->
        console.warn ['ERROR: signInFacebook', err.message]
        return $q.reject(err)

    register: (data={}, fnComplete)->
      vm['error'] = {}
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
        vm.closeModal(result)
        return result
      .catch (err)->
        if err.errorType == "Meteor.Error"
          switch err.reason
            when 'Username already exists.' # err.error==403
              vm['error']['username'] = MODAL_VIEW.ERROR.USERNAME_EXISTS

        if err == 'REQUIRED VALUE'
          vm['error']['username'] = MODAL_VIEW.ERROR.REQUIRED
        if err == 'DUPLICATE USERNAME'
          vm['error']['username'] = MODAL_VIEW.ERROR.USERNAME_EXISTS
        return $q.reject(err)
    notImplemented: (value)->
      return CALLBACKS.notImplemented(value)
  }

  init = ()->
    stop = $scope.$on 'modal.afterShow', (ev)->
      h = setModalHeight()
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
  return vm

SignInRegisterCtrl.$inject = ['$scope', 'parameters', '$q', '$timeout', '$window']


angular.module 'blocks.components'
  .config signInRegisterSvcConfig
  .factory 'signInRegisterSvc', SignInRegister
  # .directive 'clearField', ClearFieldDirective
  .controller 'SignInRegisterCtrl', SignInRegisterCtrl
