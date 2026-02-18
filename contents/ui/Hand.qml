/*
    SPDX-FileCopyrightText: 2012 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg

KSvg.SvgItem {
    id: handRoot

    property alias rotation: handRotation.angle
    property real svgScale: 1.0
    property string rotationCenterHintId
    property string handIdentifier: elementId
    readonly property double horizontalRotationCenter: {
        if (svg.hasElement(rotationCenterHintId)) {
            var hintedCenterRect = svg.elementRect(rotationCenterHintId),
                handRect = svg.elementRect(elementId),
                hintedX = hintedCenterRect.x - handRect.x + hintedCenterRect.width/2;
            return Math.round(hintedX * svgScale) + Math.round(hintedX * svgScale) % 2;
        }
        return width/2;
    }
    readonly property double verticalRotationCenter: {
        if (svg.hasElement(rotationCenterHintId)) {
            var hintedCenterRect = svg.elementRect(rotationCenterHintId),
                handRect = svg.elementRect(elementId),
                hintedY = hintedCenterRect.y - handRect.y + hintedCenterRect.height/2;
            return Math.round(hintedY * svgScale) + width % 2;
        }
        return width/2;
    }

    property real _fixedWidth: naturalSize.width * svgScale
    property real _fixedHeight: naturalSize.height * svgScale

    width: Math.round(_fixedWidth) + (Math.round(_fixedWidth) % 2)
    height: Math.round(_fixedHeight) + (Math.round(_fixedHeight) % 2)

    anchors {
        top: clock.verticalCenter
        topMargin: -verticalRotationCenter
        left: clock.horizontalCenter
        leftMargin: -horizontalRotationCenter
    }

    svg: clockSvg

    // Propiedades de rotación recibidas desde el componente padre
    property real hours: 0
    property real minutes: 0
    property real secondHandRotation: 0
    property int handAnimationMode: 0

    function normalizeRotation(angle) {
        angle = angle % 360;
        return angle < 0 ? angle + 360 : angle;
    }

    property real targetRotation: 0
    property bool isInitializing: true

    function calculateRotation(hours, minutes, secondHandRotation) {
        if (isInitializing) {
            return 0
        }

        // Usar lowercase para comparaciones de elementId robustas
        let id = elementId.toLowerCase()

        if (id.indexOf("hour") !== -1) return normalizeRotation(hours * 30 + minutes/2);
        if (id.indexOf("minute") !== -1) return normalizeRotation(minutes * 6);
        if (id.indexOf("second") !== -1) return normalizeRotation(secondHandRotation);
        
        // El resto de elementos (como junction o caps) no rotan
        return 0;
    }

    function updateRotation(hours, minutes, secondHandRotation) {
        targetRotation = calculateRotation(hours, minutes, secondHandRotation)
        if (isInitializing) {
            Qt.callLater(function() {
                isInitializing = false
            })
        }
    }

    rotation: targetRotation

    Component.onCompleted: {
        targetRotation = 0
    }

    transform: Rotation {
        id: handRotation
        origin {
            x: handRoot.horizontalRotationCenter
            y: handRoot.verticalRotationCenter
        }
        Behavior on angle {
            RotationAnimation {
                direction: RotationAnimation.Clockwise
                duration: {
                    if (handAnimationMode === 2 && elementId.indexOf("Second") > -1) {
                        return Kirigami.Units.shortDuration
                    }
                    return Kirigami.Units.longDuration
                }
                easing.type: {
                    if (handAnimationMode === 2 && elementId.indexOf("Second") > -1) {
                        return Easing.OutElastic
                    }
                    return Easing.InOutQuad
                }
            }
        }
    }
}
