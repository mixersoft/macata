'use strict'

# helper functions for managing user Authentication, Authorization, & Accounting
# works with sign-in-register directive
AAAHelpers = ($rootScope, $q, $location, $stateParams
  UsersResource
  signInRegisterSvc
  devConfig, $log, toastr)->
    self = {
      signIn: (person)->
        return $q.when()
        .then ()->
          # TODO: do password sign-in
          return UsersResource.query({username:person.username})
        .then (results)->
          return results?[0]
        .catch (err)->
          $rootScope.$emit 'user:sign-out'
          if _.isString err
            err = {
              message: err
            }
          err['isError'] = true
          return err

      register: (person)->
        return $q.when()
        .then ()->
          person.face = UsersResource.randomFaceUrl()
          return UsersResource.post(person)
        .catch (err)->
          $rootScope.$emit 'user:sign-out'
          if err == 'DUPLICATE USERNAME'
            toastr.warning "That username was already taken. Please try again."
            return false # try again

          if _.isString err
            err = {
              message: err
            }
          err['isError'] = true
          return err

      # exaple AAAHelpers.showSignInRegister.apply(vm, arguments)
      showSignInRegister: (initialSlide)->
        vm = this
        return signInRegisterSvc.showSignInRegister(null, {
          signIn: self.signIn
          checkIfUserExists: (data)->
            return UsersResource.query({username:data.username})
          register: self.register
          notImplemented: vm.on.notReady
        })
        .then (person)->
          console.log ['SignInRegisterSvc', person]
          return devConfig.loginUser( person.id , true)
    }
    
    return self # AAAHelpers


AAAHelpers.$inject = ['$rootScope', '$q', '$location', '$stateParams'
'UsersResource'
'signInRegisterSvc'
'devConfig', '$log', 'toastr']


angular.module 'starter.profile'
  .factory 'AAAHelpers', AAAHelpers
