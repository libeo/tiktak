function toggleFilterPanel(link, cookie) {
  link = jQuery(link);
  parent().next().toggle(500, function(){
      if (!jQuery.cookie(cookie) == 'true') {
          jQuery.cookie(cookie, 'true');
      } else {
          jQuery.cookie(cookie, 'false');
      }
  });
}
