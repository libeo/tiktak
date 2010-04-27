function updateSheetInfo() {
  alert('UPDATING');
  jQuery.ajax({dataType:'script', type:'post', url:'/tasks/update_sheet_info?format=js'});
}

function toggleUpdater() {
  if (intervalId == null) {
    intervalId = setInterval("updateSheetInfo()", 30 * 1000);
  } else {
    clearInterval(intervalId);
    intervalId = null;
  }
}

function sendSheetText(text) {
  jQuery.ajax({data: {text: text},
     type: 'post',
     url: '/tasks/updatelog'
     });
}

function updateLog() {
  sendSheetText(jQuery('#worklog_body').val());
  return true;
}

