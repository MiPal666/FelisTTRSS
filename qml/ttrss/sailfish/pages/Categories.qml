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

Page {
    id: categoriesPage
    property bool needsUpdate: false
    property bool hasBeenShown: false

    SilicaListView {
        id: listView
        anchors.fill: parent

        model: categoryModel

        PullDownMenu {
            MenuLabel {
                text: "FelisTTRSS " + rootWindow.appVersion
            }
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            SettingsItem {}
            MenuItem {
                text: qsTr("Logout")
                visible: pageStack.depth === 1
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("MainPage.qml"),
                                      { doAutoLogin: false })
                }
            }
            MenuItem {
                text: qsTr("Update")
                enabled: !network.loading
                onClicked: {
                    categoryModel.update()
                }
            }
        }

        delegate: CategoryDelegate {
            onClicked: {
                categoryModel.selectedIndex = index
                showCategory(categoryModel.getSelectedItem())
            }
        }

        header: Column {
            width: listView.width

            PageHeader {
                title: qsTr("FelisTTRSS")
            }

            ShowAllSwitch {
                onUpdateView: {
                    if (categoriesPage.visible) {
                        categoryModel.load(false)
                    } else {
                        categoriesPage.needsUpdate = true
                    }
                }
            }
        }
        ViewPlaceholder {
            enabled: listView.count == 0
            text: network.loading ?
                      qsTr("Loading") :
                      (settings.showAll ?
                           qsTr("No categories to display") :
                           qsTr("No categories have unread items"))
        }
        BusyIndicator {
            visible: listView.count != 0 && network.loading
            running: visible
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }
        VerticalScrollDecorator { }
    }

    function showCategory(category) {
        if (category === null) {
            return
        }

        if (category.directFeed) {
            var ttrss = rootWindow.getTTRSS()
            var params = {
                feed: {
                    feedId: category.feedId,
                    categoryId: ttrss.constants['categories']['SPECIAL'],
                    title: category.name,
                    unreadcount: category.unreadcount,
                    isCat: false,
                    icon: ttrss.getIconUrl(category.feedId),
                    lastUpdated: ''
                }
            }
            pageStack.push(Qt.resolvedUrl("FeedItems.qml"), params)
        } else {
            pageStack.push(Qt.resolvedUrl("Feeds.qml"),
                           { category: category })
        }
    }

    onVisibleChanged: {
        if (visible) {
            cover = Qt.resolvedUrl("../cover/CategoriesCover.qml")
            categoriesPage.needsUpdate = false

            // configDone() already performs the initial update.  Refresh on
            // every later return to the main page so All Feeds and Read later
            // always reflect the server state without requiring manual Update.
            if (categoriesPage.hasBeenShown)
                categoryModel.update()
            else
                categoriesPage.hasBeenShown = true
        }
    }
}
