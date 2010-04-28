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
