// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails


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

