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
TableCreateWizard = {
  bindings: {
    editData: '<'
    onSubmit: '&'
  }
  templateUrl: 'events/table/table-create-wizard.html'
  controller:[ 'TableEditSvc', (TableEditSvc)->
    $ctrl = this

    $ctrl.wizardInput = null
    $ctrl.show = {
      spinner: false
    }
    $ctrl.$onInit = ()=>
      return

    $ctrl.on = {

      'beginTableWizard':(ev, type)->
        type ?= 'standard'
        data = {
          title: $ctrl.wizardInput
          # image: $ctrl.wizardInput
        }
        TableEditSvc.beginTableWizard(type, data)
        .then (result)->
          return if result == 'CANCELED'
          return $ctrl.onSubmit({data: result})
        .finally ()->
          $ctrl.wizardInput = null

    }
    return
  ]
}

###
# @description modal for editing Table/Event fields
###
TableEditSvc = (
  $q, $templateCache, $ionicTemplateLoader
  TableRouter, appModalSvc, geocodeSvc
)->

  ###
  # @description controller for modal
  ###
  $ctrl = {  # modal controller
    'data': null
    'templateUrl': null
    'on':
      updateWhen: (data)->
        # data = _.pick data,['startTime', 'duration']
        $ctrl.data['startTime'] = data['startTime']
        $ctrl.data['duration'] = data['duration']
        return

      updateLocation: (data)->
        # data = _.pick data,['startTime', 'duration']
        $ctrl.data['address'] = data['address']
        $ctrl.data['neighborhood'] = data['neighborhood']
        $ctrl.data['geojson'] = data['geojson']
        return

      updateImage: (data)->
        $ctrl.data['image'] = data.src
        return

      validateModalClose: (data)->
        return self.validateFields(data)
        .catch (err)->
          console.warn ["There are form errors", err]
          throw err
  }

  self = {

    beginTableWizard: (type, data)->
      type ?= 'standard'
      $ctrl['data'] = _.extend {} , TableRouter.defaults(type), data
      $ctrl['templateUrl'] = [
        'events/table/types/'
        $ctrl.data.type
        '.template.html'
      ].join('')

      console.log ['loading template=', $ctrl.templateUrl]
      # url = "events/table/types/standard.template.html"
      # return $ionicTemplateLoader.load(url)
      # .then (modalTemplate)->
      #   modalTemplate = "ERROR: $ionicTemplateLoader.load()" if !modalTemplate
      #   templateKey = 'modal_TableEditSvc'
      #   modalTemplateWrap = [
      #     '<ion-modal-view id="table-type-standard">'
      #       '<ion-header-bar class="bar-balanced">'
      #         '<h1 class="title">Host a Table</h1>'
      #       '</ion-header-bar>'
      #       '<ion-content>'
      #         '$modalTemplate'
      #       '</ion-content>'
      #     '</ion-modal-view>'
      #   ]
      #   modalTemplateString = modalTemplateWrap.join('')
      #     .replace('$modalTemplate', modalTemplate)
      #   $templateCache.put(templateKey, modalTemplateString)
      #   return templateKey
      return $q.when($ctrl.templateUrl)
      .then (templateKey)->
        # showModal for template
        return appModalSvc.show( templateKey
          , $ctrl                   # modalScope.$ctrl
          , {
            me: Meteor.user()       # modalScope.me
          }
          , {
            modalCallback: (modal)-> return
          }
        )
      .then (result)->
        return result if result=='CANCELED'
        return self.prepareSubmit(result)

    validateFields: (data)->
      model = TableRouter.model(data)
      return $q.when(data)
      .then (data)->
        return model.validateFields(data)

    prepareSubmit: (data)->
      # check if closeModal == tcw.closeModal
      console.log "prepareSubmit", data
      data.type = 'standard'
      model = TableRouter.model(data)
      return $q.when(data)
      .then (data)->
        return model.aaa(data)
      .then (data)->
        return model.validateFields(data)
      .then (data)->
        return model.beforeSave(data)
      .catch (err)->
        console.warn ['prepareSubmit', err]
        # TODO: do not close modal, call
        return $q.reject(err)

  }
  return self

TableEditSvc.$inject = [
  '$q', '$templateCache', '$ionicTemplateLoader'
  'TableRouter', 'appModalSvc', 'geocodeSvc'
]



###
# TableRouter
# @description call TableRouter.getType([event.type]) to get controller for
#   a specific table type
###
TableRouter = (
  AAAHelpers, $q, $timeout
  TableStandard
)->
  tableTypes = [TableStandard]

  TableModelBaseClass = (@model)->
    #constructor
    this.aaa = (data)->
      return data if Meteor.userId()
      return AAAHelpers.showSignInRegister('sign-in')
      .then ()->
        return @model['aaa']?(data) || data
    this.validateFields = (data)->
      return @model['validateFields']?(data) || data
    this.beforeSave = (data)->
      data = @model['beforeSave']?(data) || data
      return this.beforeUpdate(data) if data._id
      return this.beforeInsert(data)
    this.beforeInsert = (data)->
      return @model['beforeInsert']?(data) || data
    this.beforeUpdate = (data)->
      return @model['beforeUpdate']?(data) || data
    return

  this.getType = (type)=>
    return angular.copy _.find(tableTypes, {type:type})

  this.defaults = (type)->
    ctrl = this.getType(type)
    return null if !ctrl
    ctrl.defaults['type'] = type
    return ctrl.defaults

  this.model = (type)=>
    type = if type?.type then type.type else type
    ctrl = this.getType(type)
    return model = new TableModelBaseClass(ctrl.model)
  return


TableRouter.$inject = [
  'AAAHelpers', '$q', '$timeout'
  'TableStandard'
]




TableStandard = ($q)->
  # ???: should we use inheritance model, or "mixin"?
  # class TableStandardModel extends TableModelBaseClass
  #   constructor: (options)->
  #     super(options)

  self = {
    type: 'standard'
    defaults: {
      # see: EVENT_ATTRIBUTES.all
      _id: null
      type: null
      className: null
      ownerId: null
      title: null
      description: null
      image: null
      seatsOpen: 12
      seatsTotal: 12
      startTime: null
      duration: null
      isPublic: false
      locationName: null
      address: null
      neighborhood: null
      geojson: null
      settings: {}
      participations: []
      participantIds: []
      moderatorIds: []
      menuItemIds: []
      # participations: []
      # deprecate:
      #   participantIds = _.pluck(event.participations, 'ownerId')
    }
    allowedFields: ()->
      return allowed = _.keys(self.defaults)
    model:
      # TODO:  self.model instanceof class TableStandardModel
      validateFields: (data)->
        # convert datatypes
        intFields = ['seatsOpen', 'seatsTotal']
        _.each intFields, (k)->
          data[k] = parseInt(data[k])
          return

        # check required fields
        return $q.reject('missing GPS coordinates') if !data.geojson
        return data
      beforeSave: (data)->
        return data = _.pick data, self.allowedFields()
      beforeInsert: (data)->
        # data = _.pick data, self.allowedFields()
        data.type ?= 'standard'
        data.className ?= 'Events'
        data.ownerId = Meteor.userId()
        data.moderatorIds = [data.ownerId]
        data.participations ?= []
        data.participantIds ?= _.map(data.participations, 'ownerId')
        # add FKs
        # denormalize
        return data

  }
  return self

TableStandard.$inject = ['$q']

angular.module 'starter.events'
  .factory 'TableEditSvc', TableEditSvc
  .service 'TableRouter', TableRouter
  .factory 'TableStandard', TableStandard
  .component 'tableCreateWizard', TableCreateWizard
