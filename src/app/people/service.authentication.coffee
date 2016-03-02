'use strict'

# helper functions for managing user Authentication, Authorization, & Accounting
# works with sign-in-register directive
AAAHelpers = ($rootScope, $q, $timeout
  unsplashItSvc
  signInRegisterSvc
  devConfig, $log, toastr)->

    self = {

      _backwardCompatibleMeteorUser: (user)->
        return if !user
        # backward compatibility for Meteor.user
        angular.extend user, _.pick user.profile, ['displayName', 'face']
        user.id = user._id

      isAnonymous: ()->
        return true if not Meteor.user() || _.isEmpty $rootScope.user
        return false

      signIn: (person)->
        dfd = $q.defer()
        Meteor.loginWithPassword(
          person.username
          , person.password
          , (err)->
            return dfd.reject(err) if err
            return dfd.resolve( Meteor.user() )
        )
        return dfd.promise
        .catch (err)->
          $rootScope.$emit 'user:sign-out'
          if _.isString err
            err = {
              message: err
            }
          err['isError'] = true
          return $q.reject err

      register: (data)->
        dfd = $q.defer()
        meteorPerson = _.pick data, ['username','email','password']
        meteorPerson.profile = _.omit data, ['username','email','password']
        Accounts.createUser(
          meteorPerson
          , (err)->
            return dfd.reject(err) if err
            return dfd.resolve( Meteor.user() )
        )
        return dfd.promise
        .catch (err)->
          $rootScope.$emit 'user:sign-out'
          err['isError'] = true
          return $q.reject err

      # exaple AAAHelpers.showSignInRegister.apply(vm, arguments)
      showSignInRegister: (initialSlide)->
        vm = this
        return signInRegisterSvc.showSignInRegister(null, {
          signIn: self.signIn
          # checkIfUserExists: (data)->
          #   return UsersResource.query({username:data.username})
          register: self.register
          notImplemented: vm.on.notReady
        })
        .then (user)->
          console.log ['SignInRegisterSvc, user=', user]
          # return devConfig.loginUser( person.id , true)
          $log.info "Sign-in for username=" + user.username

          _setProfileDefaults = ()->
            # sign-in-register cleanup
            profileDefaults = {}
            if not user.profile.displayName
              displayName = []
              displayName.push user.profile.firstname if user.profile.firstname
              displayName.push user.profile.lastname if user.profile.lastname
              displayName = [user.username] if !displayName.length
              profileDefaults['profile.displayName'] = displayName.join(' ')
            if not user.profile.face
              face = unsplashItSvc.getImgSrc(Meteor.userId(), 'people-1', {face:true} )
              profileDefaults['profile.face'] = face
            if not _.isEmpty profileDefaults
              Meteor.users.update Meteor.userId(), {$set: profileDefaults}
            return

          _setProfileDefaults()

          $rootScope['user'] = Meteor.user()
          self._backwardCompatibleMeteorUser($rootScope['user'])

          $rootScope.$emit 'user:sign-in', $rootScope['user']
          return $rootScope['user']
    }

    return self # AAAHelpers


AAAHelpers.$inject = ['$rootScope', '$q', '$timeout'
'unsplashItSvc'
'signInRegisterSvc'
'devConfig', '$log', 'toastr']


angular.module 'starter.profile'
  .factory 'AAAHelpers', AAAHelpers
