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
    // const THEME_DARK = 0x000055;
    // const THEME_MID = 0x003355;
    // const THEME_BRIGHT = 0x00FFFF;
    // const CRT_COLOR = 0x003355;
    const THEME_DARK = 0x005500;
    const THEME_MID = 0x00AA00;
    const THEME_BRIGHT = 0x00FF00;
    const CRT_COLOR = 0x00AA00;

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
    const TIME_XOFF = 15;
    const TIME_YOFF = -2;
    const TIME_YPAD = -9; // Controls vertical spacing of hours and minutes
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
        drawTime(dc);

        drawCelestialIcon(dc);

        drawVaultBoy(dc);

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

    // Draw the celestial icon
    function drawCelestialIcon(dc as Dc) as Void {
        // Configuration for the arc limits
        var horizontalLimit = 40;  // Max distance in pixels from center horizontally
        var verticalLimit = 10;    // Max distance in pixels from top of screen
        var topPadding = 2;       // Minimum distance from the top of the screen

        // Configuration for the actual drawn arc
        // Use .5 if there are rounding issues between arc and horizontal line
        var arcStartDegree = 127.5; // Left side (112 is start of motion)
        var arcEndDegree = 53;   // Right side (68 is end of motion)

        var tabPadding = 6;
        var sunriseText = "N X:XX";  // Placeholder text

        // Get the current time
        var hour = currentTime.hour;
        var min = currentTime.min;
        var hourDecimal = hour + (min / 60.0);
        
        // Calculate how many hours have passed since 4 AM
        var hoursSince4am;
        if (hourDecimal >= 4) {
            hoursSince4am = hourDecimal - 4;
        } else {
            hoursSince4am = hourDecimal + 20;  // Add 24 - 4 = 20 hours
        }
        
        // Calculate position around the arc (0.0 to 1.0)
        var arcPosition;
        if (hoursSince4am <= 16) {
            // Day time (4 AM to 8 PM): Left to right
            arcPosition = hoursSince4am / 16.0;
        } else {
            // Night time (8 PM to 4 AM): Right to left
            arcPosition = 1.0 - ((hoursSince4am - 16) / 8.0);
        }
        
        // Calculate the x position
        var xOffset = (arcPosition * 2 - 1) * horizontalLimit;
        var xPos = screenHalfWidth + xOffset;
        
        // Calculate the y position to follow an arc
        var mappedX = arcPosition * 2 - 1;  // Map to -1 to 1
        var yPos = topPadding + verticalLimit * (mappedX * mappedX);
        
        // Draw an arc that follows the celestial path
        var arcCenterX = screenHalfWidth;
        var arcCenterY = screenHalfHeight;
        var iconHeight = dc.getFontHeight(ICON_FONT);
        var arcRadius = screenHalfHeight - topPadding - iconHeight / 2 - 2; // Radius of the arc

        // Calculate the actual leftmost and rightmost points of the arc
        var arcStartRad = Math.toRadians(arcStartDegree);
        var arcEndRad = Math.toRadians(arcEndDegree);
        var arcLeftmostX = arcCenterX + arcRadius * Math.cos(arcStartRad);
        var arcLeftmostY = arcCenterY - arcRadius * Math.sin(arcStartRad);
        var arcRightmostX = arcCenterX + arcRadius * Math.cos(arcEndRad);
        var arcRightmostY = arcCenterY - arcRadius * Math.sin(arcEndRad);

        // Get icon dimensions to create gap in arc
        var iconText = "c";
        var iconWidth = dc.getTextWidthInPixels(iconText, CELESTIAL_ICONS);
        var gapWidth = iconWidth + 8; // Add padding around icon
        var leftOfIcon = xPos - (gapWidth / 2);
        var rightOfIcon = xPos + (gapWidth / 2);
        
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        
        // Draw left segment of arc
        dc.setClip(0, 0, leftOfIcon, screenHeight);
        dc.drawArc(arcCenterX, arcCenterY, arcRadius, Graphics.ARC_CLOCKWISE, arcStartDegree, arcEndDegree);

        // Draw right segment of arc
        dc.setClip(rightOfIcon, 0, screenWidth - rightOfIcon, screenHeight);
        dc.drawArc(arcCenterX, arcCenterY, arcRadius, Graphics.ARC_CLOCKWISE, arcStartDegree, arcEndDegree);
        
        // Clear the clip
        dc.clearClip();

        // Calculate text dimensions and position for the sunriseText
        var sunriseTextWidth = dc.getTextWidthInPixels(sunriseText, DAY_FONT);
        var sunriseTextHeight = dc.getFontHeight(DAY_FONT);
        var sunriseTextX = screenHalfWidth;
        var sunriseTextY = arcLeftmostY;
        
        // Calculate tab points
        var tabLeftX = sunriseTextX - (sunriseTextWidth/2) - tabPadding;
        var tabRightX = sunriseTextX + (sunriseTextWidth/2) + tabPadding;
        var tabBottomY = sunriseTextY + sunriseTextHeight / 2;
        
        // Draw the line with detour under text (in multiple segments)
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        
        // Left segment of line
        dc.drawLine(arcLeftmostX, arcLeftmostY, tabLeftX, arcLeftmostY);
        
        // Left vertical down
        dc.drawLine(tabLeftX, arcLeftmostY, tabLeftX, tabBottomY);
        
        // Horizontal under text
        dc.drawLine(tabLeftX, tabBottomY, tabRightX, tabBottomY);
        
        // Right vertical up
        dc.drawLine(tabRightX, tabBottomY, tabRightX, arcRightmostY);

        // Right segment of line
        dc.drawLine(tabRightX, arcRightmostY, arcRightmostX, arcRightmostY);

        // Draw the sunrise text
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sunriseTextX, sunriseTextY, DAY_FONT, sunriseText, 
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw the celestial icon
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xPos, yPos, CELESTIAL_ICONS, iconText, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    // Draw a stat bar with progress indicator
    function drawStatBar(dc as Dc, x as Number, y as Number, label as String, value as String, 
                        percentage as Float, length as Number) as Void {
        // Constants
        var leftBarHeight = 10;      // Height of left vertical line
        var triangleHeight = 6;     // Height of the triangle
        var triangleWidth = 6;      // Width of the triangle
        var valueGap = 10;          // Gap between value and bar assembly
        
        // Get text dimensions
        var labelHeight = dc.getFontHeight(DAY_FONT);
        var valueWidth = dc.getTextWidthInPixels(value, DATE_FONT);
        
        // Position calculations
        var labelX = x + valueWidth + valueGap;
        var barX = labelX;
        var labelY = y;
        var barY = labelY + labelHeight;
        var valueY = labelY + (labelHeight / 2); // Center value vertically with label
        
        // Set color
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        
        // Draw label
        dc.drawText(labelX, labelY, DAY_FONT, label, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw horizontal line
        dc.fillRectangle(barX, barY, length, 2);
        
        // Draw left vertical line
        dc.fillRectangle(barX, barY, 2, leftBarHeight);
        
        // Draw right triangle (bottom half of arrow pointing right)
        var rightX = barX + length;
        var points = [
            [rightX, barY],
            [rightX + triangleWidth, barY],
            [rightX, barY + triangleHeight]
        ];
        dc.fillPolygon(points);
        
        // Draw progress fill
        var fillWidth = (length * percentage).toNumber();
        if (fillWidth > 0) {
            dc.fillRectangle(barX + 3, barY + 3, fillWidth, leftBarHeight - 3);
        }
        
        // Draw value (right justified)
        dc.drawText(labelX - valueGap/2, valueY, DATE_FONT, value, Graphics.TEXT_JUSTIFY_RIGHT);
    }

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
        dc.drawBitmap2(x, y, vaultBoyBitmap, {
            :tintColor => THEME_BRIGHT, // Tint color
        });
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
        dc.setColor(THEME_DARK, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < screenHeight; i += freq) {
            dc.drawLine(0, i, screenWidth, i);
        }
    }


    // Draw the time and date
    function drawTime(dc as Dc) as Void {
        // Format time
        var hour = currentTime.hour;
        var min = currentTime.min;
        var isPM = hour >= 12; // Determine AM/PM
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour > 12 ? hour - 12 : hour;
            hour = hour == 0 ? 12 : hour; // Handle midnight correctly
        }
        var hourStr = Lang.format("$1$", [hour.format("%02d")]);
        var minStr = Lang.format("$1$", [min.format("%02d")]);
        
        // Get dimensions for time, day, and date
        var timeHeight = dc.getFontHeight(TIME_FONT);
        var minDims = dc.getTextDimensions(minStr, TIME_FONT);
        var timeWidth = minDims[0];
        
        // Format date components
        var dayStr = currentDate.day_of_week.toUpper();
        var dateStr = Lang.format("$1$", [currentDate.day.format("%02d")]);
        var dayDims = dc.getTextDimensions(dayStr, DAY_FONT);
        var dateDims = dc.getTextDimensions(dateStr, DAY_FONT);
        
        // AM/PM components
        var ampmTop = isPM ? "P" : "A";
        var ampmBottom = "M";
        var ampmBottomDims = dc.getTextDimensions(ampmBottom, DATE_FONT);
        
        // Box positioning
        var boxX = 0;
        var boxY = screenHalfHeight - timeHeight - TIME_YPAD - 4;
        var boxHeight = (timeHeight * 2) + (TIME_YPAD * 2) + 8;
        var boxWidth = TIME_XOFF + timeWidth + 14;
        var boxBottomY = boxY + boxHeight - BAR_WIDTH;
        
        // Find midpoint of time digits - our reference point
        var timeLeftX = TIME_XOFF;
        var minMidpointX = timeLeftX + (timeWidth / 2);
        
        // Position day and date relative to midpoint
        var dayBoxXOffset = 10; // Push right so day doesn't get cut off by display
        var dayBoxHPadding = 1;
        var dayBoxWidth = dayDims[0] + (dayBoxHPadding * 2);
        var dateHPadding = 4; // More padding to make it roughly same width as day
        var dateWidth = dateDims[0] + (dateHPadding * 2);
        
        // Position elements so their combined center aligns with time midpoint
        var totalWidth = dayBoxWidth + dateWidth;
        var dayX = minMidpointX - (totalWidth / 2) + (dayBoxWidth / 2) + dayBoxXOffset;
        var dateX = dayX + (dayBoxWidth / 2) + (dateWidth / 2);
        
        // AM/PM positioning
        var ampmX = boxX + boxWidth - (BAR_WIDTH / 2);
        var ampmCenterY = boxY + (boxHeight / 2);
        var ampmTopY = ampmCenterY - ampmBottomDims[1];
        var ampmBottomY = ampmCenterY - 4;
        
        // Alarm icon positioning (if needed)
        var alarmIconText = "R";
        var alarmIconDims = dc.getTextDimensions(alarmIconText, ICON_FONT);
        var alarmX = ampmX;
        var alarmY = ampmBottomY + ampmBottomDims[1] + 18; // Position below AM/PM
        var alarmBreakTop = alarmY - 2;
        var alarmBreakBottom = alarmY + alarmIconDims[1] + 4;
        
        // Format seconds for bottom display
        var secStr = Lang.format("$1$", [currentTime.sec.format("%02d")]);
        var secDims = dc.getTextDimensions(secStr, DATE_FONT);
        var secHPadding = 4; // Padding around seconds
        var secX = minMidpointX; // Center seconds at midpoint
        
        // Draw the box lines
        dc.setColor(THEME_BRIGHT, THEME_BRIGHT);
        
        // Top line - draw in segments with breaks for day and date
        dc.fillRectangle(boxX, boxY, dayX - (dayBoxWidth / 2) - boxX, BAR_WIDTH);
        dc.fillRectangle(dateX + (dateWidth / 2), boxY, 
                        (boxX + boxWidth) - (dateX + (dateWidth / 2)), BAR_WIDTH);
        
        // Right vertical edge with breaks for AM/PM and alarm (if needed)
        var ampmBreakTop = ampmTopY - 1;
        var ampmBreakBottom = ampmBottomY + ampmBottomDims[1] + 1;
        
        dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, boxY, BAR_WIDTH, ampmBreakTop - boxY);
        
        if (hasAlarms) {
            // Draw right edge with breaks for both AM/PM and alarm
            dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, ampmBreakBottom, 
                            BAR_WIDTH, alarmBreakTop - ampmBreakBottom);
            dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, alarmBreakBottom, 
                            BAR_WIDTH, boxBottomY - alarmBreakBottom + BAR_WIDTH);
        } else {
            // Draw right edge with break only for AM/PM
            dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, ampmBreakBottom, 
                            BAR_WIDTH, boxBottomY - ampmBreakBottom + BAR_WIDTH);
        }
        
        // Bottom line with break for seconds
        if (!aboutToSleep) {
            dc.fillRectangle(boxX, boxBottomY, 
                            secX - (secDims[0] / 2) - secHPadding - boxX, BAR_WIDTH);
            dc.fillRectangle(secX + (secDims[0] / 2) + secHPadding, boxBottomY,
                            (boxX + boxWidth) - (secX + (secDims[0] / 2) + secHPadding), BAR_WIDTH);
        } else {
            // Full bottom line if sleeping
            dc.fillRectangle(boxX, boxBottomY, boxWidth, BAR_WIDTH);
        }
        
        // Draw hours and minutes
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(timeLeftX, boxY - TIME_YPAD + TIME_YOFF, TIME_FONT, hourStr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(timeLeftX, boxY + timeHeight + TIME_YPAD + TIME_YOFF, TIME_FONT, minStr, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw AM/PM
        dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ampmX, ampmTopY, DATE_FONT, ampmTop, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(ampmX, ampmBottomY, DATE_FONT, ampmBottom, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw alarm icon if alarms are present
        if (hasAlarms) {
            dc.drawText(alarmX, alarmY, ICON_FONT, alarmIconText, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw day in filled box
        drawInvertedText(
            dc,
            dayX,
            boxY,
            dayStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            dayBoxHPadding,
            0,  // No vertical padding
            true // Fill background
        );
        
        // Draw date in outlined box
        drawInvertedText(
            dc,
            dateX,
            boxY,
            dateStr,
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            dateHPadding,
            0,  // No vertical padding
            false // Don't fill, just outline
        );
        
        // Draw seconds on bottom line
        if (!aboutToSleep) {
            dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(secX, boxBottomY, DATE_FONT, secStr, 
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
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
