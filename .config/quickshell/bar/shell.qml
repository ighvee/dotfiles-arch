import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

ShellRoot {

property string cpuUsage: "0%"
property string ramUsage: "0%"

Process {

    id: statsProcess

    command: [
        "sh",
        "-c",

        "CPU=$(top -bn1 | " +
        "awk '/Cpu\\(s\\)/ {printf \"%.0f\", 100-$8}'); " +

        "RAM=$(free | " +
        "awk '/Mem:/ {printf \"%.0f\", ($3/$2)*100}'); " +

        "printf '%s\\n%s\\n' " +
        "\"${CPU:-0}%\" " +
        "\"${RAM:-0}%\""
    ]

    stdout: StdioCollector {

        onStreamFinished: {

            var lines =
                this.text.trim().split("\n")

            if (lines.length >= 2) {

                cpuUsage =
                    lines[0]

                ramUsage =
                    lines[1]
            }
        }
    }

    running:
        true
}

Timer {

    interval:
        2000

    running:
        true

    repeat:
        true

    onTriggered: {

        if (!statsProcess.running)
            statsProcess.running = true
    }
}

Variants {

    model:
        Quickshell.screens

    delegate:
        PanelWindow {

            id: bar

            required property var modelData

            screen:
                modelData

            anchors {
                top:
                    true

                left:
                    true

                right:
                    true
            }

            margins {
                top:
                    8

                left:
                    12

                right:
                    12
            }

            implicitHeight:
                42

            color:
                "transparent"

            exclusiveZone:
                0

            aboveWindows:
                true

            focusable:
                false

            property int currentWorkspace:
                Hyprland.focusedWorkspace
                ? Math.min(
                    Math.max(
                        Hyprland.focusedWorkspace.id,
                        1
                    ),
                    9
                )
                : 1

            property int sixthWorkspace:
                currentWorkspace > 6
                ? currentWorkspace
                : 6

            property int sixthWorkspaceWidth:
                28

            Rectangle {

                id:
                    workspacePill

                anchors {
                    left:
                        parent.left

                    top:
                        parent.top
                }

                height:
                    42

                width:
                    workspaceRow.width + 40

                radius:
                    21

                color:
                    "#161616"

                Item {

                    id:
                        workspaceRow

                    anchors {
                        left:
                            parent.left

                        leftMargin:
                            6

                        verticalCenter:
                            parent.verticalCenter
                    }

                    width:
                        5 * 28 +
                        5 * 2 +
                        (
                            sixthWorkspaceWidth -
                            28
                        )

                    height:
                        28

                    Rectangle {

                        id:
                            activeWorkspaceIndicator

                        z:
                            0

                        y:
                            0

                        height:
                            28

                        radius:
                            14

                        color:
                            "#f2f2f2"

                        width:
                            currentWorkspace >= 6
                            ? sixthWorkspaceWidth
                            : 28

                        x:
                            currentWorkspace <= 5
                            ? (
                                (currentWorkspace - 1) * 30
                            )
                            : 5 * 30

                        Behavior on x {

                            NumberAnimation {

                                duration:
                                    280

                                easing.type:
                                    Easing.OutCubic
                            }
                        }
                    }

                    Repeater {

                        model:
                            5

                        delegate:
                            Item {

                                required property int index

                                property int workspaceId:
                                    index + 1

                                width:
                                    28

                                height:
                                    28

                                x:
                                    index * 30

                                z:
                                    1

                                Text {

                                    anchors.centerIn:
                                        parent

                                    text:
                                        workspaceId

                                    color:
                                        currentWorkspace ===
                                        workspaceId
                                        ? "#161616"
                                        : "#f2f2f2"

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

                                        Hyprland.dispatch(
                                            'hl.dsp.focus({ workspace = "r~' +
                                            workspaceId +
                                            '" })'
                                        )
                                    }
                                }
                            }
                    }

                    Item {

                        id:
                            sixthWorkspaceItem

                        x:
                            5 * 30

                        y:
                            0

                        width:
                            sixthWorkspaceWidth

                        height:
                            28

                        z:
                            1

                        Text {

                            anchors.centerIn:
                                parent

                            text:
                                sixthWorkspace

                            color:
                                currentWorkspace >= 6
                                ? "#161616"
                                : "#f2f2f2"

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

                                if (
                                    sixthWorkspace >= 6 &&
                                    sixthWorkspace <= 9
                                ) {

                                    Hyprland.dispatch(
                                        'hl.dsp.focus({ workspace = "r~' +
                                        sixthWorkspace +
                                        '" })'
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Clock {

                id:
                    clock

                targetScreen:
                    modelData

                anchors {
                    horizontalCenter:
                        parent.horizontalCenter

                    top:
                        parent.top
                }
            }

            Wifi {

                id:
                    wifi

                anchors {
                    right:
                        cpuPill.left

                    rightMargin:
                        6

                    top:
                        parent.top
                }
            }

            Rectangle {

                id:
                    cpuPill

                anchors {
                    right:
                        ramPill.left

                    rightMargin:
                        6

                    top:
                        parent.top
                }

                width:
                    58

                height:
                    42

                radius:
                    21

                color:
                    "#161616"

                Text {

                    anchors.centerIn:
                        parent

                    text:
                        "󰻠 " +
                        cpuUsage

                    color:
                        "#f2f2f2"

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        12
                }
            }

            Rectangle {

                id:
                    ramPill

                anchors {
                    right:
                        powerPill.left

                    rightMargin:
                        6

                    top:
                        parent.top
                }

                width:
                    58

                height:
                    42

                radius:
                    21

                color:
                    "#161616"

                Text {

                    anchors.centerIn:
                        parent

                    text:
                        "󰍛 " +
                        ramUsage

                    color:
                        "#f2f2f2"

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        12
                }
            }

            Rectangle {

                id:
                    powerPill

                anchors {
                    right:
                        parent.right

                    top:
                        parent.top
                }

                width:
                    42

                height:
                    42

                radius:
                    21

                color:
                    "#161616"

                Text {

                    anchors.centerIn:
                        parent

                    text:
                        "󰐥"

                    color:
                        "#f2f2f2"

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        17
                }

                MouseArea {

                    anchors.fill:
                        parent

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {

                        Quickshell.execDetached([
                            "systemctl",
                            "poweroff"
                        ])
                    }
                }
            }
        }
}
}