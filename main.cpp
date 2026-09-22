/*
 * This file is part of TTRss, a Tiny Tiny RSS Reader App
 * for MeeGo Harmattan and Sailfish OS.
 * Copyright (C) 2012–2016 Hauke Schade
 *
 * FelisTTRSS Sailfish-only maintenance and modifications
 * Copyright (C) 2026 Michal Kasík / Feliscatus
 *
 * FelisTTRSS is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <QtCore/QLocale>
#include <QtCore/QScopedPointer>
#include <QtCore/QTranslator>
#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <sailfishapp.h>

#include "settings.hh"
#include "qmlutils.hh"
#include "mynetworkmanager.hh"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    app->setApplicationVersion(APP_VERSION);
    app->setApplicationName(QStringLiteral("felisttrss"));
    app->setOrganizationName(QStringLiteral("cz.feliscatus"));
    app->setOrganizationDomain(QStringLiteral("feliscatus.cz"));

    const QString locale = QLocale::system().name();
    QTranslator translator;
    if (translator.load("qml-translation." + locale, ":/i18n"))
        app->installTranslator(&translator);

    QQuickView *viewer = SailfishApp::createView();
    viewer->engine()->setNetworkAccessManagerFactory(MyNetworkManager::instance());
    viewer->rootContext()->setContextProperty("network", MyNetworkManager::instance());
    viewer->rootContext()->setContextProperty("APP_VERSION", APP_VERSION);
    viewer->rootContext()->setContextProperty("QMLUtils", QMLUtils::instance());
    viewer->rootContext()->setContextProperty("settings", Settings::instance());

    viewer->setSource(SailfishApp::pathTo("qml/sailfish/harbour-felisttrss.qml"));
    viewer->show();

    return app->exec();
}
