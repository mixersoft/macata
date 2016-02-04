# placeholder.direcctive.coffee
'use strict'

str2Int = (key)->
  return parseInt key if not _.isNaN parseInt( key )
  return null if not _.isString key
  return _.reduce [0...key.length], (hash, i)->
    return hash += key.charCodeAt(i)
  , 0

UnsplashIt = ($http)->
  _data = []

  hashKey = (index, offset, list)->
    offset = str2Int( offset )
    index = str2Int( index )
    return hash = ((index * 11 + offset ) %% list.length)


  waitUntilReady = $http.get('https://unsplash.it/list')
  .then (result)->
    console.log ['dir:Tile data[0]', result.data[0] , result.data.length]
    _data = result.data
    self.isReady = true
    return _data
  .catch (err)->
    console.error ['Unsplash.it NOT AVAILABLE',err]
    throw err


  _defaultSize = {
    width: 320
    height: 240
  }

  self = {
    ready: waitUntilReady
    isReady: false
    getName: (index, offset, options, list)->
      return 'NOT_READY' if not self.isReady
      list ?= _data
      hash = hashKey(index,offset,list)
      name = list[hash]['author']
      return name
    getImgSrc: (index, offset, options, list)->
      return 'NOT_READY' if not self.isReady
      list ?= _data
      options = _.extend _defaultSize, options
      if options['face']?
        options = {
          width: 200
          height: 200
        }
      hash = hashKey(index,offset,list)
      id = list[ hash ].id
      return [
        'https://unsplash.it/'
        options.width + '/'
        options.height + '/'
        '?image='
        id
      ].join('')

  }
  return self


UnsplashIt.$inject = ['$http']

PlaceholderDataDirective = ($compile, unsplashItSvc)->

  return {
    restrict: 'A'
    scope: {
      model: '='
      width: '@'
      height: '@'
      size: '@'
    }
    compile: (tElement, tAttrs, transclude)->
      return {
        pre: (scope, element, attrs, ngModel) ->
          return
        post: (scope, element, attrs, ngModel) ->
          options = {}
          options.height = scope.height if attrs.height
          options.width = scope.width if attrs.width
          if attrs.size
            options = {
              width: scope.size
              height: scope.size
            }

          return unsplashItSvc.ready
          .finally ()->
            offset = str2Int attrs['group']
            offset ?= Math.random()*100
            index = attrs['index'] || attrs['key']
            index ?= Date.now()
            switch attrs['placeholderData']
              when 'img', 'image'
                # console.log ['placeholderImg', offset, index]
                src = unsplashItSvc.getImgSrc(index , offset, options)
                element.attr('src', src)
              when 'bg-src', 'bgSrc'
                # console.log ['bg-img', offset, index]
                src = unsplashItSvc.getImgSrc(index , offset, options)
                scope.model?['bgSrc'] = src
              when 'bg-image'
                # just move src to background-image
                # element.attr('bg-image', src)
                element.addClass('bg-image')
                  .css('background-image', "url({src})".replace('{src}', src) )
              when 'name'
                name = unsplashItSvc.getName(index , offset, options)
                if scope.model?
                  scope.model['name'] = name
                else
                  element.html(name)
            return
      }
  }

PlaceholderDataDirective.$inject = ['$compile', 'unsplashItSvc']

angular.module 'blocks.components'
  .factory 'unsplashItSvc', UnsplashIt
  .directive 'placeholderData', PlaceholderDataDirective
