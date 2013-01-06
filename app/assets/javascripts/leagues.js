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
		if ($(this).parents('#risk_container').length == 1){
		// non parlay bet
			win = getWin( risk )
			var win_string = sprintf("%.0f", win );
			$(this).parents(".left").siblings(".left").children("#to_win").empty();
			$(this).parents(".left").siblings(".left").children("#to_win").append(win_string);	
		}
		else 
		{
		// parlay bet
			updateParlayTally();
		}			
		updateBetSlipTally()
   })   

    // Remove single bet
	jQuery('body').delegate("button[type='submit'][id='remove_bet']", 'click', function(){
    $(this).parents('container').remove();		
		updateBetSlipTally()
   })

	// Parlay button
	jQuery('body').delegate("button[type='submit'][id='parlay']",'click', function(){
		//	get info from bet
		var game_id = $(this).parents('.bet').data('game')
		var bet_type = $(this).parents('.bet').data('bet_type')
		var league_id = $(this).parents('.bet').data('league_id')
		
 		//	remove bet from list
		$(this).parents('container').remove();
		
		if ( $('#parlay_container').length == 0)
		{	
			$.ajax({
		      url: '/parlay_header'
		  }).done( function()
				{
					$.ajax({
						url: '/add_parlay',
						data: 'game_id=' + game_id + '&league_id=' + league_id 
									+ '&bet_type=' + bet_type
					}).done( function() 
						{
							updateForParlay()
						})
				})
		}
		else
		{
			$.ajax({
				url: '/add_parlay',
				data: 'game_id=' + game_id + '&league_id=' + league_id 
							+ '&bet_type=' + bet_type
			}).done( function()
				{	
					updateForParlay()
				})
		}
	})

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
		updateBetSlipTally()
   })
    
// ************** Bet Slip Buttons *******************//
  // Clear All Bets   
  jQuery("input[type='submit'][value='Clear Bets']").each(function(index, button){
    jQuery(button).click(function(){
      $("#bet_slip_container").children(".content").empty();
			clearBetSlipTally()
    })
  })
  
  // Place all bets
  jQuery("input[type='submit'][value='Place Bets']").each(function(index, button){
    jQuery(button).click(function(){
      //Check the bet slip for bets
      $(".new_bet").each(function(){
        // not a parlay
        if ( $(this).attr('class').indexOf('parlay_bet') == -1 )
        {
          var bet_risk = $(this).children(".bet_bottom").children(".left").children("#bet_risk").val();         
          var game_id = $(this).data("game");
          var bet_type = $(this).data("bet_type");
          var league_id = $("#league_info_container").data("league_id");
          if ( bet_risk > 0 || bet_risk == "LOCK" )
          {
            if ( bet_risk == "LOCK" )
            {
                bet_risk = 0
								bet_type = bet_type + ".lock";
            }
            $.post("/bets", {game: game_id, risk: bet_risk, league: league_id, bet: bet_type});
						$(this).parents('container').remove()
          }
          else
          {
            alert('You have to risk something to place a bet!');
          }
        } // if not a parlay
      }) // each new bet
			if ( $('#parlay_header').length == 1 )
			{
				// create bet for parlay
				var bet_risk = $('#parlay_header #bet_risk').val()
				var bet_win = $('#parlay_header #to_win').text()
        var league_id = $("#league_info_container").data("league_id");
    		var selector_string = 'bet_risk=' + bet_risk + '&bet_win=' + bet_win + '&league_id=' + league_id 
				$.ajax({
				    url: '/create_parlay',
						data: selector_string
				}).done(function(parlay_id)
					{
					// create sub bets
						$('.parlay_bet').each(function(index, parlay)
							{
								var game_id = $(this).data("game")
								var bet_type = $(this).data("bet_type")
								$.ajax({
									url: '/add_to_parlay', 
									data: 'game_id=' + game_id + '&league_id=' + league_id +
												'&bet_type=' + bet_type + '&parlay_id=' + parlay_id,
									type: 'POST'
								})
							})
						$('#parlay_container').remove()
					})
			}
			updateBetSlipTally()
    }) // click handler
  }) // each button function

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
      $.get(get_string , {game_id: g_id, user_id: user, league_id: league_id, sort_param: "amount", show_for: show_for_string, direction: new_direction} )     
    })
  })
    
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
      $.get(get_string , {game_id: g_id, user_id: user, league_id: league_id, sort_param: "date", show_for: show_for_string, direction: new_direction} )
    })
  })
    
  // Sort by User
  jQuery("input[id='update_bets_for_user']").each(function(index, button){
    jQuery(button).click(function(){
      league_id = $("#index").children(".header").data("league_id");
      user = $(this).data("user");
      $('#league_info_container').attr('data-user_id', user );
      get_string = "/leagues/" + league_id + "/bets";
      $.get(get_string, {user_id: user, league_id: league_id, sort_param: "date", show_for: "user", direction: 'down'} );
  	})
  })
    
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
        data: selector_string
      })
    })
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
    })
  })
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
        data: selector_string
      })
    })
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
    })
  })
  
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
		    })
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
    })
  })
    
// **************** Button on League Home to Deploy Credits ********************** //
  jQuery("input[class='credit_button']").each(function(index, button){
    jQuery(button).click(function(){
			$(this).attr('disabled', 'disabled');
      league_id = $(this).parents('#league_info_container').attr("data-league_id");
      user_id = $(this).parents('#league_info_container').attr('data-user_id');
      membership_id = $(this).parents('#league_info_container').attr("data-membership_id");
      path_string = '/memberships/' + membership_id + '/deploy_credits';
      $.ajax({
        url: path_string
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
        data: selector_string
			})
		})
	})
 	
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
		    data: selector_string
			})
		})
	})   

	// Tooltips with qTip plugin //
	$('#list .open_bet').each( function() {
			$(this).qtip({
				content: {
				    text: $(this).attr('data-user_name') + " placed this bet."
				},
				show: 'mouseover',
				hide: 'mouseout',
				position: {
				  corner: {
				     target: 'center',
				     tooltip: 'topLeft'
				  }
			 	}
		});
	});

	$('#parlay_header').each( function() {
			$(this).qtip({
				content: {
				    text: $(this).attr('data-user_name') + " placed this bet."
				},
				show: 'mouseover',
				hide: 'mouseout',
				position: {
				  corner: {
				     target: 'center',
				     tooltip: 'topLeft'
				  }
				}
		});
	});

})


function clearBetSlipTally()
{
	$('#total_risk').empty()
	$('#total_risk').append("0")
	$('#total_win').empty()
	$('#total_win').append("0")
}

function updateBetSlipTally()
{
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
	$('#total_risk').append( total_risk )
	$('#total_win').empty()
	$('#total_win').append( total_win )
}

function updateParlayTally()
{
	var bet_risk = $('#parlay_risk').children('#bet_risk').val()
	var number_of_parlay = $('.parlay_bet').length
	var win = Math.pow( 2, number_of_parlay-1 ) * (bet_risk * .95)
	if (isNaN(win)) {
		win = 0
	}
	var win_string = sprintf("%.0f", win );
	$('#parlay_win').children('#to_win').empty()
	$('#parlay_win').children('#to_win').append(win_string)
}

function getWin( risk )
{
	var win = risk*0.95		
	if (isNaN(win)) {
		win = 0
	}
	return win
}

function updateForParlay() 
{
	var number_of_parlay = $('.parlay_bet').length
	var display_string = number_of_parlay + ' Way Parlay'
	$('#parlay_display').empty()
	$('#parlay_display').append(display_string)	
	updateParlayTally()
	updateBetSlipTally()
}
