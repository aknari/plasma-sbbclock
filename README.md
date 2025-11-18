# SBB Clock Plasmoid for KDE Plasma 6

A versatile and customizable analog/digital clock widget for the KDE Plasma 6 desktop, inspired by the iconic Swiss Federal Railways (SBB) clock design. This plasmoid is based on the default KDE digital clock and extends it with new features and customization options.

## Features

*   **Analog and Digital Modes**: Seamlessly switch between a classic analog view and a modern digital display.
*   **SBB-inspired Design**: The analog clock features the distinctive red second hand with a final pause, mimicking the Swiss railway clocks.
*   **Customizable Display**:
    *   Show or hide the date.
    *   Show or hide the second hand on the analog clock.
    *   Display the current timezone (as code, city name, or UTC offset).
    *   Adjust fonts, colors, and sizes for both time and date.
*   **Integrated Calendar**: Clicking the widget opens a full calendar view with support for event plugins (e.g., Google Calendar, etc.).
*   **Hourly Chime**: Configure an audible signal (like a gong or the BBC pips) to play on the hour, with customizable start/end times and volume.
*   **Flexible Configuration**: A comprehensive settings dialog to personalize every aspect of the clock.

## Configuration

You can customize the SBB Clock plasmoid by right-clicking on it and selecting "Configure SBB Clock...".

The settings are organized into several categories:

### General

*   **Appearance**:
    *   Switch between **Analog** and **Digital** clock faces.
    *   Toggle the visibility of the **date**, **second hand**, and **timezone string**.
    *   Customize the **format** for both the time and the date (e.g., `h:mm A` for 12-hour time with AM/PM, or `hh:mm` for 24-hour time).
    *   Choose between **12-hour** and **24-hour** time formats, or have it follow your system's locale settings.
    *   For the digital clock, enable a **blinking time separator**.
    *   Customize **fonts**, **colors**, and **boldness** for time and date.
    *   Set a transparent background.
*   **Hourly Signal**:
    *   Enable or disable the **hourly chime**.
    *   Choose a sound file for the signal (comes with `gong.ogg` and `bbc_pips.ogg`).
    *   Set the time range (e.g., only from 8 AM to 10 PM) and volume for the chime.

### Calendar

*   **Display**:
    *   Show or hide week numbers.
    *   Set the first day of the week.
*   **Events**:
    *   Enable and configure calendar event plugins to see your appointments directly in the calendar view.

## Based On

This widget is based on the standard Digital Clock plasmoid provided by the KDE Plasma team. It retains all the original functionality while adding the SBB-inspired analog theme and other enhancements.
