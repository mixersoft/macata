'use strict'

ImageServer = ($timeout, FileUploader)->

  _label = null

  formatBytes = (bytes, decimals = 1)->
    return '0 B' if (bytes == 0)
    k = 1024
    dm = decimals + 1
    sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
    i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i]


  self = {
    API: 'http://app.snaphappi.com:8765/api/'
    PATH: 'containers/{userId}/upload'
    SRC: 'http://snappi.snaphappi.com/svc/storage/{containerId}/{fileId}'
    APP_IDENTIFIER: 'macata'
    DEBUG: true

    setResult: (fileItem, response)->
      result = {}
      if fileItem.isUploaded
        result.status = 'Uploaded'
        result.src = self.getSrc(response)
      else
        if fileItem.isReady
          result.filename = "$name ($size)"
            .replace('$name', fileItem.file.name)
            .replace('$size', formatBytes(fileItem.file.size) )
        if fileItem.isUploading
          result.status = 'Uploading'
        else if fileItem.isCancel
          result.status = 'Canceled'
        else if fileItem.isError
          result.status = 'Server Error'
      _.extend fileItem, {result:result}
      return fileItem.result

    getSrc: (response)->
      return response.result.fields.src

    uuid: ()->
      return Meteor.uuid()

    postUrl: (userId)->
      return false if !userId
      return self.API + self.PATH.replace('{userId}', userId)

    imageId: (file)->
      return null if !file?.file
      uuid = self.uuid()
      switch file.file.type
        when 'image/jpeg'
          return uuid
        when 'image/png'
          return uuid
        else
          return file.file.name

    prepareUpload: (uploader, file, ownerId, options)->
      file.url = self.postUrl(ownerId)  # deprecate?
      console.log 'uploader.url=' + file.url
      # 'X-Image-Identifier': null
      # 'X-Container-Identifier': null
      # 'X-Full-Res-Image': null # save to db.images collection
      # 'X-Target-Width': 9999 # save to db.images collection
      file.headers['X-App-Identifier'] = self.APP_IDENTIFIER
      file.headers['X-Container-Identifier'] = ownerId
      file.headers['X-Image-Identifier'] = self.imageId(file)
      return uploader

    $init: (callbacks={})->
      uploader = new FileUploader( {
        headers: {
          # 'X-Image-Identifier': null
          # 'X-Container-Identifier': null
          # 'X-Full-Res-Image': 'true'  # save to db.images collection
          # 'X-Target-Width': 9999    # save to db.images collection
          }
      })
      uploader.filters.push({
        name: 'imageFilter'
        fn: (item , options)->
            type = '|' + item.type.slice(item.type.lastIndexOf('/') + 1) + '|'
            # return ~'|jpg|png|jpeg|bmp|gif|'.indexOf(type)
            return ~'|jpg|png|jpeg|'.indexOf(type)
      })

      # event handlers
      uploader.onWhenAddingFileFailed = (item, filter, options)->
        console.info('onWhenAddingFileFailed', item, filter, options) if self.DEBUG

      uploader.onAfterAddingFile = (fileItem)->
        console.info('onAfterAddingFile', fileItem) if self.DEBUG
        callbacks?['onAfterAddingFile']?.apply( uploader, arguments )
        return

      uploader.onAfterAddingAll = (addedFileItems)->
        # console.info('onAfterAddingAll', addedFileItems)
        return

      uploader.onBeforeUploadItem = (item)->
        console.info('onBeforeUploadItem', item) if self.DEBUG
        self.setResult( item )
        console.log('onBeforeUploadItem isReady=', item.isReady)
        self.prepareUpload(item.uploader, item, Meteor.userId())
        callbacks?['onBeforeUploadItem']?.apply( uploader, arguments )
        return


      uploader.onProgressItem = (fileItem, progress)->
        # console.info('onProgressItem', fileItem, progress)
        self.setResult( fileItem )
        $timeout().then ()->
          callbacks?['onProgressItem']?.call( uploader, fileItem, progress )

      uploader.onProgressAll = (progress)->
        # console.info('onProgressAll', progress)

      uploader.onSuccessItem = (fileItem, response, status, headers)->
        console.info('onSuccessItem', fileItem, result, status, headers) if self.DEBUG
        # container = fileItem.headers['X-Container-Identifier']
        # uuid = fileItem.headers['X-Image-Identifier']
        result = self.setResult( fileItem, response )
        console.info( 'imgSrc=' + result.src)  if self.DEBUG
        callbacks?['onSuccessItem']?.apply( uploader, arguments )
        return

      uploader.onErrorItem = (fileItem, response, status, headers)->
        # console.info('onErrorItem', fileItem, response, status, headers)
        console.error response
        self.setResult( fileItem, response )
        callbacks?['onErrorItem']?.apply( uploader, arguments )
        $timeout().then ()->
          fileItem.uploader.progress = null

      uploader.onCancelItem = (fileItem, response, status, headers)->
        self.setResult( fileItem, response )
        console.info('onCancelItem', fileItem, response, status, headers)  if self.DEBUG
        callbacks?['onCancelItem']?.apply( uploader, arguments )

      uploader.onCompleteItem = (fileItem, response, status, headers)->
        self.setResult( fileItem, response )
        # console.info('onCompleteItem', fileItem, response, status, headers)  if self.DEBUG
        callbacks?['onCompleteItem']?.apply( uploader, arguments )

      uploader.onCompleteAll = ()->
        console.info('onCompleteAll') if self.DEBUG

      return uploader

  }
  return self

ImageServer.$inject = ['$timeout', 'FileUploader']


ImageAttachHelper = {
  bindings:
    src:     "<"
    placeholder: "@"
    preview: "<"  # default = true
    onUpdate: "&"
  templateUrl: "blocks/components/image-attach-helper.template.html"
  # require:
  controller: [
    '$scope', '$timeout', 'imageServer'
    ($scope, $timeout, imageServer)->
      $ctrl = this
      this.fileUploader = null
      this.data = {
        src: null
        preview: null
      }
      this.previewSrc = (src)=>
        return false if this.preview == false
        return $ctrl.data.preview if !src


        return $ctrl.data.preview = null if !src
        if /^http.*snaphappi.com\/svc\/storage.*\.jpg$/i.test(src)
          src = src.split('/')
          size = '.thumbs/bp~'
          src[src.length-1] = size + src[src.length-1]
          return $ctrl.data.preview = src.join('/')
        else if src.indexOf('http') == 0
          return $ctrl.data.preview = src
        return $ctrl.data.preview = null

      this.$onInit = ()=>
        this.data.src = this.src
        this.data.placeholder = this.placeholder || "Image Url"
        this.fileUploader = imageServer.$init({
            onAfterAddingFile: (fileItem)->
              $timeout().then ()->
                console.log 'afterAddinFile', $ctrl.data
                fileItem.upload()
              return
            onBeforeUploadItem: (fileItem)->
              _.extend $ctrl.data, fileItem.result
              $ctrl.data.src = $ctrl.data.filename
              return
            onProgressItem: (fileItem, progress)->
              _.extend $ctrl.data, fileItem.result
              return
            onSuccessItem: (fileItem, response, status, headers)->
              _.extend $ctrl.data, fileItem.result
              $ctrl.onUpdate({ data: _.pick( $ctrl.data,['src'] ) })
              $timeout(1000).then ()->
                fileItem.uploader.progress = null
              return

            onErrorItem: (fileItem, response, status, headers)->
              _.extend $ctrl.data, fileItem.result
              return
            onCancelItem: (fileItem, response, status, headers)->
              _.extend $ctrl.data, fileItem.result
              return
            onCompleteItem: (fileItem, response, status, headers)->
              return
          })
        return

      $scope.$watch '$ctrl.data', (newV, oldV)->
        $ctrl.previewSrc(newV.src)
        switch newV.status
          when 'Server Error'
            $ctrl.data.progressBarClassName = 'assertive'
          when 'Canceled'
            $ctrl.data.progressBarClassName = 'energized'
          else # Uploading | Uploaded
            $ctrl.data.progressBarClassName = 'positive'
        return
      ,true


      this.$onChanges = (changes)=>
        console.log ["onChanges", changes]

      this.on = {}
      this.on['blurImageUrl'] = (ev)=>
        # manual entry, remove other attrs
        $ctrl.data = _.pick $ctrl.data, ['src', 'placeholder']
        $ctrl.onUpdate({ data: _.pick( $ctrl.data,['src'] ) })
        console.info 'blurImageUrl'
        return
      this.on['pauseUpload'] = (ev)=>
        return

      return this

  ]
}


angular.module('blocks.components')
  .factory 'imageServer', ImageServer
  .component 'imageAttachHelper', ImageAttachHelper
