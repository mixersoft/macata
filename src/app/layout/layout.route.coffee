'use strict'

otherwisePath = '/app/events/'

appRun = (routerHelper) ->
  routerHelper.configureStates getStates(), otherwisePath

getStates = ->
  [
    state: 'tab'
    config:
      url: '/tab'
      abstract: true
      templateUrl: 'layout/tabs.html'
  ,
    state: 'app'
    config:
      url: '/app'
      abstract: true
      templateUrl: 'layout/sidemenu.html'
      controllerAs: 'vm'
      controller: [
        '$rootScope', '$ionicSideMenuDelegate'
        ($rootScope, $ionicSideMenuDelegate)->
          vm = this
          vm.demoRole = null
          vm.demoRoles = {
            'host': 'Host'
            'participant': 'Participant'
            'booking': 'Booking'
            'invited': 'Invited'
            'visitor': 'Visitor'
          }
          $rootScope.$watch '$rootScope.demoRole', (newV)->
            vm.demoRole = $rootScope.demoRole

          vm.roleChanged = ($event, role)->
            $rootScope.demoRole = role
            # $emit or $watch('$rootScope.demoRole')
            $rootScope.$emit 'demo-role:changed', role
            $ionicSideMenuDelegate.toggleLeft(false)
            return
          return vm
      ]

  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.layout'
  .run appRun
