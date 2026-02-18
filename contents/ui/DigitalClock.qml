import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: digitalClock

    /**
     * Helper invisible para pre-calcular el ancho máximo necesario
     * 
     * Este elemento no se muestra pero se usa para calcular el ancho que ocuparía
     * el tiempo con los caracteres más anchos posibles ("88:88"). Esto evita que
     * el widget cambie de tamaño cuando los dígitos cambian (ej: "11:11" vs "22:22").
     * 
     * Rompe el "layout loop" al proporcionar un ancho estable y predecible.
     */
    PlasmaExtras.Heading {
        id: sizeHelper
        visible: false
        level: 1 // Use a heading to get font properties similar to the original
        font.pointSize: timeFontSize
        font.weight: timeIsBold ? Font.Bold : Font.Normal
        font.family: fontFamily || "Noto Sans"
        // Use a string with wide characters to represent the maximum possible width.
        text: "88:88"
    }

    /**
     * Ancho requerido para el widget (calculado de forma estable)
     * 
     * Se basa en el sizeHelper pre-calculado para evitar cambios de tamaño
     * durante las actualizaciones del reloj. Toma el máximo entre:
     * - El ancho del helper ("88:88")
     * - El ancho real pintado de cada elemento visible
     * 
     * El padding de +4 proporciona un pequeño margen de seguridad.
     */
    readonly property real requiredWidth: Math.max(sizeHelper.implicitWidth, timeLabel.paintedWidth, dateLabel.paintedWidth, timezoneLabel.paintedWidth) + 4 // Add a small padding
    readonly property real requiredHeight: contentLayout.height

    // Configuration properties
    readonly property bool showSeconds: Plasmoid.configuration.showSecondHand ?? false
    readonly property bool showTimezone: Plasmoid.configuration.showTimezoneString ?? false
    readonly property bool showDate: Plasmoid.configuration.showDate ?? true
    readonly property bool transparentBackground: Plasmoid.configuration.transparentBackground ?? false
    readonly property bool blinkingTimeSeparator: Plasmoid.configuration.blinkingTimeSeparator ?? false
    readonly property bool useCustomColors: Plasmoid.configuration.useCustomColors ?? false
    readonly property color timeColor: Plasmoid.configuration.timeColor ?? PlasmaCore.Theme.textColor
    readonly property color dateColor: Plasmoid.configuration.dateColor ?? PlasmaCore.Theme.textColor
    
    // Time format handling
    readonly property string timeFormat: Plasmoid.configuration.timeFormat || "hh:mm"

    // Use system locale for formatting
    readonly property string effectiveTimeFormat: timeFormat

    // Date format handling
    readonly property string dateFormat: Plasmoid.configuration.dateFormat || "ddd, MMM d"
    
    // Font properties
    readonly property int timeFontSize: Plasmoid.configuration.timeFontSize ?? 24
    readonly property int dateFontSize: Plasmoid.configuration.dateFontSize ?? 18
    readonly property bool timeIsBold: Plasmoid.configuration.timeIsBold ?? false
    readonly property bool dateIsBold: Plasmoid.configuration.dateIsBold ?? false
    readonly property string fontFamily: Plasmoid.configuration.fontFamily ?? ""

    property bool separatorVisible: true

    Timer {
        id: blinkTimer
        interval: 500  // Parpadea cada 500ms
        repeat: true
        running: blinkingTimeSeparator
        onTriggered: separatorVisible = !separatorVisible
    }

    /**
     * Formatea una fecha según el patrón especificado con soporte para mayúsculas personalizadas
     * 
     * Extiende el formateo estándar de Qt con formatos especiales:
     * - 'Dddd': Día de la semana con primera letra mayúscula ("Lunes")
     * - 'DDDD': Día de la semana en mayúsculas completas ("LUNES")
     * - Texto literal entre comillas dobles: "de", "at", etc.
     * 
     * @param date - Objeto Date a formatear
     * @param format - Patrón de formato (ej: "Dddd, d 'de' MMMM")
     * @returns String formateado según el patrón
     * 
     * Ejemplos:
     *   formatDate(new Date(), "Dddd, d 'de' MMMM") → "Lunes, 28 de noviembre"
     *   formatDate(new Date(), "DDDD d/M/yy") → "LUNES 28/11/25"
     */
    function formatDate(date, format) {
        // Función auxiliar para capitalizar
        function capitalize(str) {
            return str.charAt(0).toUpperCase() + str.slice(1);
        }
        
        // Procesar formatos especiales antes de la formatación normal
        var processedFormat = format;
        
        // Reemplazar 'Dddd' con 'dddd' y marcar para capitalizar primera letra
        var hasFirstCap = processedFormat.includes('Dddd');
        processedFormat = processedFormat.replace('Dddd', 'dddd');
        
        // Reemplazar 'DDDD' con 'dddd' y marcar para mayúsculas completas
        var hasAllCaps = processedFormat.includes('DDDD');
        processedFormat = processedFormat.replace('DDDD', 'dddd');

        // Si el formato incluye texto literal, lo procesamos especialmente
        if (processedFormat.includes('"')) {
            var baseFormat = processedFormat.replace(/"[^"]*"/g, "");
            var formattedDate = date.toLocaleDateString(Qt.locale(), baseFormat);
            
            var parts = processedFormat.match(/"[^"]*"|[^"]+/g);
            var result = "";
            parts.forEach(part => {
                if (part.startsWith('"') && part.endsWith('"')) {
                    result += part.slice(1, -1);
                } else {
                    var formatted = date.toLocaleDateString(Qt.locale(), part);
                    if (part.includes('dddd')) {
                        if (hasAllCaps) {
                            formatted = formatted.toUpperCase();
                        } else if (hasFirstCap) {
                            formatted = capitalize(formatted);
                        }
                    }
                    result += formatted;
                }
            });
            return result;
        }
        
        // Si no hay texto literal, procesamos la fecha completa
        var result = date.toLocaleDateString(Qt.locale(), processedFormat);
        if (hasAllCaps) {
            result = result.toUpperCase();
        } else if (hasFirstCap) {
            result = capitalize(result);
        }
        return result;
    }

    // Propiedades que se reciben desde main.qml
    property var timeSource: new Date()      // Fuente de tiempo actual
    property string timezoneString: ""       // String de zona horaria a mostrar
    property bool hasEventsToday: false      // Si hay eventos hoy (para cambiar color de fecha)

    Rectangle {
        id: background
        anchors.fill: parent
        color: PlasmaCore.Theme.backgroundColor
        opacity: transparentBackground ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    Item {
        id: contentLayout
        anchors.centerIn: parent

        // Calculate width based on the widest visible element
        width: Math.max(timeLabel.implicitWidth, dateLabel.visible ? dateLabel.implicitWidth : 0, timezoneLabel.visible ? timezoneLabel.implicitWidth : 0)
        // Calculate height by summing the heights of visible elements
        height: timeLabel.height + (dateLabel.visible ? (dateLabel.height + dateLabel.anchors.topMargin) : 0) + (timezoneLabel.visible ? timezoneLabel.height : 0)

        PlasmaComponents.Label {
            id: timeLabel
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: PlasmaComponents.Text.StyledText
            font.pointSize: timeFontSize
            font.weight: timeIsBold ? Font.Bold : Font.Normal
            font.family: fontFamily || "Noto Sans"
            color: useCustomColors ? timeColor : PlasmaCore.Theme.textColor
            text: {
                if (!timeSource) return "--:--"
                var now = new Date(timeSource);
                var format = Plasmoid.configuration.timeFormat;
                var formattedTime = Qt.formatDateTime(now, format);
                
                if (blinkingTimeSeparator && !separatorVisible) {
                    // Reemplaza ":" por una versión transparente para mantener el ancho exacto
                    return formattedTime.replace(/:/g, '<font color="transparent">:</font>');
                }
                return formattedTime;
            }

        }

        PlasmaComponents.Label {
            id: dateLabel
            visible: showDate
            // Anchor the top of the date to the bottom of the time. This creates the "zero spacing" effect.
            anchors.top: timeLabel.bottom
            // Use a significant negative margin to force the text closer, overcoming font metrics.
            anchors.topMargin: -Math.round(dateFontSize * 0.8)
            anchors.horizontalCenter: parent.horizontalCenter
            font.pointSize: dateFontSize
            font.weight: dateIsBold ? Font.Bold : Font.Normal
            font.family: fontFamily || "Noto Sans"
            color: {
                if (hasEventsToday && Plasmoid.configuration.showEventColor) {
                    return Plasmoid.configuration.eventColor;
                } else if (useCustomColors) {
                    return dateColor;
                } else {
                    return PlasmaCore.Theme.textColor;
                }
            }
            text: {
                if (!timeSource) return ""
                var now = new Date(timeSource);
                return formatDate(now, dateFormat);
            }
        }

        PlasmaComponents.Label {
            id: timezoneLabel
            visible: showTimezone
            anchors.top: dateLabel.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            font.pointSize: Math.max(1, Math.round(dateFontSize * 0.8))
            color: useCustomColors ? timeColor : PlasmaCore.Theme.textColor
            text: timezoneString
        }
    }
}
