# device-ready.service.coffee
'use strict'

DeviceReady = (
  $q, $timeout, $ionicPlatform, $cordovaNetwork, $localStorage
)->

  ALLOW_DEVICE_ATTRS = ['checkForUpdate', 'skipUpdates']

  _promise = null
  _timeout = if ionic.Platform.isWebView() then 10000 else 2000
  _contentWidth = null
  _device = {}
  _device =
    if $localStorage['device']?
    then angular.copy( $localStorage['device'] )
    else {    # initialize
      id: '00000000000'
      platform: {}
      isDevice: null
      isBrowser: null
    }



  self = {

    device: (options = {})->
      # READ ONLY COPY
      return _device if _.isEmpty options
      validatedAttrs = _.pick( options, ALLOW_DEVICE_ATTRS )
      _.extend( $localStorage['device'], validatedAttrs)
      _.extend( _device, validatedAttrs) # copy in place to preserve dfd.resolve()
      return _device

    contentWidth: (force)->
      return _contentWidth if _contentWidth && !force
      return _contentWidth = document.getElementsByTagName('ion-side-menu-content')[0]?.clientWidth

    #  use deviceReady.wait().then (device)->
    #  before $ngCordova calls, i.e. cordova Plugins
    #

    waitP: ()->
      return _promise if _promise
      deferred = $q.defer()
      _cancel = $timeout ()->
        # console.warn "$ionicPlatform.ready TIMEOUT!!!"
        return deferred.reject("ERROR: ionicPlatform.ready does not respond")
      , _timeout
      $ionicPlatform.ready ()->
        $timeout.cancel _cancel
        if $localStorage['device']?.id?
          _device = angular.copy $localStorage['device']
          return deferred.resolve( _device )

        platform = _.defaults ionic.Platform.device(), {
          available: false
          cordova: false
          platform: 'browser'
          uuid: 'browser'
          id: 'browser'
        }
        $localStorage['device'] = {}
        _.extend $localStorage['device'], {
          id: platform.uuid
          platform : platform
          isDevice: ionic.Platform.isWebView()
          isBrowser: ionic.Platform.isWebView() == false
        }
        _device = angular.copy $localStorage['device']
        # console.log "$ionicPlatform reports deviceReady, device.id=" + $localStorage['device'].id
        return deferred.resolve( _device )
      return _promise = deferred.promise
      .catch (err)->
        console.warn err
        throw err


    waitForDevice: ()->
      return self.waitP()
      .then (device)->
        return $q.reject("NOT_A_DEVICE") if device.isDevice == false
        return device

    isOnline: ()->
      return true if $localStorage['device'].isBrowser
      return !$cordovaNetwork.isOffline()
  }
  self['wait'] = self.waitP    # alias deviceReady.wait == waitP
  return self

DeviceReady.$inject = [
  '$q', '$timeout',  '$ionicPlatform'
  '$cordovaNetwork', '$localStorage'
]

angular.module 'blocks.components'
.factory 'deviceReady', DeviceReady
