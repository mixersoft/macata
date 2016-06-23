'use strict'

# otherwisePath = '/app/event-detail/3X8pxfsEhBrpHcdfD'
otherwisePath = '/app/feed/NCJkY7nmYeSWGqv85'
# otherwisePath = '/app/invitation/mongo'
# otherwisePath = '/app/recipe'
# otherwisePath = '/app/home'
otherwisePath = '/app/events/'
# otherwisePath = '/app/events/comingSoon'
# otherwisePath = '/app/map?id=1:Recipe'
otherwisePath = '/app/me'

appRun = (routerHelper, $location, $state) ->
  routerHelper.configureStates getStates(), otherwisePath
  if not $location.path()
    location.href = '#' + otherwisePath
  else
    location.href = '#/app'

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
        '$rootScope', '$ionicSideMenuDelegate', 'locationHelpers'
        ($rootScope, $ionicSideMenuDelegate, locationHelpers)->
          vm = this
          vm.getLocation = ($ev)->
            return locationHelpers.getCurrentPosition('loading')
            .then (result)->
              lonlat = angular.copy(result.latlon).reverse()
              Meteor.call 'Profile.saveLocation', lonlat, (err, retval)->
                'check'
            , (err)->
              console.warn ["WARNING: getCurrentPosition", err]

          vm.demoRole = null
          vm.demoRoles = {
            'host': 'Host'
            'participant': 'Participant'
            'booking': 'Booking'
            'invited': 'Invited'
            'visitor': 'Visitor'
          }
          $rootScope.$watch 'demoRole', (newV)->
            return if !newV
            vm.demoRole = $rootScope.demoRole

          vm.roleChanged = ($event, role)->
            return if !role
            $rootScope.demoRole = role
            # $emit or $watch('$rootScope.demoRole')
            $rootScope.$broadcast 'demo-role:changed', role
            $ionicSideMenuDelegate.toggleLeft(false)
            return
          return vm
      ]

  ]

appRun.$inject = ['routerHelper', '$location', '$state']

angular
  .module 'starter.layout'
  .run appRun
