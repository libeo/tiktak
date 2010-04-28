function updateSheetInfo() {
  jQuery.ajax({dataType:'script', type:'post', url:'/tasks/update_sheet_info?format=js'});
}

function toggleUpdater() {
  if (intervalId == null) {
    intervalId = setInterval("updateSheetInfo()", 75 * 1000);
  } else {
    clearInterval(intervalId);
    intervalId = null;
  }
}

function sendSheetText(text) {
  jQuery.post('/tasks/updatelog', {text: text})
}

function updateLog() {
  sendSheetText(jQuery('#worklog_body').val());
  return true;
}

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

function toggleRightColumn() {
  jQuery('#filters_content').toggle(
    function() {
      jQuery('#right_button').css('float', 'right');
      jQuery('#filters_content').css('display', 'none');
      jQuery('#right_content').css('width', '0%');
      jQuery('#subcontent').css('width', '97%');
    },
    function() {
      jQuery('#right_button').css('float', 'left');
      jQuery('#filters_content').css('display', '');
      jQuery('#right_content').css('width', '15%');
      jQuery('#subcontent').css('width', '85%');
    }
  );
}

/*
 Marks the task sender belongs to as unread.
 Also removes the "unread" class from the img html.
 */
function toggleTaskUnread(img, taskId) {
  var unread = jQuery(img).hasClass('unread');
  if (unread) {
    img.attr('src', 'images/task/img_co_icon-bookmark-up.png');
  } else {
    img.attr('src', 'images/task/img_co_icon-bookmark-select.png');
  }
  img.toggleClass('unread');
  jQuery.post('tasks/set_unread', {id: taskId, read: unread});
}
