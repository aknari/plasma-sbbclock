/*
    SPDX-FileCopyrightText: 2024 Aknari
    SPDX-License-Identifier: BSD-2-Clause
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-system-time"
        source: "configGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Calendar")
        icon: "office-calendar"
        source: "configCalendar.qml"
    }
}