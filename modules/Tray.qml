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
                    id: trayItem
                    required property var modelData
                    width: 20
                    height: 20

                    function showMenu() {
                        if (modelData.hasMenu && modelData.menu)
                            Globals.openTrayMenu(modelData.menu, trayItem.mapToItem(null, trayItem.width / 2, 0).x);
                        else
                            modelData.secondaryActivate();
                    }

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
                                // Left-click: activate, or open the menu for menu-only items.
                                if (trayItem.modelData.onlyMenu)
                                    trayItem.showMenu();
                                else
                                    trayItem.modelData.activate();
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayItem.modelData.secondaryActivate();
                            } else {
                                // Right-click: the app's context menu.
                                trayItem.showMenu();
                            }
                        }
                        onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }
}
