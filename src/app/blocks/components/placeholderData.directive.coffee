# placeholder.direcctive.coffee
'use strict'

PlaceholderDataDirective = ($http, $compile)->

  ready = $http.get('https://unsplash.it/list')
  .then (result)->
    console.log ['dir:Tile data[0]', result.data[0] , result.data.length]
    return result.data
  .catch (err)->
    console.error ['Unsplash.it NOT AVAILABLE',err]
    throw err

  hashKey = (index, offset, list)->
    index = str2Int( index )
    return hash = ((index * 11 + offset ) %% list.length)

  getImgSrc = (index, offset, list, options)->
    options = _.extend {
      width: 320
      height: 240
    }, options
    hash = hashKey(index,offset,list)
    id = list[ hash ].id
    [
      'https://unsplash.it/'
      options.width + '/'
      options.height + '/'
      '?image='
      id
    ].join('')

  str2Int = (key)->
    return parseInt key if not _.isNaN parseInt( key )
    return null if not _.isString key
    return _.reduce [0...key.length], (hash, i)->
      return hash += key.charCodeAt(i)
    , 0


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

          return ready
          .then (list)->
            offset = str2Int attrs['group']
            offset ?= Math.random()*100
            index = attrs['index'] || attrs['key']
            index ?= Date.now()
            switch attrs['placeholderData']
              when 'img', 'image'
                # console.log ['placeholderImg', offset, index]
                src = getImgSrc(index , offset, list, options)
                element.attr('src', src)
              when 'bg-src', 'bgSrc'
                # console.log ['bg-img', offset, index]
                scope.model?['bgSrc'] = getImgSrc(index , offset, list, options)
              when 'bg-image'
                # element.attr('bg-image', src)
                element.addClass('bg-image')
                  .css('background-image', "url({src})".replace('{src}', src) )
              when 'name'
                hash = hashKey(index,offset,list)
                name = list[hash]['author']
                if scope.model?
                  scope.model['name'] = name
                else
                  element.html(name)
            return
      }
  }

PlaceholderDataDirective.$inject = ['$http', '$compile']

angular.module 'blocks.components'
  .directive 'placeholderData', PlaceholderDataDirective
