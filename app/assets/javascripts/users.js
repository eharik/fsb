jQuery(function(){

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
