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

MessageComposerDirective = ($compile, $q, $timeout, $ionicScrollDelegate
  $reactive, ReactiveTransformSvc
  tileHelpers, IdeasResource
)->
  directive = {
    restrict: 'EA'
    templateUrl: 'blocks/components/message-composer.template.html'
    # replace: true
    # require: ['messageComposer','ngModel']
    controllerAs: '$mc'
    controller: [ '$scope', 'appModalSvc', 'tileHelpers', 'locationHelpers'
      'devConfig'
      ($scope, appModalSvc, tileHelpers, locationHelpers, devConfig)->
        $mc = this

        $mc.settings = {
          show:
            newTile: false
            location: false
            spinner:
              newTile: false
            postButton: false
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
              # scroll into by pixels
              el = $mc.$container[0].querySelector(selector)
              scroll = ionic.DomUtil.getParentOrSelfWithClass(el, 'ionic-scroll')
              scrollHandle = scroll?.getAttribute('delegate-handle')
              _ionScroll = $ionicScrollDelegate.$getByHandle(scrollHandle)
              $timeout ()->
                _ionScroll.scrollBy(0, el.clientHeight, true)
                el.getElementsByTagName('INPUT')?[0].focus()
                # $mc.$container[0].querySelector(selector).scrollIntoView()
            return show[key]
          'locationClick': ($event, value )->
            $mc.LOCATION.getLocation(value)
            .then (result)->
              $scope.location = result || {}

          'post': ($event)->
            # check if there is a link that needs to be fetched
            return if $mc.settings.show.newTile
            result = _.pick $scope, ['message', 'attachment', 'address','location']
            return $scope.postButton?({value: result})
            .then (result)->
              # reset form here or in parent controller?
              return



        }

        $mc.RECIPE = {
          filterBy: {}
          search: ()->
            Reactivecontext = $reactive($mc).attach($scope)
            subHandle = $mc.subscribe 'myVisibleRecipes'
            ,()->
              filterBy = null
              paginate = null
              return subscription = [ filterBy, paginate  ]
            ,{
              onReady: ()->
                console.info ["$mc.subscribe 'myVisibleRecipes'", "ready"]
              onStop: (error)->
                console.info ["$mc.subscribe 'myVisibleRecipes'", "stopped"]
            }

            $mc.helpers {
              'rows': ()->
                return mcRecipes.find( $mc.getReactively( 'RECIPE.filterBy' ) )
            }
            $mc.RECIPE.modal_showSearchRecipeTile($mc.rows, subHandle)

          modal_showSearchRecipeTile : (data, subHandle)->
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
              subHandle.stop?()
              if $mc.stop
                $mc.stop()  # stop reactivity
              else
                console.warn "WARN: How do we stop reactivity???"
              # wait for closeModal()
              result ?= 'CANCELED'
              console.log ['modal_showSearchRecipeTile()', result]
              if result == 'CANCELED'
                return $q.reject('CANCELED')
              return $q.reject(result) if result?['isError']

              return result
            .then (result)->
              # result.isRecipe = true
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
            if result
              return IdeasResource.save(result)
        }

        $mc.LOCATION = {
          getLocation: (value)->
            $mc.geo.errorMsg.location = null
            if value == 'CURRENT'
              $mc.geo.setting.show.spinner.location = true
              promise = locationHelpers.getCurrentPosition()
              .finally ()->
                $mc.geo.setting.show.spinner.location = false
            else
              # note: geocodeSvc.geocode() will parse "lat,lon" values
              promise = locationHelpers.geocodeAddress({address:value})

            return promise
            .then (result)->
              $mc.scope.address = result.address
              $mc.scope.address ?= result.latlon?.join(', ') || ''
              $mc.scope.location = result
            , (err)->
              $mc.geo.errorMsg.location = err.humanize

        }

        return $mc
    ]
    scope: {
      headerText: '@'
      placeholderText: '@'
      postButton: '&'
      message: '='
      attachment: '='
      address: '='
      location: '='
    }
    link:
      pre: (scope, element, attrs, controllers) ->
        return
      post: (scope, element, attrs, controllers) ->
        $mc = controllers
        $mc.$container = element
        $mc.settings.show.postButton = attrs.postButton?
        $mc.scope = scope

        $mc.geo.setting.hasGeolocation = navigator.geolocation?
        return

  }
  return directive

MessageComposerDirective.$inject = ['$compile', '$q', '$timeout', '$ionicScrollDelegate'
  '$reactive', 'ReactiveTransformSvc'
  'tileHelpers', 'IdeasResource'
]


angular.module('blocks.components')
  .directive 'messageComposer', MessageComposerDirective
