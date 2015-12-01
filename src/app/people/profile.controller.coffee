'use strict'

ProfileCtrl = (
  $scope, $rootScope, $location, $state, $stateParams, $ionicScrollDelegate
  AAAHelpers, UsersResource
  $log, toastr
  utils, devConfig, exportDebug
  )->

    # coffeelint: disable=max_line_length
    ANON_USER = {
      id: false
      displayName: 'Just Visiting?'
      face: 'http://38.media.tumblr.com/acccd28f5b5183011cca2f279874da79/tumblr_inline_niuxsprCsL1t9pm9x.png'
    }
    DEV_USER_ID = false
    # coffeelint: enable=max_line_length

    vm = this
    vm.title = "Profile"
    vm.me = null      # current user, set in initialize()
    vm.imgAsBg = utils.imgAsBg
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.settings = {
      view:
        show: null    # [signin|profile|account]
      editing: false
      changePassword: false
    }
    vm.on = {
      scrollTo: (anchor)->
        $location.hash(anchor)
        $ionicScrollDelegate.anchorScroll(true)
        return

      setView: (value)->
        if 'value==null'
          next = if vm.settings.show == 'less' then 'more' else 'less'
          return vm.settings.show = next
        return vm.settings.show = value

      click: (ev)->
        toastr.info("something was clicked")

      showSignInRegister: (action)->
        return AAAHelpers.showSignInRegister.call(vm, action)
        .then (user)->
          vm.me = $rootScope.user
          activate()
          $log.info vm.me

      signOut: ()->
        $rootScope.user = null
        vm.me = null
        $rootScope.$emit 'user:sign-out'
        activate()
    }

    initialize = ()->
      if $rootScope.user?
        vm.me = $rootScope.user
      else
        devConfig.loginUser( DEV_USER_ID ).then (user)->
          # loginUser() sets $rootScope.user
          vm.me = $rootScope.user
          toastr.info ["Login", vm.me]
      return

    activate = ()->
      if $state.is('app.me')
        # console.log vm.me
        vm.person = angular.copy(vm.me)
        if _.isEmpty vm.person
          vm.person = ANON_USER
          vm.settings.view.show = 'signin'
        else
          vm.settings.view.show = 'profile'
        vm.settings.editing = false
        vm.settings.changePassword = false
        return

      if $state.is('app.profile')
        userid = $stateParams.id
        if !userid
          toastr.warning "Sorry, that profile was not found."
          $rootScope.goBack()
          return
        else if userid == vm.me?.id
          # looking at my own profile
          vm.person = vm.me
          promise = $q.when vm.person
        else
          # viewing someone else's profile
          promise = UsersResource.get(userid)
          .then (user)->
            return vm.person = user
        return promise
      return

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for ProfileCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for ProfileCtrl"
      activate()

    return vm  # end ProfileCtrl


ProfileCtrl.$inject = [
  '$scope', '$rootScope', '$location', '$state', '$stateParams', '$ionicScrollDelegate'
  'AAAHelpers', 'UsersResource'
  '$log', 'toastr'
  'utils', 'devConfig', 'exportDebug'
]

angular.module 'starter.home'
  .controller 'ProfileCtrl', ProfileCtrl
