pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property ListModel availableFonts: ListModel {}
  property ListModel monospaceFonts: ListModel {}
  property ListModel displayFonts: ListModel {}
  property bool fontsLoaded: false
  property bool isLoading: false

  property var fontconfigMonospaceFonts: ({})
  property var fontCache: ({})

  readonly property int chunkSize: 100

  function init() {
    loadFontconfigMonospaceFonts();
  }

  function loadFontconfigMonospaceFonts() {
    fontconfigProcess.command = ["fc-list", ":mono", "family"];
    fontconfigProcess.running = true;
  }

  function loadSystemFonts() {
    if (isLoading)
      return;
    isLoading = true;

    var fontFamilies = Qt.fontFamilies();
    fontFamilies.sort(function (a, b) {
      return a.localeCompare(b);
    });

    availableFonts.clear();
    monospaceFonts.clear();
    displayFonts.clear();
    fontCache = {};

    processFontsAsync(fontFamilies, 0);
  }

  function processFontsAsync(fontFamilies, startIndex) {
    var endIndex = Math.min(startIndex + chunkSize, fontFamilies.length);
    var hasMore = endIndex < fontFamilies.length;

    var availableBatch = [];
    var monospaceBatch = [];
    var displayBatch = [];

    for (var i = startIndex; i < endIndex; i++) {
      var fontName = fontFamilies[i];
      if (!fontName || fontName.trim() === "")
        continue;
      var fontObj = {
        "key": fontName,
        "name": fontName
      };

      availableBatch.push(fontObj);

      if (isMonospaceFont(fontName))
        monospaceBatch.push(fontObj);

      if (isDisplayFont(fontName))
        displayBatch.push(fontObj);
    }

    batchAppendToModel(availableFonts, availableBatch);
    batchAppendToModel(monospaceFonts, monospaceBatch);
    batchAppendToModel(displayFonts, displayBatch);

    if (hasMore) {
      Qt.callLater(function () {
        processFontsAsync(fontFamilies, endIndex);
      });
    } else {
      finalizeFontLoading();
    }
  }

  function batchAppendToModel(model, items) {
    for (var i = 0; i < items.length; i++)
      model.append(items[i]);
  }

  function finalizeFontLoading() {
    if (monospaceFonts.count === 0)
      addFallbackFonts(monospaceFonts, ["DejaVu Sans Mono"]);

    if (displayFonts.count === 0)
      addFallbackFonts(displayFonts, ["Inter", "Roboto", "DejaVu Sans"]);

    fontsLoaded = true;
    isLoading = false;
  }

  function isMonospaceFont(fontName) {
    if (fontCache.hasOwnProperty(fontName))
      return fontCache[fontName].isMonospace;

    var result = false;

    if (fontconfigMonospaceFonts.hasOwnProperty(fontName)) {
      result = true;
    } else {
      var lowerFontName = fontName.toLowerCase();
      if (lowerFontName.includes("mono") || lowerFontName.includes("monospace"))
        result = true;
    }

    if (!fontCache[fontName])
      fontCache[fontName] = {};

    fontCache[fontName].isMonospace = result;
    return result;
  }

  function isDisplayFont(fontName) {
    if (fontCache.hasOwnProperty(fontName) && fontCache[fontName].hasOwnProperty("isDisplay")) {
      return fontCache[fontName].isDisplay;
    }

    var result = false;
    var lowerFontName = fontName.toLowerCase();

    if (lowerFontName.includes("display") || lowerFontName.includes("headline") || lowerFontName.includes("title")) {
      result = true;
    }

    if (["Inter", "Roboto", "DejaVu Sans"].indexOf(fontName) !== -1)
      result = true;

    if (!fontCache[fontName])
      fontCache[fontName] = {};

    fontCache[fontName].isDisplay = result;
    return result;
  }

  function sortModel(model) {
    var fontsArray = [];

    for (var i = 0; i < model.count; i++) {
      fontsArray.push({
        "key": model.get(i).key,
        "name": model.get(i).name
      });
    }

    fontsArray.sort(function (a, b) {
      return a.name.localeCompare(b.name);
    });

    model.clear();
    batchAppendToModel(model, fontsArray);
  }

  function addFallbackFonts(model, fallbackFonts) {
    var existingFonts = {};

    for (var i = 0; i < model.count; i++)
      existingFonts[model.get(i).name] = true;

    var toAdd = [];

    for (var j = 0; j < fallbackFonts.length; j++) {
      var fontName = fallbackFonts[j];
      if (!existingFonts[fontName]) {
        toAdd.push({
          "key": fontName,
          "name": fontName
        });
      }
    }

    if (toAdd.length > 0) {
      batchAppendToModel(model, toAdd);
      sortModel(model);
    }
  }

  function searchFonts(query) {
    if (!query || query.trim() === "")
      return availableFonts;

    var results = [];
    var lowerQuery = query.toLowerCase();

    for (var i = 0; i < availableFonts.count; i++) {
      var font = availableFonts.get(i);
      if (font.name.toLowerCase().includes(lowerQuery))
        results.push(font);
    }

    return results;
  }

  Process {
    id: fontconfigProcess
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text !== "") {
          var lines = this.text.split("\n");
          var monospaceLookup = {};

          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line && line !== "")
              monospaceLookup[line] = true;
          }

          root.fontconfigMonospaceFonts = monospaceLookup;
        }
        root.loadSystemFonts();
      }
    }

    onExited: function (exitCode, exitStatus) {
      if (exitCode !== 0)
        root.fontconfigMonospaceFonts = {};
      root.loadSystemFonts();
    }
  }
}
