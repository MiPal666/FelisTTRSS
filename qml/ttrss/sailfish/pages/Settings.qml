/*
 * This file is part of TTRss, a Tiny Tiny RSS Reader App
 * for MeeGo Harmattan and Sailfish OS.
 * Copyright (C) 2012–2016  Hauke Schade
 *
 * TTRss is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * TTRss is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with TTRss; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or see
 * http://www.gnu.org/licenses/.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../items"

Dialog {
    id: settingsPage

    SilicaFlickable {
        contentHeight: settingsColumn.height
        contentWidth: parent.width
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                }
            }
        }

        Column {
            id: settingsColumn
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingMedium
            }
            spacing: Theme.paddingMedium

            DialogHeader {
                width: dialog.width
                title: qsTr("Settings")
                acceptText: qsTr("Save")
                cancelText: qsTr("Cancel")
            }

            // -- Startup --
            SectionHeader {
                text: qsTr("Startup")
            }

            TextSwitch {
                id: autoLoginSetting
                text: qsTr('Automatically Login')
                checked: settings.useAutologin
            }

            ComboBox {
                id: startPage
                label: qsTr("Page after login")
                currentIndex: Math.min(settings.startpage, 3)
                description: qsTr('You need to restart the App for this to take effect.')

                menu: ContextMenu {
                    MenuItem { text: qsTr("Standard") }
                    MenuItem { text: qsTr("All Feeds") }
                    MenuItem { text: qsTr("Read later") }
                    MenuItem { text: qsTr("Labels") }
                }
            }

            ComboBox {
                id: minimumSSLVersionSetting
                label: qsTr("Minimum Ssl Version")
                currentIndex: settings.minSSLVersion
                description: qsTr('Specify a minimum protocol version for your SSL connection. This might be necessary when your server does not allow connections with older (insecure) protocols. However, your server might not support the newest protocol.')

                menu: ContextMenu {
                    MenuItem { text: qsTr("Any") }
                    MenuItem { text: qsTr("SslV2")
                        color: down || highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor }
                    MenuItem { text: qsTr("SslV3")
                        color: down || highlighted ? Theme.secondaryColor : Theme.secondaryHighlightColor }
                    MenuItem { text: qsTr("TlsV1.0") }
                    MenuItem { text: qsTr("TlsV1.1") }
                    MenuItem { text: qsTr("TlsV1.2") }
                }
            }

            // -- Item List --
            SectionHeader {
                text: qsTr("Item List")
            }

            ComboBox {
                id: orderSetting
                label: qsTr("Order")
                currentIndex: settings.feeditemsOrder

                menu: ContextMenu {
                    MenuItem { text: qsTr("Newest First") }
                    MenuItem { text: qsTr("Oldest First") }
                }
            }

            Slider {
                id: lengthOfTitleSetting
                width: parent.width
                label: qsTr("Max. Length of Title (in Lines)")
                minimumValue: 0
                maximumValue: 5
                stepSize: 1
                value: settings.lengthOfTitle
                valueText: value == 0 ? qsTr("No Limit") : value
            }

            TextSwitch {
                id: showExcerptSetting
                text: qsTr("Show Excerpt")
                checked: settings.showExcerpt
            }

            Slider {
                id: lengthOfExcerptSetting
                width: parent.width
                label: qsTr("Max. Length of Excerpt (in Lines)")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: settings.lengthOfExcerpt
                valueText: value == 0 ? qsTr("No Limit") : value
                enabled: showExcerptSetting.checked
            }

            // -- Items --
            SectionHeader {
                text: qsTr("Items")
            }

            TextSwitch {
                id: autoMarkReadSetting
                text: qsTr("Automatically Mark as Read")
                checked: settings.autoMarkRead
            }

            TextSwitch {
                id: displayImagesSetting
                width: parent.width
                text: qsTr("Show images in articles")
                description: qsTr("Includes image attachments supplied by feeds")
                checked: settings.displayImages
            }

            // -- Browser --
            SectionHeader {
                text: qsTr("Browser")
            }

            TextSwitch {
                id: clearBrowserDataSetting
                width: parent.width
                text: qsTr("Clear browser data on next start")
                description: qsTr("One-shot action. Cookies, site storage and cached web content will be deleted on the next FelisTTRSS start, then this option resets automatically.")
                checked: false
            }

        }
        VerticalScrollDecorator {}
    }

    onAccepted: {
        // Startup
        settings.useAutologin = autoLoginSetting.checked
        //settings.useAllFeedsOnStartup = useAllFeedsOnStartupSetting.checked
        settings.startpage = startPage.currentIndex
        settings.minSSLVersion = minimumSSLVersionSetting.currentIndex

        // Item List
        settings.feeditemsOrder = orderSetting.currentIndex
        settings.lengthOfTitle = lengthOfTitleSetting.value
        settings.showExcerpt = showExcerptSetting.checked
        settings.lengthOfExcerpt = lengthOfExcerptSetting.value
        // Items
        settings.autoMarkRead = autoMarkReadSetting.checked
        settings.displayImages = displayImagesSetting.checked
        // Browser - this is a one-shot request, not a persistent preference.
        if (clearBrowserDataSetting.checked)
            settings.requestBrowserDataClear()
    }
}
