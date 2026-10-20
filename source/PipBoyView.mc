import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Activity;
import Toybox.Position;

enum ThemeColor {
  THEME_GREEN = 0,
  THEME_BLUE = 1,
  THEME_AMBER = 2
}

class PipBoyView extends WatchUi.WatchFace {

  // =================================================================================
  // Constants
  // =================================================================================

  // Fonts
  const TEMP_FONT = WatchUi.loadResource(Rez.Fonts.monofonto24);
  const TIME_FONT = WatchUi.loadResource(Rez.Fonts.monofonto72);
  const DAY_FONT = WatchUi.loadResource(Rez.Fonts.monofonto16);
  const DATE_FONT = WatchUi.loadResource(Rez.Fonts.monofonto20);
  const ICON_FONT = WatchUi.loadResource(Rez.Fonts.icons24);

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

  // Colors
  var THEME_DARK = 0x005500;
  var THEME_MID = 0x00AA00;
  var THEME_BRIGHT = 0x00FF00;
  var CRT_COLOR = 0x00AA00;

  // Device screen
  var screenWidth;
  var screenHalfWidth;
  var screenHeight;
  var screenHalfHeight;

  // Weather and location
  var currentWeather = null;
  var currentLocation = null;
  var currentHeading = null;
  var sunrise = null;
  var sunset = null;

  // Settings
  var currentSettings;
  var hasMessages = false;
  var hasAlarms = false;
  var hasConnection = false;
  var use24Hour = false;

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
  var floorsClimbed = 0;
  var floorsClimbedGoal = 0;
  var moveBarLevel = ActivityMonitor.MOVE_BAR_LEVEL_MIN;
  var steps = 0;
  var stepGoal = 0;
  var bodyBattery = 100;
  var stress = 0;
  var heartRate = 0;

  // Other
  var aboutToSleep = false;
  var selectedTab = 1;
  var newHeadingReady = false;
  
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
    updateTheme();
    updateTimeFormat();
    getCurrentActivityInfo();
    getCurrentPosition();

    // Start redraw
    dc.clear();
    drawCRT(dc, CRT_FREQ);
    drawTime(dc);

    drawCelestialIcon(dc);

    // Replace these calls with the single refactored function
    drawVaultBoy(dc);

    // Draw the current heading
    drawLinearCompass(dc);
    
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
    getCurrentSettings();
  }

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {
    aboutToSleep = true;
  }

  // =================================================================================
  // Themes
  // =================================================================================

  // Update the theme colors based on the selected theme
  function updateTheme() as Void {
    var themeIndex = Application.Properties.getValue("ThemeColor");
    themeIndex = themeIndex == null ? THEME_GREEN : themeIndex as ThemeColor;

    switch (themeIndex) {
      case THEME_BLUE:
        // Blue theme
        THEME_DARK = 0x000055;
        THEME_MID = 0x0000AA;
        THEME_BRIGHT = 0x00AAFF;
        CRT_COLOR = 0x0000AA;
        break;
        
      case THEME_AMBER:
        // Amber theme
        THEME_DARK = 0x553300;
        THEME_MID = 0xAA5500;
        THEME_BRIGHT = 0xFFAA00;
        CRT_COLOR = 0xAA5500;
        break;
        
      default:
        // Green theme (default, and fallback if invalid)
        THEME_DARK = 0x005500;
        THEME_MID = 0x00AA00;
        THEME_BRIGHT = 0x00FF00;
        CRT_COLOR = 0x00AA00;
        break;
    }
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

    // Grab current heading if we can
    if (Toybox has :Position) {
      var info = Toybox.Position.getInfo();
      if (info != null) {
        newHeadingReady = info.heading != null && info.heading != currentHeading;
        if (newHeadingReady) {
          currentHeading = info.heading;
        }
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

  // Mirror the watch's 12/24-hour time setting
  function updateTimeFormat() as Void {
    use24Hour = System.getDeviceSettings().is24Hour;
  }

  // Convert a 0-23 hour to the hour shown for the current time format
  function toDisplayHour(hour as Number) as Number {
    if (use24Hour) {
      return hour;
    }
    hour = hour % 12;
    return hour == 0 ? 12 : hour; // Handle midnight and noon correctly
  }

  // Get the current user info
  function getCurrentActivityInfo() as Void {
    if (Toybox has :ActivityMonitor) {
      var info = ActivityMonitor.getInfo();
      if (info != null) {
        activityInfo = info;

        steps = info.steps == null ? 0 : info.steps;
        stepGoal = info.stepGoal == null ? 0 : info.stepGoal;
        caloriesBurned = info.calories == null ? 0 : info.calories;
        activeMinutes = info.activeMinutesDay == null ? 0 : info.activeMinutesDay.total;
        activeMinutesGoal = info.activeMinutesWeekGoal == null ? 0 : info.activeMinutesWeekGoal;
        floorsClimbed = info.floorsClimbed == null ? 0 : info.floorsClimbed;
        floorsClimbedGoal = info.floorsClimbedGoal == null ? 0 : info.floorsClimbedGoal;
        moveBarLevel = info.moveBarLevel == null ? ActivityMonitor.MOVE_BAR_LEVEL_MIN : info.moveBarLevel;

        var hr = Activity.getActivityInfo().currentHeartRate;
        heartRate = hr == null ? 0 : hr;
      }
    }

    if (Toybox has :SensorHistory) {
      // Get body battery data if available
      if (Toybox.SensorHistory has :getBodyBatteryHistory) {
        var bbIterator = Toybox.SensorHistory.getBodyBatteryHistory({});
        if (bbIterator != null) {
          var sample = bbIterator.next();
          if (sample != null && sample.data != null) {
            bodyBattery = sample.data.toNumber();
          }
        }
      }
      // Get stress data if available
      if (Toybox.SensorHistory has :getStressHistory) {
        var stressIterator = Toybox.SensorHistory.getStressHistory({});
        if (stressIterator != null) {
          var sample = stressIterator.next();
          if (sample != null && sample.data != null) {
            stress = sample.data.toNumber();
          }
        }
      }
    }
  }

  // =================================================================================
  // Layout Helpers - only callable from onUpdate
  // =================================================================================

  // Draw a linear compass at the bottom of the screen
  function drawLinearCompass(dc as Dc) as Void {
    // Define constants for the compass layout
    var separatorY = screenHeight - 43;
    var ticksY = separatorY;
    var tickHeight = 8;
    var labelsY = ticksY + tickHeight + 10;
    
    // Cardinal directions in degrees (clockwise from North)
    var cardinalDirs = [0, 45, 90, 135, 180, 225, 270, 315];
    var cardinalLabels = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    
    // Draw the separator line
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(2);
    dc.drawLine(0, separatorY, screenWidth, separatorY);

    var isHeadingValid = newHeadingReady && !aboutToSleep;
    
    // Convert heading from radians to degrees and normalize to 0-360
    var headingDegrees = (currentHeading * 180.0 / Math.PI).toNumber() % 360;
    if (headingDegrees < 0) {
      headingDegrees += 360;
    }
    
    // Define the range to display (180 degrees centered on current heading)
    var visibleRangeStart = headingDegrees - 90;
    
    // Draw minor ticks every 15 degrees and major ticks for cardinal directions
    for (var degree = 0; degree < 360; degree += 15) {
      // Draw ticks and labels
      dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);

      // Calculate where this degree falls in our visible range
      var relativeDegree = (degree - visibleRangeStart) % 360;
      if (relativeDegree < 0) {
        relativeDegree += 360;
      }
      
      // Only display ticks within our 180 degree visible range
      if (relativeDegree <= 180) {
        // Map the relative degree (0-180) to screen position (0-screenWidth)
        var tickX = (relativeDegree / 180.0) * screenWidth;
        
        // Check if this is a cardinal/ordinal direction
        var isCardinal = false;
        var cardinalIndex = -1;
        if (isHeadingValid) {
          for (var i = 0; i < cardinalDirs.size(); i++) {
            if (cardinalDirs[i] == degree) {
              isCardinal = true;
              cardinalIndex = i;
              break;
            }
          }
        }
        
        // Draw the tick
        if (!isCardinal) {
          dc.setPenWidth(isCardinal ? 3 : 1);
          dc.drawLine(tickX, ticksY, tickX, ticksY + tickHeight);
        }
        
        // Draw labels for cardinal directions
        var halfLabelHeight = dc.getFontHeight(DAY_FONT) / 2;
        var textY = isCardinal ? ticksY + halfLabelHeight : labelsY;
        if (isCardinal) {
          drawInvertedText(
            dc,
            tickX,
            textY,
            cardinalLabels[cardinalIndex],
            DAY_FONT,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            4,  // Horizontal padding
            0,  // Vertical padding
            true // Fill background
          );
        }
      }
    }
    
    // Add a triangle marker for current heading at center of screen
    var triangleWidth = 14;  // Width of the triangle base
    var triangleHeight = 8; // Height of the triangle
    var centerX = screenHalfWidth;
    var triangleY = separatorY;
    var trianglePoints = [
      [centerX, triangleY - triangleHeight], // Top point
      [centerX - triangleWidth/2, triangleY], // Bottom left
      [centerX + triangleWidth/2, triangleY]  // Bottom right
    ];
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.fillPolygon(trianglePoints);

    // Draw the heading degrees text below the compass
    var headingText = isHeadingValid ? headingDegrees.format("%d") + "°" : "NO HDG";
    var headingY = screenHeight - dc.getFontHeight(DAY_FONT) + 8; // Position below the labels
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.drawText(centerX + 3, headingY, DAY_FONT, headingText, 
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    // Reset pen width to default
    dc.setPenWidth(1);
  }

  // Draw Vault Boy with heart rate and stat bars
  function drawVaultBoy(dc as Dc) as Void {
    // Load the Vault Boy bitmap from resources
    var vaultBoyBitmap = WatchUi.loadResource(Rez.Drawables.vaultboy);

    // Get bitmap dimensions for positioning
    var bitmapWidth = vaultBoyBitmap.getWidth();
    var bitmapHeight = vaultBoyBitmap.getHeight();
    
    // Position relative to RIGHT side of screen
    var rightMargin = 20;
    var topMargin = 85;
    
    // Calculate the x position relative to right edge
    var bitmapX = screenWidth - bitmapWidth - rightMargin;
    var bitmapY = topMargin;
    
    // Draw the bitmap
    dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
    dc.drawBitmap2(bitmapX, bitmapY, vaultBoyBitmap, {:tintColor => THEME_BRIGHT});
    
    // Calculate heart rate position relative to the bitmap
    // (centered on vault boy's chest)
    if (heartRate > 0) {
      var heartX = (bitmapX + (bitmapWidth * 0.52)).toNumber();
      var heartY = (bitmapY + (bitmapHeight * 0.45)).toNumber();
      
      // Format heart rate text
      var heartRateText = heartRate.toString();
      
      // Draw heart rate in inverted box
      drawInvertedText(
        dc,
        heartX,
        heartY,
        heartRateText,
        DAY_FONT,
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        1,  // Horizontal padding
        0,  // Vertical padding
        true // Fill background for inverted look
      );
    }
    
    // Calculate stat percentages
    var topPercent = bodyBattery.toFloat() / 100;
    var topLeftPercent = steps.toFloat() / stepGoal;
    var topRightPercent = activeMinutes.toFloat() / activeMinutesGoal;
    var bottomLeftPercent = stress.toFloat() / 100;
    var bottomRightPercent = floorsClimbed.toFloat() / floorsClimbedGoal;

    // Add * to labels if the stat is maxed out
    var topLabel = "ENERGY";
    var topLeftLabel = topLeftPercent == 1.0 ? "STPS*" : "STPS";
    var topRightLabel = topRightPercent == 1.0 ? "ACTV*" : "ACTV";
    var bottomLeftLabel = bottomLeftPercent == 1.0 ? "STSS!" : "STSS";
    var bottomRightLabel = bottomRightPercent == 1.0 ? "FLRS*" : "FLRS";

    // Draw stat bars with positions relative to vault boy bitmap
    drawStatBar(dc, bitmapX + 10, bitmapY - 37, topLabel, topPercent, 90, false, false);
    drawStatBar(dc, bitmapX - 2, bitmapY, topLeftLabel, topLeftPercent, 30, true, false);
    drawStatBar(dc, bitmapX + bitmapWidth - 25, bitmapY, topRightLabel, topRightPercent, 30, true, true);
    drawStatBar(dc, bitmapX - 2, bitmapY + 62, bottomLeftLabel, bottomLeftPercent, 30, true, false);
    drawStatBar(dc, bitmapX + bitmapWidth - 25, bitmapY + 62, bottomRightLabel, bottomRightPercent, 30, true, true);
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

    // Get the current time
    var hour = currentTime.hour;
    var min = currentTime.min;
    var hourDecimal = hour + (min / 60.0);
    
    // Default sunrise/sunset times
    var sunriseHour = 6;  // Default 6 AM if no sunrise time available
    var sunsetHour = 20;  // Default 8 PM if no sunset time available
    var sunriseMinutes = 0;
    var sunsetMinutes = 0;
    
    // Use actual sunrise/sunset times if available
    if (sunrise != null && sunset != null) {
      var sunriseTime = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
      var sunsetTime = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
      
      sunriseHour = sunriseTime.hour;
      sunriseMinutes = sunriseTime.min;
      sunsetHour = sunsetTime.hour;
      sunsetMinutes = sunsetTime.min;
    }
      
    // Calculate decimal sunrise/sunset for more precise calculations
    var sunriseDecimal = sunriseHour + (sunriseMinutes / 60.0);
    var sunsetDecimal = sunsetHour + (sunsetMinutes / 60.0);
    
    // Calculate daylight hours
    var daylightHours;
    if (sunsetDecimal >= sunriseDecimal) {
      daylightHours = sunsetDecimal - sunriseDecimal;
    } else {
      daylightHours = (24 - sunriseDecimal) + sunsetDecimal;
    }
    var nightHours = 24 - daylightHours;
    
    // Calculate hours since sunrise
    var hoursSinceSunrise;
    if (hourDecimal >= sunriseDecimal) {
      hoursSinceSunrise = hourDecimal - sunriseDecimal;
    } else {
      hoursSinceSunrise = hourDecimal + 24 - sunriseDecimal;
    }

    // Calculate hours till sunset
    // Calculate hours till sunset
    var hoursUntilSunset;
    if (hoursSinceSunrise < daylightHours) {
      // During day: just subtract hours since sunrise from total daylight hours
      hoursUntilSunset = daylightHours - hoursSinceSunrise;
    } else {
      // During night: add remaining night hours and full daylight hours
      var hoursSinceSunset = hoursSinceSunrise - daylightHours;
      hoursUntilSunset = nightHours - hoursSinceSunset + daylightHours;
    }
    
    // Determine if it's day or night
    var isDay = false;
    if (sunriseDecimal <= sunsetDecimal) {
      // Normal day case
      isDay = (hourDecimal >= sunriseDecimal && hourDecimal < sunsetDecimal);
    } else {
      // Day spans midnight
      isDay = (hourDecimal >= sunriseDecimal || hourDecimal < sunsetDecimal);
    }
    
    // Calculate position around the arc (0.0 to 1.0)
    var arcPosition;
    if (hoursSinceSunrise < daylightHours) {
      // Day time (sunrise to sunset): Left to right
      arcPosition = hoursSinceSunrise / daylightHours;
    } else {
      // Night time (sunset to sunrise): Right to left
      var hoursSinceSunset = hoursSinceSunrise - daylightHours;
      arcPosition = 1.0 - (hoursSinceSunset / nightHours);
    }
    
    // Choose the appropriate icon based on time since sunrise
    var iconText;
    if (isDay) {
      if (hoursSinceSunrise < 2) {
        iconText = "a";  // Dawn (0-1 hours after sunrise)
      } else if (hoursSinceSunrise < 4) {
        iconText = "b";  // Morning (1-3 hours after sunrise)
      } else if (hoursSinceSunrise < 4 && hoursUntilSunset >= 4) {
        iconText = "c";  // Midday (5-? hours after sunrise)
      } else if (hoursUntilSunset < 4 && hoursUntilSunset >= 2) {
        iconText = "b";  // Afternoon (3 hours until sunset)
      } else if (hoursUntilSunset < 2) {
        iconText = "a";  // Dusk (1 hour until sunset)
      } else {
        iconText = "c";  // Default just in case
      }
    } else {
      iconText = "d";  // Night
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
    var iconWidth = dc.getTextWidthInPixels(iconText, ICON_FONT);
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

    // Determine whether to show sunrise or sunset based on what's coming up next
    var sunEventText = null; // Default if times are not available
    
    if (sunrise != null && sunset != null) {
      // Get current time in minutes since midnight
      var currentTimeMinutes = currentTime.hour * 60 + currentTime.min;
      
      // Convert sunrise and sunset to minutes since midnight
      var sunriseTimeMinutes = sunriseHour * 60 + sunriseMinutes;
      var sunsetTimeMinutes = sunsetHour * 60 + sunsetMinutes;
      
      // Determine which is coming up next
      var timeToSunrise = (sunriseTimeMinutes - currentTimeMinutes + 1440) % 1440;
      var timeToSunset = (sunsetTimeMinutes - currentTimeMinutes + 1440) % 1440;
        
      if (timeToSunrise < timeToSunset) {
        // Sunrise is next
        sunEventText = Lang.format("$1$:$2$", [toDisplayHour(sunriseHour), sunriseMinutes.format("%02d")]);
      } else {
        // Sunset is next
        sunEventText = Lang.format("$1$:$2$", [toDisplayHour(sunsetHour), sunsetMinutes.format("%02d")]);
      }
    }

    if (sunEventText != null) {
      var sunEventTextWidth = dc.getTextWidthInPixels(sunEventText, DAY_FONT);
      
      // Calculate text dimensions and position
      var sunEventX = screenHalfWidth;
      var sunEventY = arcLeftmostY;
      
      // Calculate tab points
      var tabLeftX = sunEventX - (sunEventTextWidth/2) - tabPadding;
      var tabRightX = sunEventX + (sunEventTextWidth/2) + tabPadding;
      
      // Draw the line with detour under text (in multiple segments)
      dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
      
      // Left segment of line
      dc.drawLine(arcLeftmostX + 2, arcLeftmostY, tabLeftX, arcLeftmostY);

      // Right segment of line
      dc.drawLine(tabRightX, arcRightmostY, arcRightmostX, arcRightmostY);

      // Draw the text
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
    dc.drawText(xPos, yPos, ICON_FONT, iconText, Graphics.TEXT_JUSTIFY_CENTER);
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
    drawStatBar(dc, startX, startY, labels[0], percentages[0], barLengths[0], false, false);
    drawStatBar(dc, startX, startY + spacing, labels[1], percentages[1], barLengths[1], false, false);
    drawStatBar(dc, startX, startY + spacing*2, labels[2], percentages[2], barLengths[2], false, false);
    drawStatBar(dc, startX, startY + spacing*3, labels[3], percentages[3], barLengths[3], false, false);
  }

  // Draw a stat bar with progress indicator
  function drawStatBar(dc as Dc, x as Number, y as Number, label as String, 
                       percentage as Float, length as Number, harpoon as Boolean, 
                       left as Boolean) as Void {
    // Constants
    var leftBarHeight = 11;      // Height of left vertical line
    var triangleHeight = 7;     // Height of the triangle
    var triangleWidth = 7;      // Width of the triangle
    
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
      
      if (harpoon) {
        // Draw left triangle (pointing left)
        var leftX = barX - 1;
        var points = [
          [leftX, barY],
          [leftX - triangleWidth, barY],
          [leftX, barY + triangleHeight]
        ];
        dc.fillPolygon(points);
      } else {
        // Just draw a line
        dc.fillRectangle(barX + length - 1, barY, 2, leftBarHeight);
      }
      
      // Draw progress fill from right to left
      var clampedPercentage = percentage > 1.0 ? 1.0 : percentage;
      var fillWidth = ((length - 4) * clampedPercentage).toNumber();
      if (fillWidth > 0) {
        dc.fillRectangle(barX + length - 3 - fillWidth, barY + 3, fillWidth, leftBarHeight - 3);
      }
    } else {
      // Draw left vertical line for right orientation
      dc.fillRectangle(barX, barY, 2, leftBarHeight);
      
      if (harpoon) {
        // Draw right triangle (pointing right)
        var rightX = barX + length;
        var points = [
          [rightX, barY],
          [rightX + triangleWidth, barY],
          [rightX, barY + triangleHeight]
        ];
        dc.fillPolygon(points);
      } else {
        // Just draw a line
        dc.fillRectangle(barX + length - 1, barY, 2, leftBarHeight);
      }
      
      // Draw progress fill from left to right
      var fillWidth = ((length - 4) * percentage).toNumber();
      if (fillWidth > 0) {
        dc.fillRectangle(barX + 3, barY + 3, fillWidth, leftBarHeight - 3);
      }
    }
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
    var hour = toDisplayHour(currentTime.hour);
    var min = currentTime.min;
    var isPM = currentTime.hour >= 12; // Determine AM/PM
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
    var alarmIconText = "g";
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
    
    if (use24Hour) {
      // No AM/PM in 24-hour format, so draw a solid right edge
      dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, boxY, BAR_WIDTH, boxBottomY - boxY + BAR_WIDTH);
    } else {
      dc.fillRectangle(boxX + boxWidth - BAR_WIDTH, boxY, BAR_WIDTH, ampmBreakTop - boxY);

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
    if (!use24Hour) {
      dc.setColor(THEME_BRIGHT, Graphics.COLOR_TRANSPARENT);
      dc.drawText(ampmX, ampmTopY, DATE_FONT, ampmTop, Graphics.TEXT_JUSTIFY_CENTER);
      dc.drawText(ampmX, ampmBottomY, DATE_FONT, ampmBottom, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
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
