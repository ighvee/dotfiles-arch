import Quickshell
import Quickshell.Io
import QtQuick

Item {
id: clockRoot

width: 110
height: 42

required property var targetScreen

property bool clockMenuOpen: false

property real smoothSeconds: 0
property real smoothMinutes: 0
property real smoothHours: 0

SystemClock {
    id: systemClock

    precision:
        SystemClock.Seconds
}

Timer {
    id: clockUpdateTimer

    interval: 16
    repeat: true
    running: clockRoot.clockMenuOpen
    triggeredOnStart: true

    onTriggered: {

        var now = new Date()

        var milliseconds =
            now.getMilliseconds()

        var seconds =
            now.getSeconds() +
            milliseconds / 1000.0

        var minutes =
            now.getMinutes() +
            seconds / 60.0

        var hours =
            (now.getHours() % 12) +
            minutes / 60.0

        smoothSeconds =
            seconds * 6

        smoothMinutes =
            minutes * 6

        smoothHours =
            hours * 30
    }
}

Rectangle {
    id: clockPill

    anchors.fill:
        parent

    radius:
        21

    color:
        clockRoot.clockMenuOpen
        ? "#242424"
        : "#161616"

    Text {
        anchors.centerIn:
            parent

        text:
            Qt.formatDateTime(
                systemClock.date,
                "h:mm:ss AP"
            )

        color:
            "#f2f2f2"

        font.family:
            "JetBrainsMono Nerd Font"

        font.pixelSize:
            12

        font.weight:
            Font.Medium
    }

    MouseArea {
        anchors.fill:
            parent

        cursorShape:
            Qt.PointingHandCursor

        onClicked: {

            if (wifi.wifiMenuOpen)
                wifi.wifiMenuOpen = false

            wifi.wifiContextMenuOpen =
                false

            clockRoot.clockMenuOpen =
                !clockRoot.clockMenuOpen
        }
    }
}

PanelWindow {
    id: clockWindow

    screen:
        clockRoot.targetScreen

    visible:
        clockRoot.clockMenuOpen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    margins {
        top: 58
    }

    color:
        "transparent"

    exclusiveZone:
        0

    aboveWindows:
        true

    focusable:
        true

    MouseArea {
        anchors.fill:
            parent

        acceptedButtons:
            Qt.LeftButton |
            Qt.RightButton

        onClicked: {

            clockRoot.clockMenuOpen =
                false
        }
    }

    Rectangle {
        id: clockContainer

        anchors {
            horizontalCenter:
                parent.horizontalCenter

            top:
                parent.top
        }

        width:
            320

        height:
            320

        radius:
            160

        color:
            "#050505"

        border.width:
            1

        border.color:
            "#1d1d1d"

        z:
            10

        MouseArea {
            anchors.fill:
                parent

            acceptedButtons:
                Qt.LeftButton |
                Qt.RightButton

            cursorShape:
                Qt.PointingHandCursor

            onClicked: {

                clockRoot.clockMenuOpen =
                    false
            }
        }

        Item {
            id: clockFace

            anchors.centerIn:
                parent

            width:
                282

            height:
                282

            Rectangle {
                anchors.fill:
                    parent

                radius:
                    width / 2

                color:
                    "#000000"

                border.width:
                    1

                border.color:
                    "#151515"
            }

            Repeater {
                model:
                    60

                delegate:
                    Rectangle {

                        required property int index

                        property bool major:
                            index % 5 === 0

                        width:
                            major
                            ? 2
                            : 1

                        height:
                            major
                            ? 10
                            : 5

                        radius:
                            width / 2

                        color:
                            major
                            ? "#f2f2f2"
                            : "#555555"

                        anchors.centerIn:
                            parent

                        transform: [

                            Translate {
                                y:
                                    -(
                                        clockFace.height / 2
                                        - (
                                            major
                                            ? 18
                                            : 17
                                        )
                                    )
                            },

                            Rotation {
                                angle:
                                    index * 6

                                origin.x:
                                    0

                                origin.y:
                                    0
                            }
                        ]
                    }
            }

            Rectangle {
                id: hourHand

                width:
                    7

                height:
                    64

                radius:
                    3.5

                color:
                    "#f5f5f5"

                anchors {
                    horizontalCenter:
                        parent.horizontalCenter

                    bottom:
                        parent.verticalCenter
                }

                transformOrigin:
                    Item.Bottom

                rotation:
                    smoothHours
            }

            Rectangle {
                id: minuteHand

                width:
                    5

                height:
                    91

                radius:
                    2.5

                color:
                    "#f5f5f5"

                anchors {
                    horizontalCenter:
                        parent.horizontalCenter

                    bottom:
                        parent.verticalCenter
                }

                transformOrigin:
                    Item.Bottom

                rotation:
                    smoothMinutes
            }

            Rectangle {
                id: secondHand

                width:
                    2

                height:
                    105

                radius:
                    1

                color:
                    "#ff3b30"

                anchors {
                    horizontalCenter:
                        parent.horizontalCenter

                    bottom:
                        parent.verticalCenter
                }

                transformOrigin:
                    Item.Bottom

                rotation:
                    smoothSeconds

                Rectangle {
                    width:
                        6

                    height:
                        30

                    radius:
                        3

                    color:
                        "#ff3b30"

                    anchors {
                        horizontalCenter:
                            parent.horizontalCenter

                        top:
                            parent.bottom

                        topMargin:
                            7
                    }
                }
            }

            Rectangle {
                width:
                    12

                height:
                    12

                radius:
                    6

                anchors.centerIn:
                    parent

                color:
                    "#f5f5f5"

                Rectangle {
                    width:
                        4

                    height:
                        4

                    radius:
                        2

                    anchors.centerIn:
                        parent

                    color:
                        "#ff3b30"
                }
            }
        }
    }
}

}
