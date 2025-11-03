/*
    SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
    SPDX-FileCopyrightText: 2024 Aknari

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.calendar 2.0 as PlasmaCalendar
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCMUtils
import QtQuick.Controls 2.15 as QQC2

KCMUtils.SimpleKCM {
    id: calendarPage

    // Estas son las propiedades que ESTA PÁGINA necesita
    property alias cfg_showWeekNumbers: showWeekNumbers.checked
    property int cfg_firstDayOfWeek

    // Esta función guarda los plugins. La llamaremos directamente.
    function saveCalendarPlugins() {
        plasmoid.configuration.enabledCalendarPlugins = eventPluginsManager.enabledPlugins;
    }

    Kirigami.FormLayout {
        PlasmaCalendar.EventPluginsManager {
            id: eventPluginsManager
            Component.onCompleted: {
                populateEnabledPluginsList(plasmoid.configuration.enabledCalendarPlugins);
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
            model: {
                var days = [-1, 0, 1, 5, 6];
                var result = [];
                for (var i = 0; i < days.length; i++) {
                    var day = days[i];
                    result.push({
                        day: day,
                        text: day === -1 ? i18nc("@item:inlistbox first day of week option", "Use region defaults") : Qt.locale().dayName(day)
                    });
                }
                return result;
            }
            onActivated: { cfg_firstDayOfWeek = model[index].day; }
            Component.onCompleted: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].day === cfg_firstDayOfWeek) {
                        currentIndex = i;
                        break;
                    }
                }
            }
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
                    property var itemModel: model
                    text: itemModel.display
                    checked: itemModel.checked
                    onClicked: {
                        itemModel.checked = checked;
                        // Guardamos la configuración al hacer clic
                        calendarPage.saveCalendarPlugins();
                    }
                }
            }
        }
    }
}
