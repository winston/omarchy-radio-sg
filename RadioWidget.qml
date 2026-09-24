import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Now-playing widget for omarchy-radio. The CLI owns all state; this polls
// `omarchy-radio status` and forwards clicks to it.
//   left = popup card   scroll = volume   middle = pause/resume   right = stop
BarWidget {
  id: root
  moduleName: "winston.radio-sg"

  readonly property string cli: Quickshell.env("HOME") + "/.local/bin/omarchy-radio"
  property var radio: ({ "class": "stopped", text: "", tooltip: "Radio stopped", volume: 0 })
  property var stations: []
  property bool popupOpen: false

  readonly property string cls: radio["class"]
  readonly property bool stopped: cls === "stopped"
  readonly property string playGlyph: "󰐊"    // 󰐊
  readonly property string pauseGlyph: "󰏤"   // 󰏤
  readonly property string radioGlyph: "󰐹"   // 󰐹
  readonly property string glyph: cls === "playing" ? playGlyph : cls === "paused" ? pauseGlyph : radioGlyph

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function close() { popupOpen = false }
  function refresh() { if (!statusProc.running) statusProc.running = true }

  // Fire and forget, then look at the result once the command has had time to land.
  function run(args) {
    Quickshell.execDetached([root.cli].concat(args))
    refreshSoon.restart()
  }

  Process {
    id: statusProc
    command: [root.cli, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.radio = JSON.parse(text) } catch (e) { }
      }
    }
  }

  Process {
    id: listProc
    command: [root.cli, "list", "--json"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.stations = JSON.parse(text) } catch (e) { }
      }
    }
  }

  Timer {
    interval: root.popupOpen ? 1000 : 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshSoon
    interval: 350
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical || root.stopped ? root.glyph : root.glyph + "  " + root.radio.text
    tooltipText: root.popupOpen ? "" : root.radio.tooltip
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.run(["toggle"])
      else if (b === Qt.RightButton) root.run(["stop"])
      else root.popupOpen = !root.popupOpen
    }
    onWheelMoved: function(delta) { root.run(["volume", delta > 0 ? "+5" : "-5"]) }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      // Header: what is on
      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(56)
          height: Style.space(56)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: root.radioGlyph
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(66)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            textFormat: Text.PlainText
            text: root.stopped ? "Radio stopped" : root.radio.name
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: root.stopped ? "Pick a station below"
                : (root.radio.freq ? root.radio.freq + " FM · " : "") + (root.cls === "paused" ? "Paused" : "Playing")
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: root.radio.title ? root.radio.title : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      // Play / pause
      Row {
        anchors.horizontalCenter: parent.horizontalCenter

        Button {
          iconText: root.cls === "playing" ? root.pauseGlyph : root.playGlyph
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          verticalPadding: Style.spacing.controlPaddingY
          iconSize: Style.font.iconLarge
          enabled: !root.stopped
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.run(["toggle"])
        }
      }

      // Volume
      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          id: volIcon
          textFormat: Text.PlainText
          text: "󰕾"   // 󰕾
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.icon
          anchors.verticalCenter: parent.verticalCenter
        }

        PanelSlider {
          id: volume
          bar: root.bar
          width: parent.width - volIcon.width - volText.width - Style.space(16)
          anchors.verticalCenter: parent.verticalCenter
          minimum: 0
          maximum: 100
          step: 5
          integer: true
          value: root.radio.volume
          onReleased: function(v) {
            root.radio = Object.assign({}, root.radio, { volume: Math.round(v) })
            root.run(["volume", String(Math.round(v))])
          }
        }

        Text {
          id: volText
          textFormat: Text.PlainText
          text: Math.round(volume.liveValue) + "%"
          color: Qt.darker(root.bar.foreground, 1.3)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          width: Style.space(38)
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      PanelSeparator { foreground: root.bar.foreground }

      PanelSectionHeader {
        text: "STATIONS"
        foreground: root.bar.foreground
        fontFamily: root.bar.fontFamily
      }

      // Stations
      Column {
        id: stationList
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.stations

          BorderSurface {
            id: row
            required property var modelData
            readonly property bool current: root.radio.station === modelData.id

            width: stationList.width
            height: rowInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: current ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
            borderSpec: current ? Border.controlSpec("normal", root.bar.foreground, Color.accent) : Border.none()

            Row {
              id: rowInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: row.borderLeft + Style.space(8)
              anchors.rightMargin: row.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: row.current ? (root.cls === "paused" ? root.pauseGlyph : root.playGlyph) : root.radioGlyph
                color: row.current ? root.bar.foreground : Qt.darker(root.bar.foreground, 1.5)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: row.modelData.name
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: row.current
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: row.modelData.freq + " FM · " + row.modelData.operator
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.run(["play", row.modelData.id])
            }
          }
        }
      }
    }
  }
}
