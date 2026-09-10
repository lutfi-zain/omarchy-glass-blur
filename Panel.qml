import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "lutfi.glass"
  ipcTarget: "lutfi.glass"
  manageIpc: true

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property string helperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/lutfi.glass/bin/glass-ctl"

  property real activeOpacity: 0.88
  property real inactiveOpacity: 0.78
  property bool blurEnabled: true
  property int blurPasses: 3
  property int blurSize: 6
  property bool barBlurEnabled: false
  property bool loaded: false

  function loadSettings() {
    getProc.running = true
  }

  function parseSettings(text) {
    try {
      var data = JSON.parse(text)
      if (data.activeOpacity !== undefined) root.activeOpacity = data.activeOpacity
      if (data.inactiveOpacity !== undefined) root.inactiveOpacity = data.inactiveOpacity
      if (data.blurEnabled !== undefined) root.blurEnabled = data.blurEnabled
      if (data.blurPasses !== undefined) root.blurPasses = data.blurPasses
      if (data.blurSize !== undefined) root.blurSize = data.blurSize
      root.loaded = true
      if (data.barBlur !== undefined) root.barBlurEnabled = data.barBlur
    } catch (e) {}
  }

  function applySettings(liveOnly) {
    if (!loaded) return
    var action = liveOnly ? "live" : "set"
    var args = [
      helperPath,
      action,
      activeOpacity.toFixed(2),
      inactiveOpacity.toFixed(2),
      blurEnabled ? "true" : "false",
      String(blurPasses),
      String(blurSize),
      barBlurEnabled ? "true" : "false"
    ]
    Quickshell.execDetached(args)
  }

  function applyPreset(active, inactive, blur, passes, size) {
    activeOpacity = active
    inactiveOpacity = inactive
    blurEnabled = blur
    blurPasses = passes
    blurSize = size
    applySettings(false)
  }

  Process {
    id: getProc
    command: [root.helperPath, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseSettings(text)
    }
  }

  Component.onCompleted: loadSettings()
  onOpenedChanged: if (opened) loadSettings()

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰾆"
    fontSize: Style.bar.iconFont
    tooltipText: "Glass & Blur Control"
    onPressed: function(b) {
      if (b === Qt.LeftButton || b === Qt.MiddleButton) root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // Header row with Icon, Title, and Blur Toggle
        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "󰾆"
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              text: "Glass & Blur"
              color: root.bar ? root.bar.foreground : Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              text: root.blurEnabled ? "Frosted glass enabled" : "Blur disabled (transparency only)"
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          ToggleSwitch {
            checked: root.blurEnabled
            onToggled: {
              root.blurEnabled = !root.blurEnabled
              root.applySettings(false)
            }
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        // Section 1: Active Opacity
        Column {
          width: parent.width
          spacing: Style.space(6)

          RowLayout {
            width: parent.width

            PanelSectionHeader {
              text: "ACTIVE WINDOW OPACITY"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }

            Item { Layout.fillWidth: true }

            Text {
              text: Math.round((opacitySlider.dragging ? opacitySlider.liveValue : root.activeOpacity) * 100) + "%"
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          PanelSlider {
            id: opacitySlider
            bar: root.bar
            width: parent.width
            minimum: 0.50
            maximum: 1.00
            step: 0.01
            value: root.activeOpacity
            onMoved: function(v) {
              root.activeOpacity = v
              root.inactiveOpacity = Math.max(0.40, Math.round((v - 0.10) * 100) / 100)
              root.applySettings(true)
            }
            onReleased: function(v) {
              root.activeOpacity = v
              root.inactiveOpacity = Math.max(0.40, Math.round((v - 0.10) * 100) / 100)
              root.applySettings(false)
            }
          }
        }

        // Section 2: Blur Passes
        Column {
          width: parent.width
          spacing: Style.space(6)
          opacity: root.blurEnabled ? 1.0 : 0.4

          RowLayout {
            width: parent.width

            PanelSectionHeader {
              text: "BLUR PASSES (SMOOTHNESS)"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }

            Item { Layout.fillWidth: true }

            Text {
              readonly property int pVal: Math.round(passesSlider.dragging ? passesSlider.liveValue : root.blurPasses)
              text: pVal + (pVal <= 1 ? " (Low)" : pVal <= 2 ? " (Med)" : pVal <= 3 ? " (High)" : " (Ultra)")
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          PanelSlider {
            id: passesSlider
            bar: root.bar
            width: parent.width
            minimum: 1
            maximum: 5
            step: 1
            integer: true
            value: root.blurPasses
            onMoved: function(v) {
              root.blurPasses = Math.round(v)
              root.applySettings(true)
            }
            onReleased: function(v) {
              root.blurPasses = Math.round(v)
              root.applySettings(false)
            }
          }
        }

        // Section 3: Blur Radius (Size)
        Column {
          width: parent.width
          spacing: Style.space(6)
          opacity: root.blurEnabled ? 1.0 : 0.4

          RowLayout {
            width: parent.width

            PanelSectionHeader {
              text: "BLUR RADIUS (SIZE)"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }

            Item { Layout.fillWidth: true }

            Text {
              text: Math.round(sizeSlider.dragging ? sizeSlider.liveValue : root.blurSize) + "px"
              color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          PanelSlider {
            id: sizeSlider
            bar: root.bar
            width: parent.width
            minimum: 2
            maximum: 12
            step: 1
            integer: true
            value: root.blurSize
            onMoved: function(v) {
              root.blurSize = Math.round(v)
              root.applySettings(true)
            }
            onReleased: function(v) {
              root.blurSize = Math.round(v)
              root.applySettings(false)
            }
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        // Section 4: Top Bar Blur
        Toggle {
          width: parent.width
          label: "Top Bar Blur"
          description: root.barBlurEnabled ? "Glass blur active on status bar" : "Status bar blur disabled"
          checked: root.barBlurEnabled
          foreground: root.bar ? root.bar.foreground : Color.foreground
          accent: root.bar ? root.bar.urgent : Color.accent
          onClicked: {
            root.barBlurEnabled = !root.barBlurEnabled
            root.applySettings(false)
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        // Section 5: Quick Presets
        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "QUICK PRESETS"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          GridLayout {
            width: parent.width
            columns: 2
            rowSpacing: Style.space(6)
            columnSpacing: Style.space(6)

            Button {
              Layout.fillWidth: true
              text: "Solid (100%)"
              bordered: true
              onClicked: root.applyPreset(1.00, 1.00, false, 1, 6)
            }

            Button {
              Layout.fillWidth: true
              text: "Subtle (92%)"
              bordered: true
              onClicked: root.applyPreset(0.92, 0.82, true, 2, 5)
            }

            Button {
              Layout.fillWidth: true
              text: "Frosted (88%)"
              bordered: true
              onClicked: root.applyPreset(0.88, 0.78, true, 3, 6)
            }

            Button {
              Layout.fillWidth: true
              text: "Deep (78%)"
              bordered: true
              onClicked: root.applyPreset(0.78, 0.68, true, 4, 8)
            }
          }
        }
      }
    }
  }
}
