/*
    SPDX-FileCopyrightText: 2024 Aknari

    SPDX-License-Identifier: BSD-2-Clause
*/

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.configuration
import org.kde.plasma.workspace.calendar as PlasmaCalendar

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
            populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins);
        }
    }

    readonly property Instantiator __eventPlugins: Instantiator {
        model: configModel.eventPluginsManager.model
        delegate: ConfigCategory {
            required property string display
            required property string decoration
            required property string configUi
            required property string pluginId

            name: display
            icon: decoration
            source: configUi
            visible: Plasmoid.configuration.enabledCalendarPlugins.indexOf(pluginId) > -1
        }

        onObjectAdded: (index, object) => configModel.appendCategory(object)
        onObjectRemoved: (index, object) => configModel.removeCategory(object)
    }
}
