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
    id: feeditemsPage
    property var feed
    property bool needsUpdate: false
    property bool selectionModeActive: false

    Component.onCompleted: {
        feedItemModel.feed = feeditemsPage.feed
        feeditemsPage.update()
    }

    RemorsePopup { id: remorse }

    Drawer {
        id: drawer
        anchors.fill: parent
        dock: Dock.Bottom
        backgroundSize: drawerView.contentHeight

        open: selectionModeActive

        background: SilicaFlickable {
            id: drawerView
            anchors.fill: parent
            contentHeight: selectionModeActive
                           ? Theme.itemSizeSmall + Theme.itemSizeMedium + Theme.itemSizeExtraSmall
                           : Theme.itemSizeSmall
            clip: true

            Column {
                visible: selectionModeActive
                width: parent.width
                height: parent.height - Theme.itemSizeSmall

                Separator {
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                    color: Theme.highlightColor
                }

                IconButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon.source: "image://theme/icon-m-close"

                    onClicked: {
                        feedItemModel.unselectAll();
                        selectionModeActive = false;
                    }
                }

                Label {
                    id: selectedLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeLarge
                    text: qsTr("%1 selected").arg(feedItemModel.selectedItems)
                }

                Row {
                    visible: selectionModeActive
                    height: Theme.itemSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter

                    IconButton {
                        enabled: feedItemModel.selectedItems > 0
                        icon.source: "qrc:///images/ic_star.svg"
                        icon.color: feedItemModel.allStarred ? Theme.highlightColor : Theme.secondaryColor
                        icon.width: Theme.iconSizeSmallPlus
                        icon.height: Theme.iconSizeSmallPlus
                        onClicked: {
                            feedItemModel.setAllSelectedMarkedState(!feedItemModel.allStarred)
                        }
                    }

                    IconButton {
                        enabled: feedItemModel.selectedItems > 0
                        icon.source: "qrc:///images/ic_"
                                     + (feedItemModel.allUnread ? "unread" : "read") + ".svg"
                        icon.color: feedItemModel.allUnread ? Theme.highlightColor : Theme.secondaryColor
                        icon.width: Theme.iconSizeSmallPlus
                        icon.height: Theme.iconSizeSmallPlus
                        onClicked: {
                            var markAsRead = feedItemModel.allUnread
                            feedItemModel.setAllSelectedReadState(markAsRead,
                                function(successful) {
                                    if (successful && markAsRead && feedItemModel.isUnreadOnlyView())
                                        selectionModeActive = false
                                })
                        }
                    }
                }
            }
        }


        SilicaListView {
            id: listView
            anchors.fill: parent
            model: feedItemModel

            PullDownMenu {
                id: pullmenu
                MenuItem {
                    text: qsTr("Update")
                    enabled: !network.loading
                    onClicked: feeditemsPage.update()
                }
                MenuItem {
                    text: qsTr('Mark all loaded read')
                    visible: !feedItemModel.isReadLaterFeed()
                    onClicked: markAllLoadedAsRead()
                }
            }


            section {
                property: 'date'

                delegate: SectionHeader {
                    text: section
                    height: Theme.itemSizeExtraSmall
                }
            }

            delegate: FeedItemDelegate {
                onClicked: {
                    if (selectionModeActive) {
                        feedItemModel.select(index)
                    }
                    else {
                        feedItemModel.selectedIndex = index
                        pageStack.push(Qt.resolvedUrl("FeedItem.qml"), { isCat: feed.isCat })
                    }
                }
                onPressAndHold: {
                    if (selectionModeActive) {
                        feedItemModel.selectedIndex = index
                        pageStack.push(Qt.resolvedUrl("FeedItem.qml"), { isCat: feed.isCat })
                    }
                    else {
                        feedItemModel.select(index)
                        selectionModeActive = true;
                    }
                }
            }

            footer: Column {
                width: listView.width

                Button {
                    text: qsTr("Load more")
                    visible: settings.feeditemsOrder === 0 && feedItemModel.hasMoreItems
                    height: visible ? Theme.itemSizeSmall : 0
                    width: parent.width
                    onClicked: feedItemModel.update()
                }

                ListItem {
                    id: moreOptionsItem
                    width: parent.width
                    contentHeight: Theme.itemSizeSmall
                    openMenuOnPressAndHold: false
                    onClicked: openMenu()

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("⋮ More options")
                        color: moreOptionsItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                text: qsTr("Update")
                                enabled: !network.loading
                                onClicked: feeditemsPage.update()
                            }
                            MenuItem {
                                text: qsTr('Mark all loaded read')
                                visible: !feedItemModel.isReadLaterFeed()
                                onClicked: markAllLoadedAsRead()
                            }
                        }
                    }
                }
            }

            header: Column {
                width: listView.width
                height: childrenRect.height
                PageHeader {
                    id: header
                    title: feed.title
                }
                // Two-state article filter.  A plain tap-to-toggle row is
                // used here instead of ComboBox: on some Sailfish devices the
                // ComboBox popup overlaps its own label in this header.
                ListItem {
                    id: articleViewToggle
                    width: parent.width
                    visible: !feedItemModel.isReadLaterFeed()
                    contentHeight: visible ? Theme.itemSizeSmall : 0

                    onClicked: {
                        var newValue = !settings.showAll
                        rootWindow.getTTRSS().setShowAll(newValue)
                        settings.showAll = newValue
                    }

                    Label {
                        id: articleViewLabel
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.32
                        text: qsTranslate("ShowAllSwitch", "View")
                        color: articleViewToggle.highlighted
                               ? Theme.highlightColor : Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        anchors.left: articleViewLabel.right
                        anchors.leftMargin: Theme.paddingMedium
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: (settings.showAll
                               ? qsTranslate("ShowAllSwitch", "All articles")
                               : qsTranslate("ShowAllSwitch", "Unread articles")) + "  ›"
                        color: articleViewToggle.highlighted
                               ? Theme.highlightColor : Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                    }

                    Connections {
                        target: settings
                        onShowAllChanged: {
                            if (feeditemsPage.visible) {
                                feeditemsPage.update()
                            } else {
                                feeditemsPage.needsUpdate = true
                            }
                        }
                    }
                }
                Button {
                    id: info
                    text: qsTr("Load more")
                    visible: settings.feeditemsOrder === 1 && feedItemModel.hasMoreItems
                    height: settings.feeditemsOrder === 1 && feedItemModel.hasMoreItems ? 51 : 0
                    width: parent.width
                    onClicked: feedItemModel.update()
                }
                SectionHeader {
                    id: lastUpdated
                    text: feed.lastUpdated !== "" ? qsTr("Last updated: %1").arg(feed.lastUpdated) : ""
                    visible: text !== ""
                    height: Theme.itemSizeExtraSmall
                }
            }

            ViewPlaceholder {
                enabled: listView.count == 0
                text: network.loading ?
                          qsTr("Loading") :
                          feedItemModel.isUnreadOnlyView() ? qsTr("No unread items in feed") : qsTr("No items in feed")
            }
            BusyIndicator {
                visible: listView.count != 0 && network.loading
                running: visible
                anchors.centerIn: parent
                size: BusyIndicatorSize.Large
            }
            VerticalScrollDecorator { }
        }
    }

    function showFeed(feedModel) {
        if(feedModel !== null) {
            pageStack.push(Qt.resolvedUrl("FeedItems.qml"),
                           { feed: feedModel })
        }
    }

    onVisibleChanged: {
        if (visible) {
            cover = Qt.resolvedUrl("../cover/FeedItemsCover.qml")

            // A detail page may have marked the current item read while this
            // list was hidden.  In unread-only mode remove such rows locally
            // as soon as the list becomes visible again.
            feedItemModel.cleanupCurrentView()

            if (feeditemsPage.needsUpdate) {
                feeditemsPage.needsUpdate = false
                feeditemsPage.update()
            }
        }
    }

    function markAllLoadedAsRead() {
        remorse.execute(qsTr("Marking all loaded as read"),
                        function() {
                            feedItemModel.markAllLoadedAsRead()
                        })
    }

    function update() {
        feedItemModel.continuation = 0
        feedItemModel.hasMoreItems = false
        feedItemModel.clear()
        feedItemModel.selectedItems = 0
        feedItemModel.update()
    }
}
