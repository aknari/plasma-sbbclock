/*
    SPDX-FileCopyrightText: 2015 Martin Klapetek <mklapetek@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1

import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: toolTipContentItem

    property int preferredTextWidth: Kirigami.Units.gridUnit * 20

    implicitWidth: mainLayout.implicitWidth + Kirigami.Units.gridUnit
    implicitHeight: mainLayout.implicitHeight + Kirigami.Units.gridUnit

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    ColumnLayout {
        id: mainLayout

        anchors {
            left: parent.left
            top: parent.top
            margins: Kirigami.Units.largeSpacing
        }

        spacing: 0

        Kirigami.Heading {
            id: tooltipMaintext

            Layout.minimumWidth: Math.min(implicitWidth, toolTipContentItem.preferredTextWidth)
            Layout.maximumWidth: toolTipContentItem.preferredTextWidth

            level: 3
            elide: Text.ElideRight
            // keep this consistent with toolTipMainText in analog-clock
            property var mainText: clocks.visible ? Qt.formatDate(root.currentDateTimeInSelectedTimeZone, Qt.locale(), Locale.LongFormat) : Qt.locale().toString(root.currentDateTimeInSelectedTimeZone, "dddd")
            property bool anyTimezoneSet: !!mainText
            text: anyTimezoneSet ? mainText : i18nc("@label main text shown in digital clock's tooltip when timezone is missing", "Time zone is not set")
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            id: tooltipSubtext

            Layout.minimumWidth: Math.min(implicitWidth, toolTipContentItem.preferredTextWidth)
            Layout.maximumWidth: toolTipContentItem.preferredTextWidth
            maximumLineCount: 2
            wrapMode: Text.Wrap

            property var subText: {
                if (plasmoid.configuration.showSeconds === 0) {
                    return Qt.formatDate(root.currentDateTimeInSelectedTimeZone, Qt.locale(), root.dateFormatString);
                } else {
                    return "%1\n%2"
                        .arg(Qt.formatTime(root.currentDateTimeInSelectedTimeZone, Qt.locale(), Locale.LongFormat))
                        .arg(Qt.formatDate(root.currentDateTimeInSelectedTimeZone, Qt.locale(), root.dateFormatString))
                }
            }
            text: tooltipMaintext.anyTimezoneSet ? subText : i18nc("@label sub text shown in digital clock's tooltip when timezone is missing", "Click the clock icon to open Date & Time settings and set a time zone.")
            opacity: 0.75
            visible: !clocks.visible
        }

        PlasmaComponents.Label {
            id: tooltipSubLabelText
            Layout.minimumWidth: Math.min(implicitWidth, toolTipContentItem.preferredTextWidth)
            Layout.maximumWidth: toolTipContentItem.preferredTextWidth
            text: root.monthView && root.monthView.todayAuxilliaryText ? root.monthView.todayAuxilliaryText : ""
            textFormat: Text.PlainText
            opacity: 0.75
            visible: !clocks.visible && text.length > 0
        }

        GridLayout {
            id: clocks

            Layout.minimumWidth: Math.min(implicitWidth, toolTipContentItem.preferredTextWidth)
            Layout.maximumWidth: toolTipContentItem.preferredTextWidth
            Layout.minimumHeight: childrenRect.height
            visible: timeZoneRepeater.count > 0 && tooltipMaintext.anyTimezoneSet
            columns: 2
            rowSpacing: 0

            Repeater {
                id: timeZoneRepeater

                model: {
                    var zones = root.selectedTimeZonesDeduplicatingExplicitLocalTimeZone();
                    var array = [];
                    for (var i = 0; i < zones.length; i++) {
                        array.push(zones[i]);
                        array.push(zones[i]);
                    }
                    return array;
                }

                PlasmaComponents.Label {
                    property int itemIndex: index
                    property string timeZone: modelData

                    // Layout.fillWidth is buggy here
                    Layout.alignment: itemIndex % 2 === 0 ? Qt.AlignRight : Qt.AlignLeft
                    text: {
                        if (itemIndex % 2 === 0) {
                            return i18nc("@label %1 is a city or time zone name", "%1:", root.displayStringForTimeZone(timeZone));
                        } else {
                            return root.timeForZone(timeZone, plasmoid.configuration.showSeconds > 0);
                        }
                    }
                    textFormat: Text.PlainText
                    font.weight: root.timeZoneResolvesToLastSelectedTimeZone(timeZone) ? Font.Bold : Font.Normal
                    wrapMode: Text.NoWrap
                    elide: Text.ElideNone
                }
            }
        }
    }
}
