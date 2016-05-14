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
        user.id = user._id

      requireUser: (initialSlide)->
        if self.isAnonymous()
          return self.showSignInRegister(initialSlide)
        return $q.when(Meteor.user())

      isAnonymous: ()->
        return true if not Meteor.user()
        return false

      notReady: (value)->
        toastr.info "Sorry, " + value + " is not available yet"
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

      # exaple AAAHelpers.showSignInRegister(arguments)
      showSignInRegister: (initialSlide)->
        return signInRegisterSvc.showSignInRegister(null, {
          signIn: self.signIn
          # checkIfUserExists: (data)->
          #   return UsersResource.query({username:data.username})
          register: self.register
          notImplemented: self.notReady
        })
        .then (user)->
          console.log ['SignInRegisterSvc, user=', user]
          # return devConfig.loginUser( person.id , true)
          $log.info "Sign-in for username=" + user.username

          # patch user data
          face = unsplashItSvc.getImgSrc(Meteor.userId(), 'people-1', {face:true} )
          Meteor.call('Profile.normalizePwdUser', Meteor.user(), face)

          # @TODO: deprecate: use $rootScope.currentUser
          $rootScope['user'] = user
          self._backwardCompatibleMeteorUser(user)

          $rootScope.$emit 'user:sign-in', user
          return user
    }

    return self # AAAHelpers


AAAHelpers.$inject = ['$rootScope', '$q', '$timeout'
'unsplashItSvc'
'signInRegisterSvc'
'devConfig', '$log', 'toastr']


angular.module 'starter.profile'
  .factory 'AAAHelpers', AAAHelpers
