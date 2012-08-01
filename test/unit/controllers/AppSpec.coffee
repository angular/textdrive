describe 'controllers App', ->
  scope = editor = null

  # use all mocks
  beforeEach module 'mocks'

  beforeEach inject ($controller, $rootScope, _editor_) ->
    scope = $rootScope.$new()
    editor = _editor_
    $controller 'App', {$scope: scope}


  it 'should publish tabs and settings', inject (settings, tabs) ->
    expect(scope.settings).toBe settings
    expect(scope.tabs).toBe tabs


  describe 'toggleSearch', ->

    it 'should toggle isSearchVisible', inject ($rootScope) ->
      scope.toggleSearch()
      expect(scope.isSearchVisible).toBe true

      scope.toggleSearch()
      expect(scope.isSearchVisible).toBe false

      scope.toggleSearch false
      expect(scope.isSearchVisible).toBe false

    it 'should clear the search when hidding', ->
      scope.search = 'something'
      scope.toggleSearch false

      expect(scope.search).toBe ''

    it 'should clearFilter and focus the editor when hidding', ->
      scope.toggleSearch false
      expect(editor.clearFilter).toHaveBeenCalled()
      expect(editor.focus).toHaveBeenCalled()


    it 'should focus the input when showing', inject (focus) ->
      scope.toggleSearch()
      expect(focus).toHaveBeenCalled()


  describe 'doSearch', ->

    describe 'goToLine', ->

      it 'should goToLine when search starts with ":"', ->
        scope.search = ':12'
        scope.doSearch()
        expect(editor.goToLine).toHaveBeenCalledWith 12


      it 'should ignore non numbers', ->
        scope.search = ':'
        scope.doSearch()

        scope.search = ':asd'
        scope.doSearch()

        expect(editor.goToLine).not.toHaveBeenCalled()


    describe 'grep', ->

      it 'should filter if when search starts with "/"', ->
        editor.filter.andCallFake (re) ->
          expect(re instanceof RegExp).toBe true
          expect('abc').toMatch re
          expect('aabc').not.toMatch re

        scope.search = '/^abc'
        scope.doSearch()

        expect(editor.filter).toHaveBeenCalled()


      it 'should not filter if search shorter than 3 characters', ->
        scope.search = '/'
        scope.doSearch()
        expect(editor.clearFilter).toHaveBeenCalled()
        editor.clearFilter.reset()

        scope.search = '/a'
        scope.doSearch()
        expect(editor.clearFilter).toHaveBeenCalled()
        editor.clearFilter.reset()

        scope.search = '/ab'
        scope.doSearch()
        expect(editor.clearFilter).toHaveBeenCalled()
        editor.clearFilter.reset()

        expect(editor.filter).not.toHaveBeenCalled()


      it 'should be case insensitive if only lower case search', ->
        editor.filter.andCallFake (re) ->
          expect('SoMeThInG').toMatch re

        scope.search = '/^some?thing$'
        scope.doSearch()
        expect(editor.filter).toHaveBeenCalled()


      it 'should be case sensitive if search contains upper case', ->
        editor.filter.andCallFake (re) ->
          expect('abc').not.toMatch re
          expect('AbC').toMatch re

        scope.search = '/AbC'
        scope.doSearch()
        expect(editor.filter).toHaveBeenCalled()


  describe 'enterSearch', ->

    describe 'goToLine', ->

      it 'should hide search', ->
        scope.search = ':123'
        scope.enterSearch()

        expect(scope.search).toBe ''
        expect(editor.clearFilter).toHaveBeenCalled()
        expect(editor.focus).toHaveBeenCalled()


    describe 'grep', ->

      it 'should goToFirstFiltered row and focus the editor', ->
        scope.search = '/something'
        scope.enterSearch()

        expect(editor.goToFirstFiltered).toHaveBeenCalled()
        expect(editor.focus).toHaveBeenCalled()


  describe 'events', ->
    broadcast = null

    beforeEach inject ($rootScope) ->
      broadcast = (event) ->
        $rootScope.$broadcast event

    it 'should handle "quit"', inject (appWindow, settings) ->
      spyOn settings, 'store'
      broadcast 'quit'

      expect(settings.store).toHaveBeenCalled()
      expect(appWindow.close).toHaveBeenCalled();


  describe 'quit', ->

    it 'should store settings and quit the app', inject (appWindow, settings) ->
      spyOn settings, 'store'
      scope.quit()

      expect(settings.store).toHaveBeenCalled()
      expect(appWindow.close).toHaveBeenCalled();


  describe 'maximize', ->

    it 'should maximize/restore', inject (appWindow) ->
      scope.maximize()
      expect(appWindow.maximize).toHaveBeenCalled()
      appWindow._resetAllSpies()

      scope.maximize()
      expect(appWindow.restore).toHaveBeenCalled()


    it 'should set proper maximizeTitle', ->
      expect(scope.maximizeTitle).toBe MAXIMIZE_TITLE

      scope.maximize()
      expect(scope.maximizeTitle).toBe RESTORE_TITLE

      scope.maximize();
      expect(scope.maximizeTitle).toBe MAXIMIZE_TITLE
