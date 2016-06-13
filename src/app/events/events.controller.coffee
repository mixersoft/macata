'use strict'

EventCtrl = (
  $scope, $rootScope, $q, $location, $window, $timeout
  $ionicScrollDelegate, $state, $stateParams, $listItemDelegate
  $log, toastr
  appModalSvc, tileHelpers, openGraphSvc, eventUtils
  AAAHelpers, locationHelpers, TableEditSvc
  $reactive, $auth, UsersResource, EventsResource
  utils, devConfig, exportDebug
  )->

    vm = this
    vm.viewId = ["events-view",$scope.$id].join('-')
    vm.title = "Events"
    vm.listItemDelegate = null
    vm.RecipeM = RecipeModel::

    # required for directive:map-view
    vm.rows = []
    vm.mapRows = null
    vm.markerKeymap = {
      id: '_id'
      location: 'location'
      label: 'title'
    }
    vm.selectedItemId = null

    vm.pg = {
      perpage: 20
      page: 1
      sort:
        startTime: -1
    }
    # exportDebug.set 'pg', vm.pg
    vm.filter = {
    }

    vm.pullToReveal = {
      options:
        initialSlide: 1
        pagination: false
      slider: null
      activeSlide: null
      slide: (name)->
        self = vm.pullToReveal
        self.activeSlide = name
        speed = 0 # no animation
        switch name
          when 'setLocation'
            self.slider.slideTo(0,speed)
          when 'searchSort'
            self.slider.slideTo(1,speed)
            selector = '#' + vm.viewId + ' input'
            setTimeout ()->return document.querySelector(selector ).focus()
          when 'newTile'
            self.slider.slideTo(2,speed)
            selector = '#' + vm.viewId + ' new-tile input'
            setTimeout ()->return document.querySelector(selector ).focus()
            return
          when 'none','reset'
            self.activeSlide = null
          when 'default'
            self.slide('searchSort') # same as self.initialSlide
            # self.slider.slideTo(self.options.initialSlide)
    }
    vm.settings = {
      view:
        show: 'grid'
        'new': false
        mapMarker: 'oneMarker'
      show:
        map: false
        emptyList: false
        pullToReveal: false
        overscrollTile: (value)->
          self = vm.settings.show

          # override
          if self.emptyList && self.pullToReveal == false
            vm.pullToReveal.slide('newTile') if not vm.pullToReveal.activeSlide
            return self.pullToReveal = true

          self.pullToReveal = value if typeof value != 'undefined'

          vm.pullToReveal.slide('none') if self.pullToReveal == false
          return self.pullToReveal

        fabIcon: 'ion-plus'
    }


    _filters = {
      CONST:
        COMING_SOON_DAYS: 21
        NEARBY: 10000 # meters

      'comingSoon': ()->
        now = moment()
        return {
          label: "Coming Soon"
          sortBy: {'startTime' : 1}  # ASC
          filterBy: {
            $and: [
              {'startTime': {$gt: moment().toDate()}}
              {'startTime': {$lt: moment().add(_filters.CONST.COMING_SOON_DAYS, 'd').toDate()}}
            ]
          }
        }
      'nearby': (lonlat)->
        ###
        TODO: don't forget to create index in mongo
          $ meteor mongo
          > db.events.createIndex({geojson:"2dsphere"})
        ###
        lonlat ?= locationHelpers.lastKnownLonLat()
        if !lonlat
          toastr.warning "Your location is not available."
          return $state.go( 'app.events', {filter: 'comingSoon'})
        return {
          label: "Events Nearby"
          sortBy: {}  # $near is already sorted
          filterBy: {
            'geojson':
              $near:
                $geometry:
                  type: "Point"
                  coordinates: lonlat # [lon,lat]
                $maxDistance: _filters.CONST.NEARBY
          }
        }
      'recent': ()->
        now = moment()  # .subtract(event.duration)
        return {
          label: "Recent Events"
          sortBy: {'startTime' : -1}  # DESC
          filterBy: {
            $and: [
              {'startTime': {$lt: moment().toDate()}}
              {'startTime': {$gt: moment().subtract(_filters.CONST.COMING_SOON_DAYS, 'd').toDate()}}
            ]
          }
        }
      'all': ()->
        return {
          label: "Events"
          sortBy: {'title' : 1}  # ASC
          filterBy: {}
      }
    }

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

      pulledToReveal: ()->
        vm.settings.show.overscrollTile(true)
        if !location = locationHelpers.lastKnownLonLat()
          return vm.pullToReveal.slide('setLocation')
        return vm.pullToReveal.slide('searchSort')

      'edit': (ev, $item)->
        data = $item
        TableEditSvc.beginTableWizard(data.type, data)
        .then (result)->
          return if result == 'CANCELED'
          return vm.on.submitNewTile({data: result})

      createNewTile: (parentEl)->
        # return AAAHelpers.requireUser('sign-in')
        # .then (me)->
        vm.settings.show.pullToReveal = !vm.settings.show.pullToReveal
        if vm.settings.show.pullToReveal
          vm.pullToReveal.slide('newTile')
        else
          $timeout(250).then ()->vm.pullToReveal.slide('default')

      submitNewTile: (result)->
        console.log ["submit New Event",result]

      fabClick: ($ev)->
        return AAAHelpers.requireUser('sign-in')
        .then ()->
          parentEl = ionic.DomUtil.getParentWithClass($ev.target, 'events')
          return vm.on['createNewTile'](parentEl)

      notReady: (value)->
        toastr.info "Sorry, " + value + " is not available yet"
        return false

      'favorite': eventUtils['favorite']

      showOnMap: ($ev, limit=5)->
        return vm.settings.show.map = false if vm.settings.show.map
        vm.mapRows = vm.rows.slice(0,limit)
        return vm.settings.show.map = false if vm.mapRows.length == 0
        vm.settings.show.map = true


      showLocationOnMap: ($ev, $item)->
        location = $item.geojson
        console.log ['geojsonPoint', location]
        vm.mapRows = [$item]
        eventUtils.setVisibleLocation($item)
        vm.settings.view.mapMarker = $item.visible.type
        vm.settings.show.map = true
        return

      filterBy: ($ev, value)->
        eventFilter = $stateParams.filter || 'all'
        location = locationHelpers.lastKnownLonLat()
        baseFilter = _filters[ eventFilter ](location)
        return vm.filter = baseFilter if !value
        baseFilter['searchString'] = value  # user provided searchString
        match = _.map value.split(' '), (word)->
          return "(?=.*" + word + ")"
        match = match.join('')
        baseFilter.filterBy = {
          $and:[
            baseFilter.filterBy
            $or: [
              { title: {$regex: match, $options: 'i'} }
              { description: {$regex: match, $options: 'i'} }
              { neighborhood: {$regex: match, $options: 'i'} }
            ]
          ]
        }

        vm.filter = baseFilter
        exportDebug.set('filter', vm.filter)
        return

    }


    vm.showRowcount = ()->
      formatted =
        if vm.rowcount
        then '(' + vm.rowcount + ')'
        else null
      return formatted

    initialize = ()->
      $reactive(vm).attach($scope)
      vm.subscribe 'myProfile'
      vm.subscribe 'userProfiles'
      # vm.subscribe 'userProfiles'
      vm.subscribe 'myVisibleEvents'
        ,()->
          return [
            vm.getReactively('filter.filterBy')
            ,{
              limit: parseInt(vm.pg.perpage),
              skip: parseInt((vm.getReactively('pg.page') - 1) * vm.pg.perpage),
              sort: vm.getReactively('pg.sort')
            }
          ]
        ,{
          onReady: ()->
            # arguments == []
            console.info ["EventsCtrl subscribe: Events onReady"]
            $timeout().then ()->
              vm.settings.show.emptyList = !mcEvents.find().count()
        }
      vm.helpers {
        'rows': ()->
          return mcEvents.find(
            vm.getReactively('filter.filterBy')
            , {
              sort : vm.getReactively('pg.sort')
            })
        'rowcount': ()->
          # TODO: bug: vm.rowcount is not getting updated on client when filterBy changes
          return Counts.get('countEvents')

      }

      vm.autorun ()->
        vm.filter = vm.getReactively('filter', true)
        return if _.isEmpty vm.filter
        console.log ['(autorun) events.filterBy=', vm.filter.filterBy]
        vm.title = vm.filter.label
        vm.pg.sort = vm.filter.sortBy
        return
      exportDebug.set 'vm', vm
      return


    activate = ()->
      vm.settings.show.map = false
      return $q.when()
      .then ()->
        return $auth.waitForUser() if Meteor.loggingIn()
      .then ()->
        location = locationHelpers.lastKnownLonLat()
        me = Meteor.user()
        if !location && me?.location
          location = locationHelpers.asLonLat me.location
          locationHelpers.lastKnownLonLat location
      .then (location)->
        # vm.settings.viewId = ["events-view",$scope.$id].join('-')
        # vm.listItemDelegate = $listItemDelegate.getByHandle('events-list-scroll', $scope)
        eventFilter = $stateParams.filter || 'all'

        switch eventFilter
          when 'nearby'
            if location = locationHelpers.lastKnownLonLat()
              return {eventFilter: eventFilter, location: location}

            return locationHelpers.getCurrentPosition('loading')
            .then (result)->
              lonlat = angular.copy(result.latlon).reverse()
              vm.call 'Profile.saveLocation', lonlat, (err, retval)->
                'check'
              return {eventFilter: eventFilter, location: lonlat}
            , (err)->
              console.warn ["WARNING: getCurrentPosition", err]

          else
            return {eventFilter: eventFilter}
      .then (result)->
        vm.filter = _filters[ result.eventFilter ](result.location)
        exportDebug.set('filter', vm.filter)
      .then ()->
        # // Set Ink
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

    $scope.$on '$ionicView.leave', (e) ->
      resetMaterialMotion('fadeSlideInRight')

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for EventCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for EventCtrl"
      activate()

    return vm  # end EventCtrl


EventCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$window', '$timeout'
  '$ionicScrollDelegate', '$state', '$stateParams', '$listItemDelegate'
  '$log', 'toastr'
  'appModalSvc', 'tileHelpers', 'openGraphSvc', 'eventUtils'
  'AAAHelpers', 'locationHelpers', 'TableEditSvc'
  '$reactive', '$auth', 'UsersResource', 'EventsResource'
  'utils', 'devConfig', 'exportDebug'
]





angular.module 'starter.events'
  .controller 'EventCtrl', EventCtrl
