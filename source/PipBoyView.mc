import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Activity;
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
  const TIME_XOFF = 18;
  const TIME_YOFF = -2;
  const TIME_YPAD = -9; // Controls vertical spacing of hours and minutes
  const STATUS_YOFF = 20;
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

  // Weather and location
  var currentWeather = null;
  var currentLocation = null;
  var sunrise = null;
  var sunset = null;

  // Settings
  var currentSettings;
  var hasMessages = false;
  var hasAlarms = false;
  var hasConnection = false;

  // Time and date
  var currentMoment;
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
  var heartRate = 0;

  // Other
  var allVitalsValid = true;
  var aboutToSleep = false;
  var selectedTab = 1;

  // =================================================================================
  // Delegate Functions
  // =================================================================================

  function initialize() {
    WatchFace.initialize();
    getCurrentTime();
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
    
    measureScreen(dc);
    getCurrentPosition();
    getCurrentSettings();
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Grab per-update data
    getCurrentTime();
    getCurrentActivityInfo();

    // Start redraw
    dc.clear();
    drawCRT(dc, CRT_FREQ);
    drawTime(dc);

    drawCelestialIcon(dc);

    // drawStats(dc);
    drawVaultBoy(dc);

    var stepsPercent = steps / stepGoal;
    var activePercent = activeMinutes / activeMinutesGoal;
    var bodyBatteryPercent = bodyBattery / 100;
    var stressPercent = stress / 100;
    drawStatBar(dc, screenHalfWidth - 18, 52, "CAPS", stepsPercent, 38, false);
    drawStatBar(dc, screenHalfWidth - 12, 115, "RADS", activePercent, 32, false);
    drawStatBar(dc, screenWidth - 37, 117, "STR", stressPercent, 28, true);
    drawStatBar(dc, screenHalfWidth - 18, 173, "ENERGY", bodyBatteryPercent, 50, false);

    // Call the function to draw heart rate
    drawHeartRate(dc);
    
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
    getCurrentPosition();
    getCurrentSettings();
  }

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {
    aboutToSleep = true;
  }

  // =================================================================================
  // Data Helpers
  // =================================================================================

  function getCurrentTime() as Void {
    currentMoment = Time.now();
    currentTime = System.getClockTime();
    currentDate = Time.Gregorian.info(currentMoment, Time.FORMAT_MEDIUM);
  }

  function getCurrentPosition() as Void {
    // Grab current weather conditions
    if (Toybox has :Weather) {
      var cond = Toybox.Weather.getCurrentConditions();
      if (cond != null) {
        currentWeather = cond;
      }
    }

    // Try and update our current location from whatever source we can get
    var newLocation = null;
    if (Toybox has :Position) {
      var info = Toybox.Position.getInfo();
      if (info != null && info.position != null) {
        newLocation = info.position;
      }
    }
    if (newLocation == null && currentWeather != null) {
      var loc = currentWeather.observationLocationPosition;
      if (loc != null) {
        newLocation = loc;
      }
    }
    if (newLocation != null) {
      currentLocation = newLocation;
    }

    // Set current location if we got something
    // These don't seem to rely on actually having a phone connection
    if (Toybox has :Weather && currentLocation != null) {
      sunrise = Toybox.Weather.getSunrise(currentLocation, currentMoment);
      sunset = Toybox.Weather.getSunset(currentLocation, currentMoment);
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
        if (ActivityMonitor has :getHeartRateHistory) {
          var hr = Activity.getActivityInfo().currentHeartRate;
          if (hr != null) {
            heartRate = hr;
          } else {
            allVitalsValid = false;
          }
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

  // Draw heart rate in an inverted box on Vault Boy's chest
  function drawHeartRate(dc as Dc) as Void {
    // Only draw if we have valid heart rate data
    if (heartRate > 0) {
      // Calculate the position for the heart rate display
      // This should be roughly where Vault Boy's chest is
      var vitalsX = screenHalfWidth + 8;
      var vitalsY = 60;
      var vitalsWidth = (screenWidth * 0.35).toNumber();
      var vitalsHeight = 5 * (17 + 7) - 7;
      
      // Position heart rate in the middle of the vitals area
      // Adjust Y position to be closer to chest area (about 40% down)
      var heartX = vitalsX + (vitalsWidth / 2) + 2;
      var heartY = vitalsY + (vitalsHeight * 0.47);
      
      // Format heart rate text
      var heartRateText = heartRate.toString();
      
      // Draw heart rate in inverted box
      drawInvertedText(
        dc,
        heartX,
        heartY.toNumber(),
        heartRateText,
        DAY_FONT,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        1,  // Horizontal padding
        0,  // Vertical padding
        true // Fill background for inverted look
      );
    }
  }

  // Draw the celestial icon
  function drawCelestialIcon(dc as Dc) as Void {
    // Configuration for the arc limits
    var horizontalLimit = 40;  // Max distance in pixels from center horizontally
    var verticalLimit = 10;    // Max distance in pixels from top of screen
    var topPadding = 1;       // Minimum distance from the top of the screen

    // Configuration for the actual drawn arc
    // Use .5 if there are rounding issues between arc and horizontal line
    var arcStartDegree = 128; // Left side (112 is start of motion)
    var arcEndDegree = 52;   // Right side (68 is end of motion)
    
    var tabPadding = 4;

    // Determine whether to show sunrise or sunset based on what's coming up next
    var sunEventText = null; // Default if times are not available
    
    if (sunrise != null && sunset != null) {
      // Get current time in minutes since midnight
      var currentTimeMinutes = currentTime.hour * 60 + currentTime.min;
      
      // Convert sunrise and sunset to minutes since midnight
      var sunriseTime = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
      var sunsetTime = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
      var sunriseMinutes = sunriseTime.hour * 60 + sunriseTime.min;
      var sunsetMinutes = sunsetTime.hour * 60 + sunsetTime.min;
      
      // Determine which is coming up next
      var timeToSunrise = (sunriseMinutes - currentTimeMinutes + 1440) % 1440;
      var timeToSunset = (sunsetMinutes - currentTimeMinutes + 1440) % 1440;
      
      if (timeToSunrise < timeToSunset) {
        // Sunrise is next
        sunEventText = Lang.format("$1$:$2$", [sunriseTime.hour, sunriseTime.min.format("%02d")]);
      } else {
        // Sunset is next
        sunEventText = Lang.format("$1$:$2$", [sunsetTime.hour, sunsetTime.min.format("%02d")]);
      }
    }

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
    var gapWidth = iconWidth + 10; // Add padding around icon
    var leftOfIcon = xPos - (gapWidth / 2);
    var rightOfIcon = xPos + (gapWidth / 2);
    
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(2);
    
    // Draw left segment of arc
    dc.setClip(0, 0, leftOfIcon, screenHeight);
    dc.drawArc(arcCenterX, arcCenterY, arcRadius, Graphics.ARC_CLOCKWISE, arcStartDegree, arcEndDegree);

    // Draw right segment of arc
    dc.setClip(rightOfIcon, 0, screenWidth - rightOfIcon, screenHeight);
    dc.drawArc(arcCenterX, arcCenterY, arcRadius, Graphics.ARC_CLOCKWISE, arcStartDegree, arcEndDegree);
    
    // Clear the clip
    dc.clearClip();

    if (sunEventText != null) {
      var sunEventTextWidth = dc.getTextWidthInPixels(sunEventText, DAY_FONT);
      
      // Calculate text dimensions and position for the sunriseText
      // var sunriseTextHeight = dc.getFontHeight(DAY_FONT);
      var sunEventX = screenHalfWidth;
      var sunEventY = arcLeftmostY;
      
      // Calculate tab points
      var tabLeftX = sunEventX - (sunEventTextWidth/2) - tabPadding;
      var tabRightX = sunEventX + (sunEventTextWidth/2) + tabPadding;
      // var tabBottomY = sunriseTextY + sunriseTextHeight / 2;
      
      // Draw the line with detour under text (in multiple segments)
      dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
      
      // Left segment of line
      dc.drawLine(arcLeftmostX + 2, arcLeftmostY, tabLeftX, arcLeftmostY);

      // Right segment of line
      dc.drawLine(tabRightX, arcRightmostY, arcRightmostX, arcRightmostY);

      // Draw the sunrise text
      dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
      dc.drawText(sunEventX, sunEventY, DAY_FONT, sunEventText, 
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    } else {
      // Otherwise just connect the line
      dc.drawLine(arcLeftmostX + 2, arcLeftmostY, arcRightmostX, arcRightmostY);
    }

    dc.setPenWidth(1);

    // Draw the celestial icon
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(xPos, yPos, CELESTIAL_ICONS, iconText, Graphics.TEXT_JUSTIFY_CENTER);
  }
  
  // Draw multiple stat bars in a stacked layout
  function drawStatStack(dc as Dc) as Void {
    // Position constants
    var startY = 54;
    
    // Vertical spacing between bars
    var spacing = 36;
    
    // Padding values
    var topBottomRightPadding = 120;   // Top and bottom rows right padding
    var middleRightPadding = 40;       // Middle rows right padding
    var startX = TIME_YOFF + dc.getTextWidthInPixels("XX", TIME_FONT) + 42;
    
    // Three-letter labels
    var labels = ["STR", "AGI", "END", "PER"];
    
    // Different percentage values for each bar
    var percentages = [0.78, 0.52, 0.63, 1.0];

    // Add * to a label if the stat is maxed out
    for (var i = 0; i < labels.size(); i++) {
      if (percentages[i] >= 1.0) {
        labels[i] += "*";
      }
    }
    
    // Calculate where the bar actually starts
    var barStartX = startX;
    
    // Calculate available width for bars (total width minus bar start position minus padding)
    var barLengths = [
      screenWidth - barStartX - topBottomRightPadding,  // Top row with 15px padding
      screenWidth - barStartX - middleRightPadding,     // Middle row with 5px padding
      screenWidth - barStartX - middleRightPadding,     // Middle row with 5px padding
      screenWidth - barStartX - topBottomRightPadding   // Bottom row with 15px padding
    ];
    
    // Draw the four stat bars stacked vertically
    drawStatBar(dc, startX, startY, labels[0], percentages[0], barLengths[0], false);
    drawStatBar(dc, startX, startY + spacing, labels[1], percentages[1], barLengths[1], false);
    drawStatBar(dc, startX, startY + spacing*2, labels[2], percentages[2], barLengths[2], false);
    drawStatBar(dc, startX, startY + spacing*3, labels[3], percentages[3], barLengths[3], false);
  }

  // Draw a stat bar with progress indicator
  function drawStatBar(dc as Dc, x as Number, y as Number, label as String, 
            percentage as Float, length as Number, left as Boolean) as Void {
    // Constants
    var leftBarHeight = 12;      // Height of left vertical line
    var triangleHeight = 8;     // Height of the triangle
    var triangleWidth = 8;      // Width of the triangle
    
    // Get text dimensions
    var labelHeight = dc.getFontHeight(DAY_FONT);
    
    // Position calculations
    var barX = x;
    var barY = y + labelHeight - 2;
    var labelX;
    
    // Set color
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    
    if (left) {
      // Right-justified text for left orientation
      labelX = x + length;
      dc.drawText(labelX, y, DAY_FONT, label, Graphics.TEXT_JUSTIFY_RIGHT);
    } else {
      // Left-justified text for right orientation
      labelX = x;
      dc.drawText(labelX, y, DAY_FONT, label, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    // Draw horizontal line
    dc.fillRectangle(barX, barY, length, 2);
    
    if (left) {
      // Draw right vertical line for left orientation
      dc.fillRectangle(barX + length - 2, barY, 2, leftBarHeight);
      
      // Draw left triangle (pointing left)
      var leftX = barX;
      var points = [
        [leftX, barY],
        [leftX - triangleWidth, barY],
        [leftX, barY + triangleHeight]
      ];
      dc.fillPolygon(points);
      
      // Draw progress fill from right to left
      var fillWidth = ((length - 4) * percentage).toNumber();
      if (fillWidth > 0) {
        dc.fillRectangle(barX + length - 3 - fillWidth, barY + 3, fillWidth, leftBarHeight - 3);
      }
    } else {
      // Draw left vertical line for right orientation
      dc.fillRectangle(barX, barY, 2, leftBarHeight);
      
      // Draw right triangle (pointing right)
      var rightX = barX + length;
      var points = [
        [rightX, barY],
        [rightX + triangleWidth, barY],
        [rightX, barY + triangleHeight]
      ];
      dc.fillPolygon(points);
      
      // Draw progress fill from left to right
      var fillWidth = ((length - 4) * percentage).toNumber();
      if (fillWidth > 0) {
        dc.fillRectangle(barX + 3, barY + 3, fillWidth, leftBarHeight - 3);
      }
    }
  }

  // Draw Vault Boy 
  function drawVaultBoy(dc as Dc) as Void {
    // Load the Vault Boy bitmap from resources
    var vaultBoyBitmap = WatchUi.loadResource(Rez.Drawables.vaultboy);
    
    // Calculate the area where vitals would be drawn
    var vitalsX = screenHalfWidth + 8;
    var vitalsY = 60;
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
    var dayBoxXOffset = 6; // Push right so day doesn't get cut off by display
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
    var alarmX = ampmX;
    var alarmY = ampmBottomY + ampmBottomDims[1] + 18; // Position below AM/PM
    // var alarmIconDims = dc.getTextDimensions(alarmIconText, ICON_FONT);
    // var alarmBreakTop = alarmY - 2;
    // var alarmBreakBottom = alarmY + alarmIconDims[1] + 4;
    
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
    
    // Draw right edge with break only for AM/PM
    dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, ampmBreakBottom, 
             BAR_WIDTH, boxBottomY - ampmBreakBottom + BAR_WIDTH);
    
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
      drawInvertedText(
        dc,
        alarmX,
        alarmY,
        alarmIconText,
        ICON_FONT,
        Graphics.TEXT_JUSTIFY_CENTER,
        1,  // Small horizontal padding
        2,  // Small vertical padding
        true // Fill background like the day box
      );
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


}
