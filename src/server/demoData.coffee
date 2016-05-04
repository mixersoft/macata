# /server/demoData.js
#
#
lookup = {
  RECIPE: [
    {
      # data = _.reduce(mcRecipes.find({}).fetch(), function(done, o){done[o['_id']]=o['title'];return done},{})
      "CoN3tSkwDayJE3pHF": "Red Wine-Braised Short Ribs Recipe - Bon Appétit",
      "e2xqAjR8jCdGNuiXx": "My Classic Caesar Recipe",
      "FhnqJT38GzaAbbHb4": "Pan Roasted Brussel Sprouts Recipe",
      "WBfnHwH2fx39Lg6Pe": "White Stork",
      "7SgRd2aJu4jWcnadG": "Thomas Keller's Roast Chicken Recipe",
      "sq7ekDt7w4DngJDrq": "Spice-Crusted Carrots with Harissa Yogurt Recipe",
      "zdcT7BQB4qYMawvKe": "How Betony Makes Their Short Ribs"
    }
    ['7SgRd2aJu4jWcnadG', 'sq7ekDt7w4DngJDrq', 'WBfnHwH2fx39Lg6Pe']
    ['e2xqAjR8jCdGNuiXx', 'CoN3tSkwDayJE3pHF', 'sq7ekDt7w4DngJDrq']
  ]
}
# coffeelint: disable=max_line_length
demoData = {
  'mcRecipes': [{"url":"http://www.yummly.com/recipe/Thomas-Keller_s-Roast-Chicken-1286231","title":"Thomas Keller's Roast Chicken Recipe","description":"Thomas Keller's Roast Chicken Recipe Main Dishes with chicken, ground black pepper, salt, orange, lemon, carrots, onions, celery ribs, shallots, bay leaves, thyme sprigs, butter","image":"http://lh3.googleusercontent.com/h9IttHblN8tuFyHG-A4cDhqzYPNB-yM4jyT2fIgLFxg6lcxKdKCSqPyCz_c5pk0eCS3JLUPXjo2M7CU4pVsWog=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:course":"Main Dishes","yummlyfood:ingredients":"butter","yummlyfood:time":"1 hr 30 min","yummlyfood:source":"TLC"},"id":"0","location":{"lat":42.6700528,"lon":23.314167099999963},"className":"Recipe","createdAt":"2016-02-29T15:58:41.849Z","$$owner":{"firstname":"Masie","lastname":"May","username":"maymay","displayName":"maymay","face":"https://unsplash.it/200/200/?image=793","id":"0","className":"Users"},"ownerId":"0","$$hashKey":"object:87"},{"url":"http://www.yummly.com/recipe/Spice-Crusted-Carrots-with-Harissa-Yogurt-1054422","title":"Spice-Crusted Carrots with Harissa Yogurt Recipe","description":"Spice-Crusted Carrots with Harissa Yogurt Recipe with carrots, kosher salt, sugar, mustard powder, spanish paprika, ground cumin, ground coriander, vegetable oil, ground black pepper, plain greek yogurt, harissa paste, chopped fresh thyme, grated lemon zest, lemon wedge","image":"http://lh3.googleusercontent.com/Psf5ZDTw2hgQNDOjI0ZtwYqiDWHbeXzMrJALdVSMNhdtedpq5IfQvy_sVZLLuN3tuQIUVkBqkl8LS4I6gDgsm_o=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:ingredients":"lemon wedge","yummlyfood:time":"45 min","yummlyfood:source":"Bon Appétit"},"id":"1","location":{"lat":42.6737483,"lon":23.325192799999968},"className":"Recipe","createdAt":"2016-02-28T15:58:41.849Z","$$owner":{"firstname":"Marky","lastname":"Mark","username":"marky","displayName":"marky","face":"https://unsplash.it/200/200/?image=804","id":"xSs5BigB8yCkqRbxA","className":"Users"},"ownerId":"xSs5BigB8yCkqRbxA","$$hashKey":"object:88"},{"url":"http://newyork.seriouseats.com/2013/09/how-betony-makes-their-short-ribs.html","title":"How Betony Makes Their Short Ribs","description":"It's rare that a restaurant opening in Midtown causes much of a stir, but with Chef Bryce Shuman—the former executive Sous Chef of Eleven Madison Park—at the helm, it's no surprise that Betony is making waves. This short rib dish is one of those wave-makers.","image":"http://newyork.seriouseats.com/assets_c/2013/08/20130826-264197-behind-the-scenes-betony-short-ribs-29-thumb-625xauto-348442.jpg","extras":{},"id":"2","location":{"lat":42.6977082,"lon":23.321867500000053},"className":"Recipe","createdAt":"2016-02-27T15:58:41.849Z","$$owner":{"firstname":"Lucy","lastname":"Lu","username":"lulu","displayName":"lulu","face":"https://unsplash.it/200/200/?image=815","id":"xBYWvthK5qZ5zHx9T","className":"Users"},"ownerId":"xBYWvthK5qZ5zHx9T","$$hashKey":"object:89"},{"url":"http://www.bonappetit.com/recipe/red-wine-braised-short-ribs","title":"Red Wine-Braised Short Ribs Recipe - Bon Appétit","description":"These Red Wine-Braised Short Ribs are even better when they're allowed to sit overnight.","image":"http://www.bonappetit.com/wp-content/uploads/2011/08/red-wine-braised-short-ribs-940x560.jpg","site_name":"Bon Appétit","extras":{"og:locale":"en_US","og:type":"recipe","article:publisher":"https://www.facebook.com/bonappetitmag","article:tag":"Beef,Dinner,Meat,Ribs","article:section":"Recipes","type":"recipe"},"id":"3","location":{"lat":42.6599319,"lon":23.31657610000002},"className":"Recipe","createdAt":"2016-02-26T15:58:41.851Z","$$owner":{"firstname":"Chucky","lastname":"Chu","username":"chuchu","displayName":"chuchu","face":"https://unsplash.it/200/200/?image=826","id":"3","className":"Users"},"ownerId":"3","$$hashKey":"object:90"},{"url":"http://www.yummly.com/recipe/My-classic-caesar-318835","title":"My Classic Caesar Recipe","description":"My Classic Caesar Recipe Salads with garlic, anchovy filets, sea salt flakes, egg yolks, lemon, extra-virgin olive oil, country bread, garlic, extra-virgin olive oil, sea salt, romaine lettuce, caesar salad dressing, parmagiano reggiano, ground black pepper, anchovies","image":"http://lh3.ggpht.com/J8bTX6MuGC-8y87DHlxxagqShmJLlPjXff28hN8gksOpLp3fZJ5XaLCGrkZLYMer3YlNAEoOfl6FyrSsl9uGcw=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:course":"Salads","yummlyfood:ingredients":"anchovies","yummlyfood:time":"40 min","yummlyfood:source":"Food52"},"id":"4","location":{"lat":42.6743583,"lon":23.32824210000001},"className":"Recipe","createdAt":"2016-02-25T15:58:41.851Z","$$owner":{"firstname":"Masie","lastname":"May","username":"maymay","displayName":"maymay","face":"https://unsplash.it/200/200/?image=793","id":"0","className":"Users"},"ownerId":"0","$$hashKey":"object:91"},{"url":"http://www.yummly.com/recipe/Pan-roasted-brussel-sprouts-316203","title":"Pan Roasted Brussel Sprouts Recipe","description":"Pan Roasted Brussel Sprouts Recipe Side Dishes with brussels sprouts, olive oil, garlic cloves, white wine, cracked black pepper, sea salt, extra-virgin olive oil","image":"http://lh3.ggpht.com/__CrxYT6M2LxtItnVSkYQ7u2k-p59E8zryHmLFioy4d5oZj04pkSc88aVpLcjey19YaWUwnnM-TfhtoK4U3jXFQ=s730-e365","site_name":"Yummly","extras":{"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","yummlyfood:course":"Side Dishes","yummlyfood:ingredients":"extra-virgin olive oil","yummlyfood:time":"35 min","yummlyfood:source":"Food52"},"id":"5","location":{"lat":42.680284,"lon":23.325271},"className":"Recipe","createdAt":"2016-02-24T15:58:41.851Z","$$owner":{"firstname":"Marky","lastname":"Mark","username":"marky","displayName":"marky","face":"https://unsplash.it/200/200/?image=804","id":"xSs5BigB8yCkqRbxA","className":"Users"},"ownerId":"xSs5BigB8yCkqRbxA","$$hashKey":"object:92"},{"url":"http://whitestorkco.com/","title":"White Stork","image":"https://pbs.twimg.com/profile_images/691694111468945408/H8VRdkNg.jpg","description":"At White Stork, we are passionate about taste and the need to have more good beer in Bulgaria. After extensive research, testing, tasting, tweaking and experimentation since 2011, we hatched our first Pale Ale in December 2013 and wanted to show you the wonders of the Citra hop in our Summer Pale Ale in July 2014. Although our beers are currently made by our amazing master brewer in Belgium, we are building our brewery in Sofia which will hopefully be operational soon.","id":"6","location":{"lat":42.6945039,"lon":23.340166},"className":"Recipe","createdAt":"2016-02-23T15:58:41.851Z","$$owner":{"firstname":"Lucy","lastname":"Lu","username":"lulu","displayName":"lulu","face":"https://unsplash.it/200/200/?image=815","id":"xBYWvthK5qZ5zHx9T","className":"Users"},"ownerId":"xBYWvthK5qZ5zHx9T","$$hashKey":"object:93"}]
  'mcEvents': {
    0:
      # what
      title: "Ramen For That!"
      description: """
        Everything in life should start and end with food. Live by that rule and kickstart your week with an amazing Ramen-fest, Ramen Hello !!
        Blending old world flavors with new world ingredients we bring a unique twist to the traditional delight. Join us as we break the rules , Ichigo-Ichie!
        """
      category: "Potluck"     # [Potluck|Popup]
      cusine: "Japanese"      # [American|Japanese|California|Seafood|etc.]
      style: 'Seated'         # [Seated|Casual|Grazing|Picnic]
      attire: 'Casual'        # [Casual|Cocktail|Business|Formal|Fun]
      inspiration: "Just because I miss my days in Tokyo"
      aspiration: 2           # 0-3 stars

      image: "http://vignette2.wikia.nocookie.net/ramen/images/c/c2/Tonkotsu_ramen_640.jpg"

      # when: 4=Thur
      startTime: moment().weekday(7).add(14,'d').hour(20).startOf('hour').toJSON() # search/filter
      duration: moment.duration(3, 'hours').asMilliseconds()

      # where:
      neighborhood: "Dragalevtsi, Sofia"
      address: '23b Dragalevtsi'
      location: [42.629065, 23.316999] # search/filter
      seatsTotal: 12
      seatsOpen: 12

      # host:
      ownerId: "xSs5BigB8yCkqRbxA" # markymark belongsTo Users
      menuItemIds: ['7SgRd2aJu4jWcnadG', 'sq7ekDt7w4DngJDrq', 'WBfnHwH2fx39Lg6Pe']
      participantIds: ["xBYWvthK5qZ5zHx9T"]
      isPublic: true # searchable

      # contributors: {}      # see vm.lookup['Contributions']
      menu:
        allowCategoryKeys: ['SmallPlate','Main','Dessert','Drink']

      setting:
        isExclusive: false   # invite Only
        denyGuestShare: false # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: false    # only guests see address
        denyParticipantList: false # guests can see Participants
        denyMaybeNoResponseList: false
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: false    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0

    1:
      # what
      title: "Pizza Night"
      description: """
        Enjoy a delightful dinner tasting different pizzas, made with only the best ingredients.
        Bring your favorite Italian wines to share.
        """
      category: "Potluck"     # [Potluck|Popup]
      cusine: "Italian"      # [American|Japanese|California|Seafood|etc.]
      style: 'Seated'         # [Seated|Casual|Grazing|Picnic]
      attire: 'Casual'        # [Casual|Cocktail|Business|Formal|Fun]
      inspiration: "just because"
      aspiration: 1           # 0-3 stars
      price: null             # guest can contribute money?

      image: "http://slice.seriouseats.com/images/20111208-basil-duo.jpg"

      # when: 4=Thur
      startTime: moment().weekday(6).add(14,'d').hour(17).startOf('hour').toJSON() # search/filter
      duration: moment.duration(3, 'hours').asMilliseconds()

      # where:
      neighborhood: "Lozenets, Sofia"
      address: 'ul. "Neofit Rilski" 18'
      location: [42.690626, 23.316678] # search/filter
      seatsTotal: 12
      seatsOpen: 12

      # host:
      ownerId: "xBYWvthK5qZ5zHx9T" # lulu belongsTo Users
      menuItemIds: ['e2xqAjR8jCdGNuiXx', 'CoN3tSkwDayJE3pHF', 'sq7ekDt7w4DngJDrq']
      participantIds: ["xSs5BigB8yCkqRbxA"]

      # guests:  # habtm Users
      # menu:    # menu ideas

      setting:
        isExclusive: false   # invite Only
        denyGuestShare: false # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: false    # only guests see address
        denyParticipantList: false # guests can see Participants
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: true    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0
    2:
      # what
      title: "American BBQ"
      description: """
      Join us for a quick a cultural tour of American-a - with a sampling of my favorite regional BBQs
      """
      category: "Potluck"     # [Potluck|Popup]
      cusine: "American"      # [American|Japanese|California|Seafood|etc.]
      style: 'Casual'         # [Seated|Casual|Grazing|Picnic]
      attire: 'Casual'        # [Casual|Cocktail|Business|Formal|Fun]
      inspiration: "здравей софия"
      aspiration: 3           # 0-3 stars
      price: null             # guest can contribute money?

      image: "http://whatscookingamerica.net/Beef/Beef-Brisket/Brisket-final2.jpg"

      # when: 4=Thur
      startTime: moment(new Date('2015-09-12')).hour(16).startOf('hour').toJSON() # search/filter
      duration: moment.duration(5, 'hours').asMilliseconds()

      # where:
      neighborhood: "Lozenets, Sofia"
      address: 'Ulitsa Bogatitsa'
      location: [42.671027, 23.316299] # search/filter

      seatsTotal: 12
      seatsOpen: 4

      # host:
      ownerId: "xSs5BigB8yCkqRbxA" # markymark belongsTo Users
      menuItemIds: ['7SgRd2aJu4jWcnadG', 'sq7ekDt7w4DngJDrq', 'WBfnHwH2fx39Lg6Pe']
      participantIds: ["xBYWvthK5qZ5zHx9T"]
      isPublic: true # searchable

      # guests:  # habtm Users
      # menu:    # menu ideas

      setting:
        isExclusive: true   # invite Only
        denyGuestShare: false # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: false    # only guests see address
        denyParticipantList: false # guests can see Participants
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: false    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0
    3:
      # what
      title: "Tailgate on the Farm"
      description: """
      Join us on the Farm for our season opening tailgate
      as the Cardinal looks to build on their Pac-12 lead.
      Stop by for a beer, some BBQ, hot wings, and more;
      then settle in to watch that McCaffery kid run wild!
      """
      category: "Potluck"     # [Potluck|Popup]
      cusine: "American"      # [American|Japanese|California|Seafood|etc.]
      style: 'Casual'         # [Seated|Casual|Grazing|Picnic]
      attire: 'Casual'        # [Casual|Cocktail|Business|Formal|Fun]
      inspiration: "Go Stanford!"
      aspiration: 2           # 0-3 stars
      price: null             # guest can contribute money?

      image: "http://x.pac-12.com/sites/default/files/styles/event_page_content__hero/public/STAN-FB-SPRING-3__1428795219.jpg"

      # when: 4=Thur
      # startTime: moment(new Date('2015-10-03')).hour(17).toJSON() # search/filter
      startTime: moment().weekday(6).subtract(14,'d').hour(10).startOf('hour').toJSON() # search/filter
      duration: moment.duration(3, 'hours').asMilliseconds()

      # where:
      neighborhood: "Stanford Stadium, Palo Alto"
      address: 'El Camino Grove'
      location: [37.436191, -122.159668] # search/filter

      seatsTotal: 25
      seatsOpen: null

      # host:
      ownerId: "3" # belongsTo Users
      isPublic: true # searchable

      # guests:  # habtm Users
      # menu:    # menu ideas
      menu:
        allowCategoryKeys: ['Side','Main','Dessert','Drink']

      setting:
        # isExclusive: false   # invite Only
        denyGuestShare: false # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: true    # only guests see address
        denyParticipantList: false # guests can see Participants
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: false    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0
    4:
      # what
      title: "Last Days of Summer"
      description: """
      Come on over, we're having one last BBQ before I start thinking of ski season.
      """
      category: "Potluck"     # [Potluck|Popup]
      cusine: "American"      # [American|Japanese|California|Seafood|etc.]
      style: 'Casual'         # [Seated|Casual|Grazing|Picnic]
      attire: 'Casual'        # [Casual|Cocktail|Business|Formal|Fun]
      inspiration: "Because it's a great time of year."
      aspiration: 2           # 0-3 stars
      price: null             # guest can contribute money?

      image: "https://s-media-cache-ak0.pinimg.com/736x/ba/e2/50/bae250a5bb4f5c93b4314f40c6498ba2.jpg"

      # when: 4=Thur
      startTime: moment().weekday(6).add(7,'d').hour(17).startOf('hour').toJSON()
      duration: moment.duration(5, 'hours').asMilliseconds()

      # where:
      neighborhood: "Lozenets, Sofia"
      address: 'Ulitsa Bogatitsa'
      location: [42.690626, 23.316678]# search/filter

      seatsTotal: 16
      seatsOpen: null

      # host:
      ownerId: "xBYWvthK5qZ5zHx9T" # lulu belongsTo Users
      menuItemIds: ['e2xqAjR8jCdGNuiXx', 'CoN3tSkwDayJE3pHF', 'sq7ekDt7w4DngJDrq']
      participantIds: ["xSs5BigB8yCkqRbxA"]
      isPublic: true # searchable

      # guests:  # habtm Users
      menu:
        allowCategoryKeys: ['Side','Main','Dessert','Drink']

      setting:
        isExclusive: false   # invite Only
        denyGuestShare: false # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: false    # only guests see address
        denyParticipantList: false # guests can see Maybe,No responses
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: false    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0

    5:
      # what
      title: "Variations on the Theme of Rice"
      description: """
      We're going to Spain for the Easter break,
      and that's got me in the mood for Paella.

      Please join us for dinner this Saturday,
      as we explore the limits of this rice dish
      as it crosses over to the American South.
      """

      image: "http://viajerosblog.com/wp-content/uploads/2012/04/la-boqueria.jpg"

      # when: 4=Thur
      startTime: moment('2016-04-16').hour(18).startOf('hour').toJSON()
      duration: moment.duration(5, 'hours').asMilliseconds()

      # where:
      neighborhood: "Lozenets, Sofia"
      address: 'Ulitsa Bogatitsa 36, et 5 ap9'
      location: [42.670676, 23.313738] # search/filter

      seatsTotal: 12
      seatsOpen: null

      # host:
      ownerId: "gTpZTsnMeKtor7aJ9" # michael
      menuItemIds: ['e2xqAjR8jCdGNuiXx', 'CoN3tSkwDayJE3pHF', 'sq7ekDt7w4DngJDrq']
      isPublic: true # searchable


      setting:
        isExclusive: false   # invite Only
        denyGuestShare: true # guests can share event, same as denyForward
        denyRsvpFriends: false # guests can rsvp friends
        rsvpFriendsLimit: 12 # guests rsvp limit for friends
        allowSuggestedFee: false # monentary fee in lieu of donation
        allowPublicAddress: true    # only guests see address
        denyParticipantList: false # guests can see Maybe,No responses
        denyWaitlist: true    # use waitlist if full
        feedVisibility: "public"  # [public|guests|none]
        denyAddMenu: false    # only host can update menu Items

      wrapUp:
        rating: null          # guest ratings

      controlPanel:
        yes: 0
        maybe: 0
        no: 0
  },
  'mcFeeds': [
    # Event: 'LastDaysSummer' = 'vYCDTNzc4Ky6CXyi3'
    # Event.ownerId = "xBYWvthK5qZ5zHx9T" # lulu
    #                 "xSs5BigB8yCkqRbxA" # markymark
    {
      "type":"Comment"
      head:
        "createdAt":"2016-01-28T14:37:41.983Z",
        "ownerId": "xSs5BigB8yCkqRbxA" # markymark
        "eventId": "3X8pxfsEhBrpHcdfD"
        "isPublic": true
      body:
        "type":"Comment"
        "message":"This is what I've been waiting for. I'm on it.",
        "attachment":{"_id":"sq7ekDt7w4DngJDrq","type":"Recipe"}
        "location":null
    }
    {
      type:"Notification"
      head:
        id: Date.now()
        "createdAt": moment()
        "expiresAt": null
        "eventId": "3X8pxfsEhBrpHcdfD"
        "ownerId": "xBYWvthK5qZ5zHx9T" # lulu
      body:
        message: "<b>Hello!</b> This is a notification. It might be appear as a mobile notification in the App."
    }
    {
      # NOTE: for invitation by link, we only know from the invite token
      #   vm.me may be undefined
      "type":"Invitation"
      head:
        # "id":"1453967670694"
        "createdAt": moment().subtract(7, 'hours').toJSON()
        "eventId": "3X8pxfsEhBrpHcdfD"
        "ownerId": "xBYWvthK5qZ5zHx9T" # lulu      # for .item-post .item-avatar
        "recipientIds": ["L8EdePbduQ3Aj3r3W"]  # filterBy: feed.type chuckychu
        "nextActionBy": 'recipient' # [recipient, owner]
        "token":  "invite-token-if-found"
      body:
        "type":"Invitation"
        "status":"new"      # [new, viewed, closed, hide]
        "message":"Please come-this will be epic!"
        "comments":[]       #$postBody.comments, show msg, regrets here
    }
    {
      # from an open booking
      "type":"Participation"
      head:
        # "id":"1453967670695"
        "createdAt": moment().subtract(23, 'minutes').toJSON()
        "eventId": "3X8pxfsEhBrpHcdfD"
        "ownerId": "xSs5BigB8yCkqRbxA" # markymark
        "recipientIds": ["xBYWvthK5qZ5zHx9T"] # lulu
        "nextActionBy": 'recipient' # [owner, recipient, moderator, xxeventOwner]
      body:
        "type":"Participation"
        "status":"new"
        "response":"Yes"
        "seats":2,
        "message":"Exciting. I'll take 2 and bring the White Stork."
        "attachment": {"_id":"WBfnHwH2fx39Lg6Pe","type":"Recipe"}
        "address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria",
        "location":{"latlon":[42.69448,23.342364],"address":"ul. \"Oborishte\" 18, 1504 Sofia, Bulgaria"}
    }

  ]

}


# coffeelint: enable=max_line_length
loadData = (collection)->
  context = @
  count = {}
  asGeoJsonPoint = (latlon)->
    lonlat = [latlon[1], latlon[0]] if _.isArray latlon
    lonlat = [latlon['lon'], latlon['lat']] if latlon['lat']?
    lonlat ?= []
    return {
      type: "Point"
      coordinates: lonlat # [lon,lat]
    }
  loadset =
    if collection
    then _.pick loadset, collection
    else demoData
  _.each loadset, (data, collection)->
    count[collection] = context[collection]?.find().count()
    if count[collection]==0
      console.log ['loading demoData for ', collection]
      _.each data, (o,i,l)->
        omitKeys = _.filter(_.keys(o), (k)->return k[0]=='$')
        clean = _.omit o, omitKeys
        # append fields
        clean['createdAt'] = moment().subtract(i, 'days').toJSON()
        clean['geojson'] = asGeoJsonPoint(clean.location) if clean.location

        console.log ["clean keys=", _.keys(clean).join() ]

        context[collection].insert(clean)
      count[collection] = context[collection].find().count()

  console.log ["demoData count=", count]

Meteor.methods {
  'Admin.resetData': (collection)->
    context[collection].remove({})
    loadData(collection)
    return


}

Meteor.startup loadData
