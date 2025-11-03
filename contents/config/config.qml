/*
    SPDX-FileCopyrightText: 2024 Aknari

    SPDX-License-Identifier: BSD-2-Clause
*/

import QtQuick 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.configuration 2.0
import org.kde.plasma.calendar 2.0 as PlasmaCalendar

ConfigModel {
    id: configModel

    ConfigCategory {
        name: i18n("General")
        icon: "preferences-system-time"
        source: "../ui/configGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Calendar")
        icon: "office-calendar"
        source: "../ui/configCalendar.qml"
    }

    readonly property PlasmaCalendar.EventPluginsManager eventPluginsManager: PlasmaCalendar.EventPluginsManager {
        Component.onCompleted: {
            populateEnabledPluginsList(plasmoid.configuration.enabledCalendarPlugins);
        }
    }

    readonly property Instantiator __eventPlugins: Instantiator {
        model: configModel.eventPluginsManager.model
        delegate: ConfigCategory {
            property string pluginDisplay: model.display
            property string pluginDecoration: model.decoration
            property string pluginConfigUi: model.configUi
            property string pluginId: model.pluginId

            name: pluginDisplay
            icon: pluginDecoration
            source: pluginConfigUi
            visible: plasmoid.configuration.enabledCalendarPlugins.indexOf(pluginId) > -1
        }

        onObjectAdded: configModel.appendCategory(object)
        onObjectRemoved: configModel.removeCategory(object)
    }
}
