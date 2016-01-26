#  message-composer.directive.coffeelint
'use strict'

# directive:message-composer
#   - enhanced component for creating rich posts including attachments
#   - "somewhat" facebook-style
#   - use appModalSvc modals for detail view
#   - usage:
#     <ion-list>
#       <message-composer></message-composer>
#

MessageComposerDirective = ($compile, $q, $timeout, tileHelpers)->
  directive = {
    restrict: 'EA'
    templateUrl: 'blocks/components/message-composer.template.html'
    # replace: true
    # require: ['messageComposer','ngModel']
    controllerAs: '$mc'
    controller: [ '$scope', 'appModalSvc', 'tileHelpers', 'devConfig'
      ($scope, appModalSvc, tileHelpers, devConfig)->
        $mc = this

        $mc.settings = {
          show:
            newTile: false
            location: false
            spinner:
              newTile: false
        }

        $mc.geo = {
          setting:
            hasGeolocation: null  # set in init
            show:
              spinner:
                location: false
              location: false
          errorMsg:
            location: null
        }

        $mc.on = {
          'click': ($event)->
            console.log ['message-composer Click', $event]
          'toggleShow': (show, key, selector)->
            show[key] = !show[key]
            if show[key] && selector
              # scroll into View
              $timeout ()->
                $mc.$container[0].querySelector(selector).scrollIntoView()
            return show[key]
          'locationClick': ($event, opton )->
            TileEditorCtrl.locationClick.apply(this, arguments)
            return
        }

        $mc.RECIPE = {
          search: ()->
            return devConfig.getData()
            .then (data)->
              rows = data
              return $mc.RECIPE.modal_showSearchRecipeTile(rows)
          modal_showSearchRecipeTile : (data)->
            options = {modalCallback: null} # see RecipeSearchCtrl
            return appModalSvc.show(
              'events/modal-actions/search-recipe.modal.html'
              , 'RecipeSearchCtrl as mm'
              , {
                copyToModalViewModal :
                  rows: data
                vm: $scope.vm
              }
              , options )
            .then (result)->
              # wait for closeModal()
              result ?= 'CANCELED'
              console.log ['modal_showSearchRecipeTile()', result]
              if result == 'CANCELED'
                return $q.reject('CANCELED')
              return $q.reject(result) if result?['isError']

              return result
            .then (result)->
              $mc.scope.attachment = result
              return

        }

        $mc.TILE = {
          editTile: (data)->
            return tileHelpers.modal_showTileEditor(data)
            .then (result)->
              $mc.scope.attachment = result
            return

          detachTile: (tile)->
            console.log ['detachTile', 'id='+tile.id , tile]
            $mc.scope.attachment = null

          attachTile: (result)->
            return $mc.TILE.submitNewTile(result)
            .then (result)->
              $mc.scope.attachment = result

              # tile = $mc.on.makeTile(result)
              # $scope['attachmentContainer'].push tile

          submitNewTile: (result)->
            console.log ['submitNewTile', result]
            $mc.settings.show.newTile = false
            result = devConfig.setData(result) if result
            return $q.when result
        }

        return $mc
    ]
    scope: {
      placeholderText: '@'
      message: '='
      attachment: '='
      location: '='
    }
    link:
      pre: (scope, element, attrs, controllers) ->
        return
      post: (scope, element, attrs, controllers) ->
        $mc = controllers
        $mc.$container = element
        $mc.scope = scope
        return

  }
  return directive



MessageComposerDirective.$inject = ['$compile', '$q', '$timeout', 'tileHelpers']

angular.module('blocks.components')
  .directive 'messageComposer', MessageComposerDirective
