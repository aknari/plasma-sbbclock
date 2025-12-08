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
    property int handAnimationMode: Plasmoid.configuration.handAnimationMode || 0

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

    /**
     * Inicializa la lista de zonas horarias
     * 
     * Asegura que "Local" (zona horaria del sistema) esté siempre presente
     * en la lista de zonas horarias, incluso si el usuario no la ha añadido
     * explícitamente en la configuración.
     */
    function initTimeZones() {
        const timeZones = [];
        if (Plasmoid.configuration.selectedTimeZones.indexOf("Local") === -1) {
            timeZones.push("Local");
        }
        root.allTimeZones = timeZones.concat(Plasmoid.configuration.selectedTimeZones);
    }

    /**
     * Formatea la hora para una zona horaria específica
     * 
     * Obtiene la hora actual de una zona horaria del DataSource y la formatea
     * según las preferencias del usuario (con o sin segundos). Si la fecha de
     * la zona horaria es diferente a la local, añade la fecha entre paréntesis.
     * 
     * @param timeZone - Identificador de la zona horaria (ej: "Europe/London", "Local")
     * @param showSeconds - Si debe mostrar los segundos en el formato
     * @returns String con la hora formateada, ej: "14:30" o "14:30 (Tomorrow)"
     */
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

    /**
     * Obtiene el nombre legible de una zona horaria
     * 
     * Convierte el identificador técnico de una zona horaria en un string
     * legible para el usuario, ya sea como código (ej: "GMT") o como nombre
     * de ciudad (ej: "London"), según la configuración del usuario.
     * 
     * @param timeZone - Identificador de la zona horaria
     * @returns String legible de la zona horaria
     */
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
            // DataSource solo se usa para metadatos y offsets de zonas horarias
            // La hora local se gestiona con el systemTimer de alta precisión
        }
        Component.onCompleted: {
            dataSource.connectedSources = sources
            
            // Inicialización inmediata para evitar que empiece en 00:00
            var now = new Date()
            hours = now.getHours()
            minutes = now.getMinutes()
            seconds = now.getSeconds()
            currentDateTime = now
            
            if (handAnimationMode === 1) {
                smoothMinutes = minutes + (seconds / 60.0)
            } else {
                smoothMinutes = minutes
            }
        }
    }

    // Variables para sincronización precisa
    property double lastDataSourceUpdate: 0
    property int dataSourceSeconds: 0
    property int dataSourceMilliseconds: 0
    
    // Propiedad auxiliar para forzar actualizaciones del binding de smoothSeconds
    property double timePulse: 0
    
    // Fecha y hora actual sincronizada con el sistema (para DigitalClock)
    property var currentDateTime: new Date()

    /**
     * Timer maestro de alta precisión
     * Actualiza la hora del sistema independientemente del DataSource
     * Garantiza sincronización perfecta con el reloj del sistema
     */
    Timer {
        id: systemTimer
        interval: 50 // 20 FPS
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            timePulse = now.getTime()
            currentDateTime = now
            
            
            checkAndPlaySignal()

            // Actualizar propiedades de tiempo base
            var newHours = now.getHours()
            var newMinutes = now.getMinutes()
            var newSeconds = now.getSeconds()
            var newMilliseconds = now.getMilliseconds()
            
            // Actualizar variables de sincronización para smoothSeconds
            lastDataSourceUpdate = timePulse
            dataSourceSeconds = newSeconds
            dataSourceMilliseconds = newMilliseconds
            
            // Actualizar horas y segundos
            if (hours !== newHours) hours = newHours
            if (seconds !== newSeconds) seconds = newSeconds
            
            // Calcular smoothMinutes atómicamente para evitar saltos
            if (handAnimationMode === 1) { // Smooth
                var totalMinutes = newMinutes + (newSeconds / 60.0) + (newMilliseconds / 60000.0)
                if (Math.abs(smoothMinutes - totalMinutes) > 0.0001) {
                    smoothMinutes = totalMinutes
                }
            } else {
                smoothMinutes = newMinutes
            }
            
            // Lógica de minutero (con o sin adelanto)
            if (handAnimationMode === 0 && !useDigitalMode) {
                // Modo SBB: Adelanto de 200ms
                var totalMs = (newSeconds * 1000) + newMilliseconds
                if (totalMs >= 59800) {
                    var nextMinute = newMinutes + 1
                    if (nextMinute >= 60) nextMinute = 0
                    if (minutes !== nextMinute) minutes = nextMinute
                } else if (totalMs < 1000 && minutes !== newMinutes) {
                    // Corrección por si el timer saltó el intervalo exacto
                    minutes = newMinutes
                }
            } else {
                // Otros modos: Actualización normal
                if (minutes !== newMinutes) minutes = newMinutes
            }
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


    /**
     * Genera el formato de fecha eliminando el día de la semana
     * 
     * Toma el formato de fecha largo del locale del sistema y elimina la parte
     * del día de la semana ("dddd"), que siempre aparece al inicio o al final
     * en todos los locales.
     * 
     * Ejemplo: "dddd, d 'de' MMMM 'de' yyyy" → "d 'de' MMMM 'de' yyyy"
     * 
     * @returns String con el formato de fecha sin el día de la semana
     */
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
    
    // Segundos suaves sincronizados con DataSource
    property real smoothSeconds: {
        if (useDigitalMode) return seconds
        
        // Dependencia explícita del pulso de tiempo
        var pulse = timePulse
        
        // Calcular segundos basados en el tiempo transcurrido desde la última actualización del DataSource
        var elapsed = Date.now() - lastDataSourceUpdate
        var val = dataSourceSeconds + (dataSourceMilliseconds + elapsed) / 1000.0
        
        // Manejar desbordamiento (ej: si el timer se retrasa un poco)
        if (val >= 60) val = val % 60
        
        return val
    }
    
    // Minutos suaves para modo Smooth (actualizado en systemTimer)
    property real smoothMinutes: minutes
    
    /**
     * Rotación del segundero en grados (0-360)
     * 
     * Calcula la rotación según el modo de animación seleccionado:
     * - Modo 0 (SBB): 59 segundos + pausa (comportamiento original)
     * - Modo 1 (Smooth): Movimiento continuo (60 segundos)
     * - Modo 2 (Tick): Saltos discretos por segundo (sin interpolación)
     */
    property real secondHandRotation: {
        switch(handAnimationMode) {
            case 0: // SBB - 59 segundos + pausa
                // Recorrer 360 grados en 59 segundos, terminar en 0 en el segundo 60
                if (smoothSeconds >= 59) {
                    return 0
                } else {
                    return (smoothSeconds * (360/59))
                }
            case 1: // Smooth - 60 segundos continuo
                return smoothSeconds * 6  // 360/60 = 6° por segundo
            case 2: // Tick - saltos discretos
                return seconds * 6
            default:
                return smoothSeconds * (360/59)
        }
    }
    property bool showSecondsHand: Plasmoid.configuration.showSecondHand
    property bool showTimezone: Plasmoid.configuration.showTimezoneString
    property bool playHourGong: Plasmoid.configuration.playHourGong
    property real volumeInput: Plasmoid.configuration.volumeSlider / 100
    property string hourSignalSound: Plasmoid.configuration.hourSignalSound
    property int hourSignalStartTime: Plasmoid.configuration.hourSignalStartTime
    property int hourSignalEndTime: Plasmoid.configuration.hourSignalEndTime
    property double hourSignalAdvance: Plasmoid.configuration.hourSignalAdvance
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

    /**
     * Verifica y reproduce la señal horaria si corresponde
     * 
     * Comprueba si se cumplen todas las condiciones para reproducir el sonido:
     * - Estamos cerca del minuto 59
     * - El tiempo actual coincide con el tiempo objetivo (60s - adelanto)
     * - La señal horaria está habilitada
     * - La hora actual está dentro del rango configurado
     */
    function checkAndPlaySignal() {
        if (!playHourGong || hours < hourSignalStartTime || hours >= hourSignalEndTime) {
            return
        }

        // Calcular el momento objetivo (target) en ms dentro del minuto actual
        // El objetivo es (60 - advance) segundos
        // Ejemplo: adelanto 5.5s -> target = 54.5s = 54500ms
        var targetMs = (60.0 - hourSignalAdvance) * 1000.0

        // Tiempo actual en ms dentro del minuto
        var currentMs = (currentDateTime.getSeconds() * 1000) + currentDateTime.getMilliseconds()
        
        // Tiempo del frame anterior (aproximado)
        // systemTimer corre cada 50ms
        var previousMs = currentMs - systemTimer.interval
        // Si acabamos de cambiar de minuto (currentMs es pequeño), el previousMs sería negativo (final del minuto anterior)
        // En ese caso, para simplificar la detección de cruce, podemos asumir que si currentMs < systemTimer.interval, venimos de 59999
        
        // Detectar cruce del umbral
        // El caso normal es: previousMs < targetMs <= currentMs
        // Pero hay que tener cuidado con el rollover del minuto si el target está muy cerca de 60s o 0s
        
        // Simplificación: Solo nos interesa si estamos en el minuto 59, O si el adelanto es 0 (target=60s/0s del siguiente)
        // Si adelanto es 0, queremos sonar en 00:00 exacto.
        
        var isTargetReached = false
        
        if (hourSignalAdvance === 0) {
             // Caso especial: sonar en punto (xx:00:00.000)
             // Detectamos si acabamos de cambiar de minuto a 0
             if (minutes === 0 && seconds === 0 && currentDateTime.getMilliseconds() < systemTimer.interval * 1.5) {
                 isTargetReached = true
             }
        } else {
            // Caso normal: sonar dentro del minuto 59
            if (minutes === 59) {
                if (currentMs >= targetMs && previousMs < targetMs) {
                    isTargetReached = true
                }
            }
        }
        
        // Evitar disparos múltiples muy seguidos (debounce simple por frame)
        // Como systemTimer es el único que llama, la condición previous < target <= current garantiza un solo disparo
        
        if (isTargetReached) {
            soundPlayer.source = hourSignalSound // Recargar source por si cambió config
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
            minutes: root.handAnimationMode === 1 ? root.smoothMinutes : root.minutes // Usar minutos suaves en modo Smooth
            seconds: root.seconds
            smoothSeconds: root.smoothSeconds
            secondHandRotation: root.secondHandRotation
            showSecondsHand: root.showSecondsHand
            timezoneString: root.showTimezone ? dataSource.data["Local"]["Timezone"] : ""
            handAnimationMode: root.handAnimationMode
        }

        DigitalClock {
            id: digitalClock
            anchors.fill: parent
            visible: root.useDigitalMode
            
            // Usar siempre currentDateTime sincronizado con systemTimer para hora local
            timeSource: root.currentDateTime
            
            timezoneString: root.showTimezone ? dataSource.data["Local"]["Timezone"] : ""
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
