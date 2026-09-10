import QtQuick
import Quickshell
import "root:/services"

// wlr/taskbar equivalent: icons for open windows (from niri), click to focus.
Item {
    id: root
    implicitWidth: taskRow.implicitWidth
    implicitHeight: Theme.barHeight

    function iconFor(appId) {
        if (!appId)
            return "";
        let entry = DesktopEntries.byId(appId);
        if (!entry) {
            try {
                entry = DesktopEntries.heuristicLookup(appId);
            } catch (e) {}
        }
        const name = entry && entry.icon ? entry.icon : appId;
        return Quickshell.iconPath(name, "application-x-executable");
    }

    Row {
        id: taskRow
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        spacing: 4

        Repeater {
            model: Niri.windowList
            delegate: Rectangle {
                id: taskBtn
                required property var modelData
                readonly property bool active: modelData.id === Niri.focusedWindowId

                height: parent.height
                implicitWidth: height
                radius: Theme.radius
                color: Theme.base01

                Rectangle {
                    visible: taskBtn.active
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 6
                    height: 2
                    color: Theme.base05
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    sourceSize.width: 20
                    sourceSize.height: 20
                    source: root.iconFor(modelData.app_id)
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Niri.focusWindow(modelData.id)
                }
            }
        }
    }
}
