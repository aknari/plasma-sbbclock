/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
    SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.calendar 2.0 as PlasmaCalendar
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami

// Top-level layout containing:
// - Leading column with world clock and agenda view
// - Trailing column with current date header and calendar
//
// Trailing column fills exactly half of the popup width, then there's 1
// logical pixel wide separator, and the rest is left for the Leading.
Item {
    id: calendar

    signal monthViewChanged(var monthView)

    readonly property var appletInterface: root

    Layout.minimumWidth: (calendar.showAgenda || calendar.showClocks) ? Kirigami.Units.gridUnit * 45 : Kirigami.Units.gridUnit * 22
    Layout.maximumWidth: Kirigami.Units.gridUnit * 80

    Layout.minimumHeight: Kirigami.Units.gridUnit * 25
    Layout.maximumHeight: Kirigami.Units.gridUnit * 40

    readonly property int paddings: Kirigami.Units.largeSpacing
    readonly property bool showAgenda: eventPluginsManager.enabledPlugins.length > 0
    readonly property bool showClocks: plasmoid.configuration.selectedTimeZones.length > 1

    // This helps synchronize the header of the agenda and the monthView.
    readonly property double headerHeight: Math.max(agendaHeader.implicitHeight, monthView.headerHeight)

    Keys.onDownPressed: {
        monthView.Keys.downPressed(event);
    }

    Connections {
        target: root

        onExpandedChanged: {
            // clear all the selections when the plasmoid is showing/hiding
            monthView.resetToToday();
        }
    }

    PlasmaCalendar.EventPluginsManager {
        id: eventPluginsManager
        enabledPlugins: plasmoid.configuration.enabledCalendarPlugins
    }

    // Leading column containing agenda view and time zones
    // ==================================================
    ColumnLayout {
        id: leadingColumn

        visible: calendar.showAgenda || calendar.showClocks

        anchors {
            top: parent.top
            left: parent.left
            right: mainSeparator.left
            bottom: parent.bottom
        }

        spacing: 0

        PlasmaExtras.Heading {
            id: agendaHeader
            Layout.preferredHeight: calendar.headerHeight
            Layout.fillWidth: true
            level: 1

            // Agenda view header
            // -----------------
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Kirigami.Heading {
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: calendar.paddings
                    Layout.rightMargin: calendar.paddings
                    Layout.fillWidth: true

                    text: monthView.currentDate.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                    textFormat: Text.PlainText
                }

                PlasmaComponents.Label {
                    visible: monthView.currentDateAuxilliaryText.length > 0

                    Layout.leftMargin: calendar.paddings
                    Layout.rightMargin: calendar.paddings
                    Layout.fillWidth: true

                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    text: monthView.currentDateAuxilliaryText
                    textFormat: Text.PlainText
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: Kirigami.Units.mediumSpacing

                    // Heading text
                    Kirigami.Heading {
                        visible: agenda.visible

                        Layout.fillWidth: true
                        Layout.leftMargin: calendar.paddings
                        Layout.rightMargin: calendar.paddings

                        level: 2

                        text: i18n("Events")
                        textFormat: Text.PlainText
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.ToolButton {
                        id: addEventButton

                        visible: agenda.visible
                        text: i18nc("@action:button Add event", "Add…")
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                        icon.name: "list-add"

                        onClicked: {
                            // Try to launch calendar application
                            plasmoid.nativeInterface.launchCalendar();
                        }
                    }
                }
            }
        }

        // Agenda view itself
        Item {
            id: agenda
            visible: calendar.showAgenda

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 4

            function formatDateWithoutYear(date) {
                const format = Qt.locale().dateFormat(Locale.ShortFormat).replace(/[./ ]*Y{2,4}[./ ]*/i, '');
                return Qt.formatDate(date, format);
            }

            function dateEquals(date1, date2) {
                // Compare two dates without taking time into account
                return date1.getFullYear() === date2.getFullYear()
                    && date1.getMonth() === date2.getMonth()
                    && date1.getDate() === date2.getDate();
            }

            function updateEventsForCurrentDate() {
                eventsList.model = monthView.daysModel.eventsForDate(monthView.currentDate);
            }

            Connections {
                target: monthView

                onCurrentDateChanged: {
                    agenda.updateEventsForCurrentDate();
                }
            }

            Connections {
                target: monthView.daysModel

                onAgendaUpdated: {
                    if (agenda.dateEquals(updatedDate, monthView.currentDate)) {
                        agenda.updateEventsForCurrentDate();
                    }
                }
            }

            PlasmaComponents.ScrollView {
                id: eventsView
                anchors.fill: parent

                ListView {
                    id: eventsList

                    focus: false
                    activeFocusOnTab: true
                    highlight: null
                    currentIndex: -1

                    onCurrentIndexChanged: if (!activeFocus) {
                        currentIndex = -1;
                    }

                    onActiveFocusChanged: if (activeFocus) {
                        currentIndex = 0;
                    } else {
                        currentIndex = -1;
                    }

                    delegate: PlasmaComponents.ItemDelegate {
                        id: eventItem

                        property var eventData: modelData

                        width: ListView.view.width

                        readonly property bool hasTime: {
                            // Explicitly all-day event
                            if (eventData.isAllDay) {
                                return false;
                            }
                            // Multi-day event which does not start or end today (so
                            // is all-day from today's point of view)
                            if (eventData.startDateTime - monthView.currentDate < 0 &&
                                eventData.endDateTime - monthView.currentDate > 86400000) { // 24hrs in ms
                                return false;
                            }

                            // Non-explicit all-day event
                            const startIsMidnight = eventData.startDateTime.getHours() === 0
                                && eventData.startDateTime.getMinutes() === 0;

                            const endIsMidnight = eventData.endDateTime.getHours() === 0
                                && eventData.endDateTime.getMinutes() === 0;

                            const sameDay = eventData.startDateTime.getDate() === eventData.endDateTime.getDate()
                                && eventData.startDateTime.getDay() === eventData.endDateTime.getDay();

                            return !(startIsMidnight && endIsMidnight && sameDay);
                        }

                        contentItem: GridLayout {
                            id: eventGrid
                            columns: 3
                            rows: 2
                            rowSpacing: 0
                            columnSpacing: Kirigami.Units.largeSpacing

                            Rectangle {
                                id: eventColor

                                Layout.row: 0
                                Layout.column: 0
                                Layout.rowSpan: 2
                                Layout.fillHeight: true

                                color: eventItem.eventData.eventColor
                                width: 5
                                visible: eventItem.eventData.eventColor !== ""
                            }

                            PlasmaComponents.Label {
                                id: startTimeLabel

                                readonly property bool startsToday: eventItem.eventData.startDateTime - monthView.currentDate >= 0
                                readonly property bool startedYesterdayLessThan12HoursAgo: eventItem.eventData.startDateTime - monthView.currentDate >= -43200000 //12hrs in ms

                                Layout.row: 0
                                Layout.column: 1

                                text: startsToday || startedYesterdayLessThan12HoursAgo
                                    ? Qt.formatTime(eventItem.eventData.startDateTime)
                                    : agenda.formatDateWithoutYear(eventItem.eventData.startDateTime)
                                textFormat: Text.PlainText
                                horizontalAlignment: Qt.AlignRight
                                visible: eventItem.hasTime
                            }

                            PlasmaComponents.Label {
                                id: endTimeLabel

                                readonly property bool endsToday: eventItem.eventData.endDateTime - monthView.currentDate <= 86400000 // 24hrs in ms
                                readonly property bool endsTomorrowInLessThan12Hours: eventItem.eventData.endDateTime - monthView.currentDate <= 86400000 + 43200000 // 36hrs in ms

                                Layout.row: 1
                                Layout.column: 1

                                text: endsToday || endsTomorrowInLessThan12Hours
                                    ? Qt.formatTime(eventItem.eventData.endDateTime)
                                    : agenda.formatDateWithoutYear(eventItem.eventData.endDateTime)
                                textFormat: Text.PlainText
                                horizontalAlignment: Qt.AlignRight
                                opacity: 0.7

                                visible: eventItem.hasTime
                            }

                            PlasmaComponents.Label {
                                id: eventTitle

                                Layout.row: 0
                                Layout.column: 2
                                Layout.fillWidth: true

                                elide: Text.ElideRight
                                text: eventItem.eventData.title
                                textFormat: Text.PlainText
                                verticalAlignment: Text.AlignVCenter
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }

            PlasmaExtras.Heading {
                anchors.centerIn: eventsView
                width: eventsView.width - (Kirigami.Units.gridUnit * 8)

                visible: eventsList.count === 0
                level: 3
                opacity: 0.6

                text: monthView.isToday(monthView.currentDate)
                    ? i18n("No events for today")
                    : i18n("No events for this day");
            }
        }

        // Horizontal separator line between events and time zones
        PlasmaCore.SvgItem {
            visible: worldClocks.visible && agenda.visible

            Layout.fillWidth: true
            Layout.preferredHeight: naturalSize.height

            svg: PlasmaCore.Svg { imagePath: "widgets/line" }
            elementId: "horizontal-line"
        }

        // Clocks stuff
        // ------------
        // Header text + button to change time & time zone
        PlasmaExtras.Heading {
            visible: worldClocks.visible
            level: 2

            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true

                    level: 2

                    text: i18n("Time Zones")
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                PlasmaComponents.ToolButton {
                    id: switchTimeZoneButton

                    text: i18n("Switch…")
                    icon.name: "preferences-system-time"

                    onClicked: {
                        // Launch time zone configuration
                        plasmoid.nativeInterface.openTimeZoneSettings();
                    }
                }
            }
        }

        // Clocks view itself
        PlasmaComponents.ScrollView {
            id: worldClocks
            visible: calendar.showClocks

            Layout.fillWidth: true
            Layout.fillHeight: !agenda.visible
            Layout.minimumHeight: visible ? Kirigami.Units.gridUnit * 7 : 0
            Layout.maximumHeight: agenda.visible ? Kirigami.Units.gridUnit * 10 : -1

            ListView {
                id: clocksList
                activeFocusOnTab: true

                highlight: null
                currentIndex: -1
                onActiveFocusChanged: if (activeFocus) {
                    currentIndex = 0;
                } else {
                    currentIndex = -1;
                }

                model: root.selectedTimeZonesDeduplicatingExplicitLocalTimeZone()

                delegate: PlasmaComponents.ItemDelegate {
                    id: listItem

                    property string timeZone: modelData
                    readonly property bool isCurrentTimeZone: root.timeZoneResolvesToLastSelectedTimeZone(timeZone)

                    width: ListView.view.width

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: root.displayStringForTimeZone(listItem.timeZone)
                            textFormat: Text.PlainText
                            font.weight: listItem.isCurrentTimeZone ? Font.Bold : Font.Normal
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }

                        PlasmaComponents.Label {
                            horizontalAlignment: Qt.AlignRight
                            text: root.timeForZone(listItem.timeZone, plasmoid.configuration.showSeconds === 2)
                            textFormat: Text.PlainText
                            font.weight: listItem.isCurrentTimeZone ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }

    // Vertical separator line between columns
    // =======================================
    PlasmaCore.SvgItem {
        id: mainSeparator

        anchors {
            top: parent.top
            right: monthViewWrapper.left
            bottom: parent.bottom
        }

        width: naturalSize.width
        visible: calendar.showAgenda || calendar.showClocks

        svg: PlasmaCore.Svg { imagePath: "widgets/line" }
        elementId: "vertical-line"
    }

    // Trailing column containing calendar
    // ===============================
    FocusScope {
        id: monthViewWrapper

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        // Not anchoring to horizontalCenter to avoid sub-pixel misalignments
        width: (calendar.showAgenda || calendar.showClocks) ? Math.round(parent.width / 2) : parent.width

        onActiveFocusChanged: if (activeFocus) {
            monthView.forceActiveFocus();
        }

        PlasmaCalendar.MonthView {
            id: monthView

            anchors {
                fill: parent
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.smallSpacing
            }

            borderOpacity: 0.25

            eventPluginsManager: eventPluginsManager
            today: root.currentDateTimeInSelectedTimeZone
            firstDayOfWeek: plasmoid.configuration.firstDayOfWeek > -1
                ? plasmoid.configuration.firstDayOfWeek
                : Qt.locale().firstDayOfWeek
            showWeekNumbers: plasmoid.configuration.showWeekNumbers

            Component.onCompleted: {
                calendar.monthViewChanged(monthView);
            }
        }
    }
}
