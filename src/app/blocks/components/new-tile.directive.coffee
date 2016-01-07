# new-tile.directive.coffee
'use strict'

# directive:newTile
#   - create a new tile from a url parsing open-graph meta tags
#   - use appModalSvc modals for detail view
#   - allow manual editing of open-graph delegate-handle
#   - usage: <new-tile></new-tile>
#

OG_API_ENDPOINT = 'http://localhost:3333/methods/' + 'get-open-graph'
MARKUP = {
  INPUT: """
    <input ng-model="dm.data.field" style="width:100%;" type="text" placeholder="Enter Title or Url"/>
    """
  MODAL:
    newTileUrl: "blocks/components/new-tile.template.html"
}

NewTileCtrl = (scope, appModalSvc, $q, $http)->
  this.id = 'NewTileCtrl'
  dm = this
  dm.data = {
    field: null
    url: null
    title: null
    description: null
    site_name: null
    image: null
  }
  dm.show = {
    ogSpinner: false
  }
  dm.matchUrl = (value)->
    # match a url inside a string
    # reMatchUrl = /(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?$/i
    # coffeelint: disable=max_line_length
    reMatchUrl = /(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?/i
    # coffeelint: enable=max_line_length
    found = value.match(reMatchUrl)
    return found?[0]
  dm.getOpenGraph = (url)->
    return $http.get(OG_API_ENDPOINT, {
      params: {url: url}
    })
    .then (resp)->
      return $q.reject(resp) if resp.statusText != 'OK'
      return $q.reject('NOT FOUND') if _.isEmpty resp.data
      og = resp.data
      return og

  dm.normalizeOG = (og)->
    primaryFields = ['og:url', 'og:title', 'og:description', 'og:image', 'og:site_name']
    normalized = {}
    _.each _.pick( og, primaryFields ), (v,k)->
      normalized[ k.replace('og:','') ] = v
      return
    normalized['extras'] = _.omit og, primaryFields
    return normalized


  dm.createTileFromUrl = (url)->
    done_http = (og)->
      scope.isFetching = dm.show.ogSpinner = false
      return

    scope.isFetching = dm.show.ogSpinner = true
    return dm.getOpenGraph(url)
    .then (og)->
      done_http(og)
      data = dm.normalizeOG(og)
      return data
    , (err)->
      console.warn ['getOpenGraph()', err]
      return
    .then (data)->
      options = {modalCallback: null}
      return appModalSvc.show(
        MARKUP.MODAL.newTileUrl
      , 'NewTileCtrl as mm'
      , { data:data, onComplete: scope.onComplete}
      , options )
    .then (result)->
      # wait for closeModal()
      result ?= 'CANCELED'
      console.log ['modal createTileFromUrl()', result]
      if result == 'CANCELED'
        dm.data = {}
        return $q.reject('CANCELED')
      return $q.reject(result) if result?['isError']
      return result
    .finally (result)->
      dm.reset()
      scope.onComplete({result: result})

  dm.reset = ()->
    dm.data = {}
    dm.show.ogSpinner = false

  dm.on = {
    cameraClick: (ev)->
      check = ev.currentTarget
      return
    locationClick: (ev)->
      check = ev.currentTarget
      return
    done: (ev)->
      # post to $meteor
      dm.closeModal dm.data

  }
  return


NewTileCtrl.$inject = ['$scope', 'appModalSvc', '$q', '$http']



NewTileDirective = ($compile, $timeout)->
  directive = {
    restrict: 'E'
    controllerAs: 'dm'
    controller: 'NewTileCtrl'
    # require: ['ngModel', 'newTile']
    require: ['newTile'] # same as directive name
    scope: {
      'returnClose': '='
      'isFetching': '='
      'onReturn': '&'
      'onFocus': '&'
      'onBlur': '&'
      'onComplete': '&'
    }
    link:
      pre: (scope, element, attrs, controllers) ->
        # inputTypes = /textarea|text|search|tel|url|email|password/i
        # if element[0].nodeName != 'INPUT'
        #   throw new Error "directive new-tile is limited to input elements"
        # if not inputTypes.test(attrs.type)
        #   throw new Error "Invalid input type for directive auto-input" + attrs.type

        [dm] = controllers

        # input element, can be either url or title
        $field = $compile( MARKUP.INPUT )(scope)
        element.append($field)

        scope.clear = (ev)->
          ev.stopImmediatePropagation()
          dm.data.field = null
          scope.enabled = false
          $timeout ()->
            return $field[0].focus()
          ,150

        $field.bind 'focus', (e)->
          scope.enabled = !dm.data.field
          scope.$apply()
          if attrs.onFocus
            $timeout ()-> scope.onFocus()
          return

        $field.bind 'blur', (e)->
          return if !dm.data.field
          matched = dm.matchUrl(dm.data.field)
          if matched
            if dm.data.url != matched
              dm.data.url = matched
              console.log "blur: "+dm.data.url
              dm.createTileFromUrl dm.data.url
          else
            dm.data.title = dm.data.field
          if attrs.onBlur
            $timeout ()->
              scope.onBlur()
              return
          return

        $field.bind 'keydown', (e)->
          if e.which == 13  # return
            if attrs.returnClose
              $field[0].blur()
            if attrs.onReturn
              $timeout ()-> scope.onReturn()
            return
          if e.which == 32 # space
            matched = dm.matchUrl(dm.data.field)
            if matched
              dm.data.url = matched
              console.log "keydown: "+dm.data.url
              dm.createTileFromUrl dm.data.url
            else
              console.log "keydown: end in space but no match"
          scope.enabled = !dm.data.field
          scope.$apply()
          return



  }
  return directive


NewTileDirective.$inject = ['$compile', '$timeout']


angular.module('blocks.components')
  .controller 'NewTileCtrl', NewTileCtrl
  .directive 'newTile', NewTileDirective
