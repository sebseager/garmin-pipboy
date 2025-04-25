import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Position;

class PipBoyView extends WatchUi.WatchFace {

    // =================================================================================
    // Constants
    // =================================================================================

    // Colors
    const THEME_DARK = 0x002222;
    const THEME_MID = 0x003355;
    const THEME_BRIGHT = 0x00FFFF;
    const CRT_COLOR = 0x003355;

    // Fonts
    const TEMP_FONT = WatchUi.loadResource(Rez.Fonts.monofonto24);
    const TIME_FONT = WatchUi.loadResource(Rez.Fonts.monofonto72);
    const DAY_FONT = WatchUi.loadResource(Rez.Fonts.monofonto16);
    const DATE_FONT = WatchUi.loadResource(Rez.Fonts.monofonto20);
    const ICON_FONT = WatchUi.loadResource(Rez.Fonts.icons24);
    const CELESTIAL_ICONS = WatchUi.loadResource(Rez.Fonts.celestial);

    // Measurements
    const CRT_FREQ = 3;
    const TEMP_YOFF = 52;
    const TEMP_BARLENGTH = 110;
    const BAR_WIDTH = 2;
    const TIME_XOFF = 24;
    const TIME_YOFF = 8;
    const TIME_YPAD = -9; // Controls vertical spacing of hours and minutes
    const DATE_XPAD = 6; // Push date away from time
    const DATE_YPAD = 2; // Push date components away from center line
    const STATUS_YOFF = 20;
    const TABS_YOFF = 60;
    const POS_YOFF = 32;

    // Other
    const BAD_NUM = 999999;

    // =================================================================================
    // Variables
    // =================================================================================

    // Device screen
    var screenWidth;
    var screenHalfWidth;
    var screenHeight;
    var screenHalfHeight;

    // Weather
    var currentTemp = BAD_NUM;
    var currentPrecip = BAD_NUM;
    var currentHumidity = BAD_NUM;

    // GPS
    var currentLat = "---";
    var currentLon = "---";

    // Settings
    var currentSettings;
    var hasMessages = false;
    var hasAlarms = false;
    var hasConnection = false;

    // Time and date
    var currentTime;
    var currentDate;

    // Vitals
    var activityInfo;
    var activeMinutes = 0;
    var activeMinutesGoal = 0;
    var caloriesBurned = 0;
    var caloriesBurnedGoal = 0;
    var steps = 0;
    var stepGoal = 0;
    var bodyBattery = 100;
    var stress = 0;

    // Other
    var allVitalsValid = true;
    var aboutToSleep = false;
    var selectedTab = 1;

    // =================================================================================
    // Delegate Functions
    // =================================================================================

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        measureScreen(dc);
        getCurrentWeather();
        getCurrentSettings();
        getCurrentActivityInfo();
        getCurrentPosition();
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
        drawCelestialIcon(dc);
        drawTime(dc);

        // drawBottomTabs(dc, "HRS", "MAP", "WTR", 8);
        // drawStatus(dc);

        // // Only draw top bar if we have weather data
        // if (currentTemp < BAD_NUM && currentPrecip < BAD_NUM && currentHumidity < BAD_NUM) {
        //     var tempStr = Lang.format("$1$°", [currentTemp.toNumber()]);
        //     var precipStr = Lang.format("$1$%", [currentPrecip.toNumber()]);
        //     var humidityStr = Lang.format("$1$%", [currentHumidity.toNumber()]);
        //     drawTopBar(dc, precipStr, tempStr, humidityStr, 4);
        // }

        // // Draw tab contents
        // if (selectedTab == 0) {
        //     // TODO
        // } else if (selectedTab == 1) {
        //     drawLatLong(dc);
        // } else if (selectedTab == 2) {
        //     // TODO
        // }

        // if (!aboutToSleep && allVitalsValid) {
        //     drawVitals(dc);
        // } else {
        //     drawVaultBoy(dc);
        // }

        // Set a black background
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);

        // // Update the view
        // var view = View.findDrawableById("TimeLabel") as Text;
        // view.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        // view.setText(timeString);

        // // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        aboutToSleep = false;
        getCurrentWeather();
        getCurrentSettings();
        getCurrentActivityInfo();
        getCurrentPosition();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        aboutToSleep = true;
    }

    // =================================================================================
    // Data Helpers
    // =================================================================================

    function getCurrentPosition() as Void {
        if (Toybox has :Position) {
            // Try to get position info
            if (Position has :getInfo) {
                var posInfo = Position.getInfo();
                if (posInfo != null && posInfo.position != null) {
                    var location = posInfo.position;
                    // Format latitude and longitude
                    if (location has :toDegrees) {
                        var coords = location.toDegrees();
                        
                        // Format latitude (XX°YY'N/S)
                        var latDec = coords[0];
                        var latDeg = latDec.abs().toNumber();
                        var latMin = ((latDec.abs() - latDeg) * 60).toNumber();
                        var latDir = latDec >= 0 ? "N" : "S";
                        currentLat = Lang.format("$1$°$2$$3$", [latDeg, latMin, latDir]);
                        
                        // Format longitude (XX°YY'E/W)
                        var lonDec = coords[1];
                        var lonDeg = lonDec.abs().toNumber();
                        var lonMin = ((lonDec.abs() - lonDeg) * 60).toNumber();
                        var lonDir = lonDec >= 0 ? "E" : "W";
                        currentLon = Lang.format("$1$°$2$$3$", [lonDeg, lonMin, lonDir]);
                    }
                }
            }
        }
    }

    function getCurrentWeather() as Void {
        if (Toybox has :Weather) {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                if (conditions.temperature != null) {
                    currentTemp = conditions.temperature;
                }
                if (conditions.precipitationChance != null) {
                    currentPrecip = conditions.precipitationChance;
                }
                if (conditions.relativeHumidity != null) {
                    currentHumidity = conditions.relativeHumidity;
                }
            }
        }
    }

    // Get the current device settings
    function getCurrentSettings() as Void {
        currentSettings = System.getDeviceSettings();
        hasMessages = currentSettings.notificationCount > 0;
        hasAlarms = currentSettings.alarmCount > 0;
        hasConnection = currentSettings.phoneConnected;
    }

    // Get the current user info
    function getCurrentActivityInfo() as Void {
        allVitalsValid = true;
        if (Toybox has :ActivityMonitor) {
            var info = ActivityMonitor.getInfo();
            if (info != null) {
                activityInfo = info;
                if (info.steps != null) {
                    steps = info.steps;
                } else {
                    allVitalsValid = false;
                }
                if (info.stepGoal != null) {
                    stepGoal = info.stepGoal;
                } else {
                    allVitalsValid = false;
                }
                if (info.calories != null) {
                    caloriesBurned = info.calories;
                } else {
                    allVitalsValid = false;
                }
                if (info.activeMinutesDay != null) {
                    activeMinutes = info.activeMinutesDay.total;
                } else {
                    allVitalsValid = false;
                }
                if (info.activeMinutesWeekGoal != null) {
                    activeMinutesGoal = info.activeMinutesWeekGoal;
                } else {
                    allVitalsValid = false;
                }
            } else {
                allVitalsValid = false;
            }
        } else {
            allVitalsValid = false;
        }

        if (Toybox has :SensorHistory) {
            // Get body battery data if available
            if (Toybox.SensorHistory has :getBodyBatteryHistory) {
                var bbIterator = Toybox.SensorHistory.getBodyBatteryHistory({});
                if (bbIterator != null) {
                    var sample = bbIterator.next();
                    if (sample != null && sample.data != null) {
                        bodyBattery = sample.data.toNumber();
                    } else {
                        allVitalsValid = false;
                    }
                } else {
                    allVitalsValid = false;
                }
            } else {
                allVitalsValid = false;
            }

            // Get stress data if available
            if (Toybox.SensorHistory has :getStressHistory) {
                var stressIterator = Toybox.SensorHistory.getStressHistory({});
                if (stressIterator != null) {
                    var sample = stressIterator.next();
                    if (sample != null && sample.data != null) {
                        stress = sample.data.toNumber();
                    } else {
                        allVitalsValid = false;
                    }
                } else {
                    allVitalsValid = false;
                }
            } else {
                allVitalsValid = false;
            }
        }
    }

    // =================================================================================
    // Layout Helpers - only callable from onUpdate
    // =================================================================================

    // Draw Vault Boy 
    function drawVaultBoy(dc as Dc) as Void {
        // Load the Vault Boy bitmap from resources
        var vaultBoyBitmap = WatchUi.loadResource(Rez.Drawables.vaultboy);
        
        // Calculate the area where vitals would be drawn
        var vitalsX = screenHalfWidth + 2;
        var vitalsY = 71;
        var vitalsWidth = (screenWidth * 0.35).toNumber();
        var vitalsHeight = 5 * (17 + 7) - 7;  // 5 bars of height 17 with padding 7 between them
        
        // Get bitmap dimensions for centering
        var bitmapWidth = vaultBoyBitmap.getWidth();
        var bitmapHeight = vaultBoyBitmap.getHeight();
        
        // Center the bitmap within the vitals area
        var x = vitalsX + (vitalsWidth - bitmapWidth) / 2;
        var y = vitalsY + (vitalsHeight - bitmapHeight) / 2;
        
        // Draw the bitmap with the same color as other UI elements
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawBitmap(x, y, vaultBoyBitmap);
    }

    // Get screen dimensions
    function measureScreen(dc as Dc) as Void {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        screenHalfWidth = screenWidth / 2;
        screenHalfHeight = screenHeight / 2;
    }

    // Draw the CRT effect
    function drawCRT(dc as Dc, freq as Number) as Void {
        dc.setColor(CRT_COLOR, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < screenHeight; i += freq) {
            dc.drawLine(0, i, screenWidth, i);
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
            iconChar = "a"; // sunrise
        } else if (decimalHour >= 6 && decimalHour < 9) {
            iconChar = "b"; // half sun
        } else if (decimalHour >= 9 && decimalHour < 15) {
            iconChar = "c"; // sun
        } else if (decimalHour >= 15 && decimalHour < 18) {
            iconChar = "b"; // half sun
        } else if (decimalHour >= 18 && decimalHour < 20) {
            iconChar = "a"; // sunset
        } else {
            iconChar = "d"; // moon
        }
        
        // Calculate necessary offsets
        var iconHeight = dc.getFontHeight(ICON_FONT);
        var voff = (iconHeight / 2) + 10; // Half icon height plus padding
        
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
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            iconX,
            iconY,
            CELESTIAL_ICONS,
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
        var hourDims = dc.getTextDimensions(hourStr, TIME_FONT);
        var minDims = dc.getTextDimensions(minStr, TIME_FONT);
        var timeWidth = hourDims[0] > minDims[0] ? hourDims[0] : minDims[0]; // Use the wider of the two

        // Format date components needed early for box calculation
        var dateStr = Lang.format("$1$", [currentDate.day.format("%02d")]);
        var dayStr = Lang.format("$1$", [currentDate.day_of_week.toUpper()]);
        var dayDims = dc.getTextDimensions(dayStr, DAY_FONT);
        var dateDims = dc.getTextDimensions(dateStr, DATE_FONT);

        // Calculate the minutes midpoint - this will be our reference point
        var minMidpointX = TIME_XOFF + (minDims[0] / 2);
        
        // Calculate box position and dimensions
        var boxX = 0; // Start slightly left of text
        var boxY = screenHalfHeight - strHeight - TIME_YPAD - 4; // Start above hours text
        var boxHeight = (strHeight * 2) + (TIME_YPAD * 2) + 8; // Height covers both lines + padding
        var boxWidth = TIME_XOFF + timeWidth + 14; // Width based on widest time string + padding
        var boxBottomY = boxY + boxHeight - BAR_WIDTH;

        // Position day and date elements relative to minutes midpoint
        // Day is to the left of midpoint with its right edge at midpoint
        var dayBoxHPadding = 2;
        var dayBoxVPadding = 0;
        var dayBoxWidth = dayDims[0] + (dayBoxHPadding * 2);
        
        // Date should be right next to the day with no spacing between
        var dateHPadding = 8;
        var dateWidth = dateDims[0] + (dateHPadding * 2);
        
        // Position elements while preserving the midpoint alignment
        var totalElementWidth = dayBoxWidth + dateWidth;
        var dayBoxX = minMidpointX - (totalElementWidth / 2) + (dayBoxWidth / 2);
        var dateX = dayBoxX + (dayBoxWidth / 2) + (dateWidth / 2); // Position date right next to day

        // Format seconds string for bottom of box
        var secStr = Lang.format("$1$", [currentTime.sec.format("%02d")]);
        var secDims = dc.getTextDimensions(secStr, DATE_FONT);
        var secHPadding = 4; // Add padding around seconds text
        
        // Align seconds vertically with minutes
        var secX = minMidpointX; // Center seconds at minutes midpoint
        var secY = boxBottomY; // Position on bottom line

        // Draw the box lines
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        
        // Top line - draw in segments
        // Segment 1: Left edge to left edge of day box
        dc.fillRectangle(boxX, boxY, dayBoxX - (dayBoxWidth / 2) - boxX, BAR_WIDTH);
        // Segment 2: After date text to right edge
        dc.fillRectangle(dateX + (dateWidth / 2), boxY, (boxX + boxWidth) - (dateX + (dateWidth / 2)), BAR_WIDTH);
        
        // Right line
        dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, boxY, BAR_WIDTH, boxHeight);
        
        // Bottom line - draw in segments for seconds
        if (!aboutToSleep) {
            // Left segment
            dc.fillRectangle(boxX, boxBottomY, secX - (secDims[0] / 2) - secHPadding - boxX, BAR_WIDTH);
            // Right segment
            dc.fillRectangle(secX + (secDims[0] / 2) + secHPadding, boxBottomY, (boxX + boxWidth) - (secX + (secDims[0] / 2) + secHPadding), BAR_WIDTH);
        } else {
            // Full bottom line if seconds are hidden
            dc.fillRectangle(boxX, boxBottomY, boxWidth, BAR_WIDTH);
        }

        // Draw hours and minutes
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(TIME_XOFF, screenHalfHeight - strHeight - TIME_YPAD, TIME_FONT, hourStr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(TIME_XOFF, screenHalfHeight + TIME_YPAD, TIME_FONT, minStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Draw day of week box on top edge (filled)
        drawInvertedText(
            dc,
            dayBoxX,
            boxY,
            dayStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            dayBoxHPadding,
            dayBoxVPadding,
            true // fill
        );

        // Draw numerical date with an outlined box (not filled)
        drawInvertedText(
            dc,
            dateX,
            boxY,
            dateStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            dateHPadding,
            0, // No vertical padding
            false // Don't fill, just outline
        );

        // Draw seconds on bottom line
        if (!aboutToSleep) {
            dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(secX, secY, DATE_FONT, secStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Draw the status boxes
    function drawStatus(dc as Dc) as Void {
        // Box dimensions and placement
        var boxSize = 18;
        var rightMargin = 9;
        var padding = 6;
        var startX = screenWidth - boxSize - rightMargin;
        
        // Calculate vertical positioning to center around screenHalfHeight
        var totalHeight = (boxSize * 3) + (padding * 2);
        var startY = screenHalfHeight - (totalHeight / 2) - 2;
        
        // Icons for each status box
        var messageIcon = "k";
        var alarmIcon = "R";
        var phoneIcon = "V";
        
        // Draw message status box
        dc.setColor(hasMessages ? THEME_BRIGHT : THEME_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(startX, startY, boxSize, boxSize);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            startX + (boxSize / 2),
            startY + (boxSize / 2),
            ICON_FONT,
            messageIcon,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw alarm status box
        dc.setColor(hasAlarms ? THEME_BRIGHT : THEME_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(startX, startY + boxSize + padding, boxSize, boxSize);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            startX + (boxSize / 2),
            startY + boxSize + padding + (boxSize / 2) - 1,
            ICON_FONT,
            alarmIcon,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw phone connection status box
        dc.setColor(hasConnection ? THEME_BRIGHT : THEME_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(startX, startY + (boxSize + padding) * 2, boxSize, boxSize);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            startX + (boxSize / 2),
            startY + (boxSize + padding) * 2 + (boxSize / 2) - 1,
            ICON_FONT,
            phoneIcon,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawVitals(dc as Dc) as Void {
        var w = (screenWidth * 0.35).toNumber();  // A little less than half the screen
        var h = 17;
        var pad = 7;
        var x = screenHalfWidth + 2;
        var y = 71;
        
        // Draw each vital stat with its progress bar
        drawVitalBar(dc, x, y, "o", activeMinutes, activeMinutesGoal, w, h);
        y += h + pad;
        drawVitalBar(dc, x, y, "X", caloriesBurned, caloriesBurnedGoal, w, h);
        y += h + pad;
        drawVitalBar(dc, x, y, "Q", steps, stepGoal, w, h);
        y += h + pad;
        drawVitalBar(dc, x, y, "A", bodyBattery, 100, w, h);
        y += h + pad;
        drawVitalBar(dc, x, y, "Y", stress, 100, w, h);
    }

    // Helper function to draw a single vital stat bar
    function drawVitalBar(dc as Dc, x as Number, y as Number, icon as String, 
                          value as Number, goal as Number, width as Number, 
                          height as Number) as Void {
        var padding = 3;
        var iconWidth = dc.getTextDimensions("W", ICON_FONT)[0] + (padding * 2);
        var valueWidth = 40;  // Space for the numeric value
        var progressWidth = width - iconWidth - valueWidth;
        
        // Draw main background rectangle
        dc.setColor(THEME_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, width, height);
        
        // Calculate progress percentage (handle division by zero)
        var percentage;
        if (value != null && goal != null) {
            percentage = (goal > 0) ? (value.toFloat() / goal.toFloat()) : 0;
            percentage = percentage > 1.0 ? 1.0 : percentage;  // Cap at 100%
        } else {
            percentage = 0;
        }
        
        // Draw filled portion of progress bar
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        dc.fillRectangle(
            x + iconWidth,
            y + padding,
            (progressWidth * percentage).toNumber(),
            height - (padding * 2)
        );
        
        // Draw the four thin rectangles for the border (since we can't set line width)
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        // Top bar - with padding
        dc.fillRectangle(x + iconWidth, y + padding, progressWidth, BAR_WIDTH);
        // Bottom bar - with padding
        dc.fillRectangle(x + iconWidth, y + height - padding - BAR_WIDTH, progressWidth, BAR_WIDTH);
        // Left bar - with padding
        dc.fillRectangle(x + iconWidth, y + padding, BAR_WIDTH, height - (padding * 2));
        // Right bar - with padding
        dc.fillRectangle(x + iconWidth + progressWidth - BAR_WIDTH, y + padding, BAR_WIDTH, height - (padding * 2));
        
        // Draw icon placeholder (use first character of name for now)
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + (iconWidth / 2),
            y + (height / 2),
            ICON_FONT,
            icon,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw value text
        var valueStr = value.toString();
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x + width - padding,
            y + (height / 2),
            Graphics.FONT_XTINY,
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
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        if (fill) {
            dc.fillRectangle(rx, ry, textWidth + (hpad * 2), textHeight + (vpad * 2));
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, text, just);
        } else {
            dc.drawRectangle(rx, ry, textWidth + (hpad * 2), textHeight + (vpad * 2));
            dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, text, just);
        }
    }

    // Draw a tab bar with three labels where the line deviates under the middle label only
    function drawBottomTabs(dc as Dc, title1 as String, title2 as String, 
                            title3 as String, hpad as Number) as Void {
        // Tab bar position
        var ty = screenHeight - TABS_YOFF;
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
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        
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
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
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

    // Draw a top bar with three evenly spaced labels that break the line
    function drawTopBar(dc as Dc, title1 as String, title2 as String, 
                        title3 as String, hpad as Number) as Void {
        // Top bar position
        var ty = TEMP_YOFF;
        var lw = BAR_WIDTH;
        
        // Create a narrower bar with text clustered more centrally
        var barWidth = screenWidth * 0.65;
        var barStartX = (screenWidth - barWidth) / 2;
        var barEndX = barStartX + barWidth;
        
        // Calculate label positions more closely clustered
        var tx1 = barStartX + (barWidth * 0.2);
        var tx2 = barStartX + (barWidth * 0.5);
        var tx3 = barStartX + (barWidth * 0.8);

        // Get text dimensions
        var font = DATE_FONT;
        var dims1 = dc.getTextDimensions(title1, font);
        var dims2 = dc.getTextDimensions(title2, font);
        var dims3 = dc.getTextDimensions(title3, font);
        
        var w1 = dims1[0];
        var w2 = dims2[0];
        var w3 = dims3[0];
        
        // Set drawing color
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        
        // Draw the line segments with breaks for text
        
        // Left bracket - vertical part (10px tall)
        dc.fillRectangle(barStartX, ty - lw/2, lw, 10);
        
        // Segment 1: left bracket to first label
        dc.fillRectangle(barStartX, ty - lw/2, tx1 - w1/2 - hpad - barStartX, lw);
        
        // Segment 2: after first label to before second label
        dc.fillRectangle(tx1 + w1/2 + hpad, ty - lw/2, tx2 - w2/2 - hpad - (tx1 + w1/2 + hpad), lw);
        
        // Segment 3: after second label to before third label
        dc.fillRectangle(tx2 + w2/2 + hpad, ty - lw/2, tx3 - w3/2 - hpad - (tx2 + w2/2 + hpad), lw);
        
        // Segment 4: after third label to right bracket
        dc.fillRectangle(tx3 + w3/2 + hpad, ty - lw/2, barEndX - (tx3 + w3/2 + hpad), lw);
        
        // Right bracket - vertical part (10px tall)
        dc.fillRectangle(barEndX - lw, ty - lw/2, lw, 10);
        
        // Draw the text for each label
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            tx1,
            ty - 2,
            font,
            title1,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            tx2,
            ty - 2,
            font,
            title2,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            tx3,
            ty - 2,
            font,
            title3,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawLatLong(dc as Dc) as Void {
        // Calculate positioning for the center of the screen
        var yPosition = screenHeight - POS_YOFF;
        
        // Get text dimensions for both coordinates
        var latDims = dc.getTextDimensions(currentLat, DAY_FONT);
        var lonDims = dc.getTextDimensions(currentLon, DAY_FONT);
        
        var latWidth = latDims[0];
        var lonWidth = lonDims[0];
        
        // Calculate total width needed and start positions
        var totalWidth = latWidth + lonWidth + 6; // padding between boxes
        var latX = screenHalfWidth - (totalWidth / 2) + (latWidth / 2);
        var lonX = latX + (latWidth / 2) + 6 + (lonWidth / 2);
        
        // Draw latitude with filled background using drawInvertedText
        drawInvertedText(
            dc,
            latX,
            yPosition,
            currentLat,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            0,  // No horizontal padding inside box
            0,  // No vertical padding inside box
            true // Fill the background
        );
        
        // Draw longitude with filled background
        drawInvertedText(
            dc,
            lonX,
            yPosition,
            currentLon,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            0,  // No horizontal padding inside box
            0,  // No vertical padding inside box
            true // Fill the background
        );
    }

}
