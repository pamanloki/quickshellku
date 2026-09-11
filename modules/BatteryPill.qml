import QtQuick
import "root:/services"

// Battery pill: icon + percent, coloured by level / charging. Hidden entirely
// when there's no battery (desktop). Width is reserved for "100%" so a changing
// value never reflows the right-anchored row.
Item {
    id: root
    visible: Battery.present
    implicitWidth: visible ? Math.round(cap.width) : 0
    implicitHeight: Theme.barHeight

    readonly property color accent: Battery.critical ? Theme.base08
        : Battery.low ? Theme.base0A
        : Battery.charging ? Theme.base0B
        : Theme.base05

    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    Rectangle {
        id: cap
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        radius: Theme.radius
        color: Theme.base01
        width: Math.round(row.implicitWidth) + 2 * Theme.pillHPad

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.icon
                color: root.accent
                font.family: Theme.fontFamilyFallback
                font.pixelSize: Theme.fontSize + 1
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent + "%"
                color: Theme.base05
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                font.features: ({ "tnum": 1 })
                width: Math.round(fm.advanceWidth("100%"))
            }
        }
    }
}
