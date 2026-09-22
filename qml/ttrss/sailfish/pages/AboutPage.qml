/*
 * This file is part of FelisTTRSS, based on TTRss.
 * Original TTRss copyright (C) 2012–2020 Hauke Schade
 * FelisTTRSS modifications (C) 2026 Michal Kasík / Feliscatus
 *
 * FelisTTRSS is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FelisTTRSS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../resources/gplv2.js" as License
import "../../resources/privacypolicy.js" as PrivacyPolicy
import "../items"

Page {
    id: aboutPage

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: aboutColumn.height + Theme.paddingLarge
        contentWidth: parent.width

        PullDownMenu {
            MenuItem {
                text: qsTr("License")
                onClicked: {
                    var params = {
                        mytitle: qsTr("License"),
                        mydata: [
                            ["", License.brief],
                            [qsTr("Full License"), License.full]
                        ]
                    }
                    pageStack.push(Qt.resolvedUrl("TextPage.qml"), params)
                }
            }
            MenuItem {
                text: qsTr("Privacy Policy")
                onClicked: {
                    var params = {
                        mytitle: qsTr("Privacy Policy"),
                        mydata: [ ["", PrivacyPolicy.sec1], ["", PrivacyPolicy.sec2] ]
                    }
                    pageStack.push(Qt.resolvedUrl("TextPage.qml"), params)
                }
            }
        }

        Column {
            id: aboutColumn
            width: parent.width

            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingMedium
            }
            spacing: Theme.paddingMedium

            PageHeader {
                title: "FelisTTRSS " + rootWindow.appVersion
            }

            Image {
                source: Qt.resolvedUrl("/usr/share/icons/hicolor/86x86/"
                                       + "apps/harbour-felisttrss.png")
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeMedium
                text: qsTr("Tiny Tiny RSS client for Sailfish OS")
            }

            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("FelisTTRSS is based on the original TTRss application by Hauke Schade.")
            }

            SectionHeader {
                text: qsTr("Current maintenance")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: "Michal Kasík / Feliscatus (2026)"
            }


            SectionHeader {
                text: qsTr("FelisTTRSS project")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("FelisTTRSS source code and issue tracker are available at %1.").arg(
                          "<a href=\"https://github.com/MiPal666/FelisTTRSS\">"
                          + "github.com/MiPal666/FelisTTRSS</a>")
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Button {
                width: parent.width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("GitHub repository")
                onClicked: Qt.openUrlExternally("https://github.com/MiPal666/FelisTTRSS")
            }

            SectionHeader {
                text: qsTr("Original application")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: "Copyright © 2012–2020 Hauke Schade"
            }
            Button {
                width: parent.width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Original project")
                onClicked: Qt.openUrlExternally(constant.sourceRepoSite)
            }

            SectionHeader {
                text: qsTr("Original contributors")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: "Francois Cattin, Jakub Kožíšek, Alberto Mardegan, "
                      + "gwmgdemj, equeim, Silviu Vulcan, Michael Käufl, "
                      + "Patrik Nilsson, Alexey, clovis86, Heimen Stoffels, "
                      + "mp107, ajya, dashinfantry, Alexus230, rinigus, "
                      + "Priit Jõerüüt"
            }

            SectionHeader {
                text: qsTr("Legal Notice")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("FelisTTRSS is free software distributed under the GNU GPL version 2 or later and comes with absolutely no warranty. See the License for details.")
            }
            Label {
                width: parent.width
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("The original project source code is available at %1.").arg(
                          "<a href=\"" + constant.sourceRepoSite + "\">"
                          + constant.sourceRepoSite + "</a>")
                onLinkActivated: Qt.openUrlExternally(link)
            }

        }
        VerticalScrollDecorator { }
    }
}
