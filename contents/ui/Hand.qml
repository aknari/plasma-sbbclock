/*
    SPDX-FileCopyrightText: 2012 Viranch Mehta <viranch.mehta@gmail.com>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

PlasmaCore.SvgItem {
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

    property real _fixedWidth: nativeWidth * svgScale
    property real _fixedHeight: nativeHeight * svgScale

    width: Math.round(_fixedWidth) + (Math.round(_fixedWidth) % 2)
    height: Math.round(_fixedHeight) + (Math.round(_fixedHeight) % 2)

    anchors {
        top: clock.verticalCenter
        topMargin: -verticalRotationCenter
        left: clock.horizontalCenter
        leftMargin: -horizontalRotationCenter
    }

    svg: clockSvg

    // Propiedades de rotación
    property real hours: 0
    property real minutes: 0
    property real secondHandRotation: 0

    // Función para normalizar ángulos
    function normalizeRotation(angle) {
        angle = angle % 360;
        return angle < 0 ? angle + 360 : angle;
    }

    // Propiedades para gestionar la rotación
    property real targetRotation: 0
    property bool isInitializing: true

    // Función de cálculo de rotación
    function calculateRotation(hours, minutes, secondHandRotation) {
        // Durante la inicialización, mantener en 0 grados
        if (isInitializing) {
            return 0
        }

        // Calcular rotación basada en el tipo de manecilla
        return normalizeRotation(
            elementId === "HourHand" ? (hours * 30 + minutes/2) :
            elementId === "HourHandShadow" ? (hours * 30 + minutes/2) :
            elementId === "MinuteHand" ? (minutes * 6) :
            elementId === "MinuteHandShadow" ? (minutes * 6) :
            elementId === "SecondHand" ? secondHandRotation :
            elementId === "SecondHandShadow" ? secondHandRotation : 0
        )
    }

    // Función de actualización de rotación
    function updateRotation(hours, minutes, secondHandRotation) {
        // Calcular nueva rotación
        targetRotation = calculateRotation(hours, minutes, secondHandRotation)

        // Transición de inicialización a estado normal
        if (isInitializing) {
            Qt.callLater(function() {
                isInitializing = false
            })
        }
    }

    // Lógica de rotación
    rotation: targetRotation

    // Inicialización al completar el componente
    Component.onCompleted: {
        targetRotation = 0
    }

    // Transformación de rotación
    transform: Rotation {
        id: handRotation
        origin {
            x: handRoot.horizontalRotationCenter
            y: handRoot.verticalRotationCenter
        }
        Behavior on angle {
            RotationAnimation {
                duration: Kirigami.Units.longDuration
                direction: RotationAnimation.Clockwise
                alwaysRunToEnd: true
            }
        }
    }
}
