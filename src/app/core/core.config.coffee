'use strict'

appRun = ($ionicPlatform, $rootScope, $location, $log) ->

  $ionicPlatform.ready ->
    # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    # for form inputs)
    if window.cordova and window.cordova.plugins and window.cordova.plugins.Keyboard
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

    if window.StatusBar
      # org.apache.cordova.statusbar required
      StatusBar.styleLightContent()

    $rootScope.goBack = (noBackTarget = 'app.home')->
      if $ionicHistory.backView()
        $ionicHistory.goBack()
      else
        $state.transitionTo(noBackTarget)
      return

    locationSearch = null
    $rootScope.$on '$stateChangeStart', (ev, toState, toParams, fromState, fromParams)->
      # save $location.search and add back after transition
      locationSearch = $location.search()

      # check if state requires user to signIn, see *.route.coffee
      requireLogin = toState.data?.requireLogin
      if requireLogin
        $log.warn "call signInRegisterSvc.showSignInRegister('signin')"

      return

    $rootScope.$on '$stateChangeSuccess', (ev, toState, toParams, fromState, fromParams)->
      # addback $location.search  after transition
      # $location.search( angular.extend(locationSearch, $location.search()) )
      return

  return # appRun

toastrConfig = (toastrConfig) ->
  angular.extend toastrConfig, {
    timeOut: 4000
    positionClass: 'toast-bottom-right'
  }





appRun.$inject = ['$ionicPlatform', '$rootScope', '$location', '$log']

angular
  .module 'starter.core'
  .config toastrConfig
  .run appRun


