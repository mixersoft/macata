'use strict'

FeedResource = (Resty, $q, openGraphSvc) ->
  className = 'Feed'

  # coffeelint: disable=max_line_length
  RAW_FEED = [
    {
      type:"Notification"
      head:
        id: Date.now()
        "createdAt": moment()
        "expiresAt": null
        "eventId":"1"
        "ownerId": "6"
      body:
        message: "<b>Hello!</b> This is a notification. It might be appear as a mobile notification in the App."
    }
    {
      # NOTE: for invitation by link, we only know from the invite token
      #   vm.me may be undefined
      "type":"Invitation"
      head:
        "id":"1453967670694"
        "createdAt": moment().subtract(7, 'hours').toJSON()
        "eventId":"1"
        "ownerId": "0"      # for .item-post .item-avatar
        "recipientIds": ["6"]  # filterBy: feed.type
        "nextActionBy": 'recipient' # [recipient, owner]
        "token":  "invite-token-if-found"
      body:
        "type":"Invitation"
        "status":"new"      # [new, viewed, closed, hide]
        "message":"Please come-this will be epic!"
        "comments":[]       #$postBody.comments, show msg, regrets here
    }
    {
      "type":"Participation"
      head:
        "id":"1453967670695"
        "createdAt": moment().subtract(23, 'minutes').toJSON()
        "eventId":"1"
        "ownerId": "5"    # booboo
        "nextActionBy": 'moderator' # [recipient, moderator, owner]
      body:
        "type":"Participation"
        "status":"new"
        "response":"Yes"
        "seats":2,
        "message":"Exciting. I'll take 2 and bring the White Stork."
        "attachment":
          "id":6
          "url":"http://whitestorkco.com/"
          "title":"White Stork","description":"At White Stork, we are passionate about taste and the need to have more good beer in Bulgaria. After extensive research, testing, tasting, tweaking and experimentation since 2011, we hatched our first Pale Ale in December 2013 and wanted to show you the wonders of the Citra hop in our Summer Pale Ale in July 2014. Although our beers are currently made by our amazing master brewer in Belgium, we are building our brewery in Sofia which will hopefully be operational soon."
          "image":"https://pbs.twimg.com/profile_images/691694111468945408/H8VRdkNg.jpg"
        "address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria",
        "location":{"latlon":[42.69448,23.342364],"address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria"}
    }
    {
      "type":"Comment"
      head:
        "id":"1453991861983",
        "createdAt":"2016-01-28T14:37:41.983Z",
        "ownerId": "0"
        "eventId":"1"
        "isPublic": true
      body:
        "type":"Comment"
        "message":"This is what I've been waiting for. I'm on it.",
        "attachment":{"id":4,"url":"http://www.yummly.com/recipe/My-classic-caesar-318835","title":"My Classic Caesar Recipe","description":"My Classic Caesar Recipe Salads with garlic, anchovy filets, sea salt flakes, egg yolks, lemon, extra-virgin olive oil, country bread, garlic, extra-virgin olive oil, sea salt, romaine lettuce, caesar salad dressing, parmagiano reggiano, ground black pepper, anchovies","image":"http://lh3.ggpht.com/J8bTX6MuGC-8y87DHlxxagqShmJLlPjXff28hN8gksOpLp3fZJ5XaLCGrkZLYMer3YlNAEoOfl6FyrSsl9uGcw=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:course":"Salads","yummlyfood:ingredients":"anchovies","yummlyfood:time":"40 min","yummlyfood:source":"Food52"},"$$hashKey":"object:258"},
        "location":null
    }
  ]
  # coffeelint: enable=max_line_length
  #


  # build data from RAW_FEED array
  data = {}
  _.each RAW_FEED, (o,i)->
    o.id = o.head.id
    data[o.id] = o
    return

  service = new Resty(data, className)


  return service


FeedResource.$inject = ['Resty', '$q']

angular.module 'starter.data'
  .factory 'FeedResource', FeedResource
