schema =
  version: 1
  stores: [{
    name: "contactGroups"
    keyPath: "id"
    autoIncrement: true
    indexes: [
      {
        name: "name"
        keyPath: "name"
      }
    ]
  }, {
    name: "contacts"
    keyPath: "id"
    autoIncrement: true
    indexes: [
      {
        name: "groupId"
        keyPath: "groupId"
      },
      {
        name: "firstName"
        keyPath: "firstName"
      },
      {
        name: "lastName"
        keyPath: "lastName"
      },
      {
        keyPath: ["groupId", "firstName"]
      }
    ]
  }]

dbOptions =
  size: 100*1024*1024,
  mechanisms: ["#{if Modernizr.indexeddb and !bowser.safari and !bowser.ios then 'indexeddb' else 'websql'}"]

mainDB = new ydn.db.Storage('addressBook', schema, dbOptions)


# module
addressBook = angular.module('addressBook', [ ])

# controller
addressBook.controller 'DashboardController', ['$scope', '$log', ($scope, $log) ->
  # functions
  fetchContactGroups = =>
    mainDB.from("contactGroups").order('name').list().done( (groups) =>
      @editGroups = _.clone(groups)
      @filterGroups = _.clone(groups)
      @filterGroups.unshift({id: 0, name: 'All'})
      @contactGroups = _.clone(groups)
      @contactGroups.push({id: 0, name: 'Create new group'})
    ).fail( (e) => $log.error(e) )

  fetchContacts = =>
    mainDB.from("contacts").order('firstName').list().done( (contacts) =>
      @contacts = angular.copy(contacts)
      $scope.$apply()
    ).fail( (e) => $log.error(e) )

  callbackToSaveContact = (contact) =>
    saveContact(contact)
    $scope.newContact =
      groupId: 0
    @closeAddContact()

  saveContact = (contact, id = null) =>
    contact = _.extend(contact, {id: id}) if id?
    mainDB.put("contacts", contact).done( (id) =>
      fetchContacts()
    ).fail( (e) => $log.error(e) )


  # status for add form
  @isAddContact = false
  @openAddContact = => @isAddContact = true
  @closeAddContact = => @isAddContact = false
  @showAddContact = => @isAddContact is true

  @addContact = (newContact) =>
    contact =
      groupId: newContact.groupId
      firstName: newContact.firstName
      lastName: newContact.lastName
      age: newContact.age
    if parseInt(newContact.groupId, 10) is 0
      mainDB.put("contactGroups", {name: newContact.newGroupName}).done( (groupId)=>
        fetchContactGroups()
        callbackToSaveContact(_.extend(contact, {groupId: groupId}))
      ).fail( (e) => $log.error(e) )
    else
      callbackToSaveContact(contact)

  @editContact = (contact) =>
    mainDB.put("contacts", contact).done( (id) =>
      @closeEditContact(contact)
      $scope.$apply()
    ).fail( (e) => $log.error(e) )

  @deleteContact = (contact) =>
    return unless confirm('Are you sure?')
    mainDB.remove("contacts", contact.id).done( (id) =>
      fetchContacts()
    ).fail( (e) => $log.error(e) )


  @filterContacts = (filter) =>
    query = mainDB.from("contacts")
    if filter.groupId? and filter.groupId isnt 0
      query = query.where('groupId', '=', parseInt(filter.groupId, 10))
    # select
    query.list().done( (contacts) =>
      filteredContacts = angular.copy(contacts)
      if filter.firstOrLastName? and filter.firstOrLastName.length > 0
        regexpForSearch = new RegExp(filter.firstOrLastName.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'i')
        filteredContacts = _.filter(filteredContacts, (c) => regexpForSearch.test(c.firstName) or regexpForSearch.test(c.lastName))
      @contacts = _.sortBy(filteredContacts, (c) => c.firstName )
      $scope.$apply()
    ).fail( (e) => $log.error(e) )

  @filterReset = =>
    fetchContacts()
    $scope.filterForm =
      groupId: 0
      firstOrLastName: ''

  @getGroupById = (id) => _.find(@editGroups, (gr) => parseInt(gr.id, 10) is parseInt(id, 10) )

  @editContactsFilter = {}
  @hideEditContact = (contact) => !(@editContactsFilter["edit_#{contact.id}"]? and @editContactsFilter["edit_#{contact.id}"] is true)
  @openEditContact = (contact) => @editContactsFilter["edit_#{contact.id}"] = true
  @closeEditContact = (contact) => @editContactsFilter["edit_#{contact.id}"] = false

  # init
  fetchContactGroups()
  fetchContacts()
  # res
  return @
]