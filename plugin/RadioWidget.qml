import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Now-playing widget for omarchy-radio. The CLI owns all state; this polls
// `omarchy-radio status` and forwards clicks to it.
//   left = station picker   scroll = volume   middle = pause/resume   right = stop
BarWidget {
  id: root
  moduleName: "local.radio-sg"

  readonly property string cli: Quickshell.env("HOME") + "/.local/bin/omarchy-radio"
  property var radio: ({ "class": "stopped", text: "", tooltip: "Radio stopped" })

  readonly property string cls: radio["class"]
  readonly property string glyph: cls === "playing" ? "󰐊"    // 󰐊 play
                                : cls === "paused"  ? "󰏤"    // 󰏤 pause
                                :                     "󰐹"    // 󰐹 radio

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() { if (!statusProc.running) statusProc.running = true }

  function run(args) {
    actionProc.command = [root.cli].concat(args)
    actionProc.running = true
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

  // Short actions; refresh once they are done.
  Process {
    id: actionProc
    onExited: root.refresh()
  }

  // `pick` blocks until a station is chosen, so it gets its own process.
  Process {
    id: pickProc
    command: [root.cli, "pick"]
    onExited: root.refresh()
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical || root.cls === "stopped" ? root.glyph : root.glyph + "  " + root.radio.text
    tooltipText: root.radio.tooltip
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.run(["toggle"])
      else if (b === Qt.RightButton) root.run(["stop"])
      else if (!pickProc.running) pickProc.running = true
    }
    onWheelMoved: function(delta) { root.run(["volume", delta > 0 ? "+5" : "-5"]) }
  }
}
