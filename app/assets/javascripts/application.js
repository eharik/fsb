// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

jQuery(function(){
    
// Bet Buttons
    jQuery("input[type='radio']").each(function(index, button){
        jQuery(button).click(function(){
            game_id =  $(this).parents(".bet").data('game');
            bet_type = $(this).attr('value');
            league_id = $("#league_info_container").data("league_id");
            $.get("/bets/new", {game: game_id, bet: bet_type, league: league_id}, function(){
                $("input[name='bet_risk']").blur(function(index, button2){
                    win = $(this).val()*0.95;
                    win_string = sprintf("%.2f", win );
                    $(this).parents(".left").siblings(".right").children("#to_win").empty();
                    $(this).parents(".left").siblings(".right").children("#to_win").append(win_string);
                });
            });
        });
    });
 // Bet Slip Buttons   
    jQuery("input[type='submit'][value='Clear Bets']").each(function(index, button){
        jQuery(button).click(function(){
            $("#bet_slip_container").children(".content").empty();
        })
    });
    
    jQuery("input[type='submit'][value='Place Bets']").each(function(index, button){
        jQuery(button).click(function(){
            //Check the bet slip for bets
            $(".new_bet").each(function(){
                bet_risk = $(this).children(".bet_bottom").children(".left").children("#bet_risk").val();         
                game_id = $(this).data("game");
                bet_type = $(this).data("bet_type");
                league_id = $("#league_info_container").data("league_id");
                if ( bet_risk > 0 )
                {
                    $.post("/bets", {game: game_id, risk: bet_risk, league: league_id, bet: bet_type});
                    $("#bet_slip_container").children(".content").empty();
                }
                else
                {
                    alert('You have to risk something to place a bet!');
                }
            })
        })
    });
    
 // Buttons for sorting the bet listing   
    jQuery("input[id='sort_by_users']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            get_string = "/leagues/" + league_id + "/bets";
            show_for_string = "user";
            $.get(get_string , {user_id: user, league_id: league_id, sort_param: "user", show_for: show_for_string} );
        });
    });
    
    jQuery("input[id='sort_by_games']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            get_string = "/leagues/" + league_id + "/games";
            show_for_string = "games";
            $.get(get_string , {user_id: user, league_id: league_id, sort_param: "games", show_for: show_for_string} );
        });
    });
    
    jQuery("input[id='sort_by_amount']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            show_for_string = $("#index").children(".header").children("h2").children(".right").attr("data-sort_by");
            old_param = $('#order_by').attr('data-order_by');
            old_direction = $('#order_by').attr('data-order_direction');
            new_direction = 'down';
            g_id = 0;
            if (old_param == 'amount')
            {
                if(old_direction == 'up')
                {
                    new_direction = 'down';
                }
                else
                {
                    new_direction = 'up';
                }
            }
            if (show_for_string == 'users')
            {
                get_string = "/leagues/" + league_id + "/bets";
            }
            else
            {
                get_string = "/leagues/" + league_id + "/games";
                g_id = $('#league_standings_list').attr('data-game_id');
            }
            $.get(get_string , {game_id: g_id, user_id: user, league_id: league_id, sort_param: "amount", show_for: show_for_string, direction: new_direction} );     
        });
    });
    
    jQuery("input[id='sort_by_date']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            show_for_string = $("#index").children(".header").children("h2").children(".right").attr("data-sort_by");
            old_param = $('#order_by').attr('data-order_by');
            old_direction = $('#order_by').attr('data-order_direction');
            new_direction = 'up';
            g_id = 0;
            if (old_param == 'date')
            {
                if(old_direction == 'up')
                {
                    new_direction = 'down';
                }
                else
                {
                    new_direction = 'up';
                }
            }
            if (show_for_string == 'users')
            {
                get_string = "/leagues/" + league_id + "/bets";
            }
            else
            {
                get_string = "/leagues/" + league_id + "/games";
                g_id = $('#league_standings_list').attr('data-game_id');
            }
            $.get(get_string , {game_id: g_id, user_id: user, league_id: league_id, sort_param: "date", show_for: show_for_string, direction: new_direction} );
        });
    });
    
    jQuery("input[id='update_bets_for_user']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $(this).data("user");
            $('#league_info_container').attr('data-user_id', user );
            get_string = "/leagues/" + league_id + "/bets";
            $.get(get_string, {user_id: user, league_id: league_id, sort_param: "date", show_for: "user", direction: 'down'} );
        });
    });
    
// League admin checkboxes
    jQuery("input[id='buy_in']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $('#user_options').attr("data-league_id");
            user_id = $('#user_options').attr("data-user_id");
            membership_id = $('#user_options').attr("data-membership_id"); 
            /*$.get("/bets/new", {game: game_id, bet: bet_type, league: league_id}, function(){
                $("input[name='bet_risk']").blur(function(index, button2){
                    win = $(this).val()*0.95;
                    win_string = sprintf("%.2f", win );
                    $(this).parents(".left").siblings(".right").children("#to_win").empty();
                    $(this).parents(".left").siblings(".right").children("#to_win").append(win_string);
                });
            });*/
        });
        jQuery(button).confirm({
            timeout:5000,
            dialogShow:'fadeIn',
            dialogSpeed:'slow',
            msg: 'Deploy Credits?    ',
            wrapper: '<pre></pre>',
            buttons: {
                wrapper:'<button></button>',
                separator:'  '
            }  
        });
    });
    
    jQuery("input[id='buy_back']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $('#user_options').attr("data-league_id");
            user_id = $('#user_options').attr("data-user_id");
            membership_id = $('#user_options').attr("data-membership_id"); /*
            $.get("/bets/new", {game: game_id, bet: bet_type, league: league_id}, function(){
                $("input[name='bet_risk']").blur(function(index, button2){
                    win = $(this).val()*0.95;
                    win_string = sprintf("%.2f", win );
                    $(this).parents(".left").siblings(".right").children("#to_win").empty();
                    $(this).parents(".left").siblings(".right").children("#to_win").append(win_string);
                });
            });*/
        });
        jQuery(button).confirm({
            timeout:5000,
            dialogShow:'fadeIn',
            dialogSpeed:'slow',
            msg: 'Deploy Credits?    ',
            wrapper: '<pre></pre>',
            buttons: {
                wrapper:'<button></button>',
                separator:'  '
            }  
        });
    });
    
    jQuery("input[id='delete_membership']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $(this).parents('#user_options').attr("data-league_id");
            user_id = $(this).parents('#user_options').attr("data-user_id");
            membership_id = $(this).parents('#user_options').attr("data-membership_id");
            path_string = '/memberships/' + membership_id;
            selector_string = '#user_options[data-user_id=\"' + user_id + '\"]';
            $.ajax({
                url: path_string,
                type: 'DELETE'                
            });
            $(selector_string).remove();
        });
        jQuery(button).confirm({
            timeout:5000,
            dialogShow:'fadeIn',
            dialogSpeed:'slow',
            msg: 'Do you really want to remove this user from the league?    ',
            wrapper: '<pre></pre>',
            buttons: {
                wrapper:'<button></button>',
                separator:'  '
            }  
        });
    });
    
    
});
