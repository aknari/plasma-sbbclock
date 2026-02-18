/*
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.kcmutils as KCM
import Qt.labs.platform as Platform
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: kcmRoot

    property bool cfg_useDigitalMode
    property bool cfg_showDate
    property bool cfg_showSecondHand
    property bool cfg_showTimezoneString
    property string cfg_timeFormat
    property string cfg_dateFormat
    property int cfg_timeFontSize
    property int cfg_dateFontSize
    property bool cfg_timeIsBold
    property bool cfg_dateIsBold
    property bool cfg_useCustomColors
    property color cfg_timeColor
    property color cfg_dateColor
    property color cfg_eventColor
    property bool cfg_showEventColor
    property bool cfg_transparentBackground
    property bool cfg_blinkingTimeSeparator
    property bool cfg_playHourGong
    property string cfg_hourSignalSound
    property int cfg_hourSignalStartTime
    property int cfg_hourSignalEndTime
    property double cfg_hourSignalAdvance
    property int cfg_volumeSlider
    property string cfg_fontFamily
    property int cfg_handAnimationMode


    property string cfg_dateDisplayFormat: cfg_dateDisplayFormatDefault
    property bool cfg_displayTimezoneAsCode: cfg_displayTimezoneAsCodeDefault
    property string cfg_displayTimezoneFormat: cfg_displayTimezoneFormatDefault
    property var cfg_enabledCalendarPlugins: cfg_enabledCalendarPluginsDefault
    property int cfg_firstDayOfWeek: cfg_firstDayOfWeekDefault
    property string cfg_lastSelectedTimezone: cfg_lastSelectedTimezoneDefault
    property bool cfg_pin: cfg_pinDefault
    property var cfg_selectedTimeZones: cfg_selectedTimeZonesDefault
    property bool cfg_showLocalTimezone: cfg_showLocalTimezoneDefault
    property bool cfg_showSeconds: cfg_showSecondsDefault
    property bool cfg_showWeekNumbers: cfg_showWeekNumbersDefault
    property bool cfg_timeFormatWithSeconds: cfg_timeFormatWithSecondsDefault
    property bool cfg_use24hFormat: cfg_use24hFormatDefault

    readonly property bool cfg_blinkingTimeSeparatorDefault: false
    readonly property color cfg_dateColorDefault: "#ffffff"
    readonly property color cfg_eventColorDefault: "#ff0000"
    readonly property bool cfg_showEventColorDefault: false
    readonly property string cfg_dateDisplayFormatDefault: "yyyy-MM-dd"
    readonly property int cfg_dateFontSizeDefault: 12
    readonly property string cfg_dateFormatDefault: "yyyy-MM-dd"
    readonly property bool cfg_dateIsBoldDefault: false
    readonly property bool cfg_displayTimezoneAsCodeDefault: false
    readonly property string cfg_displayTimezoneFormatDefault: ""
    readonly property var cfg_enabledCalendarPluginsDefault: []
    readonly property int cfg_firstDayOfWeekDefault: 1
    readonly property string cfg_fontFamilyDefault: "Noto Sans"
    readonly property double cfg_hourSignalAdvanceDefault: 0.0
    readonly property int cfg_hourSignalEndTimeDefault: 0
    readonly property string cfg_hourSignalSoundDefault: ""
    readonly property int cfg_hourSignalStartTimeDefault: 0
    readonly property string cfg_lastSelectedTimezoneDefault: ""
    readonly property bool cfg_pinDefault: false
    readonly property bool cfg_playHourGongDefault: false
    readonly property var cfg_selectedTimeZonesDefault: []
    readonly property bool cfg_showDateDefault: true
    readonly property bool cfg_showLocalTimezoneDefault: false
    readonly property bool cfg_showSecondHandDefault: true
    readonly property bool cfg_showSecondsDefault: false
    readonly property bool cfg_showTimezoneStringDefault: false
    readonly property bool cfg_showWeekNumbersDefault: false
    readonly property color cfg_timeColorDefault: "#ffffff"
    readonly property int cfg_timeFontSizeDefault: 24
    readonly property string cfg_timeFormatDefault: "HH:mm"
    readonly property bool cfg_timeFormatWithSecondsDefault: false
    readonly property bool cfg_timeIsBoldDefault: true
    readonly property bool cfg_transparentBackgroundDefault: false
    readonly property bool cfg_use24hFormatDefault: true
    readonly property bool cfg_useCustomColorsDefault: false
    readonly property bool cfg_useDigitalModeDefault: true
    readonly property int cfg_volumeSliderDefault: 100
    readonly property int cfg_handAnimationModeDefault: 0


    Kirigami.FormLayout {
        id: generalPage

        QQC2.CheckBox {
                    id: useDigitalMode
                    text: i18n("Use Digital Mode")
                    checked: cfg_useDigitalMode
                    onCheckedChanged: cfg_useDigitalMode = checked
                }

    QQC2.CheckBox {
            id: showDateCheckBox
            text: i18n("Show Date")
            checked: cfg_showDate
            enabled: useDigitalMode.checked
            onCheckedChanged: cfg_showDate = checked
        }

        QQC2.CheckBox {
                    id: showSecondHandCheckBox
                    text: i18n("Show Second Hand")
                    checked: cfg_showSecondHand
                    enabled: !useDigitalMode.checked
                    onCheckedChanged: cfg_showSecondHand = checked
                }

        QQC2.CheckBox {
                    id: showTimezoneCheckBox
                    text: i18n("Show Timezone")
                    checked: cfg_showTimezoneString
                    onCheckedChanged: cfg_showTimezoneString = checked
                }

        QQC2.Label {
            text: i18n("Hand Animation Style:")
            visible: !useDigitalMode.checked
            Kirigami.FormData.label: i18n("Animation:")
        }

        QQC2.ComboBox {
            id: handAnimationModeCombo
            visible: !useDigitalMode.checked
            enabled: !useDigitalMode.checked
            model: [
                i18n("SBB (Swiss Railway) - 59 seconds + pause"),
                i18n("Smooth - Continuous 60 seconds"),
                i18n("Tick - Discrete jumps with bounce"),
                i18n("DB (Deutsche Bahn) - Elastic 59 seconds + pause")
            ]
            currentIndex: cfg_handAnimationMode
            onCurrentIndexChanged: cfg_handAnimationMode = currentIndex
        }


        // Time Format section
    QQC2.Label {
                    text: i18n("Time Format:")
                    visible: useDigitalMode.checked
                }

    QQC2.TextField {
                    id: timeFormatField
                    text: cfg_timeFormat
                    enabled: useDigitalMode.checked
                    onTextChanged: cfg_timeFormat = text
                }

    QQC2.Label {
                    text: i18n("Date Format:")
                    visible: useDigitalMode.checked && showDateCheckBox.checked
                }

    QQC2.TextField {
                    id: dateFormatField
                    text: cfg_dateFormat
                    enabled: useDigitalMode.checked && showDateCheckBox.checked
                    onTextChanged: cfg_dateFormat = text
                }

        // Font section
    QQC2.Label {
                    text: i18n("Time Font Size:")
                    visible: useDigitalMode.checked
                }

    QQC2.SpinBox {
                    id: timeFontSizeSpinBox
                    from: 1
                    to: 999
                    enabled: useDigitalMode.checked
                    value: cfg_timeFontSize
                    onValueChanged: cfg_timeFontSize = value
                }

    QQC2.Label {
                    text: i18n("Date Font Size:")
                    visible: useDigitalMode.checked && showDateCheckBox.checked
                }

    QQC2.SpinBox {
                    id: dateFontSizeSpinBox
                    from: 1
                    to: 999
                    enabled: useDigitalMode.checked && showDateCheckBox.checked
                    value: cfg_dateFontSize
                    onValueChanged: cfg_dateFontSize = value
                }

    QQC2.Label {
                    text: i18n("Font Family:")
                    visible: useDigitalMode.checked
                }

    QQC2.ComboBox {
                    id: fontFamilyComboBox
                    model: filteredFonts
                    enabled: useDigitalMode.checked
                    currentIndex: model.indexOf(cfg_fontFamily) !== -1 ? model.indexOf(cfg_fontFamily) : model.indexOf("Noto Sans")
                    onCurrentTextChanged: cfg_fontFamily = currentText
                }

    QQC2.CheckBox {
                    id: monoFontsCheckBox
                    text: i18n("Show only monospace fonts")
                    enabled: useDigitalMode.checked
                    checked: onlyMonoFonts
                    onCheckedChanged: {
                        onlyMonoFonts = checked;
                        var currentFont = fontFamilyComboBox.currentText;
                        fontFamilyComboBox.model = filteredFonts;
                        var newIndex = fontFamilyComboBox.model.indexOf(currentFont);
                        if (newIndex !== -1) {
                            fontFamilyComboBox.currentIndex = newIndex;
                        } else {
                            fontFamilyComboBox.currentIndex = 0;
                        }
                    }
                }

        // Style section
    QQC2.Label {
                    text: i18n("Time Style:")
                    visible: useDigitalMode.checked
                }

    QQC2.CheckBox {
                    id: timeIsBoldCheckBox
                    text: i18n("Bold")
                    enabled: useDigitalMode.checked
                    checked: cfg_timeIsBold
                    onCheckedChanged: cfg_timeIsBold = checked
                }

    QQC2.Label {
                    text: i18n("Date Style:")
                    visible: useDigitalMode.checked && showDateCheckBox.checked
                }

    QQC2.CheckBox {
                    id: dateIsBoldCheckBox
                    text: i18n("Bold")
                    enabled: useDigitalMode.checked && showDateCheckBox.checked
                    checked: cfg_dateIsBold
                    onCheckedChanged: cfg_dateIsBold = checked
                }

        // Color options
        QQC2.Label {
            text: i18n("Quick Presets:")
            visible: useDigitalMode.checked
            Kirigami.FormData.label: i18n("Color Presets:")
        }

        Flow {
            Layout.fillWidth: true
            visible: useDigitalMode.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Classic")
                onClicked: applyColorPreset("classic")
            }
            QQC2.Button {
                text: i18n("Nordic")
                onClicked: applyColorPreset("nordic")
            }
            QQC2.Button {
                text: i18n("Warm")
                onClicked: applyColorPreset("warm")
            }
            QQC2.Button {
                text: i18n("Matrix")
                onClicked: applyColorPreset("matrix")
            }
            QQC2.Button {
                text: i18n("High Contrast")
                onClicked: applyColorPreset("contrast")
            }
        }

    QQC2.CheckBox {
                    id: useCustomColorsCheckBox
                    text: i18n("Use Custom Colors")
                    enabled: useDigitalMode.checked
                    Kirigami.FormData.label: i18n("Colors:")
                    checked: cfg_useCustomColors
                    onCheckedChanged: cfg_useCustomColors = checked
                }

                RowLayout {
                    enabled: useDigitalMode.checked && useCustomColorsCheckBox.checked
                    spacing: 10

    QQC2.Button {
                        text: i18n("Time Color")
                        onClicked: timeColorDialog.open()
                    }

                    Rectangle {
                        id: timeColorPreview
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: timeColorField.text || "#ffffff"
                        border.color: "gray"
                        border.width: 1
                        radius: 4

    QQC2.TextField {
                            id: timeColorField
                            visible: false
                            text: cfg_timeColor || "#ffffff"
                            readOnly: true
                        }
                    }

    QQC2.Label {
                        text: timeColorField.text
                        color: "gray"
                        font.family: "monospace"
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    enabled: useDigitalMode.checked && useCustomColorsCheckBox.checked && showDateCheckBox.checked
                    spacing: 10

    QQC2.Button {
                        text: i18n("Date Color")
                        onClicked: dateColorDialog.open()
                    }

                    Rectangle {
                        id: dateColorPreview
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: dateColorField.text || "#ffffff"
                        border.color: "gray"
                        border.width: 1
                        radius: 4

    QQC2.TextField {
                            id: dateColorField
                            visible: false
                            text: cfg_dateColor || "#ffffff"
                            readOnly: true
                        }
                    }

    QQC2.Label {
                        text: dateColorField.text
                        color: "gray"
                        font.family: "monospace"
                        Layout.fillWidth: true
                    }
                }

    QQC2.CheckBox {
                    id: showEventColorCheckBox
                    text: i18n("Use another color if there is an event today (requires expanding calendar)")
                    enabled: useDigitalMode.checked && showDateCheckBox.checked
                    checked: cfg_showEventColor
                    onCheckedChanged: cfg_showEventColor = checked
                }

                RowLayout {
                    enabled: useDigitalMode.checked && showDateCheckBox.checked && showEventColorCheckBox.checked
                    spacing: 10

    QQC2.Button {
                        text: i18n("Event Color")
                        onClicked: eventColorDialog.open()
                    }

                    Rectangle {
                        id: eventColorPreview
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        color: eventColorField.text || "#ff0000"
                        border.color: "gray"
                        border.width: 1
                        radius: 4

    QQC2.TextField {
                            id: eventColorField
                            visible: false
                            text: cfg_eventColor || "#ff0000"
                            readOnly: true
                        }
                    }

    QQC2.Label {
                        text: eventColorField.text
                        color: "gray"
                        font.family: "monospace"
                        Layout.fillWidth: true
                    }
                }

    QQC2.CheckBox {
                    id: transparentBackgroundCheckBox
                    text: i18n("Transparent Background")
                    enabled: useDigitalMode.checked
                    checked: cfg_transparentBackground
                    onCheckedChanged: cfg_transparentBackground = checked
                }

    QQC2.CheckBox {
                    id: blinkingTimeSeparatorCheckBox
                    text: i18n("Blinking Time Separator")
                    enabled: useDigitalMode.checked
                    checked: cfg_blinkingTimeSeparator
                    onCheckedChanged: cfg_blinkingTimeSeparator = checked
                }

        Item { Kirigami.FormData.isSection: true }

        // Hour Signal options
    QQC2.CheckBox {
                    id: playHourGongCheckBox
                    text: i18n("Play Hour Signal")
                    Kirigami.FormData.label: i18n("Hour Signal:")
                    checked: cfg_playHourGong
                    onCheckedChanged: cfg_playHourGong = checked
                }

                RowLayout {
                    enabled: playHourGongCheckBox.checked
                    Kirigami.FormData.label: i18n("Sound File:")

    QQC2.TextField {
                        id: hourSignalSoundField
                        Layout.fillWidth: true
                        text: cfg_hourSignalSound
                        onTextChanged: cfg_hourSignalSound = text
                    }

    QQC2.Button {
                        text: i18n("Browse...")
                        onClicked: fileDialog.open()
                    }
                }

    QQC2.SpinBox {
                    id: hourSignalStartTimeSpinBox
                    from: 0
                    to: 23
                    value: cfg_hourSignalStartTime
                    enabled: playHourGongCheckBox.checked
                    Kirigami.FormData.label: i18n("Start Time:")
                    onValueChanged: cfg_hourSignalStartTime = value
                }

    QQC2.SpinBox {
                    id: hourSignalEndTimeSpinBox
                    from: 0
                    to: 23
                    value: cfg_hourSignalEndTime
                    enabled: playHourGongCheckBox.checked
                    Kirigami.FormData.label: i18n("End Time:")
                    onValueChanged: cfg_hourSignalEndTime = value
                }

    QQC2.SpinBox {
                    id: hourSignalAdvanceSpinBox
                    from: 0
                    to: 12 // 6.0 seconds * 2
                    value: Math.round(cfg_hourSignalAdvance * 2)
                    enabled: playHourGongCheckBox.checked
                    Kirigami.FormData.label: i18n("Advance (seconds):")
                    
                    textFromValue: function(value, locale) {
                        return (value / 2.0).toFixed(1)
                    }
                    
                    valueFromText: function(text, locale) {
                        return Math.round(parseFloat(text) * 2)
                    }

                    onValueChanged: cfg_hourSignalAdvance = value / 2.0
                }

    QQC2.Slider {
                    id: volumeSlider
                    from: 0
                    to: 100
                    value: cfg_volumeSlider
                    enabled: playHourGongCheckBox.checked
                    Kirigami.FormData.label: i18n("Volume:")
                    onValueChanged: cfg_volumeSlider = value
                }
    }

    function filterFonts() {
        if (!onlyMonoFonts) return allFonts;

        var monoFonts = [];
        var metrics = Qt.createQmlObject('import QtQuick 2.15; FontMetrics {}', kcmRoot);

        for (var i = 0; i < allFonts.length; i++) {
            metrics.font.family = allFonts[i];
            var iWidth = metrics.advanceWidth("i");
            var MWidth = metrics.advanceWidth("M");
            if (Math.abs(iWidth - MWidth) < 0.1) {
                monoFonts.push(allFonts[i]);
            }
        }
        metrics.destroy();
        return monoFonts;
    }

    property bool onlyMonoFonts: false
    readonly property var allFonts: Qt.fontFamilies();
    property var filteredFonts: kcmRoot.filterFonts();

    ColorDialog {
        id: timeColorDialog
        title: i18n("Choose Time Color")
        selectedColor: timeColorField.text || "#ffffff"
        onAccepted: {
            var color = selectedColor.toString()
            timeColorField.text = color
            cfg_timeColor = color
        }
    }

    ColorDialog {
        id: dateColorDialog
        title: i18n("Choose Date Color")
        selectedColor: dateColorField.text || "#ffffff"
        onAccepted: {
            var color = selectedColor.toString()
            dateColorField.text = color
            cfg_dateColor = color
        }
    }

    ColorDialog {
        id: eventColorDialog
        title: i18n("Choose Event Color")
        selectedColor: eventColorField.text || "#ff0000"
        onAccepted: {
            var color = selectedColor.toString()
            eventColorField.text = color
            cfg_eventColor = color
        }
    }

    FileDialog {
        id: fileDialog
        title: i18n("Select Sound File")
        nameFilters: ["Sound files (*.wav *.mp3 *.ogg)", "All files (*)"]
        onAccepted: {
            if (fileDialog.selectedFile) {
                hourSignalSoundField.text = fileDialog.selectedFile
            }
        }
    }

    function applyColorPreset(presetName) {
        // Activar colores personalizados automáticamente
        cfg_useCustomColors = true;
        
        switch(presetName) {
            case "classic":
                cfg_timeColor = "#FFFFFF"; // Blanco
                cfg_dateColor = "#CCCCCC"; // Gris claro
                timeColorField.text = cfg_timeColor;
                dateColorField.text = cfg_dateColor;
                break;
            case "nordic":
                cfg_timeColor = "#88C0D0"; // Polar Night Blue
                cfg_dateColor = "#81A1C1"; // Frost Blue
                timeColorField.text = cfg_timeColor;
                dateColorField.text = cfg_dateColor;
                break;
            case "warm":
                cfg_timeColor = "#D08770"; // Aurora Orange
                cfg_dateColor = "#EBCB8B"; // Aurora Yellow
                timeColorField.text = cfg_timeColor;
                dateColorField.text = cfg_dateColor;
                break;
            case "matrix":
                cfg_timeColor = "#00FF00"; // Neon Green
                cfg_dateColor = "#008F11"; // Darker Green
                timeColorField.text = cfg_timeColor;
                dateColorField.text = cfg_dateColor;
                break;
            case "contrast":
                cfg_timeColor = "#FFFFFF"; // White
                cfg_dateColor = "#FFFF00"; // Yellow
                timeColorField.text = cfg_timeColor;
                dateColorField.text = cfg_dateColor;
                break;
        }
    }
}
