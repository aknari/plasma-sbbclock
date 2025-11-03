/*
    SPDX-FileCopyrightText: 2013 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.1

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.ScrollViewKCM {
    id: timeZonesPage

    // The content of this page is commented out because it uses a private
    // Plasma API (org.kde.plasma.private.digitalclock) that is not available
    // in Plasma 5.
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        text: i18n("Time Zone configuration is currently disabled for maintenance.")
    }
}
