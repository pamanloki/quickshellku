import QtQuick
import "root:/services"

// A Waybar-style two-segment pill: an icon segment (base02 bg, accent fg)
// followed by an optional value segment (base01 bg, base05 fg).
// The item is full bar height; the coloured pill is centred with margins,
// so it aligns cleanly next to other modules inside a Row.
Item {
    id: root

    property string icon: ""
    property string value: ""
    property color accent: Theme.base05
    property color iconBg: Theme.base02
    property bool showValue: true
    property int minValueWidth: 0   // fix a min width so changing numbers don't jitter

    signal clicked()
    signal rightClicked()
    signal scrollUp()
    signal scrollDown()

    implicitWidth: content.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        spacing: 0

        Rectangle {
            height: parent.height
            radius: Theme.radius
            color: root.iconBg
            implicitWidth: iconText.implicitWidth + 2 * Theme.pillHPad
            visible: root.icon.length > 0
            Text {
                id: iconText
                anchors.centerIn: parent
                text: root.icon
                color: root.accent
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
        }

        Rectangle {
            height: parent.height
            radius: Theme.radius
            color: Theme.base01
            implicitWidth: Math.max(root.minValueWidth, valText.implicitWidth + 2 * Theme.pillHPad)
            visible: root.showValue && root.value.length > 0
            Text {
                id: valText
                anchors.centerIn: parent
                text: root.value
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                root.scrollUp();
            else if (wheel.angleDelta.y < 0)
                root.scrollDown();
        }
    }
}
