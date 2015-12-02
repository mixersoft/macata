'use strict'

GridCtrl = (
  $scope, $rootScope, $location, $window
  $ionicScrollDelegate
  $log, toastr
  appModalSvc
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.title = "Grid"
    vm.me = null      # current user, set in initialize()
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.settings = {
      view:
        show: 'grid'
    }

    vm.lookup = {
      colors: ['positive', 'calm', 'balanced', 'energized', 'assertive', 'royal', 'dark', 'stable']
    }

    vm.rows = _.map [0..50], (i)-> return {
      id: i
      color: vm.lookup.colors[i %% vm.lookup.colors.length]
    }

    # grid layout methods
    vm.getColWidth = (minW)->
      pct = minW/$window.innerWidth
      return 'col-20' if pct <= 0.20
      return 'col-25' if pct <= 0.25
      return 'col-33' if pct <= 0.33
      return 'col-50' if pct <= 0.50
      return null
    angular.element($window).bind 'resize', ()->
      $scope.$apply()
      return

      
      
      



    vm.on = {
      scrollTo: (anchor)->
        $location.hash(anchor)
        $ionicScrollDelegate.anchorScroll(true)
        return

      setView: (value)->
        if 'value==null'
          next = if vm.settings.show == 'grid' then 'list' else 'grid'
          return vm.settings.view.show = next
        return vm.settings.view.show = value
    }

    initialize = ()->
      # return
      if $rootScope.user?
        vm.me = $rootScope.user
      else
        DEV_USER_ID = '0'
        devConfig.loginUser( DEV_USER_ID ).then (user)->
          # loginUser() sets $rootScope.user
          vm.me = $rootScope.user
          toastr.info "Login as userId=0"

    activate = ()->
      return

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for GridCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      # $log.info "viewEnter for GridCtrl"
      activate()

    return vm  # end GridCtrl


GridCtrl.$inject = [
  '$scope', '$rootScope', '$location', '$window'
  '$ionicScrollDelegate'
  '$log', 'toastr'
  'appModalSvc'
  'utils', 'devConfig', 'exportDebug'
]

angular.module 'starter.grid'
  .controller 'GridCtrl', GridCtrl




