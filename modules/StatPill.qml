import QtQuick
import "root:/services"

// A Waybar-style two-segment pill: an icon segment (base02 bg, accent fg)
// followed by an optional value segment (base01 bg, base05 fg).
//
// Anti-flicker: the bar's right side is a right-anchored Row, so if any pill
// changes width (e.g. cpu "6%" -> "12%", a different digit count) the whole
// row re-aligns and every pill — including the bright clock — visibly jumps.
// So the value segment reserves a FIXED width sized to `valueMax` via
// FontMetrics, and all widths are Math.round()-ed. With a fixed reserved
// width the row never reflows on a value change.
Item {
    id: root

    property string icon: ""
    property string value: ""
    property color accent: Theme.base05
    property color iconBg: Theme.base02
    property bool showValue: true
    property string valueMax: ""   // widest value the pill will ever show (e.g. "100%")

    signal clicked()
    signal rightClicked()
    signal scrollUp()
    signal scrollDown()

    implicitWidth: Math.round(content.implicitWidth)
    implicitHeight: Theme.barHeight

    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        spacing: 0

        Rectangle {
            height: parent.height
            radius: Theme.radius
            color: root.iconBg
            implicitWidth: Math.round(iconText.implicitWidth) + 2 * Theme.pillHPad
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
            implicitWidth: Math.round(root.valueMax.length > 0
                ? fm.advanceWidth(root.valueMax)
                : valText.implicitWidth) + 2 * Theme.pillHPad
            visible: root.showValue && root.value.length > 0
            Text {
                id: valText
                anchors.centerIn: parent
                text: root.value
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.features: ({ "tnum": 1 })
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
