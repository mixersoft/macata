'use strict'

###
  NOTE: using angular 1.5 component-directives
    see https://angular.io/docs/ts/latest/guide/upgrade.html#!#using-component-directives
    https://docs.angularjs.org/guide/component
    http://www.codelord.net/2015/12/17/angulars-component-what-is-it-good-for/
###

###
# entry point for hosts to create a variety of different tables
# - choose a type of tables
# - provide a table specific form - ???:by modal?
###
TableCreateWizard = ()->

  return {
    restrict: 'E'
    scope: {}
    bindToController: {
      'onNewTile': '&'
      'getWidth': '&'  # optional
    }
    templateUrl: 'events/table/table-create-wizard.html'
    require: ['TableCreateNew']
    controllerAs: 'tcw'
    controller: [
      '$scope', 'appModalSvc'
      ($scope, appModalSvc)->
        tcw = this

        tcw.me = Meteor.user()

        _reset = ()=>
          this.data = {
            type: null
          }

        # pattern from directive:<new-tile>
        _showTileEditorAsModal = (data, force)->
          return $q.when()
          .then ()->
            return data if tileHelpers.isTileComplete(data) && !force
            return tileHelpers.modal_showTileEditor(data)
          .then (result)->
            # format like messageComposer
            result.location = _.omit result.location, 'latlon'
            scope.onComplete({result: result}) if attrs['onComplete']
          , (err)->
            scope.onComplete({result: null}) if attrs['onComplete']
          .finally _reset

        tcw.data = {
          type: null
          title: null
          description: null
          pic: null
          heroPic: null
          seatsTotal: 12
          seatsTaken: 1
          startTime: null
          duration: null
          isPublic: false
          locationName: null
          address: null
          neighborhood: null
          geojson: null

        }

        tcw.locationHelper = {
          name: null
          address: null
          neighborhood: null
          geojson: null
          locateAddress: ()->

        }

        tcw.show = {
          spinner: false
        }

        tcw.on = {
          updateWhen: (data)->
            # data = _.pick data,['startTime', 'duration']
            tcw.data['startTime'] = data['startTime']
            tcw.data['duration'] = data['duration']
            return

          updateLocation: (data)->
            # data = _.pick data,['startTime', 'duration']
            tcw.data['address'] = data['address']
            tcw.data['neighborhood'] = data['neighborhood']
            tcw.data['geojson'] = data['geojson']
            return

          beginTableWizard: (type)->
            type ?= 'table'
            tcw.data.type = type
            modalTemplate = [
              'events/table/'
              'new-' + type
              '.template.html'
            ].join('')
            # showModal for template
            return appModalSvc.show(
              modalTemplate
              , ''
              , {
                data: data
              }
              , {
                modalCallback: null
              }
            )
            .then (result)->
              # submit to DB



          # passthru - called by <new-tile on-complete="onComplete()">
          showTableForm: (result)->
            tcw.data = result
            _showTileEditorAsModal(tcw.data, 'force')


          submitTable: (result)->
              tcw.onNewTile({result:result})
        }

        return tcw
      ]

  }



TableCreateWizard.$inject = []

angular.module 'starter.events'
  .directive 'tableCreateWizard', TableCreateWizard
