// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap

document.addEventListener("turbolinks:load", function() {
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

  $('.restart-reveals').click(restart_reveals);

  $('#game-form .shuffle-option').click(function(){
    $('#game-form .shuffle-option').removeClass('active');
    if ($(this).find('input').is(':checked')) {
      $(this).addClass('active');
    }
  });
  $('#game-form .shuffle-option input:checked').closest('.shuffle-option').click();
})


function reveal_player(player_num){
  $(`.pre-reveal-info#pre-reveal-info-${player_num}`).hide();
  $(`.player-loyalties-board#player-${player_num}-loyalties-board, .after-reveal-button-wrapper`).show();
  $('.pre-reveal-button-wrapper').hide();
}

function prepare_for_next_player(player_num){
  $(`.pre-reveal-info#pre-reveal-info-${player_num}, .pre-reveal-button-wrapper`).show();
  $('.player-loyalties-board').hide();
  $('.after-reveal-button-wrapper').hide();
}

function end_reveals(){
  $('.pre-reveal-info, .pre-reveal-button-wrapper, .after-reveal-button-wrapper, .player-loyalties-board').hide();
  $('.end-reveals').show();
}

function restart_reveals(){
  $('.end-reveals').hide();
  $('.pre-reveal-button-wrapper a').data('next-player', 1);
  $('.after-reveal-button-wrapper').data('next-player', 2);
  prepare_for_next_player(1);
}

