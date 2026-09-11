import QtQuick
import Quickshell
import "root:/services"

// Combined system stats in one capsule: cpu / mem / disk / temp.
// Each value reserves a fixed width (FontMetrics) so nothing reflows.
// Click opens btop.
Item {
    id: root
    implicitWidth: Math.round(cap.width)
    implicitHeight: Theme.barHeight

    FontMetrics {
        id: fm
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    component Seg: Row {
        property string icon: ""
        property string value: ""
        property color accent: Theme.base05
        property string vmax: ""
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: icon
            color: accent
            font.family: Theme.fontFamilyFallback
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: value
            color: Theme.base05
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
            font.features: ({ "tnum": 1 })
            width: Math.round(fm.advanceWidth(vmax))
        }
    }

    Rectangle {
        id: cap
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.barHeight - 2 * Theme.pillVMargin
        radius: Theme.radius
        color: Theme.base01
        width: Math.round(segs.implicitWidth) + 2 * Theme.pillHPad

        Row {
            id: segs
            anchors.centerIn: parent
            spacing: 14

            Seg {
                icon: "󰻠"
                value: SystemStats.cpuPercent + "%"
                accent: Theme.base08
                vmax: "100%"
            }
            Seg {
                icon: "󰍛"
                value: SystemStats.memText
                accent: Theme.base0C
                vmax: "99.9GiB"
            }
            Seg {
                icon: "󰋊"
                value: SystemStats.diskFree
                accent: Theme.base0A
                vmax: "999G"
            }
            Seg {
                icon: SystemStats.tempClass === "critical" ? "󰸁"
                    : (SystemStats.tempClass === "warm" ? "󱃂" : "󰔏")
                value: SystemStats.tempKnown ? (SystemStats.tempC + "°C") : "N/A"
                accent: SystemStats.tempClass === "critical" ? Theme.base08
                    : SystemStats.tempClass === "warm" ? Theme.base0A
                    : SystemStats.tempClass === "unknown" ? Theme.base03
                    : Theme.base0B
                vmax: "100°C"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["footx", "-e", "-f", "btop"])
    }
}
