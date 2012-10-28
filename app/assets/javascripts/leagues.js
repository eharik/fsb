jQuery(function(){

// ************** Add bet to bet slip ***************** // 
    jQuery("input[type='radio']").each(function(index, button){
        jQuery(button).click(function(){
            var game_id =  $(this).parents(".bet").data('game');
            var bet_type = $(this).attr('value');
            var league_id = $("#league_info_container").data("league_id");
            $.get("/bets/new", {game: game_id, bet: bet_type, league: league_id} )
		})
	})
                
    // Update win amount based on risk
	$('body').delegate("input[name='bet_risk']", 'blur', function(){
        var risk = parseFloat($(this).val())
		var win = risk*0.95		
		if (isNaN(win)) {
			win = 0
		}
        var win_string = sprintf("%.0f", win );
        $(this).parents(".left").siblings(".left").children("#to_win").empty();
        $(this).parents(".left").siblings(".left").children("#to_win").append(win_string);
		var total_risk = 0
		var total_win = 0			
		$("input[name='bet_risk']").each(function(){
			var risk = parseFloat($(this).val())
			if (isNaN(risk)){
				risk = 0
			}
			total_risk += risk			
		})
		$("span[id='to_win']").each(function(){
			var win = parseFloat($(this).text())
			if (isNaN(win)){
				win = 0
			}
			total_win += win						
		})					
		$('#total_risk').empty()
		$('#total_risk').append(total_risk)
		$('#total_win').empty()
		$('#total_win').append(total_win)	
    });    

    // Remove single bet
	jQuery('body').delegate("button[type='submit'][id='remove_bet']", 'click', function(){
        $(this).parents('container').remove();
		var total_risk = 0
		var total_win = 0			
		$("input[name='bet_risk']").each(function(){
			var risk = parseFloat($(this).val())
			if (isNaN(risk)){
				risk = 0
			}
			total_risk += risk			
		})
		$("span[id='to_win']").each(function(){
			var win = parseFloat($(this).text())
			if (isNaN(win)){
				win = 0
			}
			total_win += win						
		})					
		$('#total_risk').empty()
		$('#total_risk').append(total_risk)
		$('#total_win').empty()
		$('#total_win').append(total_win)
    });
 
	// Lock Button
    jQuery('body').delegate("button[type='submit'][id='lock']",'click', function(){
        var class_attr = $(this).attr("class");
        var selected = true;
        if ( class_attr.indexOf( "selected" ) == -1 )
        {
            selected = false;
        }
        if ( selected ) {
            class_attr = "no_pad no_margin bet_button";
            $(this).attr("class", class_attr);
            $(this).parent().siblings('#risk_container').children('#bet_risk').removeAttr('readonly');
            $(this).parent().siblings('#risk_container').children('#bet_risk').val('');
            $(this).parent().siblings('#win_container').children('#to_win').text('0');
        }
        else
        {
            class_attr = "no_pad no_margin bet_button selected"
            $(this).attr("class", class_attr);
            $(this).parent().siblings('#risk_container').children('#bet_risk').attr('readonly', 'readonly');
            $(this).parent().siblings('#risk_container').children('#bet_risk').val('LOCK');
            $(this).parent().siblings('#win_container').children('#to_win').text('--');
        }
		var total_risk = 0
		var total_win = 0			
		$("input[name='bet_risk']").each(function(){
			var risk = parseFloat($(this).val())
			if (isNaN(risk)){
				risk = 0
			}
			total_risk += risk			
		})
		$("span[id='to_win']").each(function(){
			var win = parseFloat($(this).text())
			if (isNaN(win)){
				win = 0
			}
			total_win += win						
		})					
		$('#total_risk').empty()
		$('#total_risk').append(total_risk)
		$('#total_win').empty()
		$('#total_win').append(total_win)
    });
    
// ************** Bet Slip Buttons *******************//
  // Clear All Bets   
    jQuery("input[type='submit'][value='Clear Bets']").each(function(index, button){
        jQuery(button).click(function(){
            $("#bet_slip_container").children(".content").empty();
						$('#total_risk').empty()
						$('#total_risk').append("0")
						$('#total_win').empty()
						$('#total_win').append("0")
        })
    });
    
  // Place all bets
  jQuery("input[type='submit'][value='Place Bets']").each(function(index, button){
      jQuery(button).click(function(){
          //Check the bet slip for bets
          $(".new_bet").each(function(){
              bet_risk = $(this).children(".bet_bottom").children(".left").children("#bet_risk").val();         
              game_id = $(this).data("game");
              bet_type = $(this).data("bet_type");
              league_id = $("#league_info_container").data("league_id");
              if ( bet_risk == "LOCK" )
              {
                  bet_type = bet_type + ".lock";
              }
              if ( bet_risk > 0 || bet_risk == "LOCK" )
              {
                  if ( bet_risk == "LOCK" )
                  {
                      bet_risk = 0
                  }
                  $.post("/bets", {game: game_id, risk: bet_risk, league: league_id, bet: bet_type});
                  $("#bet_slip_container").children(".content").empty();
              }
              else
              {
                  alert('You have to risk something to place a bet!');
              }
							$('#total_risk').empty()
							$('#total_risk').append("0")
							$('#total_win').empty()
							$('#total_win').append("0")
          })
      })
  });

    
    
// ************** Buttons for sorting the bet listing *******************// 
  // Sort by Users (default)
    jQuery("input[id='sort_by_users']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            get_string = "/leagues/" + league_id + "/bets";
            show_for_string = "user";
            $.get(get_string , {user_id: user, league_id: league_id, sort_param: "user", show_for: show_for_string} );
        });
    });
    
    // Sort by Games
    jQuery("input[id='sort_by_games']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $("#league_info_container").attr("data-user_id");
            get_string = "/leagues/" + league_id + "/games";
            show_for_string = "games";
            $.get(get_string , {user_id: user, league_id: league_id, sort_param: "games", show_for: show_for_string} );
        });
    });
    
    // Sort by Amount
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
    
    // Sort by date
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
    
    // Sort by User
    jQuery("input[id='update_bets_for_user']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $("#index").children(".header").data("league_id");
            user = $(this).data("user");
            $('#league_info_container').attr('data-user_id', user );
            get_string = "/leagues/" + league_id + "/bets";
            $.get(get_string, {user_id: user, league_id: league_id, sort_param: "date", show_for: "user", direction: 'down'} );
        });
    });
    
    
    
// **************** League admin checkboxes *********************** //
  // Buy In
    jQuery("input[id='buy_in']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $(this).parents('#user_options').attr("data-league_id");
            user_id = $(this).parents('#user_options').attr("data-user_id");
            membership_id = $(this).parents('#user_options').attr("data-membership_id");
            path_string = '/memberships/' + membership_id + '/unlock_buy_in';
            selector_string = 'user_id=' + user_id;
            $.ajax({
                url: path_string,
                type: 'GET',
                data: selector_string
            });
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
  // Buy Back
    jQuery("input[id='buy_back']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $(this).parents('#user_options').attr("data-league_id");
            user_id = $(this).parents('#user_options').attr("data-user_id");
            membership_id = $(this).parents('#user_options').attr("data-membership_id");
            path_string = '/memberships/' + membership_id + '/unlock_buy_back';
            selector_string = 'user_id=' + user_id;
            $.ajax({
                url: path_string,
                type: 'GET',
                data: selector_string
            });
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
    
  // Remove Member from League (delete membership)    
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
    
    
    
// **************** Button on League Home to Deploy Credits ********************** //
    jQuery("input[class='credit_button']").each(function(index, button){
        jQuery(button).click(function(){
            league_id = $(this).parents('#league_info_container').attr("data-league_id");
            user_id = $(this).parents('#league_info_container').attr('data-user_id');
            membership_id = $(this).parents('#league_info_container').attr("data-membership_id");
            path_string = '/memberships/' + membership_id + '/deploy_credits';
            $.ajax({
                url: path_string,
                type: 'GET'
            });
        });
    });

// **************** Matchup Screen ********************************//
	jQuery("button[class~='week_button']").each(function(index, button){
		jQuery(button).click(function(){
			week_number = index+1
			class_string = 'week_button selected'
			$(this).attr('class', class_string)
                        user_id = $('#league_info_container').attr("data-user_id");
                        league_id = $('#league_info_container').attr("data-league_id");
			path_string = '/leagues/' + league_id + '/matchups'
                        selector_string = 'week_number=' + week_number + '&user_id=' + user_id
			$("button[class~='week_button']").each(function(index2,button){
				if (index2 != index)
				{
					$(this).attr('class', 'week_button')			
				}			
			});
			$.ajax({
				url: path_string,
				type: 'GET',
                                data: selector_string
			})
		});
	});
 	
	jQuery('.matchup').each(function(index,button){
		jQuery(button).click(function(){
			week_number = $('#matchup_container').attr('data-week')
			home_team_id = $(this).attr("data-home_team_id")
			away_team_id = $(this).attr("data-away_team_id")
                        user_id = (home_team_id > away_team_id) ? home_team_id : away_team_id
                        league_id = $('#league_info_container').attr("data-league_id");
			path_string = '/leagues/' + league_id + '/matchups'
                        selector_string = 'week_number=' + week_number + '&user_id=' + user_id
			$.ajax({
				url: path_string,
				type: 'GET',
		                data: selector_string
			})
		})
	})   
});
