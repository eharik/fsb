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
    

    jQuery("input[type='radio']").each(function(index, button){
        jQuery(button).click(function(){
            game_id =  $(this).parents(".bet").data('game');
            bet_type = $(this).attr('value');
            league_id = $("#league_info_container").data("league_id");
            $.get("/bets/new", {game: game_id, bet: bet_type, league: league_id}, function(){
                $("input[name='bet_risk']").blur(function(){
                    win = $("#bet_risk").val()*0.95;
                    $("#to_win").empty();
                    $("#to_win").append(win);
                });
            });
        });
    });
    
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
                $.post("/bets", {game: game_id, risk: bet_risk, league: league_id, bet: bet_type})
            })
            $("#bet_slip_container").children(".content").empty();
        })
    });
    
});
