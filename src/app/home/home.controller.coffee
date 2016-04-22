'use strict'

HomeCtrl = (
  $scope, $rootScope, $q, $location, $timeout
  $state
  $ionicScrollDelegate, $ionicHistory, $listItemDelegate
  $log, toastr
  HomeResource, EventsResource, IdeasResource
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.title = "Discover"
    vm.me = null      # current user, set in initialize()
    vm.imgAsBg = utils.imgAsBg

    vm.settings = {
      show: 'less'
      loadMore: false
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

      goto: (targetStr)->
        # event.stopImmediatePropagation()
        console.log(['transitionTo', target])
        try
          target = JSON.parse(targetStr)
          $state.go( target.state, target.params )
        catch err
          $state.go targetStr



      loadMore: ()->
        vm.cards = vm.cards.concat( angular.copy vm.all )
        startMaterialEffects()
        vm.settings.more = false if vm.cards > 12

    }

    appendCardClasses = (items)->
      promises = []
      events = _.filter items, {class:'event'}
      promises.push EventsResource.get( _.map( events, 'classId')).then (classItems)->
        _.each events, (item)->
          event = _.find classItems, {id: item.classId}
          if event
            item.title = event['title']
            item.heroPic = event['heroPic']
            # TODO: use gotoState()
            item.target = 'app.event-detail({id:' + event.id + '})'
            item.description = 'Event'
          return
        return classItems

      menuItems = _.filter items, {class:'menuItem'}
      promises.push IdeasResource.get( _.map( menuItems, 'classId')).then (classItems)->
        _.each menuItems, (item)->
          mitem = _.find classItems, {id: item.classId}
          if mitem
            item.title = mitem['title']
            item.heroPic = mitem['image']
            # TODO: use gotoState()
            item.target = 'app.recipe({id:' + mitem.id + '})'
            item.description = 'Menu Item'
          return
        return classItems
      return $q.all promises


    getData = () ->
      HomeResource.query().then (cards)->
        vm.all = cards
        exportDebug.set( 'home', vm.all )
        # toastr.info JSON.stringify( cards)[0...50]
        return cards


    initialize = ()->
      vm.listItemDelegate = $listItemDelegate.getByHandle('home-list-scroll', $scope)
      return $q.when()
      .then ()->
        if $location.search()['user']
          DEV_USER_ID = $location.search()['user']
          $location.search('user', null)
          force = true
        else
          DEV_USER_ID = '6'
          $rootScope.demoRole = 'invited'
        devConfig.loginUser( DEV_USER_ID , force)
      .then (user)->
        vm.me = $rootScope.user
      .then ()->
        getData()
      .then (cards)->
        appendCardClasses(cards)
      .then ()->
        vm.rows = angular.copy( vm.all )


    activate = ()->
      return $q.when()
      .then ()->
        $ionicHistory.clearHistory()
      .then ()->
        ionic.material?.ink.displayEffect()
        ionic.material?.motion.fadeSlideInRight({
          startVelocity: 2000
        })
        return

    resetMaterialMotion = (motion, parentId)->
      className = {
        'fadeSlideInRight': '.animate-fade-slide-in-right'
        'blinds': '.animate-blinds'
        'ripple': '.animate-ripple'
      }
      selector = '{aniClass} .item'.replace('{aniClass}', className[motion] )
      selector = '#'+ parentId + ' ' + selector if parentId?
      angular.element(document.querySelectorAll(selector))
        .removeClass('in')
        .removeClass('done')

    $scope.$on '$ionicView.loaded', (e)->
      $log.info "viewLoaded for HomeCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for HomeCtrl"
      activate()

    $scope.$on '$ionicView.beforeEnter', (e)->
      if $rootScope['welcomeDone']
        _.remove vm.rows, {title:'Welcome'}

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')


    $rootScope.$on '$stateNotFound', (ev, toState)->
      ev.preventDefault()
      toastr.info "Sorry, that option is not ready."

    loadOnce = ()->
      return if ~$rootScope['loadOnce'].indexOf 'HomeCtrl'
      $rootScope['loadOnce'].push 'HomeCtrl'
      # load $rootScope listeners only once

    loadOnce()

    return vm # end HomeCtrl


HomeCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$timeout'
  '$state'
  '$ionicScrollDelegate', '$ionicHistory', '$listItemDelegate'
  '$log', 'toastr'
  'HomeResource', 'EventsResource','IdeasResource'
  'utils', 'devConfig', 'exportDebug'
]

angular.module 'starter.home'
  .controller 'HomeCtrl', HomeCtrl
