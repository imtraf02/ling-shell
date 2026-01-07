pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import qs.commons
import qs.services

Popup {
  id: root

  property string title: "Select File"
  property string initialPath: Quickshell.env("HOME") || "/home"
  property string selectionMode: "files"
  property var nameFilters: ["*"]
  property bool showDirs: true
  property bool showHiddenFiles: false

  property var selectedPaths: []
  property string currentPath: initialPath
  property bool shouldResetSelection: false

  signal accepted(var paths)
  signal cancelled

  onOpened: {
    VisibilityService.willOpenPopup(root);
  }

  onClosed: {
    VisibilityService.willClosePopup(root);
  }

  function openFilePicker() {
    if (!root.currentPath)
      root.currentPath = root.initialPath;
    shouldResetSelection = true;
    open();
  }

  function getFileIcon(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    const iconMap = {
      "txt": 'description',
      "md": 'description',
      "log": 'description',
      "jpg": 'image',
      "jpeg": 'image',
      "png": 'image',
      "gif": 'image',
      "bmp": 'image',
      "svg": 'image',
      "mp4": 'video_file',
      "avi": 'video_file',
      "mkv": 'video_file',
      "mov": 'video_file',
      "mp3": 'audio_file',
      "wav": 'audio_file',
      "flac": 'audio_file',
      "ogg": 'audio_file',
      "zip": 'archive',
      "tar": 'archive',
      "gz": 'archive',
      "rar": 'archive',
      "7z": 'archive',
      "pdf": 'description',
      "doc": 'description',
      "docx": 'description',
      "xls": 'table_chart',
      "xlsx": 'table_chart',
      "ppt": 'slideshow',
      "pptx": 'slideshow',
      "html": 'code',
      "htm": 'code',
      "css": 'code',
      "js": 'code',
      "json": 'code',
      "xml": 'code',
      "exe": 'settings',
      "app": 'settings',
      "deb": 'settings',
      "rpm": 'settings'
    };
    return iconMap[ext] || 'insert_drive_file';
  }

  function formatFileSize(bytes) {
    if (bytes === 0)
      return "0 B";
    const k = 1024, sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
  }

  function confirmSelection() {
    if (filePickerPanel.currentSelection.length === 0)
      return;
    root.selectedPaths = filePickerPanel.currentSelection;
    root.accepted(filePickerPanel.currentSelection);
    root.close();
  }

  function updateFilteredModel() {
    filteredModel.clear();
    const searchText = filePickerPanel.filterText.toLowerCase();

    for (var i = 0; i < folderModel.count; i++) {
      const fileName = folderModel.get(i, "fileName");
      const filePath = folderModel.get(i, "filePath");
      const fileIsDir = folderModel.get(i, "fileIsDir");
      const fileSize = folderModel.get(i, "fileSize");

      if (!root.showHiddenFiles && fileName.startsWith(".")) {
        continue;
      }

      if (root.selectionMode === "folders" && !fileIsDir)
        continue;
      if (searchText === "" || fileName.toLowerCase().includes(searchText)) {
        filteredModel.append({
          "fileName": fileName,
          "filePath": filePath,
          "fileIsDir": fileIsDir,
          "fileSize": fileSize
        });
      }
    }
  }

  width: 900
  height: 700
  modal: true
  closePolicy: Popup.CloseOnEscape
  anchors.centerIn: Overlay.overlay

  background: Rectangle {
    color: ThemeService.palette.mSurfaceVariant
    radius: Settings.appearance.cornerRadius
    border.color: ThemeService.palette.mOutline
    border.width: 2
  }

  Rectangle {
    id: filePickerPanel
    anchors.fill: parent
    anchors.margins: Style.appearance.padding.normal
    color: "transparent"

    property string filterText: ""
    property var currentSelection: []
    property bool viewMode: true
    property string searchText: ""
    property bool showSearchBar: false

    focus: true

    Keys.onPressed: event => {
      if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
        filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
        if (filePickerPanel.showSearchBar)
          Qt.callLater(() => searchInput.forceActiveFocus());
        event.accepted = true;
      } else if (event.key === Qt.Key_Escape && filePickerPanel.showSearchBar) {
        filePickerPanel.showSearchBar = false;
        filePickerPanel.searchText = "";
        filePickerPanel.filterText = "";
        root.updateFilteredModel();
        event.accepted = true;
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.appearance.spacing.small

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.appearance.spacing.small

        IIcon {
          icon: "folder"
          color: ThemeService.palette.mPrimary
          pointSize: Style.appearance.font.size.extraLarge
        }
        IText {
          text: root.title
          pointSize: Style.appearance.font.size.large
          font.weight: Font.DemiBold
          color: ThemeService.palette.mPrimary
          Layout.fillWidth: true
        }

        IButton {
          text: "Select Current"
          icon: "folder_open"
          visible: root.selectionMode === "folders"
          onClicked: {
            filePickerPanel.currentSelection = [root.currentPath];
            root.confirmSelection();
          }
        }

        IIconButton {
          icon: "refresh"
          onClicked: {
            const currentFolder = folderModel.folder;
            folderModel.folder = "";
            folderModel.folder = currentFolder;
            Qt.callLater(root.updateFilteredModel);
          }
        }
        IIconButton {
          icon: "close"
          onClicked: {
            root.cancelled();
            root.close();
          }
        }
      }

      IDivider {
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 45
        color: ThemeService.palette.mSurfaceVariant
        radius: Settings.appearance.cornerRadius
        border.color: ThemeService.palette.mOutline
        border.width: 2

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.appearance.padding.normal
          anchors.rightMargin: Style.appearance.padding.normal
          spacing: Style.appearance.padding.normal

          IIconButton {
            icon: "arrow_upward"
            size: Style.appearance.widget.size * 0.8
            enabled: folderModel.folder.toString() !== "file:///"
            onClicked: {
              const parentPath = folderModel.parentFolder.toString().replace("file://", "");
              folderModel.folder = "file://" + parentPath;
              root.currentPath = parentPath;
            }
          }

          IIconButton {
            icon: "home"
            size: Style.appearance.widget.size * 0.8
            onClicked: {
              const homePath = Quickshell.env("HOME") || "/home";
              folderModel.folder = "file://" + homePath;
              root.currentPath = homePath;
            }
          }

          IIconButton {
            icon: filePickerPanel.showSearchBar ? "close" : "search"
            size: Style.appearance.widget.size * 0.8
            onClicked: {
              filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
              if (!filePickerPanel.showSearchBar) {
                filePickerPanel.searchText = "";
                filePickerPanel.filterText = "";
                root.updateFilteredModel();
              }
            }
          }

          ITextInput {
            id: locationInput
            text: root.currentPath
            placeholderText: "Enter path..."
            Layout.fillWidth: true

            visible: !filePickerPanel.showSearchBar
            enabled: !filePickerPanel.showSearchBar

            onEditingFinished: {
              const newPath = text.trim();
              if (newPath !== "" && newPath !== root.currentPath) {
                folderModel.folder = "file://" + newPath;
                root.currentPath = newPath;
              } else {
                text = root.currentPath;
              }
            }
            Connections {
              target: root
              function onCurrentPathChanged() {
                if (!locationInput.activeFocus)
                  locationInput.text = root.currentPath;
              }
            }
          }

          ITextInput {
            id: searchInput
            inputIconName: "search"
            placeholderText: "Search..."
            Layout.fillWidth: true

            visible: filePickerPanel.showSearchBar
            enabled: filePickerPanel.showSearchBar

            text: filePickerPanel.searchText
            onTextChanged: {
              filePickerPanel.searchText = text;
              filePickerPanel.filterText = text;
              root.updateFilteredModel();
            }
            Keys.onEscapePressed: {
              filePickerPanel.showSearchBar = false;
              filePickerPanel.searchText = "";
              filePickerPanel.filterText = "";
              root.updateFilteredModel();
            }
          }

          IIconButton {
            icon: filePickerPanel.viewMode ? "view_list" : "grid_view"
            size: Style.appearance.widget.size * 0.8
            onClicked: filePickerPanel.viewMode = !filePickerPanel.viewMode
          }
          IIconButton {
            icon: root.showHiddenFiles ? "visibility_off" : "visibility"
            size: Style.appearance.widget.size * 0.8
            onClicked: {
              root.showHiddenFiles = !root.showHiddenFiles;
              const currentFolder = folderModel.folder;
              folderModel.folder = "";
              folderModel.folder = currentFolder;
              Qt.callLater(root.updateFilteredModel);
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: ThemeService.palette.mSurface
        radius: Settings.appearance.cornerRadius
        border.color: ThemeService.palette.mOutline
        border.width: 2

        FolderListModel {
          id: folderModel
          folder: "file://" + root.currentPath
          nameFilters: root.showHiddenFiles ? ["*", ".*"] : root.nameFilters
          showDirs: root.showDirs
          showHidden: true
          showDotAndDotDot: false
          sortField: FolderListModel.Name
          sortReversed: false

          onFolderChanged: {
            root.currentPath = folder.toString().replace("file://", "");
            filePickerPanel.currentSelection = [];
            Qt.callLater(root.updateFilteredModel);
          }

          onStatusChanged: {
            if (status === FolderListModel.Null) {
              if (root.currentPath !== Quickshell.env("HOME")) {
                folder = "file://" + Quickshell.env("HOME");
                root.currentPath = Quickshell.env("HOME");
              }
            } else if (status === FolderListModel.Ready) {
              root.updateFilteredModel();
            }
          }
        }

        Connections {
          target: root
          function onShowHiddenFilesChanged() {
            folderModel.nameFilters = root.showHiddenFiles ? ["*", ".*"] : root.nameFilters;
          }
        }

        ListModel {
          id: filteredModel
        }

        GridView {
          id: gridView
          anchors.fill: parent
          anchors.margins: Style.appearance.padding.normal
          model: filteredModel
          visible: filePickerPanel.viewMode
          clip: true
          reuseItems: true

          property int columns: Math.max(1, Math.floor(width / (120)))
          property int itemSize: Math.floor((width - leftMargin - rightMargin - (columns * Style.appearance.padding.normal)) / columns)

          cellWidth: Math.floor((width - leftMargin - rightMargin) / columns)
          cellHeight: Math.floor(itemSize * 0.8) + Style.appearance.spacing.small + Style.appearance.font.size.small + Style.appearance.padding.normal

          leftMargin: Style.appearance.padding.normal
          rightMargin: Style.appearance.padding.normal
          topMargin: Style.appearance.padding.normal
          bottomMargin: Style.appearance.padding.normal

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
              implicitWidth: 6
              implicitHeight: 100
              radius: Settings.appearance.cornerRadius
              color: Qt.alpha(ThemeService.palette.mPrimary, 0.8)
              opacity: {
                let bar = parent as ScrollBar;
                return (bar && (bar.policy === ScrollBar.AlwaysOn || bar.active)) ? 1.0 : 0.0;
              }
              Behavior on opacity {
                IAnim {}
              }
              Behavior on color {
                ICAnim {}
              }
            }
            background: Rectangle {
              implicitWidth: 6
              implicitHeight: 100
              color: "transparent"
              opacity: {
                let bar = parent as ScrollBar;
                return (bar && (bar.policy === ScrollBar.AlwaysOn || bar.active)) ? 0.3 : 0.0;
              }
              radius: (Settings.appearance.cornerRadius) / 2
              Behavior on opacity {
                IAnim {}
              }
            }
          }

          delegate: Rectangle {
            id: gridItem
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            required property int fileSize

            width: gridView.itemSize
            height: gridView.cellHeight
            color: "transparent"
            radius: Settings.appearance.cornerRadius

            property bool isSelected: filePickerPanel.currentSelection.includes(filePath)

            Rectangle {
              anchors.fill: parent
              color: "transparent"
              radius: parent.radius
              border.color: gridItem.isSelected ? ThemeService.palette.mSecondary : ThemeService.palette.mSurface
              border.width: 3
              Behavior on color {
                ICAnim {}
              }
            }

            Rectangle {
              anchors.fill: parent
              color: (gridMouseArea.containsMouse && !gridItem.isSelected) ? ThemeService.palette.mPrimary : "transparent"
              radius: parent.radius
              border.color: (gridMouseArea.containsMouse && !gridItem.isSelected) ? ThemeService.palette.mPrimary : "transparent"
              border.width: 2
              Behavior on color {
                ICAnim {}
              }
              Behavior on border.color {
                ICAnim {}
              }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.appearance.padding.normal
              spacing: Style.appearance.spacing.small

              Rectangle {
                id: iconContainer
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(gridView.itemSize * 0.67)
                color: "transparent"

                property bool isImage: {
                  if (gridItem.fileIsDir)
                    return false;
                  const ext = gridItem.fileName.split('.').pop().toLowerCase();
                  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'ico'].includes(ext);
                }

                Image {
                  id: thumbnail
                  anchors.fill: parent
                  anchors.margins: Style.appearance.spacing.small
                  source: iconContainer.isImage ? "file://" + gridItem.filePath : ""
                  fillMode: Image.PreserveAspectFit
                  visible: iconContainer.isImage && status === Image.Ready
                  smooth: false
                  cache: true
                  asynchronous: true
                  sourceSize.width: 120
                  sourceSize.height: 120
                  onStatusChanged: {
                    if (status === Image.Error)
                      visible = false;
                  }

                  Rectangle {
                    anchors.fill: parent
                    color: ThemeService.palette.mSurfaceVariant
                    radius: Settings.appearance.cornerRadius
                    visible: thumbnail.status === Image.Loading
                    IIcon {
                      icon: "photo"
                      pointSize: Style.appearance.font.size.large
                      color: ThemeService.palette.mOnSurfaceVariant
                      anchors.centerIn: parent
                    }
                  }
                }

                IIcon {
                  icon: gridItem.fileIsDir ? "folder" : root.getFileIcon(gridItem.fileName)
                  pointSize: Style.appearance.font.size.large * 2
                  color: {
                    if (gridItem.isSelected)
                      return ThemeService.palette.mSecondary;
                    else if (gridMouseArea.containsMouse)
                      return ThemeService.palette.mOnPrimary;
                    else
                      return gridItem.fileIsDir ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant;
                  }
                  anchors.centerIn: parent
                  visible: !iconContainer.isImage || thumbnail.status !== Image.Ready
                }

                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: Style.appearance.padding.normal
                  width: 24
                  height: 24
                  radius: width / 2
                  color: ThemeService.palette.mSecondary
                  border.color: ThemeService.palette.mOutline
                  border.width: 2
                  visible: gridItem.isSelected
                  IIcon {
                    icon: "check"
                    pointSize: Style.appearance.font.size.small
                    color: ThemeService.palette.mOnSecondary
                    anchors.centerIn: parent
                  }
                }
              }

              IText {
                text: gridItem.fileName
                color: {
                  if (gridItem.isSelected)
                    return ThemeService.palette.mSecondary;
                  else if (gridMouseArea.containsMouse)
                    return ThemeService.palette.mOnPrimary;
                  else
                    return ThemeService.palette.mOnSurfaceVariant;
                }
                pointSize: Style.appearance.font.size.small
                font.weight: gridItem.isSelected ? Font.DemiBold : Font.Medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
              }
            }

            MouseArea {
              id: gridMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                  if (gridItem.fileIsDir) {
                    if (root.selectionMode === "folders") {
                      filePickerPanel.currentSelection = [gridItem.filePath];
                    }
                  } else {
                    if (root.selectionMode === "files") {
                      filePickerPanel.currentSelection = [gridItem.filePath];
                    }
                  }
                }
              }

              onDoubleClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                  if (gridItem.fileIsDir) {
                    folderModel.folder = "file://" + gridItem.filePath;
                    root.currentPath = gridItem.filePath;
                  } else {
                    if (root.selectionMode === "files") {
                      filePickerPanel.currentSelection = [gridItem.filePath];
                      root.confirmSelection();
                    }
                  }
                }
              }
            }
          }
        }

        IListView {
          id: listView
          anchors.fill: parent
          anchors.margins: Style.appearance.padding.normal
          model: filteredModel
          visible: !filePickerPanel.viewMode

          delegate: Rectangle {
            id: listItem
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            required property int fileSize

            width: listView.width
            height: 40
            color: {
              if (filePickerPanel.currentSelection.includes(filePath))
                return ThemeService.palette.mSecondary;
              if (listMouseArea.containsMouse)
                return ThemeService.palette.mPrimary;
              return "transparent";
            }
            radius: Settings.appearance.cornerRadius
            Behavior on color {
              ICAnim {}
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.appearance.padding.normal
              anchors.rightMargin: Style.appearance.padding.normal
              spacing: Style.appearance.spacing.small

              IIcon {
                icon: listItem.fileIsDir ? "folder" : root.getFileIcon(listItem.fileName)
                pointSize: Style.appearance.font.size.large
                color: listItem.fileIsDir ? (filePickerPanel.currentSelection.includes(listItem.filePath) ? ThemeService.palette.mOnSecondary : ThemeService.palette.mPrimary) : ThemeService.palette.mOnSurfaceVariant
              }

              IText {
                text: listItem.fileName
                color: filePickerPanel.currentSelection.includes(listItem.filePath) ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurface
                font.weight: filePickerPanel.currentSelection.includes(listItem.filePath) ? Font.DemiBold : Font.Medium
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              IText {
                text: listItem.fileIsDir ? "" : root.formatFileSize(listItem.fileSize)
                color: filePickerPanel.currentSelection.includes(listItem.filePath) ? ThemeService.palette.mOnSecondary : ThemeService.palette.mOnSurfaceVariant
                pointSize: Style.appearance.font.size.small
                visible: !listItem.fileIsDir
                Layout.preferredWidth: implicitWidth
              }
            }

            MouseArea {
              id: listMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                  if (listItem.fileIsDir) {
                    if (root.selectionMode === "folders") {
                      filePickerPanel.currentSelection = [listItem.filePath];
                    }
                  } else {
                    if (root.selectionMode === "files") {
                      filePickerPanel.currentSelection = [listItem.filePath];
                    }
                  }
                }
              }

              onDoubleClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                  if (listItem.fileIsDir) {
                    folderModel.folder = "file://" + listItem.filePath;
                    root.currentPath = listItem.filePath;
                  } else {
                    if (root.selectionMode === "files") {
                      filePickerPanel.currentSelection = [listItem.filePath];
                      root.confirmSelection();
                    }
                  }
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.appearance.spacing.small

        IText {
          text: {
            if (filePickerPanel.searchText.length > 0) {
              return "Searching for: \"" + filePickerPanel.searchText + "\" (" + filteredModel.count + " matches)";
            } else if (filePickerPanel.currentSelection.length > 0) {
              const selectedName = filePickerPanel.currentSelection[0].split('/').pop();
              return "Selected: " + selectedName;
            } else {
              return filteredModel.count + " items";
            }
          }
          color: filePickerPanel.searchText.length > 0 ? ThemeService.palette.mPrimary : ThemeService.palette.mOnSurfaceVariant

          pointSize: Style.appearance.font.size.small
          Layout.fillWidth: true
        }

        IButton {
          text: "Cancel"
          outlined: true
          onClicked: {
            root.cancelled();
            root.close();
          }
        }

        IButton {
          text: root.selectionMode === "folders" ? "Select Folder" : "Select File"
          icon: "check"
          enabled: filePickerPanel.currentSelection.length > 0
          onClicked: root.confirmSelection()
        }
      }
    }

    Connections {
      target: root
      function onShouldResetSelectionChanged() {
        if (root.shouldResetSelection) {
          filePickerPanel.currentSelection = [];
          root.shouldResetSelection = false;
        }
      }
    }

    Component.onCompleted: {
      if (!root.currentPath)
        root.currentPath = root.initialPath;
      folderModel.folder = "file://" + root.currentPath;
    }
  }
}
