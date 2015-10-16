$(document).ready(function() {
  hit();
  stay();
});

function hit() {
  $(document).on("click", "form#hit-form input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg) {
      $("div#game").replaceWith(msg);
    });
    return false;
  });
};

function stay() {
  $(document).on("click", "form#stay-form input", function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/stand'
    }).done(function(msg) {
      $("div#game").replaceWith(msg);
    });
    return false;
  });
};