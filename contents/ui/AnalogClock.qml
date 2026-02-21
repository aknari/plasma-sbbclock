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
        if (smoothSeconds >= 59) {
            return 0
        } else {
            return (smoothSeconds * (360/59))
        }
    }
    property bool showSecondsHand: Plasmoid.configuration.showSecondHand
    property bool showTimezone: Plasmoid.configuration.showTimezoneString
    property string timezoneString: ""
    
    property real handScale: (face.naturalSize.width > 0) ? (face.width / face.naturalSize.width) : (Math.min(width, height) / 200)

    Layout.minimumWidth: Plasmoid.formFactor !== PlasmaCore.Types.Vertical ? height : Kirigami.Units.gridUnit
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.gridUnit

    KSvg.Svg {
        id: clockSvg
        imagePath: handAnimationMode === 3 ? Qt.resolvedUrl("../images/db-clock.svg") : Qt.resolvedUrl("../images/sbb-clock.svg")
    }

    function updateAllHands() {
        hourHandShadow.updateRotation(hours, minutes, secondHandRotation)
        hourHand.updateRotation(hours, minutes, secondHandRotation)
        minuteHandShadow.updateRotation(hours, minutes, secondHandRotation)
        minuteHand.updateRotation(hours, minutes, secondHandRotation)
        if (showSecondsHand) {
            secondHandShadow.updateRotation(hours, minutes, secondHandRotation)
            secondHand.updateRotation(hours, minutes, secondHandRotation)
        }
    }

    onSmoothSecondsChanged: updateAllHands()
    onMinutesChanged: updateAllHands()
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
            id: minuteHandShadow
            elementId: "MinuteHandShadow"
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

        KSvg.SvgItem {
            id: junctionShadow
            visible: naturalSize.width > 0
            elementId: "JunctionShadow"
            svg: clockSvg
            width: naturalSize.width * handScale
            height: naturalSize.height * handScale
            anchors.centerIn: parent
        }

        Hand {
            id: hourHand
            elementId: "HourHand"
            rotationCenterHintId: "HourHandCenter"
            svgScale: handScale
        }

        Hand {
            id: minuteHand
            elementId: "MinuteHand"
            rotationCenterHintId: "MinuteHandCenter"
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
            width: naturalSize.width * handScale
            height: naturalSize.height * handScale
            anchors.centerIn: parent
            svg: clockSvg
            elementId: "HandCenter"
        }

        KSvg.SvgItem {
            id: junction
            visible: naturalSize.width > 0
            elementId: "Junction"
            svg: clockSvg
            width: naturalSize.width * handScale
            height: naturalSize.height * handScale
            anchors.centerIn: parent
        }
    }

    // Mantener timezoneBg fuera del reloj
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
        hourHandShadow.rotation = 0
        hourHand.rotation = 0
        minuteHandShadow.rotation = 0
        minuteHand.rotation = 0
        
        if (showSecondsHand) {
            secondHandShadow.rotation = 0
            secondHand.rotation = 0
        }

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
