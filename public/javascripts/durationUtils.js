/**
 * Utility class to calculate and format durations. Used when saving a worklog
 * @var minsPerDay : Number of minutes in a day
 * @var daysPerWeek : Number of days in a week
 * @var durationFormat : Number representing the duration format to use
 * @var translatedWords : array containing the translated symbols. Used when converting durations like '1w 2d 3h 4m'
 */
function DurationUtils (minsPerDay, daysPerWeek, durationFormat, dateTimeFormat, translatedWords) {

  this.translatedWords = translatedWords;
  this.minsPerDay = minsPerDay;
  this.daysPerWeek = daysPerWeek;
  this.durationFormat = durationFormat;
  this.dateTimeFormat = dateTimeFormat;

  /**
   * Returns the number of minutes between two dates. 
   * The dates must be in the same format as this.dateTimeFormat.
   * @var startText : String representing the earliest date
   * @var endText : String representing the latest date
   */
  this.calculateDuration = function(startText, endText) {
    var start = Date.parseExact(startText, this.dateTimeFormat);
    var end = Date.parseExact(endText, this.dateTimeFormat);
    return (end - start) / 1000 / 60;
  };

  /**
   * Converts a formatted duration into an array representing the number of weeks, days, hours and minutes. 
   * The length of a day and the number of days per week are calculated using this.minsPerDay and this.daysPerWeek.
   * @var text : String representing a formatted duration
   */
  this.convertText = function(text) {
    if (text == null) return null;
    text = text.toLowerCase().replace(/^ +| +$/, "");
    return this.converters[this.durationFormat][1](text);
  };

  /**
   * Returns a formatted string representing a certain duration
   * @var duration : the number of minutes
   **/
  this.formatDuration = function(duration) {
    var num = this.numberToDuration(duration);
    var converter = this.converters[this.durationFormat][2];
    return converter(num);
  };

  /**
  * Transform a number of minutes into an array representing the equivalent number of weeks, days, hours, and minutes. 
  * The length of a day and the number of days per week are taken from the variables minsPerDay and daysPerWeek.
  * array format :
  * t['weeks'] = int,
  * t['days'] = int,
  * t['hours'] = int,
  * t['minutes'] = int
  **/
  this.numberToDuration = function(duration) {
    var t = new Array();

    t['weeks'] = Math.floor( duration / (this.minsPerDay  * this.daysPerWeek) );
    duration = duration % (this.minsPerDay * this.daysPerWeek);
    t['days'] = Math.floor( duration / this.minsPerDay );
    duration = duration % this.minsPerDay
    t['hours'] = Math.floor ( duration / 60 );
    duration = duration % 60
    t['minutes'] = duration;

    return t;
  };
  
  this.isProperlyFormatted = function(text) {
    return this.converters[this.durationFormat][0].test(text);
  }

  function parseWordedDuration(text) {
    var total = 0;
    match = this.converters[this.durationFormat][0].exec(text);
    if (match[2] != null) total += parseInt(match[2]) * this.minsPerDay * this.daysPerWeek;
    if (match[5] != null) total += parseInt(match[5]) * this.minsPerDay;
    if (match[8] != null) total += parseInt(match[8]) * 60;
    if (match[11] != null) total += parseInt(match[11]);
    return total;
  }

  function parseColumnDuration(text) {
    var total = 0;
    var parts = text.split(":");
    for (var i = parts.length; i > 0; i--) {
      if (parts.length - i == 0) total += parseInt(parts[i - 1]);
      else if (parts.length - i == 1) total += parseInt(parts[i - 1]) * 60;
      else if (parts.length - i == 2) total += parseInt(parts[i - 1]) * minsPerDay;
      else if (parts.length - i == 3) total += parseInt(parts[i - 1]) * minsPerDay * daysPerWeek;
    }
    return total;
  }

  function parseDecimalDuration(text) {
    return Math.floor(parseFloat(text) * 60);
  }

  function formatWordedDuration(duration) {
    var result = "";
    //1w 2d 3h 4m || 1w2d3h4m
    if (t['weeks'] != 0) result += duration['weeks'] + this.translatedWords['w'];
    if (t['days'] != 0) result += duration['days'] + this.translatedWords['d'];
    if (t['hours'] != 0) result += duration['hours'] + this.translatedWords['h'];
    result += duration['minutes'] + this.translatedWords['m'];
    if (this.durationFormat == 1) result = result.replace(" ", "");
    return result;
  }

  function formatColumnDuration(duration) {
    var result = "";
    if (duration['weeks'] != 0) result = duration['weeks'];
    if (duration['days'] != 0) result += ":" + duration['days'];
    result += ":" + jQuery.format('{0:01d}:{1:02d}',[duration['hours'], duration['minutes']]);
    if (result.charAt(0) == ':') result = result.slice(1);
    return result;
  }

  function formatTimeDuration(duration) {
    var hours = (duration['weeks'] * this.daysPerWeek * this.minsPerDay +
      duration['days'] * this.minsPerDay) / 60 + duration['hours'];
    return jQuery.format('{0:01d}:{1:02d}',[hours, duration['minutes']]);
  }

  function formatDecimalDuration(duration) {
    var number = duration['weeks'] * this.daysPerWeek * this.minsPerDay;
    number += duration['days'] * this.minsPerDay;
    number += duration['hours'] * 60;
    number += duration['minutes'];
    return (number / 60).toFixed(2);
  }

  /* Constructor */
  var regex = "((\\d+)(" + this.translatedWords['w'] + "))? ?";
  regex += "((\\d+)(" + this.translatedWords['d'] + "))? ?";
  regex += "((\\d+)(" + this.translatedWords['h'] + "))? ?";
  regex += "((\\d+)(" + this.translatedWords['m'] + "))?";
  
  this.converters = new Array();
  this.converters.push(new Array(regex, parseWordedDuration, formatWordedDuration));
  this.converters.push(new Array(regex, parseWordedDuration, formatWordedDuration));
  this.converters.push(new Array(/((\d+):)?((\d+):)?((\d+):)?((\d{2}))/, parseColumnDuration, formatColumnDuration));
  this.converters.push(new Array(/\d+:\d{2}/, parseColumnDuration, formatTimeDuration));
  this.converters.push(new Array(/\d+\.\d{2}/, parseDecimalDuration, formatDecimalDuration));
}
