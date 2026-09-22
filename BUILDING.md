# Building FelisTTRSS

FelisTTRSS is built with the Sailfish SDK / `sfdk`.

From the project directory:

```sh
sfdk config --push no-fix-version
rm -f .sfdk/spec
sfdk build
```

For version 0.1.13 the expected RPM name is:

```text
harbour-felisttrss-0.1.13-1.<arch>.rpm
```

The application requires the Sailfish WebView components. Package dependencies
are declared in `rpm/harbour-felisttrss.yaml` and the generated spec file.
