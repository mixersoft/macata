'use strict'

HomeResource = (Resty, amMoment) ->
  className = 'Home'
  # coffeelint: disable=max_line_length
  data = {
    0:
      layout: "tile-center"
      color: "royal"
      title: "Welcome"
      heroPic: '' # "http://www.self.com/wp-content/uploads/2015/03/chef-cooking.jpg"
      target: "app.welcome"
    9:
      layout: "tile-left"
      color: ""
      title: "Coming Soon"
      heroPic: ""
      target: "app.events({filter:'comingSoon'})"
    10:
      layout: "tile-left"
      color: ""
      title: "Nearby"
      heroPic: "http://www.offthegridnews.com/wp-content/uploads/2015/02/Google-maps-techmeupDOTnet.jpg"
      target: "app.events({filter:'nearby'})"
    11:
      layout: "tile-left"
      color: ""
      title: "Recent Events"
      heroPic: "http://img.wonderhowto.com/img/07/41/63536109115939/0/keep-champagne-bubbly-hint-spoon-doesnt-work.w654.jpg"
      target: "app.events({filter:'recent'})"
    12:
      layout: "tile-center"
      color: "positive"
      title: "How It Works"
      heroPic: '' # "http://www.self.com/wp-content/uploads/2015/03/chef-cooking.jpg"
      target: "app.onboard"
    13:
      layout: "tile-right"
      class: "event"
      classId: 1
      target: 'app.className'
    15:
      layout: "tile-right"
      color: ""
      class: "menuItem"
      classId: 1
      target: 'app.className'
    16:
      layout: "tile-left"
      color: ""
      title: "Menu Ideas"
      heroPic: "http://lorempixel.com/400/200/food/4"
      target: "app.recipe({filter:'all'})"
    17:
      layout: "tile-right"
      color: ""
      class: "menuItem"
      classId: 2
      target: 'app.className'

    19:
      layout: "tile-right"
      class: "event"
      classId: 0
      target: 'app.className'
    20:
      layout: "tile-left"
      color: ""
      title: "Mains"
      heroPic: "http://lorempixel.com/400/200/food/7"
      target: "app.recipe({filter:'main'})"
    26:
      layout: "tile-left"
      color: ""
      title: "Sides"
      heroPic: "http://lorempixel.com/400/200/food/8"
      target: "app.recipe({filter:'side'})"
  }
  # coffeelint: enable=max_line_length
  return service = new Resty(data, className)


HomeResource.$inject = ['Resty','amMoment']

angular.module 'starter.core'
  .factory 'HomeResource', HomeResource
