/*
 * FelisTTRSS UI addition.
 * Based on TTRss, Copyright (C) 2012-2016 Hauke Schade.
 * Licensed under GPLv2 or later.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

ComboBox {
    id: root
    width: parent ? parent.width : Screen.width

    signal updateView

    label: qsTr("View")
    currentIndex: settings.showAll ? 1 : 0

    menu: ContextMenu {
        MenuItem { text: qsTr("Unread articles") }
        MenuItem { text: qsTr("All articles") }
    }

    onCurrentIndexChanged: {
        if (currentIndex < 0)
            return

        var newValue = currentIndex === 1
        if (settings.showAll === newValue)
            return

        rootWindow.getTTRSS().setShowAll(newValue)
        settings.showAll = newValue
    }

    Connections {
        target: settings
        onShowAllChanged: root.updateView()
    }
}
