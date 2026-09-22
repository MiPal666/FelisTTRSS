/*
 * FelisTTRSS internal article browser.
 * Licensed under GPLv2 or later.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

WebViewPage {
    id: browserPage

    property url initialUrl
    property bool initialLoadStarted: false
    readonly property real topSafeInset: orientation === Orientation.Portrait
                                           ? Math.max(0, Screen.topCutout.height)
                                           : 0

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    function startInitialLoad() {
        if (initialLoadStarted || !WebEngine.initialized)
            return

        // Clear browsing data through the WebEngine itself.  Deleting the
        // .mozilla profile breaks Sailfish WebView one-time preferences.
        if (settings.browserClearDataOnNextStart) {
            WebEngine.notifyObservers("clear-private-data", "cookies-and-site-data")
            WebEngine.notifyObservers("clear-private-data", "cache")
            settings.browserClearDataOnNextStart = false
        }

        initialLoadStarted = true
        if (browserPage.initialUrl.toString().length > 0) {
            console.log("FelisTTRSS browser requested URL:", browserPage.initialUrl)
            // One-shot assignment, not a permanent QML binding.  Redirects
            // performed by the website are therefore free to update the URL.
            webView.url = browserPage.initialUrl
        }
    }

    function cycleTextZoom() {
        var steps = [100, 125, 150, 175]
        var current = settings.browserTextZoomPercent
        var index = steps.indexOf(current)
        settings.browserTextZoomPercent = steps[(index + 1) % steps.length]
        textZoomTimer.restart()
    }

    function applyTextZoom() {
        if (!webView.domContentLoaded)
            return

        // Sailfish WebView already loads TextZoom.js internally.  Reuse its
        // public embedui:textZoom message so only text is enlarged; page width
        // remains responsive instead of being magnified off-screen.
        var baseZoom = Math.pow(Theme.fontSizeMedium / Theme.fontSizeMediumBase, 1.25)
        webView.sendAsyncMessage("embedui:textZoom",
                                 { "zoom": baseZoom * settings.browserTextZoomPercent / 100.0 })
    }

    Connections {
        target: WebEngine
        onInitialized: browserPage.startInitialLoad()
    }

    Timer {
        id: textZoomTimer
        interval: 0
        repeat: false
        onTriggered: browserPage.applyTextZoom()
    }

    WebView {
        id: webView
        anchors {
            top: parent.top
            topMargin: browserPage.topSafeInset
            left: parent.left
            right: parent.right
            bottom: browserBar.top
        }
        privateMode: false

        onDomContentLoadedChanged: {
            if (domContentLoaded)
                textZoomTimer.restart()
        }
        onLoadedChanged: {
            if (loaded)
                console.log("FelisTTRSS browser final URL:", url)
        }

        Component.onCompleted: browserPage.startInitialLoad()
    }

    // Fixed controls deliberately avoid PullDownMenu/WebViewFlickable: their
    // vertical drag handling competes with Gecko scrolling on some pages.
    Item {
        id: browserBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Theme.itemSizeMedium

        // Four equal hit areas keep the controls stable on every screen
        // width.  Refresh and external-browser graphics are bundled with the
        // app because the corresponding theme icon names are not present on
        // every Sailfish OS release (the buttons worked in 0.1.10 but were
        // visually blank on Jolla Phone 2026).
        Row {
            anchors.fill: parent

            BackgroundItem {
                width: browserBar.width / 4
                height: browserBar.height
                enabled: webView.canGoBack || pageStack.depth > 1
                onClicked: webView.canGoBack ? webView.goBack() : pageStack.pop()

                Icon {
                    anchors.centerIn: parent
                    source: "image://theme/icon-m-previous"
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

            BackgroundItem {
                width: browserBar.width / 4
                height: browserBar.height
                onClicked: webView.loading ? webView.stop() : webView.reload()

                Icon {
                    anchors.centerIn: parent
                    width: Theme.iconSizeSmall
                    height: width
                    source: webView.loading
                            ? "image://theme/icon-m-close"
                            : "qrc:///images/ic_refresh.svg"
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

            BackgroundItem {
                width: browserBar.width / 4
                height: browserBar.height
                onClicked: browserPage.cycleTextZoom()

                Icon {
                    source: "image://theme/icon-m-font-size"
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: Theme.paddingSmall
                    }
                    width: Theme.iconSizeSmall
                    height: width
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                    }
                    text: settings.browserTextZoomPercent + "%"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

            BackgroundItem {
                width: browserBar.width / 4
                height: browserBar.height
                enabled: webView.url.toString().length > 0
                onClicked: Qt.openUrlExternally(webView.url)

                Icon {
                    anchors.centerIn: parent
                    width: Theme.iconSizeSmall
                    height: width
                    source: "qrc:///images/ic_external.svg"
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }
        }
    }
}
