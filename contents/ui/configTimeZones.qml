/*
    SPDX-FileCopyrightText: 2013 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.private.digitalclock
import org.kde.kirigami as Kirigami
import org.kde.config as KConfig
import org.kde.kcmutils as KCMUtils

KCMUtils.ScrollViewKCM {
    id: timeZonesPage


    // The content of this page is commented out because it uses a private
    // Plasma API (org.kde.plasma.private.digitalclock) that is likely
    // obsolete or broken in Plasma 6, causing the entire configuration
    // dialog to fail.
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        text: i18n("Time Zone configuration is currently disabled for maintenance.")
    }
}
