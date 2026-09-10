import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "root:/services"

// System tray, styled like your Waybar #tray (base03 background).
Item {
    id: root
    implicitWidth: pill.width
    implicitHeight: Theme.barHeight
    visible: {
        const it = SystemTray.items;
        if (!it) return false;
        const v = it.values !== undefined ? it.values : it;
        return v && v.length > 0;
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        width: Math.max(1, trayRow.implicitWidth + 8)
        radius: Theme.radius
        color: Theme.base03

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property var modelData
                    width: 20
                    height: 20

                    Image {
                        anchors.fill: parent
                        sourceSize.width: 20
                        sourceSize.height: 20
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.onlyMenu)
                                    modelData.secondaryActivate();
                                else
                                    modelData.activate();
                            } else {
                                modelData.secondaryActivate();
                            }
                        }
                        onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
}
