'use strict'

moments2Dates = (o)->
  return _.each o, (v,k)->
    o[k] = v.toDate() if v?.toDate
    return

EventWhenHelper = {
  bindings:
    when:     "<" # {startDate, startTime:, endTime:, duration:}
    onUpdate: "&"
  templateUrl: "events/table/event-when-helper.template.html"
  # require:
  controller: [
    '$scope', '$timeout'
    ($scope, $timeout)->
      $ctrl = this
      this.data = {}
      this.showHelper = false
      this.$onInit = ()=>
        now = moment()
        this.data = _.pick( this.when, ['startDate', 'startTime', 'endTime', 'duration'])
        this.data['startDate'] = moment( this.data.startDate || now )
          .startOf('day')
        this.data['startTime'] =
          if this.data.startTime
          then moment(this.data.startTime)
          else moment(now).startOf('hour').add('hour',1)


        if this.data['endTime']
          this.data['endTime'] = moment(this.data.endTime)
          this.data['duration'] =
            this.data.endTime - this.data.startTime
        else if this.data['duration']
          this.data['endTime'] = moment(this.data.startTime)
            .add(this.data.duration,'ms')

        moments2Dates this.data
        return this.data = this.updateChanges(this.data)


      this.$onChanges = (changes)=>
        console.log ["onChanges", changes]

      this.updateChanges = (data)=>
        data ?= this.data
        dateTimeString = [
          moment(data.startDate).format('YYYY-MM-DD')
          moment(data.startTime).format('HH:mm')
        ].join(' ')
        data['startTime'] = startTime = moment(dateTimeString)

        if data.endTime
          endTime = moment(data.startDate)
            .hour(data.endTime.getHours())
            .minute(data.endTime.getMinutes())
          if startTime < endTime
            data.duration = endTime - startTime
          else
            data.duration = endTime.add(1,'day') - startTime
          data['endTime'] = endTime
          data['asString'] = moment(startTime).calendar(null,{
            sameElse: 'llll'  # Thu, Sep 4 1986 8:30 PM
          })

        moments2Dates data
        return data

      this.updateWhen = (ev)=>
        data = this.updateChanges()
        this.onUpdate({data:data})
        if ev.target.getAttribute('name') == 'endTime'
          this.showHelper = false
        return

      this.on = {}
      this.on['showHelper'] = (ev)=>
          this.showHelper = true
          parent = ionic.DomUtil.getParentWithClass ev.currentTarget, 'event-when-helper'
          $timeout().then ()->
            nextEl = parent.querySelector('.time-input-helper input')
            nextEl.focus()

      return this

  ]
}


angular.module 'starter.events'
  .component 'eventWhenHelper', EventWhenHelper
