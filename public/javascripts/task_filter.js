function toggleFilterPanel(link, cookie) {
  jQuery(link).parent().next().toggle(500, function(){
      if (jQuery.cookie(cookie) == 'false') {
          jQuery.cookie(cookie, 'true');
      } else {
          jQuery.cookie(cookie, 'false');
      }
  });
}
