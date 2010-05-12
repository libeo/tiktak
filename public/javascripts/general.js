var intervalId = null;
var intervalSecs = 75;

function updateSheetInfo() {
  jQuery.ajax({dataType:'script', type:'post', url:'/tasks/update_sheet_info?format=js'});
}

function toggleUpdater() {
  if (intervalId == null) {
    intervalId = setInterval("updateSheetInfo()", intervalSecs * 1000);
  } else {
    clearInterval(intervalId);
    intervalId = null;
  }
}

/*
function sendSheetText(text) {
  jQuery.post('/sheets/updatelog', {description: text})
}

function updateLog() {
  sendSheetText(jQuery('#worklog_body').val());
  return true;
}
*/

function toggleWorkLogJournal() {
  if ( jQuery('#worklog_form').is(':visible') ) {
    jQuery('#worklog_form').toggle(500);
    updateLog();
    toggleUpdater();
  } else {
    jQuery('#worklog_form').toggle(500);
    toggleUpdater();
  }
}

function warnWorkLogJournal() {
  var log = jQuery('#worklog_body');
  var empty = (jQuery.trim(log.val()) == '');
  if (empty) {
    if( !log.is(':visible')) {
      toggleWorkLogJournal();
    } else {
      log.effect('hightlight', {}, 1000);
      log.effect('hightlight', {}, 1000);
      log.effect('hightlight', {}, 1000);
    }
  }
  return empty;
}

function sendWorkLogJournal() {
  showProgress();
  /*if (!warnWorkLogJournal()) {*/
  jQuery.ajax({
    data: {description: jQuery('#worklog_body').val(), format:'js'},
    dataType: 'script',
    url: '/sheets/stop',
    type: 'post'
  });
  hideProgress();
}

function defineToggleRightColumn() {
  jQuery('#right_button').toggle(
    function() {
      jQuery('#right_button').css('float', 'right');
      jQuery('#filters_content').css('display', 'none');
      jQuery('#right_content').css('width', '0%');
      jQuery('#subcontent').css('width', '97%');
      jQuery('#right_button a img').attr('src', '/images/general/img_co_icon-filters-close.png')
      jQuery.cookie("showrightcolumn", "false");
    },
    function() {
      jQuery('#right_button').css('float', 'left');
      jQuery('#filters_content').css('display', '');
      jQuery('#right_content').css('width', '15%');
      jQuery('#subcontent').css('width', '85%');
      jQuery('#right_button a img').attr('src', '/images/general/img_co_icon-filters-open.png')
      jQuery.cookie("showrightcolumn", "true");
    }
  );
}

function toggleTaskBookmarked(taskId) {
  var links = jQuery('.entry_icon_bookmark', '.tasks-' + taskId);
  var imgs = jQuery('img', links);
  var bookmarked = imgs.hasClass('bookmarked');

  if (unread) {
    imgs.attr('src', '/images/task/img_co_icon-bookmark-up.png');
  } else {
    imgs.attr('src', '/images/task/img_co_icon-bookmark-select.png');
  }
  imgs.toggleClass('bookmarked');
  jQuery.post('/tasks/bookmark', {id: taskId, bookmark: !bookmarked});
}
