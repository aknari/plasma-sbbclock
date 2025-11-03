/*
    SPDX-FileCopyrightText: 2024 Aknari
    SPDX-License-Identifier: BSD-2-Clause
*/

import QtQuick 2.15
import org.kde.plasma.configuration 2.0

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
