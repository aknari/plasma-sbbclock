import QtQuick
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.plasma.private.digitalclock

import "." as Local

PlasmoidItem {
    id: root

    property bool useDigitalMode: Plasmoid.configuration.useDigitalMode

    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

    readonly property string dateFormatString: setDateFormatString()
    readonly property string timeFormat: Plasmoid.configuration.timeFormat || "hh:mm"
    readonly property string timeFormatWithSeconds: Plasmoid.configuration.timeFormatWithSeconds || "hh:mm:ss"

    readonly property date currentDateTimeInSelectedTimeZone: {
        const data = dataSource.data[Plasmoid.configuration.lastSelectedTimezone];
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
        if (Plasmoid.configuration.selectedTimeZones.indexOf("Local") === -1) {
            timeZones.push("Local");
        }
        root.allTimeZones = timeZones.concat(Plasmoid.configuration.selectedTimeZones);
    }

    function timeForZone(timeZone: string, showSeconds: bool): string {
        if (!compactRepresentationItem) {
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

    function displayStringForTimeZone(timeZone: string): string {
        const data = dataSource.data[timeZone];
        if (data === undefined) {
            return timeZone;
        }

        // add the time zone string to the clock
        if (Plasmoid.configuration.displayTimezoneAsCode) {
            return data["Timezone Abbreviation"];
        } else {
            return TimeZonesI18n.i18nCity(data["Timezone"]);
        }
    }

    function selectedTimeZonesDeduplicatingExplicitLocalTimeZone():/* [string] */var {
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
        const isLiterallyLocalOrResolvesToSomethingOtherThanLocal = timeZone =>
            timeZone === "Local" || displayStringForTimeZone(timeZone) !== displayStringForLocalTimeZone;

        return Plasmoid.configuration.selectedTimeZones
            .filter(isLiterallyLocalOrResolvesToSomethingOtherThanLocal)
            .sort((a, b) => dataSource.data[a]["Offset"] - dataSource.data[b]["Offset"]);
    }

    function timeZoneResolvesToLastSelectedTimeZone(timeZone: string): bool {
        return timeZone === Plasmoid.configuration.lastSelectedTimezone
            || displayStringForTimeZone(timeZone) === displayStringForTimeZone(Plasmoid.configuration.lastSelectedTimezone);
    }

    P5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: "Local"
        interval: 1000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"])
            hours = date.getHours()
            minutes = date.getMinutes()
            seconds = date.getSeconds()

            checkAndPlaySignal()
        }
        Component.onCompleted: {
            dataChanged();
        }
    }

    property bool hasEventsToday: false

    function updateHasEventsToday() {
        if (fullRepresentationItem && fullRepresentationItem.monthView && fullRepresentationItem.monthView.daysModel) {
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            hasEventsToday = fullRepresentationItem.monthView.daysModel.eventsForDate(today).length > 0;
            console.log("hasEventsToday updated:", hasEventsToday);
        } else {
            hasEventsToday = false;
        }
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                updateHasEventsToday();
            }
        }
    }


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
    property bool showSecondsHand: Plasmoid.configuration.showSecondHand
    property bool showTimezone: Plasmoid.configuration.showTimezoneString
    property bool playHourGong: Plasmoid.configuration.playHourGong
    property real volumeInput: Plasmoid.configuration.volumeSlider / 100
    property string hourSignalSound: Plasmoid.configuration.hourSignalSound
    property int hourSignalStartTime: Plasmoid.configuration.hourSignalStartTime
    property int hourSignalEndTime: Plasmoid.configuration.hourSignalEndTime
    property int hourSignalAdvance: Plasmoid.configuration.hourSignalAdvance
    property int tzOffset

    preferredRepresentation: compactRepresentation

    MediaPlayer {
        id: soundPlayer
        source: hourSignalSound
        audioOutput: AudioOutput {
            volume: volumeInput
        }
    }

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

    function checkAndPlaySignal() {
        var date = new Date(dataSource.data["Local"]["DateTime"])
        var currentMinute = date.getMinutes()
        var currentSecond = date.getSeconds()

        if (minutes === 59 && 
            (hourSignalAdvance === 0 ? currentSecond === 59 : currentSecond === 60 - hourSignalAdvance) && 
            playHourGong && hours >= hourSignalStartTime && hours < hourSignalEndTime) {
            soundPlayer.play()
        }
    }

    compactRepresentation: Item {
        id: representation
        
        // Replicate the sizing logic from the original digital clock:
        // The minimum and maximum width are set to the content's required width.
        // This makes the widget horizontally rigid, preventing the user from resizing it.
        Layout.minimumWidth: useDigitalMode ? digitalClock.requiredWidth : analogClock.implicitWidth
        Layout.maximumWidth: useDigitalMode ? digitalClock.requiredWidth : Infinity // Allow analog clock to be resized

        // The height should be flexible to fill the panel.
        Layout.fillHeight: true

        AnalogClock {
            id: analogClock
            anchors.fill: parent
            visible: !useDigitalMode
            
            // Pasar propiedades desde el root
            hours: root.hours
            minutes: root.minutes
            seconds: root.seconds
            smoothSeconds: root.smoothSeconds
            secondHandRotation: root.secondHandRotation
            showSecondsHand: root.showSecondsHand
            timezoneString: root.showTimezone ? dataSource.data["Local"]["Timezone"] : ""
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
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    root.expanded = !root.expanded
                }
            }
        }
    }

    fullRepresentation: CalendarView {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 40
        Layout.minimumHeight: Kirigami.Units.gridUnit * 25
    }

    toolTipItem: Loader {
        id: tooltipLoader

        Layout.minimumWidth: item ? item.implicitWidth : 0
        Layout.maximumWidth: item ? item.implicitWidth : 0
        Layout.minimumHeight: item ? item.implicitHeight : 0
        Layout.maximumHeight: item ? item.implicitHeight : 0

        source: Qt.resolvedUrl("Tooltip.qml")
    }

}
