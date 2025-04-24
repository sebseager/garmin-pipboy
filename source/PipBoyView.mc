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
    const NO_COLOR = Graphics.COLOR_TRANSPARENT;
    const BG_COLOR = Graphics.COLOR_BLACK;
    const CRT_COLOR = 0x003355;
    const FG_COLOR = 0x00FFFF;
    const MAX_TEMP = 99999;

    // Fonts
    const TEMP_FONT = WatchUi.loadResource(Rez.Fonts.monofonto24);
    const TIME_FONT = WatchUi.loadResource(Rez.Fonts.monofonto72);
    const DAY_FONT = WatchUi.loadResource(Rez.Fonts.monofonto16);
    const DATE_FONT = WatchUi.loadResource(Rez.Fonts.monofonto20);
    const ICON_FONT = WatchUi.loadResource(Rez.Fonts.icons24);

    // Measurements
    const CRT_FREQ = 3;
    const TEMP_YOFF = 46;
    const TEMP_BARLENGTH = 110;
    const BAR_WIDTH = 2;
    const TIME_XOFF = 50;
    const TIME_YPAD = -9; // Controls vertical spacing of hours and minutes
    const DATE_XPAD = 6; // Push date away from time
    const DATE_YPAD = 2; // Push date components away from center line
    const STATUS_YOFF = 20;
    const STATUS_BOXSIZE = 15;
    const STATUS_BOXMRGN = 5;
    const TAB_YOFF = 52;

    // =================================================================================
    // Variables
    // =================================================================================

    var screenWidth;
    var screenHalfWidth;
    var screenHeight;
    var screenHalfHeight;
    var currentTemp = MAX_TEMP;
    var hasMessages = false;
    var hasAlarms = false;
    var hasConnection = false;

    // Time and date
    var currentTime;
    var currentDate;

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
        // Grab per-update data
        currentTime = System.getClockTime();
        currentDate = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        // Start redraw
        dc.clear();
        drawCRT(dc, CRT_FREQ);

        currentTemp = 45; // TODO: DEBUG

        drawTemp(dc);
        drawCelestialIcon(dc);

        drawTime(dc);
        // drawStatus(dc);

        drawTabs(dc, "HRS", "WTR", "MAP", 8);

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
                    currentTemp = conditions.temperature;
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
    function drawCRT(dc as Dc, freq as Number) as Void {
        dc.setColor(CRT_COLOR, NO_COLOR);
        for (var i = 0; i < screenHeight; i += freq) {
            dc.drawLine(0, i, screenWidth, i);
        }
    }

    // Draw the temperature in a bar across the top
    function drawTemp(dc as Dc) as Void {
        if (currentTemp < MAX_TEMP) {
            // Draw temperature text
            var str = Lang.format("$1$°", [currentTemp.toNumber()]);
            var strHeight = dc.getFontHeight(TEMP_FONT);
            var strWidth = dc.getTextWidthInPixels(str, TEMP_FONT);
            var strHalfWidth = strWidth / 2;
            dc.setColor(FG_COLOR, NO_COLOR);
            dc.drawText(
                screenHalfWidth,
                TEMP_YOFF - strHeight / 2 - 2,
                TEMP_FONT,
                str,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            // Draw temperature bar on either side
            var barLength = (TEMP_BARLENGTH - strWidth) / 2;
            dc.setColor(FG_COLOR, FG_COLOR);
            dc.fillRectangle(
                screenHalfWidth - strHalfWidth - barLength - 4,
                TEMP_YOFF,
                barLength - 4,
                BAR_WIDTH
            );
            dc.fillRectangle(
                screenHalfWidth + strHalfWidth + 2,
                TEMP_YOFF,
                barLength - 2,
                BAR_WIDTH
            );
        } else {
            // Draw a full bar if no temperature is available
            dc.setColor(FG_COLOR, FG_COLOR);
            dc.fillRectangle(
                (screenWidth - TEMP_BARLENGTH) / 2, 
                TEMP_YOFF, 
                TEMP_BARLENGTH, 
                BAR_WIDTH
            );
        }
    }

    // Draw the moving sun/moon icon
    function drawCelestialIcon(dc as Dc) as Void {
        // Constants for icon positioning
        var topMargin = 12;  // Distance from top of screen to highest point of arcs
        var iconSideOffset = 46; // How far from center to the sides the icon travels
        
        // Draw weather icon based on time of day
        var hour = currentTime.hour;
        var min = currentTime.min;
        
        // Convert time to decimal hours for smooth movement
        var decimalHour = hour + (min / 60.0);
        
        // Determine which icon to show
        var iconChar;
        if (decimalHour >= 4 && decimalHour < 6) {
            iconChar = "b"; // sunrise
        } else if (decimalHour >= 6 && decimalHour < 17) {
            iconChar = "q"; // sun
        } else if (decimalHour >= 18 && decimalHour < 20) {
            iconChar = "b"; // sunset
        } else {
            iconChar = "c"; // moon
        }
        
        // Calculate necessary offsets
        var iconHeight = dc.getFontHeight(ICON_FONT);
        var voff = (iconHeight / 2) + 6; // Half icon height plus padding
        
        // Baseline for the icons should be above the temperature bars
        var baselineY = TEMP_YOFF - voff;
        
        // Set maximum heights for day and night arcs
        var dayMaxHeight = baselineY - topMargin; // Higher maximum for day (sun goes higher)
        var nightMaxHeight = dayMaxHeight * 1.0; // Lower maximum for night (moon stays lower)
        
        // Calculate icon position
        var iconX, iconY;
        
        // Morning arc (4am to noon)
        if (decimalHour >= 4 && decimalHour < 12) {
            var progress = (decimalHour - 4) / 8.0; // 0 to 1 as time goes from 4am to noon
            
            // X moves from left edge to center
            iconX = screenHalfWidth - iconSideOffset + (iconSideOffset * progress);
            
            // Y moves from baseline to high point
            iconY = baselineY - (dayMaxHeight * progress);
        }
        // Afternoon arc (noon to 8pm)
        else if (decimalHour >= 12 && decimalHour < 20) {
            var progress = (decimalHour - 12) / 8.0; // 0 to 1 as time goes from noon to 8pm
            
            // X moves from center to right edge
            iconX = screenHalfWidth + (iconSideOffset * progress);
            
            // Y moves from high point back down to baseline
            iconY = baselineY - dayMaxHeight + (dayMaxHeight * progress);
        }
        // Night arc (8pm to 4am)
        else {
            // Normalize hours to 0-8 range from 8pm to 4am (crossing midnight)
            var nightHour = (decimalHour < 4) ? decimalHour + 24 : decimalHour;
            var progress = (nightHour - 20) / 8.0; // 0 to 1 as time goes from 8pm to 4am
            
            // X moves from right to left
            iconX = screenHalfWidth + iconSideOffset - (iconSideOffset * 2 * progress);
            
            // Use the same approach as daytime arcs, just with a different height
            if (progress < 0.5) {
                // 8pm to midnight: Moving up to peak
                var upProgress = progress * 2; // Scale 0-0.5 to 0-1
                iconY = baselineY - (nightMaxHeight * upProgress);
            } else {
                // Midnight to 4am: Moving down from peak
                var downProgress = (progress - 0.5) * 2; // Scale 0.5-1 to 0-1
                iconY = baselineY - nightMaxHeight + (nightMaxHeight * downProgress);
            }
        }
        
        // Draw the icon
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            iconX,
            iconY,
            ICON_FONT,
            iconChar,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Draw the time and date
    function drawTime(dc as Dc) as Void {
        // Format time
        var hour = currentTime.hour;
        var min = currentTime.min;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour > 12 ? hour - 12 : hour;
        }
        var hourStr = Lang.format("$1$", [hour.format("%02d")]);
        var minStr = Lang.format("$1$", [min.format("%02d")]);
        var strHeight = dc.getFontHeight(TIME_FONT);

        // Draw hours and minutes
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_XOFF,
            screenHalfHeight - strHeight - TIME_YPAD,
            TIME_FONT,
            hourStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );
        dc.drawText(
            TIME_XOFF,
            screenHalfHeight + TIME_YPAD,
            TIME_FONT,
            minStr,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Format date
        var dateStr = Lang.format("$1$", [currentDate.day.format("%02d")]);
        var secStr = Lang.format(":$1$", [currentTime.sec.format("%02d")]);
        var dayStr = Lang.format("$1$", [currentDate.day_of_week.toUpper()]);
        var monthStr = Lang.format("$1$", [currentDate.month.toUpper()]);
        var secDims = dc.getTextDimensions(secStr, DAY_FONT);
        var dayDims = dc.getTextDimensions(dayStr, DAY_FONT);
        var monthDims = dc.getTextDimensions(monthStr, DAY_FONT);

        // Draw day of week with background rectangle
        drawInvertedText(
            dc,
            TIME_XOFF - DATE_XPAD - 2,
            screenHalfHeight - DATE_YPAD  - dayDims[1] - 6,
            dayStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_RIGHT,
            4, // horizontal padding
            0, // vertical padding
            true // fill
        );

        // Draw month with background rectangle
        drawInvertedText(
            dc,
            TIME_XOFF - DATE_XPAD - 2,
            screenHalfHeight + DATE_YPAD,
            monthStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_RIGHT,
            4, // horizontal padding
            0, // vertical padding
            true // fill
        );
        
        // Draw numerical date
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_XOFF - DATE_XPAD,
            screenHalfHeight + DATE_YPAD + monthDims[1] + 2,
            DATE_FONT,
            dateStr,
            Graphics.TEXT_JUSTIFY_RIGHT
        );

        // Draw seconds above the day
        dc.setColor(currentTime.sec % 2 ? FG_COLOR : FG_COLOR, NO_COLOR);
        dc.drawText(
            TIME_XOFF - DATE_XPAD,
            screenHalfHeight - DATE_YPAD - dayDims[1] - secDims[1] - 14,
            DATE_FONT,
            secStr,
            Graphics.TEXT_JUSTIFY_RIGHT
        );
    }

    function drawStatus(dc as Dc) as Void {
        // Box dimensions
        var totalWidth = (STATUS_BOXSIZE * 3) + (STATUS_BOXMRGN * 2);
        var startX = (screenWidth - totalWidth) / 2;
        var startY = screenHeight - STATUS_YOFF - STATUS_BOXSIZE;
        
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

    // Draw text with a filled rectangular background
    function drawInvertedText(dc as Dc, x as Number, y as Number, text as String,
                              font as FontResource, just as Number, hpad as Number,
                              vpad as Number, fill as Boolean) as Void {
        // Get text dimensions
        var textDims = dc.getTextDimensions(text, font);
        var textWidth = textDims[0];
        var textHeight = textDims[1];
        var rx, ry;
        
        // Calculate rectangle position based on text justification
        // For horizontal positioning
        if ((just & Graphics.TEXT_JUSTIFY_CENTER) == Graphics.TEXT_JUSTIFY_CENTER) {
            rx = x - (textWidth / 2) - hpad;
        } else if ((just & Graphics.TEXT_JUSTIFY_RIGHT) == Graphics.TEXT_JUSTIFY_RIGHT) {
            rx = x - textWidth - hpad;
        } else {
            // Default to LEFT justification
            rx = x - hpad;
        }
        
        // For vertical positioning
        if ((just & Graphics.TEXT_JUSTIFY_VCENTER) == Graphics.TEXT_JUSTIFY_VCENTER) {
            ry = y - (textHeight / 2) - vpad;
        } else {
            // Default to TOP justification
            ry = y - vpad;
        }
        
        // Draw everything
        dc.setColor(FG_COLOR, FG_COLOR);
        if (fill) {
            dc.fillRectangle(rx, ry, textWidth + (hpad * 2), textHeight + (vpad * 2));
            dc.setColor(BG_COLOR, NO_COLOR);
            dc.drawText(x, y, font, text, just);
        } else {
            dc.drawRectangle(rx, ry, textWidth + (hpad * 2), textHeight + (vpad * 2));
            dc.setColor(FG_COLOR, NO_COLOR);
            dc.drawText(x, y, font, text, just);
        }
    }

    // Draw a tab bar with three labels where the line deviates under the middle label only
    function drawTabs(dc as Dc, title1 as String, title2 as String, title3 as String, hpad as Number) as Void {
        // Tab bar position
        var ty = screenHeight - TAB_YOFF;
        var lw = BAR_WIDTH;
        
        // Calculate tab positions (biased towards center a bit)
        var tx1 = screenWidth / 4;
        var tx2 = screenWidth / 2;
        var tx3 = (screenWidth * 3) / 4;

        // Get text dimensions
        var dims1 = dc.getTextDimensions(title1, DAY_FONT);
        var dims2 = dc.getTextDimensions(title2, DAY_FONT);
        var dims3 = dc.getTextDimensions(title3, DAY_FONT);
        
        var w1 = dims1[0];
        var w2 = dims2[0];
        var h2 = dims2[1];
        var w3 = dims3[0];
        
        // Set drawing color
        dc.setColor(FG_COLOR, FG_COLOR);
        
        // Draw the tab line in segments using fillRectangle for thickness
        // Segment 1: left edge to first tab
        dc.fillRectangle(0, ty - lw/2, tx1 - w1/2 - hpad, lw);
        
        // Segment 2: first tab to second tab (skip under first tab)
        dc.fillRectangle(tx1 + w1/2 + hpad, ty - lw/2, tx2 - w2/2 - hpad - (tx1 + w1/2 + hpad), lw);
        
        // Segment 3: under second tab (middle tab)
        dc.fillRectangle(tx2 - w2/2 - hpad - lw/2, ty - lw/2, lw, h2/2 + lw/2);
        // Bottom horizontal - extended by lw/2 on each side
        dc.fillRectangle(tx2 - w2/2 - hpad - lw/2, ty + h2/2 - lw/2, w2 + 2*hpad + lw, lw);
        dc.fillRectangle(tx2 + w2/2 + hpad - lw/2, ty - lw/2, lw, h2/2 + lw/2);
        
        // Segment 4: second tab to third tab
        dc.fillRectangle(tx2 + w2/2 + hpad, ty - lw/2, tx3 - w3/2 - hpad - (tx2 + w2/2 + hpad), lw);
        
        // Segment 5: third tab to right edge (skip under third tab)
        dc.fillRectangle(tx3 + w3/2 + hpad, ty - lw/2, screenWidth - (tx3 + w3/2 + hpad), lw);
        
        // Draw the text for each tab
        dc.setColor(FG_COLOR, NO_COLOR);
        dc.drawText(
            tx1,
            ty - 2,
            DAY_FONT,
            title1,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        dc.drawText(
            tx2,
            ty - 2,
            DAY_FONT,
            title2,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        dc.drawText(
            tx3,
            ty - 2,
            DAY_FONT,
            title3,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
