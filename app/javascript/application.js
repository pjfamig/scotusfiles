// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

//= require jquery3
//= require popper
//= require bootstrap-sprockets

import "@hotwired/turbo-rails"
import "controllers"
import "trix"
import "@rails/actiontext"
import LocalTime from "local-time"
LocalTime.start()

$(window).on('load', function() {
  const customHeader = document.querySelector('#custom-header');
  let prevScrollPos = window.pageYOffset;

  window.onscroll = function() {
    let currentScrollPos = window.pageYOffset;

    // Show the custom header if the user scrolls down and hide it if they scroll up
    if (prevScrollPos > currentScrollPos) {
      customHeader.style.display = "none";
    } else {
      customHeader.style.display = "block";
    }

    prevScrollPos = currentScrollPos;
  }
});


$(document).on('click', '.sentence', function() {
  var sentenceId = $(this).data('sentence-id');
  
  // Remove all existing comment-boxes
  $('.comment-box').remove();

  // Create a new container for the comment-box
  var commentBox = $('<div class="comment-box"><form action="/comments" method="POST"><input type="hidden" name="sentence_id" value="' + sentenceId + '"><textarea name="content"></textarea><button type="submit">Submit</button></form></div>');
  
  // Append the comment box to the body and set its position
  $('body').append(commentBox);
  
  // Calculate the position for the comment box
  var position = $(this).offset();
  position.left += $(this).outerWidth() + 10;
  commentBox.css({top: position.top, left: position.left, position: 'absolute'});
});

// Close comment box when clicking outside
$(document).on('click', function(event) {
  if (!$(event.target).closest('.sentence, .comment-box').length) {
    $('.comment-box').remove();
  }
});
