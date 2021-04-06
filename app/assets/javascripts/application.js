//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap

document.addEventListener("turbolinks:load", function() {

  //***** show functions *****//
  $('.pre-reveal-button-wrapper a').click(function(e){
    this_button = $(this);
    next_player = this_button.data('next-player');

    reveal_player(next_player);
    this_button.data('next-player', next_player + 1);

    e.preventDefault();
    return false;
  })

  $('.after-reveal-button-wrapper a').click(function(e){
    this_button = $(this);
    next_player = this_button.data('next-player');
    last_player = this_button.data('last-player');

    if (next_player <= last_player) {
      prepare_for_next_player(next_player);
      this_button.data('next-player', next_player + 1);
    } else {
      end_reveals();
    }

    e.preventDefault();
    return false;
  })

  $('.restart-reveals, #start-button').click(restart_reveals);

  //***** form functions *****//

  $('#game-form .shuffle-option').click(function(){
    $(this).parent().find('.shuffle-option').removeClass('active');
    if ($(this).find('input').is(':checked')) {
      $(this).addClass('active');
    }
  });
  $('#game-form .shuffle-option input:checked').closest('.shuffle-option').click();
})


function reveal_player(player_num){
  $(`.pre-reveal-info`).hide();
  $('.player-loyalties-board').hide();
  $(`.player-loyalties-board#player-${player_num}-loyalties-board, .after-reveal-button-wrapper`).show();
  $('.pre-reveal-button-wrapper').hide();
}

function prepare_for_next_player(player_num){
  $(`.pre-reveal-info`).hide();
  $(`.pre-reveal-info#pre-reveal-info-${player_num}, .pre-reveal-button-wrapper`).show();
  $('.player-loyalties-board').hide();
  $('.after-reveal-button-wrapper').hide();

// debugger
  audio_tag = $(`.pre-reveal-info#pre-reveal-info-${player_num} audio`);
  if (audio_tag.length > 0) {
    audio_tag.trigger('play');
  }
}

function end_reveals(){
  $('.pre-reveal-info, .pre-reveal-button-wrapper, .after-reveal-button-wrapper, .player-loyalties-board').hide();
  $('.end-reveals').show();
}

function restart_reveals(){
  $('.end-reveals, #begin-reveal-wrapper').hide();
  $('.pre-reveal-button-wrapper a').data('next-player', 1);
  $('.after-reveal-button-wrapper a').data('next-player', 2);
  prepare_for_next_player(1);
}

