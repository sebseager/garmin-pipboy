import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;

class PipBoyView extends WatchUi.WatchFace {

    // =================================================================================
    // Constants
    // =================================================================================

    // Colors
    var NO_COLOR = Graphics.COLOR_TRANSPARENT;
    var BG_COLOR = Graphics.COLOR_BLACK;
    var CRT_COLOR = 0x003355;
    var FG_COLOR = 0x00FFFF;
    var MAX_TEMP = 99999;

    // Fonts
    var TEMP_FONT = Graphics.FONT_SYSTEM_TINY;
    var TIME_FONT = Graphics.FONT_SYSTEM_NUMBER_HOT;
    var DAY_FONT = Graphics.FONT_SYSTEM_XTINY;
    var DATE_FONT = Graphics.FONT_SYSTEM_SMALL;

    // Measurements
    var CRT_FREQ = 3;
    var TEMP_VOFFSET = 40;
    var TEMP_BARLENGTH = 100;
    var TEMP_BARWIDTH = 2;
    var TIME_HOFFSET = 50;
    var TIME_VOFFSET = -3;
    var TIME_SQUEEZE = 16;
    var STATUS_VOFFSET = 20;
    var STATUS_BOXSIZE = 15;
    var STATUS_BOXMRGN = 5;

    // =================================================================================
    // Variables
    // =================================================================================

    var screenWidth;
    var screenHalfWidth;
    var screenHeight;
    var screenHalfHeight;
    var currentTemperature = MAX_TEMP;
    var hasMessages = false;
    var hasAlarms = false;
    var hasConnection = false;

    // Vitals
    var activeMinutes = 0;
    var activeMinutesGoal = 0;
    var caloriesBurned = 0;
    var caloriesBurnedGoal = 0;
    var steps = 0;
    var stepGoal = 0;
    var bodyBattery = 100;
    var stress = 0;

    // =================================================================================
    // Delegate Functions
    // =================================================================================

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        screenHalfWidth = screenWidth / 2;
        screenHalfHeight = screenHeight / 2;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.clear();
        drawCRT(dc);

        currentTemperature = 45; // TODO: DEBUG

        drawTemperature(dc);

        // TODO: Draw the sun/moon/cloud above temp

        drawTime(dc);
        drawStatus(dc);
        drawVitals(dc);

        // Set a black background
        dc.setColor(NO_COLOR, BG_COLOR);

        // // Get the current time and format it correctly
        // var timeFormat = "$1$:$2$";
        // var clockTime = System.getClockTime();
        // var hours = clockTime.hour;
        // if (!System.getDeviceSettings().is24Hour) {
        //     if (hours > 12) {
        //         hours = hours - 12;
        //     }
        // } else {
        //     if (Application.Properties.getValue("UseMilitaryFormat")) {
        //         timeFormat = "$1$$2$";
        //         hours = hours.format("%02d");
        //     }
        // }
        // var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // // Update the view
        // var view = View.findDrawableById("TimeLabel") as Text;
        // view.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        // view.setText(timeString);

        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        // Get anything we need from current weather
        if (Toybox has :Weather) {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                if (conditions.temperature != null) {
                    currentTemperature = conditions.temperature;
                }
            }
        }

        // Grab device settings
        var settings = System.getDeviceSettings();
        hasMessages = settings.notificationCount > 0;
        hasAlarms = settings.alarmCount > 0;
        hasConnection = settings.phoneConnected;

        // TODO: Grab user vitals
        // var userInfo = ActivityMonitor.getInfo();
        // if (userInfo != null) {
        //     activeMinutes = userInfo.activeMinutesWeek;
        //     activeMinutesGoal = userInfo.activeMinutesWeekGoal;
        //     steps = userInfo.steps;
        //     stepGoal = userInfo.stepGoal;
        //     stress = userInfo.stressScore;
        // }
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    // =================================================================================
    // Layout Helpers - only callable from onUpdate
    // =================================================================================

    // Draw the CRT effect
    function drawCRT(dc as Dc) as Void {
        dc.setColor(CRT_COLOR, NO_COLOR);
        for (var i = 0; i < screenHeight; i += CRT_FREQ) {
            dc.drawLine(0, i, screenWidth, i);
        }
    }

    // Draw the temperature in a bar across the top
    function drawTemperature(dc as Dc) as Void {
        if (currentTemperature < MAX_TEMP) {
            // Draw temperature text
            var str = Lang.format("$1$°", [currentTemperature.toNumber()]);
            var strHeight = dc.getFontHeight(TEMP_FONT);
            var strWidth = dc.getTextWidthInPixels(str, TEMP_FONT);
            var strHalfWidth = strWidth / 2;
            dc.setColor(FG_COLOR, NO_COLOR);
            dc.drawText(
                screenHalfWidth,
                TEMP_VOFFSET - strHeight / 2 - 2,
                TEMP_FONT,
                str,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            // Draw temperature bar on either side
            var barLength = (TEMP_BARLENGTH - strWidth) / 2;
            dc.setColor(FG_COLOR, FG_COLOR);
            dc.fillRectangle(
                screenHalfWidth - strHalfWidth - barLength - 4,
                TEMP_VOFFSET,
                barLength,
                TEMP_BARWIDTH
            );
            dc.fillRectangle(
                screenHalfWidth + strHalfWidth + 2,
                TEMP_VOFFSET,
                barLength,
                TEMP_BARWIDTH
            );
        } else {
            // Draw a full bar if no temperature is available
            dc.setColor(FG_COLOR, FG_COLOR);
            dc.fillRectangle(
                (screenWidth - TEMP_BARLENGTH) / 2, 
                TEMP_VOFFSET, 
                TEMP_BARLENGTH, 
                TEMP_BARWIDTH
            );
        }
    }

    // Draw the time and date
    function drawTime(dc as Dc) as Void {
        // Get the current time
        var time = System.getClockTime();
        if (!System.getDeviceSettings().is24Hour) {
            if (time.hour > 12) {
                time.hour = time.hour - 12;
            }
        }
        var hourStr = Lang.format("$1$", [time.hour.format("%02d")]);
        var minStr = Lang.format("$1$", [time.min.format("%02d")]);
        var strHeight = dc.getFontHeight(TIME_FONT);

        // Draw hours and minutes
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_HOFFSET,
            screenHalfHeight - strHeight + TIME_SQUEEZE + TIME_VOFFSET,
            TIME_FONT,
            hourStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
        dc.drawText(
            TIME_HOFFSET,
            screenHalfHeight - TIME_SQUEEZE + TIME_VOFFSET,
            TIME_FONT,
            minStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Get the current date
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayStr = today.day_of_week.toUpper();
        var dateStr = Lang.format("$1$", [today.day.format("%02d")]);
        var dayDims = dc.getTextDimensions(dayStr, DAY_FONT);
        var dateDims = dc.getTextDimensions(dateStr, DATE_FONT);
        var hpad = 8; // push day/date away from the time

        // Draw day of week with background rectangle
        dc.setColor(FG_COLOR, FG_COLOR);
        dc.fillRectangle(
            TIME_HOFFSET - dayDims[0] - hpad,
            screenHalfHeight - dayDims[1] + TIME_VOFFSET - 7,
            dayDims[0] + 6,
            dayDims[1] + 6
        );
        dc.setColor(BG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_HOFFSET - hpad + 2,
            screenHalfHeight - dayDims[1] + TIME_VOFFSET - 4,
            DAY_FONT,
            dayStr,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
        
        // Draw numerical date
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_HOFFSET - hpad + 5,
            screenHalfHeight + TIME_VOFFSET + 1,
            DATE_FONT,
            dateStr,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        // Draw a small rectangle under the date
        dc.setColor(FG_COLOR, FG_COLOR);
        dc.fillRectangle(
            TIME_HOFFSET - hpad - dateDims[0] + 19,
            screenHalfHeight + TIME_VOFFSET + dateDims[1] + 3,
            dateDims[0] - 14, // a bit shorter than the date
            5
        );
    }

    function drawStatus(dc as Dc) as Void {
        // Box dimensions
        var totalWidth = (STATUS_BOXSIZE * 3) + (STATUS_BOXMRGN * 2);
        var startX = (screenWidth - totalWidth) / 2;
        var startY = screenHeight - STATUS_VOFFSET - STATUS_BOXSIZE;
        
        // Draw three empty boxes
        dc.setColor(hasMessages ? FG_COLOR : BG_COLOR, BG_COLOR);
        dc.fillRectangle(startX, startY, STATUS_BOXSIZE, STATUS_BOXSIZE);
        dc.setColor(hasAlarms ? FG_COLOR : BG_COLOR, BG_COLOR);
        dc.fillRectangle(
            startX + STATUS_BOXSIZE + STATUS_BOXMRGN,
            startY,
            STATUS_BOXSIZE,
            STATUS_BOXSIZE
        );
        dc.setColor(hasConnection ? FG_COLOR : BG_COLOR, BG_COLOR);
        dc.fillRectangle(
            startX + (STATUS_BOXSIZE + STATUS_BOXMRGN) * 2,
            startY,
            STATUS_BOXSIZE,
            STATUS_BOXSIZE
        );
    }

    function drawVitals(dc as Dc) as Void {
        var vitalBarWidth = (screenWidth * 0.40).toNumber();  // A little less than half the screen
        var vitalBarHeight = 16;
        var vitalBarSpacing = 5;
        var vitalStartX = screenHalfWidth + 8;
        var vitalStartY = 80;
        
        // Draw each vital stat with its progress bar
        drawVitalBar(dc, vitalStartX, vitalStartY, "EM", activeMinutes, activeMinutesGoal, vitalBarWidth, vitalBarHeight);
        vitalStartY += vitalBarHeight + vitalBarSpacing;
        
        drawVitalBar(dc, vitalStartX, vitalStartY, "CL", caloriesBurned, caloriesBurnedGoal, vitalBarWidth, vitalBarHeight);
        vitalStartY += vitalBarHeight + vitalBarSpacing;
        
        drawVitalBar(dc, vitalStartX, vitalStartY, "SP", steps, stepGoal, vitalBarWidth, vitalBarHeight);
        vitalStartY += vitalBarHeight + vitalBarSpacing;
        
        drawVitalBar(dc, vitalStartX, vitalStartY, "ST", bodyBattery, 100, vitalBarWidth, vitalBarHeight);
        vitalStartY += vitalBarHeight + vitalBarSpacing;
        
        drawVitalBar(dc, vitalStartX, vitalStartY, "SR", stress, 100, vitalBarWidth, vitalBarHeight);
    }

    // Helper function to draw a single vital stat bar
    function drawVitalBar(dc as Dc, x as Number, y as Number, name as String, value as Number, 
                        goal as Number, width as Number, height as Number) as Void {
        var font = Graphics.FONT_XTINY;
        var padding = 3;
        var progressWidth = width - 60;  // Leave room for label and value
        var nameWidth = 30;
        
        // Draw outline rectangle
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawRectangle(x, y, width, height);
        
        // Draw 3-letter abbreviation
        dc.drawText(
            x + padding, 
            y + (height / 2) - 1, 
            font, 
            name, 
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Calculate progress percentage (handle division by zero)
        var percentage = (goal > 0) ? (value.toFloat() / goal.toFloat()) : 0;
        if (percentage > 1.0) {
            percentage = 1.0;  // Cap at 100%
        }
        
        // Draw progress bar background
        dc.setColor(CRT_COLOR, CRT_COLOR);
        dc.fillRectangle(
            x + nameWidth,
            y + padding,
            progressWidth,
            height - (padding * 2)
        );
        
        // Draw filled portion of progress bar
        dc.setColor(FG_COLOR, FG_COLOR);
        dc.fillRectangle(
            x + nameWidth,
            y + padding,
            (progressWidth * percentage).toNumber(),
            height - (padding * 2)
        );
        
        // Draw value
        var valueStr = value.toString();
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            x + width - padding,
            y + (height / 2),
            font,
            valueStr,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
