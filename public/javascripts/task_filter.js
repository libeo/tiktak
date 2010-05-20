function toggleFilterPanel(link, cookie) {
  jQuery(link).parent().next().toggle(500, function(){
      if (jQuery.cookie(cookie) == 'false') {
          jQuery.cookie(cookie, 'true');
      } else {
          jQuery.cookie(cookie, 'false');
      }
  });
}

/*
Removes the search filter the link belongs to and submits
the containing form.
*/
function removeSearchFilter(link) {
    link = jQuery(link);
    var form = link.parents("form");
    link.parent(".search_filter").remove();

    submitSearchFilterForm();
}

function addSearchFilter(textField, selected) {
    selected = jQuery(selected);
    var idField = selected.find(".id");
    var typeField = selected.find(".type");
    
    if (idField && idField.length > 0) {
	var filterForm = jQuery("#search_filter_form");
	filterForm.append(idField.clone());
	filterForm.append(typeField.clone());
	submitSearchFilterForm();
    }
    else {
	// probably selected a heading, just ignore
    }
}

/* 
Submits the search filter form. If we are looking at the task list, 
does that via ajax. Otherwise does a normal html post
*/
function submitSearchFilterForm() {
    var form = jQuery("#search_filter_form")[0];
    var redirect = jQuery(form.redirect_action).val();
    form.submit();
    /*
    if (redirect.indexOf("/tasks/list_new?") >= 0) {
      form.onsubmit();
    }
    else {
      form.submit();
    }
    */
}
