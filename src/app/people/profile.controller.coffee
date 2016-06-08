'use strict'

ProfileCtrl = (
  $scope, $rootScope, $q, $location, $state, $stateParams, $timeout
  $ionicScrollDelegate
  AAAHelpers, $reactive, $auth
  locationHelpers
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
    vm.person = null  # active profile, or copy of vm.me
    vm.imgAsBg = utils.imgAsBg

    vm.settings = {
      view:
        show: null    # [signin|profile|account]
      show:
        imageAttach: false
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

      getFullNameLabel: (user)->
        label = _.filter([user.firstname, user.lastname])
        label = [user.name] if user.name && label.length == 0
        if label.length
          label.push ['(',user.displayName,')'].join('') if user.displayName
        else
          label = [user.displayName]
        return label.join(' ')

      'updateImage': (data)->
        vm.person.face = if data.src then data.src else vm.me.face
        return

      'imageAttachToggle': (ev, show)->
        vm.person.newFace = null
        if typeof show != 'undefined'
          vm.settings.show.imageAttach = show
        else
          vm.settings.show.imageAttach = !vm.settings.show.imageAttach
        return if !vm.settings.show.imageAttach
        parent = ionic.DomUtil.getParentOrSelfWithClass(ev.target, 'ionic-scroll')
        $timeout().then ()->
          el = parent.querySelector('image-attach-helper input[name=image-url]')
          el.focus()

      'imageAttachSave': (ev)->
        vm.me.face = vm.person.face
        # save to Meteor
        vm.call 'Profile.save', vm.me, ['face'], (err, retval)->
          return console.err ['Profile.save', err] if err
          vm.on.imageAttachToggle(null, false)
          return

      showSignInRegister: (action)->
        return AAAHelpers.showSignInRegister.call(vm, action)
        .then (user)->
          vm.me = $rootScope.user
          activate()
          $log.info vm.me

      getLocation: ($ev)->
        return locationHelpers.getCurrentPosition('loading')
        .then (result)->
          lonlat = angular.copy(result.latlon).reverse()
          Meteor.call 'Profile.saveLocation', lonlat, (err, retval)->
            return
        , (err)->
          console.warn ["WARNING: getCurrentPosition", err]


      signOut: ()->
        Meteor.logout (err)->
          return console.warn ['sign-out err=', err] if err
          $rootScope.user = null
          vm.me = null
          $rootScope.$emit 'user:sign-out'
          activate()
    }

    initialize = ()->
      $reactive(vm).attach($scope)
      vm.subscribe 'myProfile'
      vm.subscribe 'userProfiles'
      return

    activate = ()->
      return $q.when()
      .then ()->
        return $auth.waitForUser() if Meteor.loggingIn()
      .then ()->
        vm.me = Meteor.user()
        AAAHelpers._backwardCompatibleMeteorUser(vm.me)
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
          return  $q.reject('done')

        return vm.me
      .then (me)->
        if $state.is('app.profile')
          # route = _.pick $stateParams,
          $stateParams._id = $stateParams.id
          route = _.chain($stateParams)
            .pick(['_id', 'username'])
            .pickBy( _.identity )
            .value()

          if _.keys(route).length == 0
            toastr.warning "Sorry, that profile was not found."
            $rootScope.goBack()
            return $q.reject('redirect')

          else if (me && (route.username == me.username || route._id == me._id))
            # looking at my own profile
            $state.go('app.me')
            return $q.reject('redirect')

          # viewing someone else's profile
          return Meteor.users.findOne(route)
        return $q.reject('unknown $state')
      .then (profile)->
        if !profile
          toastr.info "Sorry, that profile was not found"
          $rootScope.goBack()
          return $q.reject('redirect')
        vm.person = profile
        AAAHelpers._backwardCompatibleMeteorUser(vm.person)
        return vm.person

    $scope.$on '$ionicView.loaded', (e)->
      # $log.info "viewLoaded for ProfileCtrl"
      initialize()

    $scope.$on '$ionicView.enter', (e)->
      $log.info "viewEnter for ProfileCtrl"
      activate()

    return vm  # end ProfileCtrl


ProfileCtrl.$inject = [
  '$scope', '$rootScope', '$q', '$location', '$state', '$stateParams', '$timeout'
  '$ionicScrollDelegate'
  'AAAHelpers', '$reactive', '$auth'
  'locationHelpers'
  '$log', 'toastr'
  'utils', 'devConfig', 'exportDebug'
]

angular.module 'starter.home'
  .controller 'ProfileCtrl', ProfileCtrl
