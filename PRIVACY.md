# FelisTTRSS privacy

FelisTTRSS does not include analytics, advertising SDKs or telemetry.

The application stores the Tiny Tiny RSS server address and login credentials
in its local application configuration. FelisTTRSS itself does not encrypt
that configuration. The stored credentials are used to connect to the Tiny
Tiny RSS server selected by the user.

Article and feed content can cause network requests to the configured Tiny Tiny
RSS server and to websites referenced by feeds, for example when feed icons,
article images or a web article are loaded.

The embedded browser stores cookies, site data and cache in the application's
own WebView profile. Settings contains a one-shot option to clear cookies,
site data and browser cache.

FelisTTRSS does not send article URLs through a FelisTTRSS-operated or
third-party image proxy.

Questions and bug reports can be submitted at:
https://github.com/MiPal666/FelisTTRSS/issues
