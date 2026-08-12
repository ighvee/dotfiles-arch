import Quickshell
import Quickshell.Io
import QtQuick

Item {
id: wifi

width: 42
height: 42

property bool wifiMenuOpen: false
property bool wifiContextMenuOpen: false

property bool wifiEnabled: true

property string connectedSsid: "Not connected"
property string connectedBand: ""
property int connectedSignal: 0

property var wifiNetworks: []

property string selectedSsid: ""

property bool passwordMode: false
property bool showPassword: false
property string wifiPassword: ""

property bool wifiConnecting: false

property bool passwordError: false
property color passwordTextColor: "#858585"

function openPasswordScreen(ssid) {
    wifiContextMenuOpen = false
    selectedSsid = ssid
    passwordInput.text = ""
    wifiPassword = ""
    showPassword = false
    passwordError = false
    passwordTextColor = "#858585"
    passwordMode = true

    Qt.callLater(function() {
        passwordInput.text = ""
        wifiPassword = ""
        passwordInput.forceActiveFocus()
    })
}

function closePasswordScreen() {
    passwordInput.text = ""
    wifiPassword = ""
    showPassword = false
    passwordError = false
    passwordTextColor = "#858585"
    passwordMode = false
}

function submitPassword() {
    if (wifiConnectProcess.running || wifiConnecting)
        return

    if (wifiPassword.length === 0)
        return

    connectToNetwork(
        selectedSsid,
        wifiPassword
    )
}

function passwordFailed() {
    passwordInput.text = ""
    wifiPassword = ""
    passwordError = true
    passwordTextColor = "#ff5f5f"
    passwordShake.restart()
    passwordErrorFade.restart()
}

SequentialAnimation {
    id: passwordShake

    PropertyAnimation {
        target: passwordInput
        property: "x"
        to: -4
        duration: 45
    }

    PropertyAnimation {
        target: passwordInput
        property: "x"
        to: 4
        duration: 45
    }

    PropertyAnimation {
        target: passwordInput
        property: "x"
        to: -3
        duration: 40
    }

    PropertyAnimation {
        target: passwordInput
        property: "x"
        to: 3
        duration: 40
    }

    PropertyAnimation {
        target: passwordInput
        property: "x"
        to: 0
        duration: 45
    }
}

SequentialAnimation {
    id: passwordErrorFade

    PauseAnimation {
        duration: 180
    }

    ColorAnimation {
        target: passwordInput
        property: "color"
        to: "#858585"
        duration: 400
    }

    ScriptAction {
        script: {
            passwordError = false
            passwordTextColor = "#858585"
        }
    }
}

function connectToNetwork(ssid, password) {
    if (wifiConnectProcess.running)
        return

    if (password === undefined)
        password = ""

    selectedSsid = ssid
    wifiConnecting = true

    wifiConnectProcess.command = [
        "sh",
        "-c",
        "DEVICE=$(nmcli -t -f DEVICE,TYPE,STATE device | " +
        "awk -F: '$2==\"wifi\" && $3==\"connected\" " +
        "{print $1; exit}'); " +
        "if [ -n \"$DEVICE\" ]; then " +
        "nmcli device disconnect \"$DEVICE\" " +
        ">/dev/null 2>&1 || true; " +
        "sleep 0.25; " +
        "fi; " +
        "nmcli dev wifi connect \"$1\" password \"$2\"",
        "quickshell-wifi",
        ssid,
        password
    ]

    wifiConnectProcess.running = true
}

function disconnectWifi() {
    if (wifiConnectProcess.running)
        return

    wifiContextMenuOpen = false

    Quickshell.execDetached([
        "sh",
        "-c",
        "DEVICE=$(nmcli -t -f DEVICE,TYPE,STATE device | " +
        "awk -F: '$2==\"wifi\" && $3==\"connected\" " +
        "{print $1; exit}'); " +
        "if [ -n \"$DEVICE\" ]; then " +
        "nmcli device disconnect \"$DEVICE\"; " +
        "fi"
    ])

    disconnectRefreshTimer.restart()
}

Timer {
    id: disconnectRefreshTimer

    interval: 300
    repeat: false

    onTriggered: {
        connectedProcess.running = true
        wifiScanProcess.running = true
    }
}

Process {
    id: wifiStatusProcess

    command: [
        "nmcli",
        "-t",
        "-f",
        "WIFI",
        "radio"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            wifiEnabled =
                this.text.trim() === "enabled"
        }
    }

    running: true
}

Process {
    id: connectedProcess

    command: [
        "nmcli",
        "-t",
        "-f",
        "ACTIVE,SSID,SIGNAL,FREQ",
        "dev",
        "wifi"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            var lines =
                this.text.trim().split("\n")

            var foundNetwork = false

            for (
                var i = 0;
                i < lines.length;
                i++
            ) {
                if (!lines[i].startsWith("yes:"))
                    continue

                var parts =
                    lines[i].split(":")

                var ssid =
                    parts.length > 1
                    ? parts[1]
                    : ""

                var signal =
                    parts.length > 2
                    ? parseInt(parts[2])
                    : 0

                var frequency =
                    parts.length > 3
                    ? parseInt(parts[3])
                    : 0

                if (ssid.length > 0) {
                    connectedSsid = ssid

                    connectedSignal =
                        isNaN(signal)
                        ? 0
                        : signal

                    connectedBand =
                        frequency >= 5000
                        ? "5GHZ"
                        : "2.4GHZ"

                    foundNetwork = true
                }

                break
            }

            if (!foundNetwork) {
                connectedSsid =
                    "Not connected"

                connectedBand =
                    ""

                connectedSignal =
                    0
            }
        }
    }

    running: true
}

Process {
    id: wifiScanProcess

    command: [
        "nmcli",
        "-t",
        "-f",
        "IN-USE,SSID,SIGNAL,SECURITY,FREQ",
        "dev",
        "wifi",
        "list"
    ]

    stdout: StdioCollector {
        onStreamFinished: {
            var lines =
                this.text.trim().split("\n")

            var networks = []

            for (
                var i = 0;
                i < lines.length;
                i++
            ) {
                var line =
                    lines[i]

                if (!line)
                    continue

                var parts = []
                var current = ""
                var escaped = false

                for (
                    var j = 0;
                    j < line.length;
                    j++
                ) {
                    var character =
                        line.charAt(j)

                    if (escaped) {
                        current += character
                        escaped = false
                        continue
                    }

                    if (character === "\\") {
                        escaped = true
                        continue
                    }

                    if (
                        character === ":" &&
                        parts.length < 4
                    ) {
                        parts.push(current)
                        current = ""
                        continue
                    }

                    current += character
                }

                parts.push(current)

                if (parts.length < 5)
                    continue

                var inUse =
                    parts[0]

                var ssid =
                    parts[1]

                var signal =
                    parseInt(parts[2])

                var security =
                    parts[3]

                var frequency =
                    parseInt(parts[4])

                if (!ssid)
                    ssid = "Hidden network"

                var band =
                    frequency >= 5000
                    ? "5GHZ"
                    : "2.4GHZ"

                networks.push({
                    ssid: ssid,
                    signal:
                        isNaN(signal)
                        ? 0
                        : signal,
                    security: security,
                    frequency: frequency,
                    band: band,
                    connected:
                        inUse === "*"
                })
            }

            wifiNetworks =
                networks
        }
    }
}

Process {
    id: wifiRescanProcess

    command: [
        "nmcli",
        "dev",
        "wifi",
        "rescan"
    ]
}

Timer {
    interval: 5000
    running: wifiMenuOpen
    repeat: true

    onTriggered: {
        if (!wifiScanProcess.running)
            wifiScanProcess.running = true

        if (!connectedProcess.running)
            connectedProcess.running = true
    }
}

Process {
    id: wifiConnectProcess

    stdout:
        StdioCollector {}

    stderr:
        StdioCollector {}

    onExited:
        function(exitCode, exitStatus) {
            wifiConnecting = false

            if (exitCode === 0) {
                passwordInput.text = ""
                wifiPassword = ""

                connectedProcess.running = true
                wifiScanProcess.running = true

                if (passwordMode)
                    closePasswordScreen()

                return
            }

            if (passwordMode) {
                passwordFailed()
                return
            }

            connectedProcess.running = true
            wifiScanProcess.running = true
        }
}

Rectangle {
    id: wifiPill

    anchors.fill:
        parent

    radius:
        21

    color:
        wifiMenuOpen
        ? "#242424"
        : "#161616"

    Text {
        anchors.centerIn:
            parent

        text:
            connectedSsid !== "Not connected"
            ? "󰖩"
            : "󰖪"

        color:
            "#f2f2f2"

        font.family:
            "JetBrainsMono Nerd Font"

        font.pixelSize:
            16
    }

    MouseArea {
        anchors.fill:
            parent

        cursorShape:
            Qt.PointingHandCursor

        onClicked: {
            clock.clockMenuOpen = false
            wifiContextMenuOpen = false

            wifiMenuOpen =
                !wifiMenuOpen

            if (wifiMenuOpen) {
                wifiStatusProcess.running =
                    true

                connectedProcess.running =
                    true

                wifiRescanProcess.running =
                    true

                wifiScanProcess.running =
                    true
            }
        }
    }
}

PanelWindow {
    id: wifiWindow

    visible:
        wifiMenuOpen

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
            wifiContextMenuOpen =
                false

            wifiMenuOpen =
                false

            if (passwordMode)
                closePasswordScreen()
        }
    }

    Rectangle {
        id: wifiDropdown

        x:
            parent.width -
            width -
            12

        y:
            0

        width:
            320

        height:
            passwordMode
            ? 202
            : 340

        radius:
            18

        color:
            "#161616"

        border.width:
            1

        border.color:
            "#292929"

        z:
            10

        opacity:
            wifiMenuOpen
            ? 1
            : 0

        scale:
            wifiMenuOpen
            ? 1
            : 0.96

        transformOrigin:
            Item.TopRight

        Behavior on opacity {
            NumberAnimation {
                duration:
                    140
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration:
                    140

                easing.type:
                    Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill:
                parent

            acceptedButtons:
                Qt.LeftButton |
                Qt.RightButton

            onClicked: {
                wifiContextMenuOpen =
                    false

                mouse.accepted =
                    false
            }
        }

        Rectangle {
            id: wifiHeader

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            height:
                58

            color:
                "transparent"

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 18
                    top: parent.top
                    topMargin: 10
                }

                text:
                    passwordMode
                    ? "Connect to Wi-Fi"
                    : "Wi-Fi"

                color:
                    "#f2f2f2"

                font.family:
                    "JetBrainsMono Nerd Font"

                font.pixelSize:
                    14

                font.weight:
                    Font.Medium
            }

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 18
                    bottom: parent.bottom
                    bottomMargin: 10
                }

                text:
                    passwordMode
                    ? selectedSsid
                    : (
                        connectedSsid !==
                        "Not connected"
                        ? connectedSsid +
                          " [" +
                          connectedBand +
                          "]"
                        : "Not connected"
                    )

                color:
                    "#858585"

                font.family:
                    "JetBrainsMono Nerd Font"

                font.pixelSize:
                    10

                width:
                    220

                elide:
                    Text.ElideRight
            }

            Rectangle {
                visible:
                    !passwordMode

                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter:
                        parent.verticalCenter
                }

                width:
                    42

                height:
                    24

                radius:
                    12

                color:
                    wifiEnabled
                    ? "#f2f2f2"
                    : "#303030"

                Rectangle {
                    width:
                        18

                    height:
                        18

                    radius:
                        9

                    anchors.verticalCenter:
                        parent.verticalCenter

                    x:
                        wifiEnabled
                        ? parent.width -
                          width -
                          3
                        : 3

                    color:
                        wifiEnabled
                        ? "#161616"
                        : "#888888"
                }

                MouseArea {
                    anchors.fill:
                        parent

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        wifiEnabled =
                            !wifiEnabled

                        Quickshell.execDetached([
                            "nmcli",
                            "radio",
                            "wifi",
                            wifiEnabled
                            ? "on"
                            : "off"
                        ])

                        Qt.callLater(function() {
                            wifiStatusProcess.running =
                                true

                            connectedProcess.running =
                                true

                            wifiScanProcess.running =
                                true
                        })
                    }
                }
            }
        }

        Rectangle {
            anchors {
                top: wifiHeader.bottom
                left: parent.left
                right: parent.right
            }

            height:
                1

            color:
                "#292929"
        }

        Item {
            id: passwordPage

            visible:
                passwordMode ||
                passwordAnimation.running

            anchors {
                top: wifiHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            opacity:
                passwordMode
                ? 1
                : 0

            scale:
                passwordMode
                ? 1
                : 0.97

            transformOrigin:
                Item.Top

            Behavior on opacity {
                NumberAnimation {
                    id:
                        passwordAnimation

                    duration:
                        160

                    easing.type:
                        Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration:
                        160

                    easing.type:
                        Easing.OutCubic
                }
            }

            Column {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                anchors.topMargin:
                    17

                spacing:
                    10

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text:
                        "Password"

                    color:
                        passwordTextColor

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        11
                }

                Rectangle {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    width:
                        270

                    height:
                        40

                    radius:
                        10

                    color:
                        "#222222"

                    border.width:
                        1

                    border.color:
                        passwordError
                        ? "#6b3030"
                        : "#303030"

                    TextInput {
                        id:
                            passwordInput

                        anchors {
                            left: parent.left
                            right: showPasswordToggle.left
                            verticalCenter:
                                parent.verticalCenter
                        }

                        anchors.leftMargin:
                            12

                        anchors.rightMargin:
                            6

                        color:
                            passwordTextColor

                        echoMode:
                            showPassword
                            ? TextInput.Normal
                            : TextInput.Password

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            12

                        font.letterSpacing:
                            4

                        onTextChanged: {
                            wifiPassword = text
                        }

                        Keys.onPressed:
                            function(event) {
                                if (
                                    event.key === Qt.Key_Return ||
                                    event.key === Qt.Key_Enter
                                ) {
                                    event.accepted = true
                                    submitPassword()
                                }
                            }
                    }

                    Rectangle {
                        id:
                            showPasswordToggle

                        anchors {
                            right: parent.right
                            rightMargin: 7
                            verticalCenter:
                                parent.verticalCenter
                        }

                        width:
                            28

                        height:
                            28

                        radius:
                            8

                        color:
                            showPassword
                            ? "#303030"
                            : "transparent"

                        Text {
                            anchors.centerIn:
                                parent

                            text:
                                showPassword
                                ? "󰈈"
                                : "󰈉"

                            color:
                                "#858585"

                            font.family:
                                "JetBrainsMono Nerd Font"

                            font.pixelSize:
                                14
                        }

                        MouseArea {
                            anchors.fill:
                                parent

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                showPassword =
                                    !showPassword
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    spacing:
                        8

                    Rectangle {
                        width:
                            90

                        height:
                            34

                        radius:
                            10

                        color:
                            "#242424"

                        Text {
                            anchors.centerIn:
                                parent

                            text:
                                "Cancel"

                            color:
                                "#f2f2f2"

                            font.family:
                                "JetBrainsMono Nerd Font"

                            font.pixelSize:
                                11
                        }

                        MouseArea {
                            anchors.fill:
                                parent

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                closePasswordScreen()
                        }
                    }

                    Rectangle {
                        id:
                            connectButton

                        width:
                            90

                        height:
                            34

                        radius:
                            10

                        color:
                            wifiConnecting
                            ? "#303030"
                            : "#f2f2f2"

                        Rectangle {
                            visible:
                                wifiConnecting

                            anchors.centerIn:
                                parent

                            width:
                                17

                            height:
                                17

                            radius:
                                8.5

                            color:
                                "transparent"

                            border.width:
                                2

                            border.color:
                                "#161616"

                            Rectangle {
                                width:
                                    6

                                height:
                                    6

                                radius:
                                    3

                                color:
                                    "#161616"

                                anchors {
                                    top: parent.top
                                    horizontalCenter:
                                        parent.horizontalCenter
                                }
                            }

                            RotationAnimation on rotation {
                                running:
                                    wifiConnecting

                                from:
                                    0

                                to:
                                    360

                                duration:
                                    750

                                loops:
                                    Animation.Infinite
                            }
                        }

                        Text {
                            visible:
                                !wifiConnecting

                            anchors.centerIn:
                                parent

                            text:
                                "Connect"

                            color:
                                "#161616"

                            font.family:
                                "JetBrainsMono Nerd Font"

                            font.pixelSize:
                                11
                        }

                        MouseArea {
                            anchors.fill:
                                parent

                            cursorShape:
                                wifiConnecting
                                ? Qt.BusyCursor
                                : Qt.PointingHandCursor

                            onClicked:
                                submitPassword()
                        }
                    }
                }
            }
        }

        Item {
            id:
                wifiPage

            visible:
                !passwordMode &&
                !passwordAnimation.running

            anchors {
                top: wifiHeader.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Column {
                id:
                    connectedSection

                visible:
                    connectedSsid !==
                    "Not connected"

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                anchors.topMargin:
                    8

                spacing:
                    2

                Text {
                    leftPadding:
                        18

                    text:
                        "Connected"

                    color:
                        "#858585"

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        10

                    height:
                        20

                    verticalAlignment:
                        Text.AlignVCenter
                }

                Rectangle {
                    id:
                        connectedNetwork

                    width:
                        parent.width - 16

                    height:
                        42

                    x:
                        8

                    radius:
                        10

                    color:
                        wifiContextMenuOpen
                        ? "#303030"
                        : "#242424"

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            "󰖩"

                        color:
                            "#f2f2f2"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            15
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 38
                            right: connectedSignalText.left
                            rightMargin: 10
                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            connectedSsid +
                            " [" +
                            connectedBand +
                            "]"

                        color:
                            "#f2f2f2"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            11

                        elide:
                            Text.ElideRight
                    }

                    Text {
                        id:
                            connectedSignalText

                        anchors {
                            right: parent.right
                            rightMargin: 12
                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            connectedSignal +
                            "%"

                        color:
                            "#858585"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            10
                    }

                    MouseArea {
                        anchors.fill:
                            parent

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked: {
                            wifiContextMenuOpen =
                                !wifiContextMenuOpen
                        }
                    }
                }

                Rectangle {
                    width:
                        parent.width - 36

                    height:
                        1

                    x:
                        18

                    color:
                        "#292929"
                }

                Text {
                    leftPadding:
                        18

                    text:
                        "Available networks"

                    color:
                        "#858585"

                    font.family:
                        "JetBrainsMono Nerd Font"

                    font.pixelSize:
                        10

                    height:
                        24

                    verticalAlignment:
                        Text.AlignVCenter
                }
            }

            Flickable {
                anchors {
                    top: parent.top
                    bottom: refreshArea.top
                    left: parent.left
                    right: parent.right
                }

                anchors.topMargin:
                    connectedSsid !==
                    "Not connected"
                    ? 106
                    : 16

                anchors.bottomMargin:
                    4

                clip:
                    true

                contentHeight:
                    networkColumn.height

                boundsBehavior:
                    Flickable.StopAtBounds

                Column {
                    id:
                        networkColumn

                    width:
                        parent.width

                    topPadding:
                        4

                    bottomPadding:
                        8

                    spacing:
                        2

                    Repeater {
                        model: {
                            var availableNetworks = []

                            for (
                                var i = 0;
                                i < wifiNetworks.length;
                                i++
                            ) {
                                var network =
                                    wifiNetworks[i]

                                if (
                                    network.ssid ===
                                    connectedSsid &&
                                    network.band ===
                                    connectedBand
                                )
                                    continue

                                availableNetworks.push(
                                    network
                                )
                            }

                            return availableNetworks
                        }

                        delegate:
                            Rectangle {
                                required property var modelData

                                width:
                                    networkColumn.width - 16

                                height:
                                    42

                                x:
                                    8

                                radius:
                                    10

                                color:
                                    modelData.ssid ===
                                    selectedSsid &&
                                    wifiConnecting
                                    ? "#242424"
                                    : "transparent"

                                Text {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 12
                                        verticalCenter:
                                            parent.verticalCenter
                                    }

                                    text:
                                        "󰖪"

                                    color:
                                        "#f2f2f2"

                                    font.family:
                                        "JetBrainsMono Nerd Font"

                                    font.pixelSize:
                                        15
                                }

                                Text {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 38
                                        right: signalText.left
                                        rightMargin: 10
                                        verticalCenter:
                                            parent.verticalCenter
                                    }

                                    text:
                                        modelData.ssid +
                                        " [" +
                                        modelData.band +
                                        "]"

                                    color:
                                        "#cccccc"

                                    font.family:
                                        "JetBrainsMono Nerd Font"

                                    font.pixelSize:
                                        11

                                    elide:
                                        Text.ElideRight
                                }

                                Rectangle {
                                    visible:
                                        modelData.ssid ===
                                        selectedSsid &&
                                        wifiConnecting

                                    anchors {
                                        right: parent.right
                                        rightMargin: 13
                                        verticalCenter:
                                            parent.verticalCenter
                                    }

                                    width:
                                        17

                                    height:
                                        17

                                    radius:
                                        8.5

                                    color:
                                        "transparent"

                                    border.width:
                                        2

                                    border.color:
                                        "#858585"

                                    Rectangle {
                                        width:
                                            6

                                        height:
                                            6

                                        radius:
                                            3

                                        color:
                                            "#858585"

                                        anchors {
                                            top: parent.top
                                            horizontalCenter:
                                                parent.horizontalCenter
                                        }
                                    }

                                    RotationAnimation on rotation {
                                        running:
                                            modelData.ssid ===
                                            selectedSsid &&
                                            wifiConnecting

                                        from:
                                            0

                                        to:
                                            360

                                        duration:
                                            750

                                        loops:
                                            Animation.Infinite
                                    }
                                }

                                Text {
                                    id:
                                        signalText

                                    visible:
                                        !(
                                            modelData.ssid ===
                                            selectedSsid &&
                                            wifiConnecting
                                        )

                                    anchors {
                                        right: parent.right
                                        rightMargin: 12
                                        verticalCenter:
                                            parent.verticalCenter
                                    }

                                    text:
                                        modelData.signal +
                                        "%"

                                    color:
                                        "#858585"

                                    font.family:
                                        "JetBrainsMono Nerd Font"

                                    font.pixelSize:
                                        10
                                }

                                MouseArea {
                                    anchors.fill:
                                        parent

                                    enabled:
                                        !wifiConnecting &&
                                        !wifiConnectProcess.running

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: {
                                        if (
                                            wifiConnectProcess.running
                                        )
                                            return

                                        selectedSsid =
                                            modelData.ssid

                                        if (
                                            modelData.security === "" ||
                                            modelData.security === "--"
                                        ) {
                                            connectToNetwork(
                                                selectedSsid
                                            )
                                        } else {
                                            openPasswordScreen(
                                                modelData.ssid
                                            )
                                        }
                                    }
                                }
                            }
                    }

                    Text {
                        visible:
                            wifiNetworks.filter(
                                function(network) {
                                    return !(
                                        network.ssid ===
                                        connectedSsid &&
                                        network.band ===
                                        connectedBand
                                    )
                                }
                            ).length === 0

                        width:
                            networkColumn.width

                        horizontalAlignment:
                            Text.AlignHCenter

                        text:
                            "Scanning for Networks.."

                        color:
                            "#858585"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            11
                    }
                }
            }

            Rectangle {
                id:
                    wifiContextMenu

                visible:
                    wifiContextMenuOpen &&
                    connectedSsid !==
                    "Not connected"

                x:
                    18

                y:
                    connectedSection.visible
                    ? 70
                    : 18

                width:
                    160

                height:
                    52

                radius:
                    10

                color:
                    "#242424"

                border.width:
                    1

                border.color:
                    "#353535"

                z:
                    100

                opacity:
                    wifiContextMenuOpen
                    ? 1
                    : 0

                scale:
                    wifiContextMenuOpen
                    ? 1
                    : 0.95

                transformOrigin:
                    Item.TopLeft

                Behavior on opacity {
                    NumberAnimation {
                        duration:
                            110
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration:
                            110

                        easing.type:
                            Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill:
                        parent

                    anchors.margins:
                        4

                    radius:
                        7

                    color:
                        "transparent"

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            "Disconnect"

                        color:
                            "#f2f2f2"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            11
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            "󰅖"

                        color:
                            "#858585"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            14
                    }

                    MouseArea {
                        anchors.fill:
                            parent

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked:
                            disconnectWifi()
                    }
                }
            }

            Rectangle {
                id:
                    refreshArea

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height:
                    48

                radius:
                    18

                color:
                    "#161616"

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }

                    height:
                        18

                    color:
                        "#161616"
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }

                    height:
                        1

                    color:
                        "#292929"
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter:
                            parent.verticalCenter
                    }

                    width:
                        34

                    height:
                        34

                    radius:
                        17

                    color:
                        "#242424"

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            "󰑐"

                        color:
                            "#858585"

                        font.family:
                            "JetBrainsMono Nerd Font"

                        font.pixelSize:
                            15
                    }

                    MouseArea {
                        anchors.fill:
                            parent

                        enabled:
                            !wifiConnecting

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked: {
                            if (wifiConnecting)
                                return

                            wifiRescanProcess.running =
                                true

                            wifiScanProcess.running =
                                true

                            connectedProcess.running =
                                true
                        }
                    }
                }
            }
        }
    }
}

}
