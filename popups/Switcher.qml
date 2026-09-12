import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// macOS ⌘-Tab app switcher: a centred row of large app icons; the selected
// app is highlighted with its name above. Cycle with Tab / arrows, confirm on
// releasing Alt (or Enter / click), cancel with Escape.
//   labwc:  <keybind key="A-Tab"><action name="Execute" command="qs ipc call switcher next"/></keybind>
//           <keybind key="A-S-Tab"><action name="Execute" command="qs ipc call switcher prev"/></keybind>
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.switcherOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Globals.switcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:switcher"

        function iconFor(appId) {
            if (!appId) return Quickshell.iconPath("application-x-executable");
            let e = DesktopEntries.byId(appId);
            if (!e) { try { e = DesktopEntries.heuristicLookup(appId); } catch (err) {} }
            return Quickshell.iconPath(e && e.icon ? e.icon : appId, "application-x-executable");
        }
        function labelFor(appId) {
            if (!appId) return "";
            let e = DesktopEntries.byId(appId);
            if (!e) { try { e = DesktopEntries.heuristicLookup(appId); } catch (err) {} }
            return e && e.name ? e.name : (appId.charAt(0).toUpperCase() + appId.slice(1));
        }

        // dim backdrop
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: Globals.switcherOpen ? 0.28 : 0; Behavior on opacity { NumberAnimation { duration: 120 } } }

        // keyboard grab
        Item {
            anchors.fill: parent
            focus: Globals.switcherOpen
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Tab:
                    (event.modifiers & Qt.ShiftModifier) ? Globals.switcherStep(-1) : Globals.switcherStep(1);
                    event.accepted = true; break;
                case Qt.Key_Backtab:
                case Qt.Key_Left:
                    Globals.switcherStep(-1); event.accepted = true; break;
                case Qt.Key_Right:
                    Globals.switcherStep(1); event.accepted = true; break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    Globals.switcherConfirm(); event.accepted = true; break;
                case Qt.Key_Escape:
                    Globals.switcherCancel(); event.accepted = true; break;
                }
            }
            Keys.onReleased: event => {
                // releasing the modifier confirms, like macOS ⌘-Tab
                if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                    Globals.switcherConfirm();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, rowFlow.implicitWidth + 40)
            height: 132
            radius: 24
            color: Theme.base00
            border.width: 1
            border.color: Theme.base02

            opacity: Globals.switcherOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }
            scale: Globals.switcherOpen ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.OutCubic } }

            // selected app name
            Text {
                id: nameLabel
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: {
                    const e = Globals.switcherList[Globals.switcherIndex];
                    return e ? win.labelFor(e.app_id) : "";
                }
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }

            Row {
                id: rowFlow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 8

                Repeater {
                    model: Globals.switcherList
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 76; height: 76; radius: 16
                        readonly property bool sel: index === Globals.switcherIndex
                        color: sel ? Theme.base02 : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Image {
                            anchors.centerIn: parent
                            width: 56; height: 56
                            sourceSize.width: 56; sourceSize.height: 56
                            source: win.iconFor(modelData.app_id)
                            fillMode: Image.PreserveAspectFit
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: Globals.switcherIndex = index
                            onClicked: Globals.switcherConfirm()
                        }
                    }
                }
            }
        }
    }
}
