'use strict'

appRun = ($ionicPlatform, $ionicHistory, $rootScope, $location
  $log, devConfig, AAAHelpers
) ->

  devConfig.loadData()

  $rootScope['loadOnce'] = []

  $rootScope.user = Meteor.user()
  AAAHelpers._backwardCompatibleMeteorUser($rootScope.user)

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
    positionClass: 'toast-bottom-left'
  }

ionicConfig = ($ionicConfigProvider)->
  $ionicConfigProvider.backButton.text('')
  $ionicConfigProvider.backButton.previousTitleText(false)
  $ionicConfigProvider.views.forwardCache(true)
  return

ionicConfig.$inject = ['$ionicConfigProvider']





appRun.$inject = ['$ionicPlatform', '$ionicHistory', '$rootScope', '$location',
  '$log', 'devConfig', 'AAAHelpers'
]

angular
  .module 'starter.core'
  .config toastrConfig
  .config ionicConfig
  .run appRun
