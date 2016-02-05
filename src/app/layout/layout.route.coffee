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
      controller: [ '$rootScope', ($rootScope)->
        vm = this
        vm.demoRole = null
        vm.demoRoles = {
          'host': 'Host'
          'participant': 'Participant'
          'booking': 'Booking'
          'invited': 'Invited'
          'visitor': 'Visitor'
        }
        vm.roleChanged = ($event, role)->
          $rootScope.demoRole = role
          $rootScope.$emit 'demo-role:changed', role
          return
        return vm
      ]

  ]

appRun.$inject = ['routerHelper']

angular
  .module 'starter.layout'
  .run appRun
