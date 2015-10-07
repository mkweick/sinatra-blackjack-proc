$(document).ready(function() {
  $('li').each(function () {
    $(this).html($(this).html().replace(/(\♥)/g, '<span style="color: #FF0000;">♥</span>'));
  });
  $('li').each(function () {
    $(this).html($(this).html().replace(/(\♦)/g, '<span style="color: #FF0000;">♦</span>'));
  });
});