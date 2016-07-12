# ionic-deploy.service.coffee
'use strict'

###
ionic add ionic-platform-web-client
ionic io init
ionic config build

lifecycle:
  deviceReady.waitForDevice().then ()-> new Ionic.Deploy()
  ionicDeploy.check() called in HomeCtrl.activate()
###

_progress = {
  value: null
  color: 'royal'
}

IonicDeploy = (
  $q, $timeout, deviceReady, appModalSvc
  exportDebug
)->

  CHECK_AGAIN_IN_MINS = 5

  deploy = null

  self = {
    setChannel: (device)->
      return deviceReady.waitForDevice()
      .then ()->
        device ?= deviceReady.device()
        # check for channel update first
        dfd = $q.defer()
        Meteor.call('deploy.getChannel', device.id
        , (err, channelTag)->
          if channelTag
            deploy.setChannel channelTag
            console.info ["deploy.channel=", channelTag]
          return dfd.resolve( channelTag || 'NO_CHANGE' )
        )
        return dfd.promise

    check: (force)->
      return deviceReady.waitForDevice()
      .catch (err)->
        return $q.reject err if err == 'NOT_A_DEVICE'
        throw err
      .then ()->
        return self.load() if !deploy
      .then ()->
        device = deviceReady.device()
        return device if force
        now = new Date()
        checkAfter = device.checkForUpdate
        checkAfter ?= moment().subtract(1, 'h').toDate()
        if now < checkAfter
          return $q.reject('LATER')
        return device
      .then (device)->
        return self.setChannel(device)
      .then (tag)->
        return deploy.check()
      .then (isUpdate)->
        if !isUpdate
          self.scheduleNextCheck( CHECK_AGAIN_IN_MINS ) if !force
          return false

        return deploy.getMetadata()
        .catch (err)->
          console.warn ["ERROR: deploy.check()", err]
          return false


    askToUpdate: (metadata)->
      # return deviceReady.wait()
      return deviceReady.waitForDevice()
      .then ()->
        device = deviceReady.device()
        found = _.find( device.skipUpdates, metadata)
        return $q.reject('SKIP') if not _.isEmpty found

        return appModalSvc.show(
          'blocks/components/ionic-deploy.template.html'
          , 'IonicDeployCtrl as idc'
          , {
            metadata: metadata
          }
        )
        .then (result)->

          self.updateProgress(null, 'royal')

          result ?= 'LATER'
          switch result
            when 'LATER'
              next = self.scheduleNextCheck( CHECK_AGAIN_IN_MINS )
              return console.log ['check again at', next ]
            when 'SKIP', 'CANCELED'
              next = self.scheduleNextCheck( CHECK_AGAIN_IN_MINS )
              return self.skipUpdate(metadata)


    update: (isChecked, watch = {})->
      # $scope.$watch '[watch].progress', (newV, oldV)->
      #   progress = newV
      return deviceReady.waitForDevice()
      .then ()->
        device = deviceReady.device()
        if not isChecked
          return self.check("force")
        return isChecked
      .then (isUpdate)->
        if isUpdate
          self.updateProgress(0, 'royal')
          deploy.update()
          .then (result)->
            console.info ['deploy.update() result=', result]
          , (err)->
            self.updateProgress null, 'assertive'
            console.warn ['deploy.update() err=', err]
          , (progress)->
            $timeout().then ()->
              self.updateProgress progress
              console.log 'update.progress=' + progress + '%'

    scheduleNextCheck: (wait)->
      wait ?= CHECK_AGAIN_IN_MINS
      nextTime = moment().add( wait, 'm').toDate()
      device = deviceReady.device({
        checkForUpdate : nextTime
      })
      return device.checkForUpdate

    skipUpdate: (metadata)->
      return if _.isEmpty metadata
      skipUpdates = deviceReady.device().skipUpdates || []
      skipUpdates.push metadata
      device = deviceReady.device({
        skipUpdates : skipUpdates
      })
      return device.skipUpdates

    updateProgress: (value, color)->
      _progress.value = value if typeof value != 'undefined'
      _progress.color = color if typeof color != 'undefined'
      return _progress

    #  for debug
    info: ()->
      deploy.info().then (result)->
        # {deploy_uuid: "NO_DEPLOY_LABEL", binary_version: "0.0.1"}
        console.log ["deploy.info()", result]
      return

    versions: ()->
      deploy.getVersions().then (result)->
        # array
        console.log ["deploy.getVersions()", result]
      return

    metadata: ()->
      deploy.getMetadata().then (result)->
        console.log ["deploy.getMetadata()", result]
      return

    load: ()->
      return deviceReady.waitForDevice()
      .catch (err)->
        # console.warn(err)
        return $q.reject err if err == 'NOT_A_DEVICE'
        throw err
      .then (device)->
        console.log "loading IonicDeploy"
        deploy ?= new Ionic.Deploy()
        exportDebug.set('deploy',{
          info: self.info
          versions: self.versions
          metadata: self.metadata
        })
        return
      ,
  }


  self.load()
  return self

IonicDeploy.$inject = [
  '$q', '$timeout', 'deviceReady', 'appModalSvc'
  'exportDebug'
]




IonicDeployCtrl = ($scope, ionicDeploy, $timeout)->
  idc = this
  idc.progress = {
    value: null
    color: ''
  }

  idc.afterModalShow = ()->
    return if _.isEmpty $scope.metadata
    idc.metadata = $scope.metadata
    return

  once = $scope.$on 'modal.afterShow', (ev, modal)->
    once?()
    if modal == $scope.modal
      idc.afterModalShow()
    return

  idc.on = {
    update: ($ev, value)->
      ionicDeploy.update(true, idc.watch)
      .finally ()->
        $timeout(2000)
      .then ()->
        $scope.closeModal('DONE')
  }

  $scope.$watch ()->
    return ionicDeploy.updateProgress()
  , (newV)->
    idc.progress = newV  # {value:, color:}

  return idc

IonicDeployCtrl.$inject = ['$scope', 'ionicDeploy', '$timeout']

angular.module 'blocks.components'
  .value 'deployProgress', 0
  .factory 'ionicDeploy', IonicDeploy
  .controller 'IonicDeployCtrl', IonicDeployCtrl
