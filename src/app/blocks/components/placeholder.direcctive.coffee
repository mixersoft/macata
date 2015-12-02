# placeholder.direcctive.coffee
'use strict'

PlaceholderDirective = ($http)->

  ready = $http.get('https://unsplash.it/list')
  .then (result)->
    console.log ['imageDB[0]', result.data[0] , result.data.length]
    return result.data

  hashKey = (index, offset, list)->
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
    scope: false
    link: (scope, element, attrs, ngModel) ->
      return ready
      .then (list)->
        offset = str2Int attrs['group']
        offset ?= Math.random()*100
        index = str2Int( attrs['index'] || attrs['key'])
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
            element.html(name)

  }

PlaceholderDirective.$inject = ['$http']

angular.module 'blocks.components'
  .directive 'placeholder', PlaceholderDirective