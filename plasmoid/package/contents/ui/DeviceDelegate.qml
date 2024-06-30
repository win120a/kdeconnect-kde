/**
 * SPDX-FileCopyrightText: 2013 Albert Vaca <albertvaka@gmail.com>
 * SPDX-FileCopyrightText: 2024 ivan tkachenko <me@ratijas.tk>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtCore
import QtQuick
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts

import org.kde.kdeconnect as KDEConnect
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

PlasmaComponents.ItemDelegate {
    id: root

    readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(model.deviceId)

    hoverEnabled: false
    down: false

    Kirigami.PromptDialog {
        id: prompt
        visible: false
        showCloseButton: true
        standardButtons: Kirigami.Dialog.NoButton
        title: i18n("Virtual Monitor is not available")
    }

    DropArea {
        id: fileDropArea
        anchors.fill: parent

        onDropped: drop => {
            if (drop.hasUrls) {
                const urls = new Set(drop.urls.map(url => url.toString()));
                urls.forEach(url => share.plugin.shareUrl(url));
            }
            drop.accepted = true;
        }

        PlasmaCore.ToolTipArea {
            id: dropAreaToolTip
            anchors.fill: parent
            active: true
            mainText: i18n("File Transfer")
            subText: i18n("Drop a file to transfer it onto your phone.")
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Battery {
                id: battery
                device: root.device
            }

            Connectivity {
                id: connectivity
                device: root.device
            }

            VirtualMonitor {
                id: virtualmonitor
                device: root.device
            }

            PlasmaComponents.Label {
                id: deviceName
                elide: Text.ElideRight
                text: model.name
                Layout.fillWidth: true
                textFormat: Text.PlainText
            }

            PlasmaComponents.ToolButton {
                icon.name: "video-monitor"
                visible: virtualmonitor.available
                text: i18n("Virtual Display")
                onClicked: {
                    let err = "";
                    if (virtualmonitor?.plugin?.hasRemoteVncClient === false) {
                        err = i18n("Remote device does not have a VNC client (eg. krdc) installed.");
                    }
                    if (virtualmonitor?.plugin?.isVirtualMonitorAvailable === false) {
                        err = (err ? err + "\n\n" : "")
                            + i18n("The krfb package is required on the local device.");
                    }

                    if (err) {
                        prompt.subtitle = err;
                        prompt.visible = true;
                    } else if (!virtualmonitor.plugin.requestVirtualMonitor()) {
                        prompt.subtitle = i18n("Failed to create the virtual monitor.");
                        prompt.visible = true;
                    }
                }
            }

            RowLayout {
                id: connectionInformation

                visible: connectivity.available
                spacing: Kirigami.Units.smallSpacing

                // TODO: In the future, when the Connectivity Report plugin supports more than one
                // subscription, add more signal strength icons to represent all the available
                // connections.

                Kirigami.Icon {
                    id: celluarConnectionStrengthIcon
                    source: connectivity.iconName
                    Layout.preferredHeight: connectivityText.height
                    Layout.preferredWidth: Layout.preferredHeight
                    Layout.alignment: Qt.AlignCenter
                    visible: valid
                }

                PlasmaComponents.Label {
                    // Fallback plain-text label. Only show this if the icon doesn't work.
                    id: connectivityText
                    text: connectivity.displayString
                    textFormat: Text.PlainText
                    visible: !celluarConnectionStrengthIcon.visible
                }
            }

            RowLayout {
                id: batteryInformation

                visible: battery.available && battery.charge > -1
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    id: batteryIcon
                    source: battery.iconName
                    // Make the icon the same size as the text so that it doesn't dominate
                    Layout.preferredHeight: batteryPercent.height
                    Layout.preferredWidth: Layout.preferredHeight
                    Layout.alignment: Qt.AlignCenter
                }

                PlasmaComponents.Label {
                    id: batteryPercent
                    text: i18nc("Battery charge percentage", "%1%", battery.charge)
                    textFormat: Text.PlainText
                }
            }

            PlasmaComponents.ToolButton {
                id: overflowMenu

                icon.name: "application-menu"
                checked: menu.status === PlasmaExtras.Menu.Open

                onPressed: menu.openRelative()

                PlasmaExtras.Menu {
                    id: menu
                    visualParent: overflowMenu
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup

                    // Share
                    PlasmaExtras.MenuItem {
                        id: shareFile

                        readonly property QtDialogs.FileDialog data: QtDialogs.FileDialog {
                            id: fileDialog
                            title: i18n("Please choose a file")
                            currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                            fileMode: QtDialogs.FileDialog.OpenFiles
                            onAccepted: fileDialog.selectedFiles.forEach(url => share.plugin.shareUrl(url))
                        }

                        icon: "document-share"
                        visible: share.available
                        text: i18n("Share file")
                        onClicked: fileDialog.open()
                    }

                    // Clipboard
                    PlasmaExtras.MenuItem {
                        id: sendclipboard

                        readonly property Clipboard data: Clipboard {
                            id: clipboard
                            device: root.device
                        }

                        icon: "klipper"
                        visible: clipboard.clipboard?.isAutoShareDisabled ?? false
                        text: i18n("Send Clipboard")

                        onClicked: {
                            clipboard.sendClipboard()
                        }
                    }


                    // Find my phone
                    PlasmaExtras.MenuItem {
                        id: ring

                        readonly property FindMyPhone data: FindMyPhone {
                            id: findmyphone
                            device: root.device
                        }

                        icon: "irc-voice"
                        visible: findmyphone.available
                        text: i18n("Ring my phone")

                        onClicked: {
                            findmyphone.ring()
                        }
                    }

                    // SFTP
                    PlasmaExtras.MenuItem {
                        id: browse

                        readonly property Sftp data: Sftp {
                            id: sftp
                            device: root.device
                        }

                        icon: "document-open-folder"
                        visible: sftp.available
                        text: i18n("Browse this device")

                        onClicked: {
                            sftp.browse()
                        }
                    }

                    // SMS
                    PlasmaExtras.MenuItem {
                        readonly property SMS data: SMS {
                            id: sms
                            device: root.device
                        }

                        icon: "message-new"
                        visible: sms.available
                        text: i18n("SMS Messages")

                        onClicked: {
                            sms.plugin.launchApp()
                        }
                    }
                }
            }
        }

        // RemoteKeyboard
        PlasmaComponents.ItemDelegate {
            visible: remoteKeyboard.remoteState
            Layout.fillWidth: true

            contentItem: RowLayout {
                width: parent.width
                spacing: 5

                PlasmaComponents.Label {
                    id: remoteKeyboardLabel
                    text: i18n("Remote Keyboard")
                }

                KDEConnect.RemoteKeyboard {
                    id: remoteKeyboard
                    device: root.device
                    Layout.fillWidth: true
                }
            }
        }

        // Notifications
        PlasmaComponents.ItemDelegate {
            visible: notificationsModel.count > 0
            enabled: true
            Layout.fillWidth: true

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Notifications:")
                }

                PlasmaComponents.ToolButton {
                    enabled: true
                    visible: notificationsModel.isAnyDimissable;
                    Layout.alignment: Qt.AlignRight
                    icon.name: "edit-clear-history"
                    PlasmaComponents.ToolTip.text: i18n("Dismiss all notifications")
                    onClicked: notificationsModel.dismissAll();
                }
            }
        }

        Repeater {
            id: notificationsView

            model: KDEConnect.NotificationsModel {
                id: notificationsModel
                deviceId: root.device.id()
            }

            delegate: PlasmaComponents.ItemDelegate {
                id: listitem

                enabled: true
                onClicked: checked = !checked
                Layout.fillWidth: true

                property bool replying: false

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            id: notificationIcon
                            source: appIcon
                            width: (valid && appIcon.length) ? dismissButton.width : 0
                            height: width
                            Layout.alignment: Qt.AlignLeft
                        }

                        PlasmaComponents.Label {
                            id: notificationLabel
                            text: appName + ": " + (title.length > 0 ? (appName == title ? notitext : title + ": " + notitext) : model.name)
                            elide: listitem.checked ? Text.ElideNone : Text.ElideRight
                            maximumLineCount: listitem.checked ? 0 : 1
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.ToolButton {
                            id: replyButton
                            visible: repliable
                            enabled: repliable && !replying
                            icon.name: "mail-reply-sender"
                            PlasmaComponents.ToolTip.text: i18n("Reply")
                            onClicked: { replying = true; replyTextField.forceActiveFocus(); }
                        }

                        PlasmaComponents.ToolButton {
                            id: dismissButton
                            visible: notificationsModel.isAnyDimissable;
                            enabled: dismissable
                            Layout.alignment: Qt.AlignRight
                            icon.name: "window-close"
                            PlasmaComponents.ToolTip.text: i18n("Dismiss")
                            onClicked: dbusInterface.dismiss();
                        }
                    }

                    RowLayout {
                        visible: replying
                        width: notificationLabel.width + replyButton.width + dismissButton.width + Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Button {
                            Layout.alignment: Qt.AlignBottom
                            id: replyCancelButton
                            text: i18n("Cancel")
                            display: PlasmaComponents.AbstractButton.IconOnly
                            PlasmaComponents.ToolTip {
                                text: parent.text
                            }
                            icon.name: "dialog-cancel"
                            onClicked: {
                                replyTextField.text = "";
                                replying = false;
                            }
                        }

                        PlasmaComponents.TextArea {
                            id: replyTextField
                            placeholderText: i18nc("@info:placeholder", "Reply to %1…", appName)
                            wrapMode: TextEdit.Wrap
                            Layout.fillWidth: true
                            Keys.onPressed: event => {
                                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                    replySendButton.clicked();
                                    event.accepted = true;
                                }
                                if (event.key === Qt.Key_Escape) {
                                    replyCancelButton.clicked();
                                    event.accepted = true;
                                }
                            }
                        }

                        PlasmaComponents.Button {
                            Layout.alignment: Qt.AlignBottom
                            id: replySendButton
                            text: i18n("Send")
                            icon.name: "document-send"
                            enabled: replyTextField.text
                            onClicked: {
                                dbusInterface.sendReply(replyTextField.text);
                                replyTextField.text = "";
                                replying = false;
                            }
                        }
                    }
                }
            }
        }

        RemoteCommands {
            id: remoteCommands
            device: root.device
        }

        // Commands
        RowLayout {
            visible: remoteCommands.available
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: i18n("Run command")
                Layout.fillWidth: true
            }

            PlasmaComponents.Button {
                id: addCommandButton
                icon.name: "list-add"
                PlasmaComponents.ToolTip.text: i18n("Add command")
                onClicked: remoteCommands.plugin.editCommands()
                visible: remoteCommands.plugin?.canAddCommand ?? false
            }
        }

        Repeater {
            id: commandsView

            visible: remoteCommands.available

            model: KDEConnect.RemoteCommandsModel {
                id: commandsModel
                deviceId: remoteCommands.device.id()
            }

            delegate: PlasmaComponents.ItemDelegate {
                enabled: true
                onClicked: remoteCommands.plugin?.triggerCommand(key)
                Layout.fillWidth: true

                contentItem: PlasmaComponents.Label {
                    text: name + "\n" + command
                }
            }
        }

        // Share
        Share {
            id: share
            device: root.device
        }
    }
}
