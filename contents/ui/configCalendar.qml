/*
    SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
    SPDX-FileCopyrightText: 2024 Aknari

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import QtQuick.Controls as QQC2

KCMUtils.SimpleKCM {
    id: calendarPage

    // Estas son las propiedades que ESTA PÁGINA necesita
    property alias cfg_showWeekNumbers: showWeekNumbers.checked
    property int cfg_firstDayOfWeek

    // Esta propiedad es para el botón de aplicar, no la necesitamos ahora
    // property bool unsavedChanges: false

    // Esta función guarda los plugins. La llamaremos directamente.
    function saveCalendarPlugins() {
        Plasmoid.configuration.enabledCalendarPlugins = eventPluginsManager.enabledPlugins;
    }

    Kirigami.FormLayout {
        PlasmaCalendar.EventPluginsManager {
            id: eventPluginsManager
            Component.onCompleted: {
                populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins);
            }
        }

        QQC2.CheckBox {
            id: showWeekNumbers
            Kirigami.FormData.label: i18n("General:")
            text: i18n("Show week numbers")
        }

        QQC2.ComboBox {
            id: firstDayOfWeekCombo
            Kirigami.FormData.label: i18nc("@label:listbox", "First day of week:")
            Layout.fillWidth: true
            textRole: "text"
            model: [-1, 0, 1, 5, 6].map(day => ({ day, text: day === -1 ? i18nc("@item:inlistbox first day of week option", "Use region defaults") : Qt.locale().dayName(day) }))
            onActivated: (index) => { cfg_firstDayOfWeek = model[index].day; }
            currentIndex: model.findIndex(item => item.day === cfg_firstDayOfWeek)
        }

        Item {
            Kirigami.FormData.isSection: true
        }
        
        ColumnLayout {
            id: calendarPluginsLayout
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: i18n("Available Plugins:")

            Repeater {
                id: calendarPluginsRepeater
                model: eventPluginsManager.model
                delegate: QQC2.CheckBox {
                    required property var model
                    text: model.display
                    checked: model.checked
                    onClicked: {
                        model.checked = checked;
                        // Guardamos la configuración al hacer clic
                        calendarPage.saveCalendarPlugins();
                    }
                }
            }
        }
    }
}
