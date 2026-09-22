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

import QtQuick 2.0 // sailfish

ListModel {
    id: root

    property int selectedIndex: -1
    property variant feed
    property int continuation: 0
    property bool hasMoreItems: false
    property bool requestServerUpdate: false
    property int selectedItems: 0

    property var categories

    // keep track of status of selected Items, will be calculated upon select
    property bool allUnread: false
    property bool allPublished: false
    property bool allStarred: false

    signal itemUnreadChanged(variant item)
    signal itemPublishedChanged(variant item)
    signal itemStarChanged(variant item)

    onFeedChanged: requestServerUpdate = false

    function isReadLaterFeed() {
        if (!root.feed)
            return false
        var ttrss = rootWindow.getTTRSS()
        return parseInt(root.feed.feedId) === parseInt(ttrss.constants['feeds']['starred'])
    }

    function isUnreadOnlyView() {
        return !settings.showAll || root.isReadLaterFeed()
    }

    function update() {
        if (requestServerUpdate) {
            var ttrss = rootWindow.getTTRSS();
            ttrss.trace(2, "requesting the server to update the feed " + feed.feedId);
            ttrss.updateFeed(feed.feedId,
                             function(successful, errorMessage) {
                                 if (successful) {
                                     requestServerUpdate = false;
                                 }
                                 doUpdate();
                             });
        } else {
            doUpdate();
        }
    }

    /** @private */
    function doUpdate() {
        var ttrss = rootWindow.getTTRSS();
        ttrss.updateFeedItems(feed.feedId, feed.isCat, continuation,
                              function(successful, errorMessage) {
                                  if (successful) {
                                      root.load()
                                  }

                                  // TODO Add a callback to update() which can
                                  // be used to display errorMessage.
                              }, root.isReadLaterFeed());
    }

    /** @private */
    function load() {
        var ttrss = rootWindow.getTTRSS()
        var feeditems = ttrss.getFeedItems(feed.feedId)

        var showAll = ttrss.getShowAll()
        settings.showAll = showAll

        //root.clear(); clearing is done by caller instead, so this is more like an 'append' and can be used by loadMore aswell

        if (feeditems && feeditems.length) {
            root.continuation += feeditems.length

            for(var feeditem = 0; feeditem < feeditems.length; feeditem++) {
                var modelEntry = buildEntry(feeditems[feeditem])

                if (settings.feeditemsOrder === 0) {
                    root.append(modelEntry)
                } else {
                    root.insert(0, modelEntry)
                }
            }

            // QUICKFIX FIXME the ttrss api will always query exactly 200 elements
            // so if we get a different amount there are none left
            // This holds for API level 6 or later; before the limit was 60
            if (feeditems.length === 200) {
                hasMoreItems = true
            }
        } else {
            hasMoreItems = false
        }

        if (!hasMoreItems) {
            requestServerUpdate = true
        }
    }

    function getSelectedItem() {
        if (root.selectedIndex === -1) {
            return null;
        }

        return root.get(root.selectedIndex)
    }

    /** @private */
    function buildEntry(feedItem) {
        var subtitle = feedItem.content || ""
        subtitle = subtitle.replace(/\n/gi, " ")
        subtitle = subtitle.replace(/<[\/]?[a-zA-Z][^>]*>/gi, "")
        subtitle = unescape(subtitle.replace(/<!--.*-->/gi, ""))
        subtitle = "<body>" + subtitle + "</body>"

        var title = feedItem.title
        title = title.replace(/<br.*>/gi, "")
        title = "<body>" + unescape(title.replace(/\n/gi, "")) + "</body>"


        var images = []

        // strip images and replace with "fancy links", store the images in an extra array
        function imgReplacer(match, offset, string) {
            var srcRegex = /src=\"([^"]*)\"/i;
            var altRegex = /alt=\"([^"]*)\"/i;
            var titleRegex = /title=\"([^"]*)\"/i;

            var src = srcRegex.exec(match);
            var alt = altRegex.exec(match);
            var title = titleRegex.exec(match);
            if (alt === null) {
                alt = title;
            }

            // tt-rss content often contains query strings encoded as
            // &amp;. Store a real URL for the image viewer instead of the
            // literal HTML entity.
            var url = rootWindow.getTTRSS().html_entity_decode(src[1], 'ENT_QUOTES');
            var t;
            if (alt !== null && alt[1] !== "") {
                t = alt[1];
            }
            else if (title !== null && title[1] !== "") {
                t = title[1];
            }
            else {
                t = url.substring(url.lastIndexOf('/')+1);
            }

            // Drop explicit 0/1 px images automatically. These are normally
            // tracking pixels and are not useful article content.
            var width_height_regex = /<img\s[^>]*((height|width)="[01]"[^>]*)+>/gi;
            if (width_height_regex.test(match)) {
                return ""
            }

            images.push({'title': t, 'url': url});

            return "<a href=\"|||" + url + "|||" + t + "|||\">" + match + "</a> "
        }

        var image_regex = /<img\s*[^>]*src=\"([^"]+)\"[^>]*>/gi;
        var content = feedItem.content || ""
        content = content.replace(image_regex, imgReplacer)

        var d = new Date(feedItem.updated * 1000)
        var formatedDate = Qt.formatDate(d, Qt.DefaultLocaleShortDate)
        var now = new Date()
        if (d.getDate() === now.getDate()
                && d.getMonth() === now.getMonth()
                && d.getFullYear() === now.getFullYear()) {
            formatedDate = qsTr('Today')
        }

        var url = feedItem.link
        url = url.replace(/^\s\s*/, '').replace(/\s\s*$/, '')

        var labels = []
        var labelcount = feedItem.labels ? feedItem.labels.length : 0
        for (var l = 0; l < labelcount; l++) {
            labels[l] = {
                'id': parseInt(feedItem.labels[l][0]),
                'caption': feedItem.labels[l][1],
                'fg_color': (feedItem.labels[l][2] === "" ? "black" : feedItem.labels[l][2]),
                'bg_color': (feedItem.labels[l][3] === "" ? "white" : feedItem.labels[l][3])
            }
        }

        var ttrss = rootWindow.getTTRSS()
        var modelEntry = {
            title:      ttrss.html_entity_decode(title, 'ENT_QUOTES'),
            content:    content,
            subtitle:   ttrss.html_entity_decode(subtitle, 'ENT_QUOTES'),
            id:         parseInt(feedItem.id),
            unread:     !!feedItem.unread,
            marked:     !!feedItem.marked,
            rss:        feedItem.published,
            url:        url,
            date:       formatedDate,
            images:     images,
            attachments:feedItem.attachments,
            note:       feedItem.note,
            feedId:     parseInt(feedItem.feed_id),
            feedTitle:  ttrss.html_entity_decode(feedItem.feed_title, 'ENT_QUOTES'),
            labels:     labels,
            icon:       ttrss.getIconUrl(feedItem.feed_id),
            selected:   false
        }
        return modelEntry;
    }

    /** @private */
    function getSelectedItems() {
        var ids = ""
        for (var i = 0; i < root.count; i++) {
            var item = root.get(i)
            // Only include items that are selected.
            if (item.selected) {
                ids += item.id + ","
            }
        }

        if (ids === "") {
            // None selected
            return ids
        }

        // trim of last ,
        ids = ids.slice(0,-1)

        return ids
    }

    /**
     * Select or unselect an item at a given index, The action will always toggle
     * @param {int} The item to select/unselect
     */
    function select(index) {
        var item = root.get(index);
        // Only include items that are unread.
        if (!item.selected) {
            item.selected = true;
            selectedItems++;
        }
        else {
            item.selected = false;
            selectedItems--;
        }

        // update the flags
        var tmpAllUnread = true;
        var tmpAllStarred = true;
        var tmpAllPublished = true;
        var performanceCounter = selectedItems;
        for (var i = 0; i < root.count; i++) {
            var itemI = root.get(i);
            if (itemI.selected) {
                tmpAllUnread = tmpAllUnread && itemI.unread;
                tmpAllStarred = tmpAllStarred && itemI.marked;
                tmpAllPublished = tmpAllPublished && itemI.rss;

                if (!(tmpAllUnread || tmpAllStarred || tmpAllPublished)) {
                    break;
                }
                if (performanceCounter == 0) {
                    break;
                }
                performanceCounter--;
            }
        }
        root.allUnread = tmpAllUnread
        root.allStarred = tmpAllStarred
        root.allPublished = tmpAllPublished
    }

    /**
     * Unselect all items
     */
    function unselectAll() {
        for (var i = 0; i < root.count; i++) {
            var item = root.get(i);
            // Only include items that are unread.
            if (item.selected) {
                item.selected = false;
            }
        }
        selectedItems = 0;
    }

    /**
     * Mark all selected items as (unr)read
     * @param {bool} Whether mark as read (true) or unread (false)
     */
    function setAllSelectedReadState(readState, callback) {
        var ttrss = rootWindow.getTTRSS()
        var ids = getSelectedItems()
        if (ids === "") {
            // None selected
            if (callback)
                callback(false)
            return
        }

        ttrss.updateFeedUnread(ids, !readState, function(successful, errorMessage) {
            if (successful) {
                var removeIndices = []

                for (var i = 0; i < root.count; i++) {
                    var item = root.get(i)
                    if (item.selected && item.unread === readState) {
                        root.setProperty(i, "unread", !readState)
                        if (root.isUnreadOnlyView()) {
                            // Keep the API continuation offset in sync with
                            // the unread-only result set.
                            root.continuation += !readState ? +1 : -1
                        }
                        root.itemUnreadChanged(item)

                        // In the unread-only view an item no longer belongs
                        // in the list as soon as it is marked read.
                        if (readState && root.isUnreadOnlyView())
                            removeIndices.push(i)
                    }
                }

                if (removeIndices.length > 0) {
                    // Remove backwards so ListModel indices stay valid.
                    for (var r = removeIndices.length - 1; r >= 0; r--)
                        root.remove(removeIndices[r])

                    root.selectedIndex = -1
                    root.selectedItems = 0
                    root.allUnread = false
                    root.allStarred = false
                    root.allPublished = false
                } else {
                    root.allUnread = !readState
                }
            }

            if (callback)
                callback(successful, errorMessage)
        })
    }

    /**
     * Mark all selected items as (un)starred
     * @param {bool} Whether mark as starred (true) or unstarred (false)
     */
    function setAllSelectedMarkedState(markedState) {
        var ttrss = rootWindow.getTTRSS()
        var ids = getSelectedItems()
        if (ids === "") {
            // None selected
            return
        }

        ttrss.updateFeedStar(ids, markedState, function(successful, errorMessage) {
            if (successful) {
                for (var i = 0; i < root.count; i++) {
                    var item = root.get(i)
                    if (item.selected && item.marked === !markedState) {
                        root.setProperty(i, "marked", markedState)
                        root.itemStarChanged(item)
                    }
                }
                allStarred = markedState

                // In FelisTTRSS a star means "Read later". Keep newly
                // starred articles unread so they remain in the normal view.
                if (markedState) {
                    setAllSelectedReadState(false)
                    return
                }

                // Inside Read later, removing the star means "done with this
                // queued article".  Mark the same selected articles read as
                // part of the operation so they do not reappear in ordinary
                // unread feeds after disappearing from the queue.
                if (root.isReadLaterFeed()) {
                    ttrss.updateFeedUnread(ids, false, function(readSuccessful,
                                                               readError) {
                        var removed = 0
                        if (readSuccessful) {
                            for (var i = root.count - 1; i >= 0; --i) {
                                var selectedItem = root.get(i)
                                if (!selectedItem.selected)
                                    continue

                                if (selectedItem.unread) {
                                    root.setProperty(i, "unread", false)
                                    selectedItem = root.get(i)
                                    root.itemUnreadChanged(selectedItem)
                                }
                                root.remove(i)
                                removed += 1
                            }
                            root.continuation = Math.max(0, root.continuation - removed)
                            root.selectedIndex = -1
                            root.selectedItems = 0
                            root.allUnread = false
                            root.allStarred = false
                            root.allPublished = false
                        } else {
                            // Star removal already succeeded, therefore these
                            // rows no longer belong in Read later even if the
                            // follow-up read request failed.
                            root.cleanupCurrentView()
                        }
                    })
                }
            }
        })
    }

    /**
     * Mark all selected items as (un)starred
     * @param {bool} Whether mark as starred (true) or unstarred (false)
     */
    function setAllSelectedRSSState(rssState) {
        var ttrss = rootWindow.getTTRSS()
        var ids = getSelectedItems()
        if (ids === "") {
            // None selected
            return
        }

        ttrss.updateFeedRSS(ids, rssState, function(successful, errorMessage) {
            if (successful) {
                for (var i = 0; i < root.count; i++) {
                    var item = root.get(i)
                    if (item.selected && item.rss === !rssState) {
                        root.setProperty(i, "rss", rssState)
                        root.itemPublishedChanged(item)
                    }
                }
                allPublished = rssState
            }
        })
    }

    /**
     * Mark all items above an index as read, i.e. item with an index less than
     * the given index.
     * @param {int} The index above which items should be marked read.
     */
    function markAllAboveAsRead(index) {
        var ttrss = rootWindow.getTTRSS()
        var limit = Math.min(index, root.count)

        var ids = ""
        for (var i = 0; i < limit; i++) {
            var item = root.get(i)
            // FelisTTRSS uses the star as "Read later". Bulk cleanup must
            // not consume those items, so only unstarred unread items are
            // included in the catch-up operation.
            if (item.unread && !item.marked) {
                ids += item.id + ","
            }
        }

        if (ids === "") {
            // All regarding items are already marked as read.
            return
        }

        // trim of last ,
        ids = ids.slice(0,-1)

        ttrss.updateFeedUnread(ids, false, function(successful, errorMessage) {
            if (successful) {
                var removeIndices = []

                for (var i = 0; i < limit; i++) {
                    var item = root.get(i)
                    if (item.unread && !item.marked) {
                        root.setProperty(i, "unread", false)
                        if (root.isUnreadOnlyView()) {
                            // Keep pagination aligned with the server's
                            // unread-only result set.
                            root.continuation -= 1
                            removeIndices.push(i)
                        }
                        root.itemUnreadChanged(item)
                    }
                }

                // When the current view is "Unread articles", read entries
                // should disappear immediately instead of merely fading.
                for (var r = removeIndices.length - 1; r >= 0; r--)
                    root.remove(removeIndices[r])

                if (removeIndices.length > 0) {
                    root.selectedIndex = -1
                    root.unselectAll()
                    root.allUnread = false
                    root.allStarred = false
                    root.allPublished = false
                }
            }

            // TODO Add a callback to markAllAboveAsRead() which can be used to
            // display errorMessage.
        })
    }

    /**
     * Mark all loaded items as read.
     */
    function markAllLoadedAsRead() {
        markAllAboveAsRead(root.count)
    }

    /**
     * Toggle unread/read of currently selected item.
     * @param {function} A callback function with parameters boolean (indicating
     *     success), string (an optional error message) and boolean (true if
     *     unread; false if read).
     */
    function toggleRead(callback, preserveStarredUnread) {
        var ttrss = rootWindow.getTTRSS()
        var index = root.selectedIndex
        var item = getSelectedItem()
        if (item === null) {
            if (callback)
                callback(false, "No selected item", false)
            return
        }

        var newState = !item.unread

        // Automatic mark-as-read must never consume a Read later item.
        // If the star already exists, keep the article unread and do not
        // even send a read request to the server.
        if (preserveStarredUnread && !newState && item.marked) {
            if (callback)
                callback(true, null, true)
            return
        }

        ttrss.updateFeedUnread(item.id, newState, function(successful,
                                                           errorMessage) {
            if (!successful) {
                if (callback)
                    callback(false, errorMessage, item.unread)
                return
            }

            var currentItem = root.get(index)

            // The user can tap the star while the automatic mark-as-read
            // request is still in flight.  If that happened, restore unread
            // on the server before changing the local model.
            if (preserveStarredUnread && !newState && currentItem.marked) {
                ttrss.updateFeedUnread(currentItem.id, true,
                    function(restored, restoreError) {
                        if (restored && !currentItem.unread) {
                            if (root.isUnreadOnlyView())
                                root.continuation += 1
                            root.setProperty(index, "unread", true)
                            root.itemUnreadChanged(currentItem)
                        }
                        if (callback)
                            callback(restored, restoreError, true)
                    })
                return
            }

            if (root.isUnreadOnlyView())
                root.continuation += newState ? +1 : -1

            root.setProperty(index, "unread", newState)
            root.itemUnreadChanged(currentItem)

            if (callback)
                callback(true, null, newState)
        })
    }

    /**
     * Toggle starred/unstarred of currently selected item.
     * @param {function} A callback function with parameters boolean (indicating
     *     success), string (an optional error message) and boolean (true if
     *     starred; false if unstarred).
     */
    function toggleStar(callback) {
        var ttrss = rootWindow.getTTRSS()
        var index = root.selectedIndex
        var item = getSelectedItem()
        var newState = !item.marked

        ttrss.updateFeedStar(item.id, newState, function(successful,
                                                         errorMessage) {
            if (!successful) {
                if (callback)
                    callback(false, errorMessage, item.marked)
                return
            }

            root.setProperty(index, "marked", newState)
            item = root.get(index)
            root.itemStarChanged(item)

            if (!newState && root.isReadLaterFeed()) {
                root.continuation = Math.max(0, root.continuation - 1)

                // In the Read later queue, removing the star also completes
                // the article.  Otherwise it would immediately reappear as
                // an ordinary unread article in its source feed.
                var wasUnreadInQueue = item.unread
                ttrss.updateFeedUnread(item.id, false, function(readSuccessful,
                                                                readError) {
                    if (readSuccessful && wasUnreadInQueue) {
                        root.setProperty(index, "unread", false)
                        item = root.get(index)
                        root.itemUnreadChanged(item)
                    }

                    if (callback)
                        callback(readSuccessful, readError, item.marked)
                })
                return
            }

            // In FelisTTRSS a star means Read later.  Make the invariant
            // explicit on the server every time the star is enabled, even if
            // the local item already looks unread.  This also closes a race
            // with the automatic mark-as-read request fired when opening an
            // article.
            if (newState) {
                var wasUnread = item.unread
                ttrss.updateFeedUnread(item.id, true, function(unreadSuccessful,
                                                               unreadError) {
                    if (unreadSuccessful && !wasUnread) {
                        if (root.isUnreadOnlyView())
                            root.continuation += 1

                        root.setProperty(index, "unread", true)
                        item = root.get(index)
                        root.itemUnreadChanged(item)
                    }

                    if (callback)
                        callback(unreadSuccessful, unreadError, item.marked)
                })
                return
            }

            if (callback)
                callback(true, null, item.marked)
        })
    }

    /**
     * Toggle published/unpublished of currently selected item.
     * @param {function} A callback function with parameters boolean (indicating
     *     success), string (an optional error message) and boolean (true if
     *     published; false if unpublished).
     */
    function togglePublished(callback) {
        var ttrss = rootWindow.getTTRSS()
        var index = root.selectedIndex
        var item = getSelectedItem()
        var newState = !item.rss

        ttrss.updateFeedRSS(item.id, newState, function(successful,
                                                        errorMessage) {
            if (successful) {
                root.setProperty(index, "rss", newState)
                root.itemPublishedChanged(item)
            }

            if (callback) {
                callback(successful, errorMessage, item.rss)
            }
        })
    }

    function updateNote(note, callback) {
        var ttrss = rootWindow.getTTRSS()
        var index = root.selectedIndex
        var item = getSelectedItem()

        ttrss.updateFeedNote(item.id, note, function(successful, errorMessage) {
            if (successful) {
                root.setProperty(index, "note", note)
            }

            if (callback) {
                callback(successful, errorMessage)
            }
        })
    }

    function getLabels(callback) {
        var ttrss = rootWindow.getTTRSS()
        var item = getSelectedItem()

        ttrss.getLabels(item.id, function(successful, errorMessage, labels) {
            if (!successful) {
                callback(false, errorMessage)
                return
            }
            if (!labels || labels.length === 0) {
                callback(true, "", [])
                return
            }

            var i
            var j

            // This is in O(nm) where n is the number of labels defined and
            // m the number of labels checked. It's unefficient, but it should
            // be fast enough for us.
            for (i = 0; i < labels.length; ++i) {
                labels[i].checked = false

                for (j = 0; j < item.labels.count; ++j) {
                    if(labels[i].id === item.labels.get(j).id) {
                        labels[i].checked = true
                        break
                    }
                }
            }

            labels.sort(function (left, right) { return left.caption.localeCompare(right.caption); });

            callback(true, "", labels)
        })
    }

    function setLabel(labelId, assign, callback) {
        var ttrss = rootWindow.getTTRSS()
        var item = getSelectedItem()

        ttrss.setLabel(item.id, labelId, assign,
                       function(successful, errorMessage) {
                           callback(successful, errorMessage);
                       })
    }

    function updateLabels(callback) {
        var ttrss = rootWindow.getTTRSS()
        var item = getSelectedItem()

        ttrss.updateLabels(item.id, function(successful, errorMessage, labels) {
            if (!successful) {
                callback(false, errorMessage)
                return
            }

            item.labels.clear()

            for (var i = 0; i < labels.length; ++i) {
                if (!labels[i].checked) {
                    continue
                }

                item.labels.append({
                    'id': parseInt(labels[i].id),
                    'caption': labels[i].caption,
                    'fg_color': (labels[i].fg_color === "" ? "black" : labels[i].fg_color),
                    'bg_color': (labels[i].bg_color === "" ? "white" : labels[i].bg_color)
                })
            }

            callback(true, "", item.labels)
        })
    }

    function catchUp() {
        var ttrss = rootWindow.getTTRSS()
        ttrss.catchUp(feed.feedId, feed.isCat, function(successful, errorMessage) {
            if (successful) {
                for(var index = 0; index < root.count; index++) {
                    var feedItem = root.get(index)
                    if (feedItem.unread) {
                        root.setProperty(index, "unread", false)
                        root.itemUnreadChanged(feedItem)
                    }
                }
            }

            // TODO Add a callback to catchUp() which can be used to display
            // errorMessage.
        })
    }


    // Remove entries which no longer belong in the current filtered view.
    // Read later is always an unread queue, independent of the global All /
    // Unread switch.  It also stops showing an item as soon as its star is
    // removed.
    function cleanupCurrentView() {
        var removed = 0
        var readLater = root.isReadLaterFeed()
        var unreadOnly = root.isUnreadOnlyView()

        for (var i = root.count - 1; i >= 0; --i) {
            var item = root.get(i)
            if ((unreadOnly && !item.unread) || (readLater && !item.marked)) {
                root.remove(i)
                removed += 1
            }
        }

        if (removed > 0) {
            root.selectedIndex = -1
            root.selectedItems = 0
            root.allUnread = false
            root.allStarred = false
            root.allPublished = false
        }
        return removed
    }

    function hasPrevious() {
        return root.selectedIndex > 0
    }

    function selectPrevious() {
        root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        return root.selectedIndex
    }

    function hasNext() {
        return root.selectedIndex < root.count - 1
    }

    function selectNext() {
        root.selectedIndex = Math.min(root.selectedIndex + 1, root.count - 1)
        return root.selectedIndex
    }

    onItemUnreadChanged: {
        var ttrss = rootWindow.getTTRSS();
        var op = item.unread ?
                    function(x) { return x + 1 } :
                    function(x) { return x - 1 }

        // update the feed's category
        feedModel.updateUnreadCountForId(item.feedId, op)

        // update special for all feeditems category
        categories.updateUnreadCountForId(
                    ttrss.constants['categories']['SPECIAL'],
                    op)

        // if the item is new, update 'special feeds' for 'fresh articles'
        // TODO
        if (item.unread && false) {
            categories.updateUnreadCountForId(
                        ttrss.constants['categories']['SPECIAL'],
                        op)
        }

        // if item was is starred/published, update special feeds aswell
        if (item.rss) {
            categories.updateUnreadCountForId(
                        ttrss.constants['categories']['SPECIAL'],
                        op)
        }

        if (item.marked) {
            categories.updateUnreadCountForId(
                        ttrss.constants['categories']['SPECIAL'],
                        op)
            categories.updateReadLaterUnreadCount(op)
        }

        // maybe check if currently viewing special feeds and update published
        // not nesseccary because this is updated by mark unread
    }

    onItemPublishedChanged: {
        var ttrss = rootWindow.getTTRSS();
        var op = item.rss ?
                    function(x) { return x + 1 } :
                    function(x) { return x - 1 }

        // if the item is unread, update 'special feeds'
        if (item.unread) {
            categories.updateUnreadCountForId(
                        ttrss.constants['categories']['SPECIAL'],
                        op)
        }

        // maybe check if currently viewing special feeds and update published
        // not nesseccary because this is updated by mark unread
    }

    onItemStarChanged: {
        var ttrss = rootWindow.getTTRSS();
        var op = item.marked ?
                    function(x) { return x + 1 } :
                    function(x) { return x - 1 }

        // if the item is unread, update 'special feeds'
        if (item.unread) {
            categories.updateUnreadCountForId(
                        ttrss.constants['categories']['SPECIAL'],
                        op)
            categories.updateReadLaterUnreadCount(op)
        }

        // maybe check if currently viewing special feeds and update starred
        // not nesseccary because this is updated by mark unread
    }
}
