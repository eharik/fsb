// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery(function(){

/* Credit Release Buttons */
    jQuery("input[class='expand_league']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $(this).attr("id");
            path_string = '/super_user/' + league_id + '/settings';
            $.ajax({
               url: path_string,
               type: 'GET'
            });
            path_string = '/super_user/' + league_id + '/users';
            $.ajax({
               url: path_string,
               type: 'GET'
            });            
        });
    });
    
});
