# FelisTTRSS

FelisTTRSS is a Sailfish OS client for [Tiny Tiny RSS](https://tt-rss.org/),
written in Qt/QML and using the Tiny Tiny RSS JSON API.

It is a Sailfish-focused derivative of the original **TTRss** application by
Hauke Schade (`cnlpete`). The original project is available at
https://github.com/cnlpete/ttrss.

## Highlights

- categories, feeds and article lists
- unread/all filtering
- **Read later** queue based on starred articles
- mark read/unread and star/unstar actions, including multi-select
- feed icons, labels and notes when provided by Tiny Tiny RSS
- inline article images and image attachments
- built-in article browser with persistent cookies/site data
- browser text zoom: 100 / 125 / 150 / 175 %
- open the current article in the external browser
- one-shot browser data cleanup from Settings
- Sailfish cover support
- Czech translation maintained with FelisTTRSS

## Requirements

- Sailfish OS
- a working Tiny Tiny RSS installation with the JSON API enabled
- `sailfish-components-webview-qt5`

FelisTTRSS 0.1.13 has been tested on Sailfish OS 5.x / aarch64.

## Building

See [BUILDING.md](BUILDING.md).

## Privacy

FelisTTRSS has no analytics or telemetry. Login data is stored locally in the
application configuration and is used only to connect to the Tiny Tiny RSS
server configured by the user. The embedded browser stores its own cookies,
site data and cache until the user clears them.

See [PRIVACY.md](PRIVACY.md) for details.

## Project

Repository and issue tracker:

- https://github.com/MiPal666/FelisTTRSS
- https://github.com/MiPal666/FelisTTRSS/issues

Current FelisTTRSS maintenance and modifications:

- Michal Kasík / Feliscatus (2026)

## Upstream and contributors

FelisTTRSS is based on the original TTRss application by Hauke Schade.
Original author and contributor credits are retained in
[CONTRIBUTORS.md](CONTRIBUTORS.md), the application About page and source
copyright notices.

The public FelisTTRSS tree is Sailfish-only; legacy Harmattan and Ubuntu Touch
packaging/UI files from the upstream repository are intentionally not carried
in this fork.

## Translations

English is the source language. Czech is maintained with FelisTTRSS.
Translations inherited from upstream are retained; newly added strings may
fall back to English until translated.

## License

FelisTTRSS is free software distributed under the GNU General Public License,
version 2 or, at your option, any later version (**GPL-2.0-or-later**).
See [LICENSE.txt](LICENSE.txt).
