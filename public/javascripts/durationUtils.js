/**
 * Utility class to calculate and format durations. Used when saving a worklog
 * @var minsPerDay : Number of minutes in a day
 * @var daysPerWeek : Number of days in a week
 * @var durationFormat : Number representing the duration format to use
 * @var translatedWords : array containing the translated symbols. Used when converting durations like '1w 2d 3h 4m'
 */
function DurationUtils(minsPerDay, daysPerWeek, durationFormat, dateTimeFormat, translatedWords) {

  var translatedWords = translatedWords;
  var minsPerDay = minsPerDay;
  var daysPerWeek = daysPerWeek;
  var durationFormat = durationFormat;
  var dateTimeFormat = dateTimeFormat;
  var converters = new Array();

  var parseWordedDuration = function(text) {
    var total = 0;
    match = converters[durationFormat][0].exec(text);
    if (match[2] != null) total += parseInt(match[2]) * minsPerDay * daysPerWeek;
    if (match[5] != null) total += parseInt(match[5]) * minsPerDay;
    if (match[8] != null) total += parseInt(match[8]) * 60;
    if (match[11] != null) total += parseInt(match[11]);
    return total;
  };

  var parseColumnDuration = function(text) {
    var total = 0;
    var parts = text.split(":");
    for (var i = parts.length; i > 0; i--) {
      if (parts.length - i == 0) total += parseInt(parts[i - 1]);
      else if (parts.length - i == 1) total += parseInt(parts[i - 1]) * 60;
      else if (parts.length - i == 2) total += parseInt(parts[i - 1]) * minsPerDay;
      else if (parts.length - i == 3) total += parseInt(parts[i - 1]) * minsPerDay * daysPerWeek;
    }
    return total;
  };

  var parseDecimalDuration = function(text) {
    return Math.floor(parseFloat(text) * 60);
  };

  var formatWordedDuration = function(duration) {
    var result = "";
    //1w 2d 3h 4m || 1w2d3h4m
    if (duration['weeks'] != 0) result += duration['weeks'] + translatedWords['w'] + ' ';
    if (duration['days'] != 0) result += duration['days'] + translatedWords['d'] + ' ';
    if (duration['hours'] != 0) result += duration['hours'] + translatedWords['h'] + ' ';
    result += duration['minutes'] + translatedWords['m'];
    if (durationFormat == 1) result = result.replace(/\s+/g, '');
    return result;
  };

  var formatColumnDuration = function(duration) {
    var result = "";
    if (duration['weeks'] != 0) result = duration['weeks'];
    if (duration['days'] != 0) result += ":" + duration['days'];
    result += ":" + jQuery.format('{0:01d}:{1:02d}',[duration['hours'], duration['minutes']]);
    if (result.charAt(0) == ':') result = result.slice(1);
    return result;
  };

  var formatTimeDuration = function(duration) {
    var hours = (duration['weeks'] * daysPerWeek * minsPerDay +
      duration['days'] * minsPerDay) / 60 + duration['hours'];
    return jQuery.format('{0:01d}:{1:02d}',[hours, duration['minutes']]);
  };

  var formatDecimalDuration = function(duration) {
    var number = duration['weeks'] * daysPerWeek * minsPerDay;
    number += duration['days'] * minsPerDay;
    number += duration['hours'] * 60;
    number += duration['minutes'];
    return (number / 60).toFixed(2);
  };


  var init = function() {
    var regex = "^\\s*((\\d+)(" + translatedWords['w'] + "))?\\s*";
    regex += "((\\d+)(" + translatedWords['d'] + "))?\\s*";
    regex += "((\\d+)(" + translatedWords['h'] + "))?\\s*";
    regex += "((\\d+)(" + translatedWords['m'] + "))?\\s*$";
    regex = new RegExp(regex);

    converters.push(new Array(regex, parseWordedDuration, formatWordedDuration));
    converters.push(new Array(regex, parseWordedDuration, formatWordedDuration));
    converters.push(new Array(/((\d+):)?((\d+):)?((\d+):)?((\d{2}))/, parseColumnDuration, formatColumnDuration));
    converters.push(new Array(/\d+:\d{2}/, parseColumnDuration, formatTimeDuration));
    converters.push(new Array(/\d+\.\d{2}/, parseDecimalDuration, formatDecimalDuration));
  };

  init();

  //Constructor
  return {

    /**
     * Returns the number of minutes between two dates. 
     * The dates must be in the same format as this.dateTimeFormat.
     * @var startText : String representing the earliest date
     * @var endText : String representing the latest date
     */
    calculateDuration: function(startText, endText) {
      var start = Date.parseExact(startText, dateTimeFormat);
      var end = Date.parseExact(endText, dateTimeFormat);
      return (end - start) / 1000 / 60;
    },

    /**
     * Converts a formatted duration into an array representing the number of weeks, days, hours and minutes. 
     * The length of a day and the number of days per week are calculated using this.minsPerDay and this.daysPerWeek.
     * @var text : String representing a formatted duration
     */
    convertText: function(text) {
      if (text == null) return null;
      text = text.toLowerCase().replace(/^ +| +$/, "");
      return converters[durationFormat][1](text);
    },

    /**
     * Returns a formatted string representing a certain duration
     * @var duration : the number of minutes
     **/
    formatDuration: function(duration) {
      var num = this.numberToDuration(duration);
      var converter = converters[durationFormat][2];
      return converter(num);
    },

    /**
    * Transform a number of minutes into an array representing the equivalent number of weeks, days, hours, and minutes. 
    * The length of a day and the number of days per week are taken from the variables minsPerDay and daysPerWeek.
    * array format :
    * t['weeks'] = int,
    * t['days'] = int,
    * t['hours'] = int,
    * t['minutes'] = int
    **/
    numberToDuration: function(duration) {
      var t = new Array();

      t['weeks'] = Math.floor( duration / (minsPerDay  * daysPerWeek) );
      duration = duration % (minsPerDay * daysPerWeek);
      t['days'] = Math.floor( duration / minsPerDay );
      duration = duration % minsPerDay
      t['hours'] = Math.floor ( duration / 60 );
      duration = duration % 60
      t['minutes'] = duration;

      return t;
    },
    
    /**
     * Check if a string is formatted using the duration format.
     * @var text : the string to check
     * @return : true if the string is properly formatted, otherwise false
     */
    isProperlyFormatted: function(text) {
      return converters[durationFormat][0].test(text);
    }

  };

}
