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

    /**
     * Normaliza un ángulo al rango [0, 360)
     * 
     * Asegura que todos los ángulos estén en el rango estándar de 0 a 360 grados,
     * facilitando las comparaciones y evitando valores negativos o mayores a 360.
     * 
     * @param angle - Ángulo en grados (puede ser negativo o > 360)
     * @returns Ángulo normalizado en el rango [0, 360)
     * 
     * Ejemplos:
     *   normalizeRotation(370) → 10
     *   normalizeRotation(-30) → 330
     *   normalizeRotation(720) → 0
     */
    function normalizeRotation(angle) {
        angle = angle % 360;
        return angle < 0 ? angle + 360 : angle;
    }

    // Propiedades para gestionar la rotación y evitar saltos visuales al iniciar
    property real targetRotation: 0
    property bool isInitializing: true  // Previene animación desde 0° al cargar el widget

    /**
     * Calcula el ángulo de rotación apropiado para cada tipo de manecilla
     * 
     * Fórmulas matemáticas:
     * - Manecilla de hora: 30°/hora (360°÷12 horas) + 0.5°/minuto (ajuste fino)
     *   Ejemplo: 3:30 → (3 × 30) + (30 ÷ 2) = 90° + 15° = 105°
     * 
     * - Manecilla de minutos: 6°/minuto (360°÷60 minutos)
     *   Ejemplo: 30 minutos → 30 × 6 = 180°
     * 
     * - Manecilla de segundos: Calculada en main.qml según el modo (SBB/Normal/Tick)
     *   Modo SBB: Recorre 360° en 59 segundos, pausa en el segundo 60
     * 
     * @param hours - Hora actual (0-23)
     * @param minutes - Minutos actuales (0-59)
     * @param secondHandRotation - Rotación del segundero (calculada externamente)
     * @returns Ángulo normalizado en grados (0-360)
     */
    function calculateRotation(hours, minutes, secondHandRotation) {
        // Durante la inicialización, mantener en 0 grados para evitar saltos visuales
        if (isInitializing) {
            return 0
        }

        // Calcular rotación basada en el tipo de manecilla (identificada por elementId)
        return normalizeRotation(
            elementId === "HourHand" ? (hours * 30 + minutes/2) :
            elementId === "HourHandShadow" ? (hours * 30 + minutes/2) :
            elementId === "MinuteHand" ? (minutes * 6) :
            elementId === "MinuteHandShadow" ? (minutes * 6) :
            elementId === "SecondHand" ? secondHandRotation :
            elementId === "SecondHandShadow" ? secondHandRotation : 0
        )
    }

    /**
     * Actualiza la rotación de la manecilla con los valores actuales de tiempo
     * 
     * Esta función es llamada desde AnalogClock.qml cada vez que cambia el tiempo.
     * Calcula la nueva rotación objetivo y gestiona la transición desde el estado
     * de inicialización al estado normal de funcionamiento.
     * 
     * @param hours - Hora actual (0-23)
     * @param minutes - Minutos actuales (0-59)
     * @param secondHandRotation - Rotación del segundero
     */
    function updateRotation(hours, minutes, secondHandRotation) {
        // Calcular nueva rotación objetivo
        targetRotation = calculateRotation(hours, minutes, secondHandRotation)

        // Transición de inicialización a estado normal (se ejecuta solo una vez)
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
                direction: RotationAnimation.Clockwise
                duration: {
                    // En modo Tick (2), usar animación rápida para el segundero
                    if (handAnimationMode === 2 && elementId.indexOf("Second") > -1) {
                        return Kirigami.Units.shortDuration
                    }
                    return Kirigami.Units.longDuration
                }
                easing.type: {
                    // En modo Tick (2), usar efecto de rebote elástico para el segundero
                    if (handAnimationMode === 2 && elementId.indexOf("Second") > -1) {
                        return Easing.OutElastic
                    }
                    return Easing.InOutQuad
                }
            }
        }
    }
}
