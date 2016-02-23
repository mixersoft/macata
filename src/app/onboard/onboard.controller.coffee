'use strict'

OnboardCtrl = (
  $scope, $rootScope, $q, $state, $window
  $ionicHistory
  $log, toastr
  utils, devConfig, exportDebug
  )->

    MIN_SLIDE_W = 320

    vm = this
    vm.title = null
    vm.me = null      # current user, set in initialize()
    vm.acl = {
      isVisitor: ()->
        return true if !$rootScope.user
      isUser: ()->
        return true if $rootScope.user
    }
    vm.lookup = {
      # colors: ['royal', 'positive', 'calm', 'balanced', 'energized', 'assertive']
      colors: ['positive', 'balanced', 'assertive', 'royal']
    }

    vm.slider = null
    vm.settings = {
      show: 'less'
      auto: true
      slider:
        'HowItWorks':
          autoplay: 1000
          autoplayStopOnLast: true
          slidesPerView: 3
          keyboardControl: true
          pagination: '.swiper-pagination'
          breakpoints:
            480:
              slidesPerView: 1
            960:
              slidesPerView: 2
          onClick: (swiper, ev)->
            check = swiper
    }

    vm.on = {

      getStarted: ()->
        $ionicHistory.clearHistory()
        $state.transitionTo('app.home')

      welcomeDone: ()->
        # $rootScope['welcomeDone'] = true
        $state.transitionTo('app.home')

    }

    vm.cards = cards_onboard = [
      title   : "Community Meals"
      subTitle: "from the humble to exhalted"
      content : """

      """
      template: ''
    ,
      title   : "Find"
      subTitle: "them around the block <span class='nowrap'>or around the world</span>"
      content : """
      Search at home or on the road.
      Whether it be food, friends, or culture you can always discover something new.
      """
    ,
      title   : "Contribute"
      subTitle: "to the shared experience"
      content : """
      Show some pluck, give it your best shot.
      Bring something special and shout it out.
      Or just bring dough.
      """
    ,
      title   : "Host"
      subTitle: "meals for old friends or new"
      content : """
      Let the world come to your door, or just your friends.
      But craft your shared experience with control over the menu and guest list.
      """
    ,
      title   : "Elevate"
      subTitle: "the Community Meal"
    ]


    initialize = ()->
      switch $state.$current.name
        when 'app.onboard'
          vm.title = 'How It Works'
          vm.settings.slider['HowItWorks'].slidesPerView = 3
      # dev


    activate = ()->
      switch $state.$current.name
        when 'app.onboard'
          vm.title = 'How It Works'
          vm.settings.slider['HowItWorks'].slidesPerView = 3
        when 'app.welcome'
          vm.title='Welcome'

      # // Set Ink
      ionic.material?.ink.displayEffect()
      return

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for OnboardCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for OnboardCtrl"
      activate()

    $scope.$on '$ionicView.leave', (e)->
      vm.slider?.slideTo(0, null, false)


    return # end OnboardCtrl


OnboardCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$state', '$window'
  '$ionicHistory'
  '$log', 'toastr'
  'utils', 'devConfig', 'exportDebug'
]

angular.module 'starter.home'
  .controller 'OnboardCtrl', OnboardCtrl
