import QtQuick 2.15
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.calendar 2.0 as PlasmaCalendar

import "." as Local

Item {
    id: root

    property bool useDigitalMode: plasmoid.configuration.useDigitalMode

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    readonly property string dateFormatString: setDateFormatString()
    readonly property string timeFormat: plasmoid.configuration.timeFormat || "hh:mm"
    readonly property string timeFormatWithSeconds: plasmoid.configuration.timeFormatWithSeconds || "hh:mm:ss"

    readonly property date currentDateTimeInSelectedTimeZone: {
        const data = dataSource.data[plasmoid.configuration.lastSelectedTimezone];
        // The order of signal propagation is unspecified, so we might get
        // here before the dataSource has updated. Alternatively, a buggy
        // configuration view might set lastSelectedTimezone to a new time
        // zone before applying the new list, or it may just be set to
        // something invalid in the config file.
        if (data === undefined) {
            return new Date();
        }
        // get the time for the given time zone from the dataengine
        const now = data["DateTime"];
        // get current UTC time
        const nowUtcMilliseconds = now.getTime() + (now.getTimezoneOffset() * 60000);
        const selectedTimeZoneOffsetMilliseconds = data["Offset"] * 1000;
        // add the selected time zone's offset to it
        return new Date(nowUtcMilliseconds + selectedTimeZoneOffsetMilliseconds);
    }

    function initTimeZones() {
        const timeZones = [];
        if (plasmoid.configuration.selectedTimeZones.indexOf("Local") === -1) {
            timeZones.push("Local");
        }
        root.allTimeZones = timeZones.concat(plasmoid.configuration.selectedTimeZones);
    }

    function timeForZone(timeZone, showSeconds) {
        if (!compactRepresentation) {
            return "";
        }

        const data = dataSource.data[timeZone];
        if (data === undefined) {
            return "";
        }

        // get the time for the given time zone from the dataengine
        const now = data["DateTime"];
        // get current UTC time
        const msUTC = now.getTime() + (now.getTimezoneOffset() * 60000);
        // add the dataengine TZ offset to it
        const dateTime = new Date(msUTC + (data["Offset"] * 1000));

        let formattedTime;
        if (showSeconds) {
            formattedTime = Qt.formatTime(dateTime, timeFormatWithSeconds);
        } else {
            formattedTime = Qt.formatTime(dateTime, timeFormat);
        }

        if (dateTime.getDay() !== dataSource.data["Local"]["DateTime"].getDay()) {
            formattedTime += " (" + dateFormatter(dateTime) + ")";
        }

        return formattedTime;
    }

    function displayStringForTimeZone(timeZone) {
        const data = dataSource.data[timeZone];
        if (data === undefined) {
            return timeZone;
        }

        // add the time zone string to the clock
        if (plasmoid.configuration.displayTimezoneAsCode) {
            return data["Timezone Abbreviation"];
        } else {
            return data["Timezone City"] || data["Timezone"];
        }
    }

    function selectedTimeZonesDeduplicatingExplicitLocalTimeZone() {
        const displayStringForLocalTimeZone = displayStringForTimeZone("Local");
        /*
         * Don't add this item if it's the same as the local time zone, which
         * would indicate that the user has deliberately added a dedicated entry
         * for the city of their normal time zone. This is not an error condition
         * because the user may have done this on purpose so that their normal
         * local time zone shows up automatically while they're traveling and
         * they've switched the current local time zone to something else. But
         * with this use case, when they're back in their normal local time zone,
         * the clocks list would show two entries for the same city. To avoid
         * this, let's suppress the duplicate.
         */
        const isLiterallyLocalOrResolvesToSomethingOtherThanLocal = function(timeZone) {
            return timeZone === "Local" || displayStringForTimeZone(timeZone) !== displayStringForLocalTimeZone;
        }

        return plasmoid.configuration.selectedTimeZones
            .filter(isLiterallyLocalOrResolvesToSomethingOtherThanLocal)
            .sort(function(a, b) { return dataSource.data[a]["Offset"] - dataSource.data[b]["Offset"]; });
    }

    function timeZoneResolvesToLastSelectedTimeZone(timeZone) {
        return timeZone === plasmoid.configuration.lastSelectedTimezone
            || displayStringForTimeZone(timeZone) === displayStringForTimeZone(plasmoid.configuration.lastSelectedTimezone);
    }

    PlasmaCore.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 1000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"])
            hours = date.getHours()
            minutes = date.getMinutes()
            seconds = date.getSeconds()
        }
        Component.onCompleted: {
            dataChanged();
        }
    }

    property bool hasEventsToday: false

    function updateHasEventsToday() {
        if (plasmoid.expanded && monthView && monthView.daysModel) {
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            hasEventsToday = monthView.daysModel.eventsForDate(today).length > 0;
        } else {
            hasEventsToday = false;
        }
    }

    Connections {
        target: plasmoid
        onExpandedChanged: {
            if (plasmoid.expanded) {
                updateHasEventsToday();
            }
        }
    }

    property PlasmaCalendar.MonthView monthView: null

    function setDateFormatString() {
        // remove "dddd" from the locale format string
        // /all/ locales in LongFormat have "dddd" either
        // at the beginning or at the end. so we just
        // remove it + the delimiter and space
        let format = Qt.locale().dateFormat(Locale.LongFormat);
        format = format.replace(/(^dddd.?\s)|(,?\sdddd$)/, "");
        return format;
    }

    property int hours
    property int minutes
    property int seconds
    property real smoothSeconds: seconds
    property real secondHandRotation: {
        // Recorrer 360 grados en 59 segundos, terminar en 0 en el segundo 60
        if (smoothSeconds >= 59) {
            return 0  // Volver a 0 grados en el segundo 60
        } else {
            // Calcular rotación para que recorra 360 grados en 59 segundos
            return (smoothSeconds * (360/59))
        }
    }
    property bool showSecondsHand: plasmoid.configuration.showSecondHand
    property bool showTimezone: plasmoid.configuration.showTimezoneString
    property int tzOffset

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Timer {
        id: smoothSecondsTimer
        interval: 50  // Actualizar cada 50ms
        repeat: true
        running: showSecondsHand
        onTriggered: {
            var now = new Date()
            // Usar la hora local del sistema para la animación suave, es solo visual
            var currentSeconds = now.getSeconds()
            var currentMilliseconds = now.getMilliseconds()

            // Calcular segundos suaves con mayor precisión
            smoothSeconds = currentSeconds + (currentMilliseconds / 1000)
        }
    }

    function dateTimeChanged() {
        var currentTZOffset = dataSource.data["Local"]["Offset"] / 60;
        if (currentTZOffset !== tzOffset) {
            tzOffset = currentTZOffset;
            Date.timeZoneUpdated();
        }
    }

    Plasmoid.compactRepresentation: Item {
        id: compactRepresentation

        Layout.minimumWidth: useDigitalMode ? digitalClock.requiredWidth : analogClock.Layout.minimumWidth
        Layout.maximumWidth: useDigitalMode ? digitalClock.requiredWidth : -1
        Layout.fillHeight: true

        AnalogClock {
            id: analogClock
            anchors.fill: parent
            visible: !useDigitalMode

            hours: root.hours
            minutes: root.minutes
            seconds: root.seconds
            smoothSeconds: root.smoothSeconds
            secondHandRotation: root.secondHandRotation
            showSecondsHand: root.showSecondsHand
            timezoneString: root.showTimezone ? (dataSource.data["Local"] ? dataSource.data["Local"]["Timezone"] : "") : ""
        }

        DigitalClock {
            id: digitalClock
            anchors.fill: parent
            visible: useDigitalMode
            timeSource: dataSource.data["Local"] ? dataSource.data["Local"]["DateTime"] : new Date()
            timezoneString: showTimezone ? (dataSource.data["Local"] ? dataSource.data["Local"]["Timezone"] : "") : ""
            hasEventsToday: root.hasEventsToday
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                plasmoid.expanded = !plasmoid.expanded
            }
        }
    }

    Plasmoid.fullRepresentation: CalendarView {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 40
        Layout.minimumHeight: Kirigami.Units.gridUnit * 25

        onMonthViewChanged: {
            root.monthView = monthView;
        }
    }

    Plasmoid.toolTipItem: Loader {
        id: tooltipLoader

        Layout.minimumWidth: item ? item.implicitWidth : 0
        Layout.maximumWidth: item ? item.implicitWidth : 0
        Layout.minimumHeight: item ? item.implicitHeight : 0
        Layout.maximumHeight: item ? item.implicitHeight : 0

        source: Qt.resolvedUrl("Tooltip.qml")
    }
}
