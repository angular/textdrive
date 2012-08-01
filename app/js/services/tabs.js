TD.factory('Tab', function(EditSession, $rootScope, log, modeForPath) {
  return function(fileEntry, content) {

    this._onSessionChange = function() {
      if (this.modified) {
        return;
      }

      var tab = this;
      $rootScope.$apply(function() {
        log(tab.file, 'modified');
        tab.modified = true;
      });
    };

    this.setFileEntry = function(fileEntry) {
      this.file = fileEntry || null;
      this.label = fileEntry && fileEntry.name || '<new file>';
      this.modified = false;
      if (!this.manualMode) {
        this.mode = modeForPath(this.label);
        this.session.setMode(this.mode.id);
        log('Set mode to', this.mode);
      } else {
        log('Keeping current mode (set manually).');
      }
    };

    this.icon = function() {
      return this.modified ? 'icon-certificate' : 'icon-remove';
    };

    this.manualMode = false;
    // TODO(vojta): pass mode to the constructor to avoid extra parsing
    this.session = new EditSession(content || '');
    this.setFileEntry(fileEntry);
    this.session.on('change', this._onSessionChange.bind(this));
  };
});


TD.factory('tabs', function(editor, fs, log, Tab, chromeFs, lru, settings, $rootScope) {
  var tabs = [];

  tabs.select = function(tab) {
    if (tabs.current) {
      $rootScope.$broadcast('tab_deselected');
    }

    tabs.current = tab;

    // move to editor
    if (tab) {
      editor.setSession(tab.session);
      lru.touch(tab);
      editor.focus();
    } else {
      editor.clearSession();
    }
  };

  tabs.close = function(tab) {
    tab = tab || tabs.current;

    var removeTab = function() {
      tabs.splice(tabs.indexOf(tab), 1);
      lru.remove(tab);
      tabs.select(lru.head());
    };

    // save the file
    var saveFile = function(writableFileEntry) {
      if (!writableFileEntry) {
        log('Closing file without saving.');
        $rootScope.$apply(removeTab);
        return;
      }

      fs.saveFile(writableFileEntry, tab.session.getValue()).then(function() {
        removeTab();
      });
    };

    if (!tab) {
      log('No open tab to close.');
      return;
    }

    if (!tab.modified) {
      log('Current file not modified.');
      return removeTab();
    }

    if (tab.file) {
      saveFile(tab.file);
    } else {
      chromeFs.chooseFile({type: "saveFile"}, saveFile);
    }
  };

  tabs.saveCurrent = function() {
    var tab = tabs.current;

    var saveFile = function(writableFileEntry) {
      if (!writableFileEntry) {
        return;
      }

      fs.saveFile(writableFileEntry, tab.session.getValue()).then(function() {
        tab.setFileEntry(writableFileEntry);
      });
    };

    if (!tab || (!tab.modified && tab.file)) {
      log('Nothing to save.');
      return;
    }

    if (tab.file) {
      saveFile(tab.file);
    } else {
      chromeFs.chooseFile({type: "saveFile"}, saveFile);
    }
  };

  tabs.open = function() {
    chromeFs.chooseFile({type: 'openWritableFile'}, function(fileEntry) {
      if (!fileEntry) {
        return;
      }

      if (tabs.selectByFile(fileEntry)) {
        return;
      }

      fs.loadFile(fileEntry).then(function(content) {
        // TODO(vojta): make this nicer
        var firstTab = tabs[0];
        var closeInitialTab = !!(tabs.length === 1 && !firstTab.file && !firstTab.modified);
        tabs.add(fileEntry, content);
        if (closeInitialTab) {
          log('Closing initial empty tab');
          tabs.close(firstTab);
        }
      }, function() {
        log('Error during opening file');
      });
    });
  };

  tabs.selectByFile = function(file) {
    for (var i = 0; i < tabs.length; i++) {
      // TODO(vojta): use chromeFs.getDisplayPath() instead
      if (tabs[i].file && tabs[i].file.fullPath === file.fullPath) {
        tabs.select(tabs[i]);
        return true;
      }
    }

    return false;
  };

  tabs.add = function(fileEntry, content) {
    var tab = new Tab(fileEntry, content);
    var current = tabs.current;

    if (current) {
      tabs.splice(tabs.indexOf(current) + 1, 0, tab);
    } else {
      tabs.push(tab);
    }

    tabs.select(tab);

    return tab;
  };

  return tabs;
});
