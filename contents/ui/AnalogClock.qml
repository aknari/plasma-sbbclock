import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtMultimedia 6.7

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: analogclock

    property int hours
    property real minutes
    property int seconds
    property int handAnimationMode: 0
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
    property string timezoneString: ""
    
    /**
     * Factor de escala para las manecillas del reloj
     * 
     * Calcula el factor de escala necesario para que las manecillas SVG
     * se ajusten correctamente al tamaño de la esfera del reloj, manteniendo
     * las proporciones correctas independientemente del tamaño del widget.
     * 
     * Fórmula: min(ancho, alto) del widget / max(ancho, alto) natural del SVG
     */
    property real handScale: Math.min(width, height) / Math.max(face.naturalSize.width, face.naturalSize.height)

    Layout.minimumWidth: Plasmoid.formFactor !== PlasmaCore.Types.Vertical ? height : Kirigami.Units.gridUnit
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.gridUnit

    KSvg.Svg {
        id: clockSvg
        imagePath: Qt.resolvedUrl("../images/sbb-clock.svg")
    }
    /**
     * Actualiza la rotación de todas las manecillas del reloj
     * 
     * Esta función centraliza la actualización de todas las manecillas (hora, minutos, segundos)
     * incluyendo sus sombras. Se llama desde:
     * - El timer de animación suave (cada 50ms) cuando showSecondsHand está activo
     * - Los handlers onSmoothSecondsChanged y onMinutesChanged
     * 
     * El orden de actualización es importante: primero hora y minutos, luego segundos,
     * para mantener la sincronización correcta en los cambios de minuto.
     */
    function updateAllHands() {
        // Actualizar manecillas de hora (incluye ajuste fino por minutos)
        hourHandShadow.updateRotation(hours, minutes, secondHandRotation)
        hourHand.updateRotation(hours, minutes, secondHandRotation)
        
        // Actualizar manecillas de minutos
        minuteHandShadow.updateRotation(hours, minutes, secondHandRotation)
        minuteHand.updateRotation(hours, minutes, secondHandRotation)

        // Actualizar manecillas de segundos (solo si están visibles)
        if (showSecondsHand) {
            secondHandShadow.updateRotation(hours, minutes, secondHandRotation)
            secondHand.updateRotation(hours, minutes, secondHandRotation)
        }
    }

    // Actualizar todas las manecillas cuando cambian los segundos suaves (animación continua)
    onSmoothSecondsChanged: updateAllHands()
    
    // Actualizar cuando cambian los minutos (importante para sincronización hora/minuto)
    onMinutesChanged: updateAllHands()
    
    // En modo Tick, actualizar cuando cambian los segundos (ya que el timer está apagado)
    onSecondsChanged: if (handAnimationMode === 2) updateAllHands()



    Item {
        id: clock
        anchors.fill: parent

        KSvg.SvgItem {
            id: face
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: Math.min(parent.width, parent.height)
            svg: clockSvg
            elementId: "ClockFace"
        }

        Hand {
            id: hourHandShadow
            elementId: "HourHandShadow"
            rotationCenterHintId: "HourHandCenter"
            svgScale: handScale
        }

        Hand {
            id: hourHand
            elementId: "HourHand"
            rotationCenterHintId: "HourHandCenter"
            svgScale: handScale
        }

        Hand {
            id: minuteHandShadow
            elementId: "MinuteHandShadow"
            rotationCenterHintId: "MinuteHandCenter"
            svgScale: handScale
        }

        Hand {
            id: minuteHand
            elementId: "MinuteHand"
            rotationCenterHintId: "MinuteHandCenter"
            svgScale: handScale
        }

        Hand {
            id: secondHandShadow
            visible: showSecondsHand
            elementId: "SecondHandShadow"
            rotationCenterHintId: "SecondHandCenter"
            svgScale: handScale
        }

        Hand {
            id: secondHand
            visible: showSecondsHand
            elementId: "SecondHand"
            rotationCenterHintId: "SecondHandCenter"
            svgScale: handScale
        }

        KSvg.SvgItem {
            id: center
            width: naturalSize.width * (face.width / face.naturalSize.width)
            height: naturalSize.height * (face.width / face.naturalSize.width)
            anchors.centerIn: parent
            svg: clockSvg
            elementId: "HandCenter"
        }
    }

    KSvg.FrameSvgItem {
        id: timezoneBg
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 0
        }
        imagePath: "widgets/background"
        width: childrenRect.width + margins.left + margins.right
        height: childrenRect.height + margins.top + margins.bottom
        visible: showTimezone

        PlasmaComponents.Label {
            id: timezoneText
            x: parent.margins.left
            y: parent.margins.top
            text: timezoneString
        }
    }



    Component.onCompleted: {
        updateAllHands()
    }

    function normalizeRotation(angle) {
        angle = angle % 360;
        return angle < 0 ? angle + 360 : angle;
    }

    function initializeHands() {
        // Inicializar directamente a 0 grados
        hourHandShadow.rotation = 0
        hourHand.rotation = 0
        minuteHandShadow.rotation = 0
        minuteHand.rotation = 0
        
        if (showSecondsHand) {
            secondHandShadow.rotation = 0
            secondHand.rotation = 0
        }

        // Programar actualización a la posición real después de un breve retraso
        Qt.callLater(function() {
            var hourRotation = normalizeRotation(hours * 30 + (minutes/2))
            var minuteRotation = normalizeRotation(minutes * 6)
            var secondRotation = normalizeRotation(secondHandRotation)

            hourHandShadow.rotation = hourRotation
            hourHand.rotation = hourRotation
            minuteHandShadow.rotation = minuteRotation
            minuteHand.rotation = minuteRotation
            
            if (showSecondsHand) {
                secondHandShadow.rotation = secondRotation
                secondHand.rotation = secondRotation
            }
        })
    }
}
