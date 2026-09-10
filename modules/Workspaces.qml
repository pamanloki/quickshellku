import QtQuick
import "root:/services"

// niri workspaces, styled like your Waybar #workspaces buttons.
Item {
    id: root
    implicitWidth: wsRow.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: wsRow
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        spacing: 5

        Repeater {
            model: Niri.workspaces
            delegate: Rectangle {
                id: btn
                required property var modelData
                readonly property bool active: modelData.is_active || modelData.is_focused
                readonly property bool urgent: modelData.is_urgent === true
                readonly property bool empty: (modelData.windowCount || 0) === 0 && !active

                height: parent.height
                implicitWidth: Math.max(28, wsLabel.implicitWidth + 2 * Theme.pillHPad)
                radius: Theme.radius

                color: urgent ? Theme.base08
                    : active ? Theme.base0B
                    : empty ? Theme.base01
                    : Theme.base05

                border.width: urgent ? 2 : 0
                border.color: Theme.base0A

                Text {
                    id: wsLabel
                    anchors.centerIn: parent
                    text: modelData.name && String(modelData.name).length > 0
                        ? modelData.name : String(modelData.idx)
                    color: btn.empty ? Theme.base05 : Theme.base00
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Niri.focusWorkspace(modelData)
                }
            }
        }
    }
}
