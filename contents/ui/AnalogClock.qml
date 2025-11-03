import QtQuick 2.15
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: analogclock

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
    property string timezoneString: ""
    property real handScale: Math.min(width, height) / Math.max(face.nativeWidth, face.nativeHeight)

    Layout.minimumWidth: plasmoid.formFactor !== PlasmaCore.Types.Vertical ? height : Kirigami.Units.gridUnit
    Layout.minimumHeight: plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.gridUnit

    PlasmaCore.Svg {
        id: clockSvg
        imagePath: Qt.resolvedUrl("../images/sbb-clock.svg")
    }

    function updateAllHands() {
        // This logic was previously in the onDataChanged and onTriggered handlers
        hourHandShadow.updateRotation(hours, minutes, secondHandRotation)
        hourHand.updateRotation(hours, minutes, secondHandRotation)
        minuteHandShadow.updateRotation(hours, minutes, secondHandRotation)
        minuteHand.updateRotation(hours, minutes, secondHandRotation)

        if (showSecondsHand) {
            secondHandShadow.updateRotation(hours, minutes, secondHandRotation)
            secondHand.updateRotation(hours, minutes, secondHandRotation)
        }
    }

    // Call updates when the relevant properties from main.qml change
    onSmoothSecondsChanged: updateAllHands()
    onMinutesChanged: updateAllHands() // To update minute and hour hands

    Item {
        id: clock
        anchors.fill: parent

        PlasmaCore.SvgItem {
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

        PlasmaCore.SvgItem {
            id: center
            width: nativeWidth * (face.width / face.nativeWidth)
            height: nativeHeight * (face.width / face.nativeWidth)
            anchors.centerIn: parent
            svg: clockSvg
            elementId: "HandCenter"
        }
    }

    PlasmaCore.FrameSvgItem {
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

    Timer {
        id: smoothSecondsTimer
        interval: 50  // Actualizar cada 50ms
        repeat: true
        running: showSecondsHand
        onTriggered: {
            var now = new Date()
            var currentSeconds = now.getSeconds()
            var currentMilliseconds = now.getMilliseconds()

            // Calcular segundos suaves con mayor precisión
            smoothSeconds = currentSeconds + (currentMilliseconds / 1000)

            // Actualizar todas las manecillas
            hourHandShadow.updateRotation(hours, minutes, secondHandRotation)
            hourHand.updateRotation(hours, minutes, secondHandRotation)
            minuteHandShadow.updateRotation(hours, minutes, secondHandRotation)
            minuteHand.updateRotation(hours, minutes, secondHandRotation)

            if (showSecondsHand) {
                secondHandShadow.updateRotation(hours, minutes, secondHandRotation)
                secondHand.updateRotation(hours, minutes, secondHandRotation)
            }
        }
    }

    Component.onCompleted: {
        smoothSecondsTimer.triggered()
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
