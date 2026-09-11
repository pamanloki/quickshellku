import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/services"

// Wallpaper picker for the current theme (thumbnails), applies via awww.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: Globals.wallpaperOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:wallpaper"

        onVisibleChanged: if (visible) Wallpaper.refresh()

        function fileUrl(p) { return "file://" + p.replace(/ /g, "%20"); }

        MouseArea { anchors.fill: parent; onClicked: Globals.wallpaperOpen = false }

        Item {
            id: box
            opacity: win.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durEffects; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEffects } }
            transformOrigin: Item.BottomRight
            scale: win.visible ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpatial } }

            width: 420
            height: 380
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 0
            IslandBg { anchors.fill: parent; radius: 16 }
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "󰸉  Wallpaper"
                    color: Theme.base05
                    font.family: Theme.fontFamilyFallback
                    font.pixelSize: Theme.fontSize + 2
                    font.weight: Theme.fontWeight
                }

                Text {
                    visible: Wallpaper.walls.length === 0
                    width: parent.width
                    text: "No wallpapers for the current theme\n(check ~/.config/flavours/walls.map)"
                    color: Theme.base03
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - 34
                    clip: true
                    visible: Wallpaper.walls.length > 0
                    model: Wallpaper.walls
                    cellWidth: Math.floor(width / 3)
                    cellHeight: Math.round(cellWidth * 0.62)
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        required property var modelData
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: Theme.base02
                            clip: true
                            border.width: imgHover.hovered ? 2 : 0
                            border.color: Theme.base0D

                            Image {
                                anchors.fill: parent
                                source: win.fileUrl(modelData)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 240
                                sourceSize.height: 150
                            }
                            HoverHandler { id: imgHover }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Wallpaper.apply(modelData);
                                    Globals.wallpaperOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
