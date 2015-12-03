# placeholder.direcctive.coffee
'use strict'

PlaceholderDirective = ($http, $compile)->

  ready = $http.get('https://unsplash.it/list')
  .then (result)->
    console.log ['dir:Tile data[0]', result.data[0] , result.data.length]
    return result.data

  hashKey = (index, offset, list)->
    index = str2Int( index )
    return hash = ((index * 11 + offset ) %% list.length)

  getImgSrc = (index, offset, list)->
    hash = hashKey(index,offset,list)
    id = list[ hash ].id
    ['https://unsplash.it/320/240?image', id].join('=')

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
    }
    compile: (tElement, tAttrs, transclude)->
      return {
        pre: (scope, element, attrs, ngModel) ->
          return
        post: (scope, element, attrs, ngModel) ->
          return ready
          .then (list)->
            offset = str2Int attrs['group']
            offset ?= Math.random()*100
            index = attrs['index'] || attrs['key']
            index ?= Date.now()
            switch attrs['placeholder']
              when 'img', 'image'
                # console.log ['placeholderImg', offset, index]
                src = getImgSrc(index , offset, list)
                element.attr('src', src)
              when 'bg-img', 'bg-image'
                # console.log ['bg-img', offset, index]
                src = getImgSrc(index , offset, list)
                element.addClass('bg-image')
                  .css('background', "url({src}) 50% 50%".replace('{src}', src) )
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

PlaceholderDirective.$inject = ['$http', '$compile']

angular.module 'blocks.components'
  .directive 'placeholder', PlaceholderDirective