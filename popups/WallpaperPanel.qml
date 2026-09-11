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
        visible: Globals.wallpaperOpen || slide.y > -box.height
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:wallpaper"

        onVisibleChanged: if (visible) Wallpaper.refresh()

        function fileUrl(p) { return "file://" + p.replace(/ /g, "%20"); }

        MouseArea { anchors.fill: parent; onClicked: Globals.wallpaperOpen = false }

        Item {
            id: box
            transform: Translate {
                id: slide
                y: Globals.wallpaperOpen ? 0 : -box.height
                Behavior on y { NumberAnimation { duration: Theme.durSlide; easing.type: Easing.OutCubic } }
            }

            width: 420
            height: 380
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: Theme.menuBarHeight + 6
            Rectangle { color: Theme.base00; border.width: 1; border.color: Theme.base02; anchors.fill: parent; radius: 16 }
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
