function scrollToSection(sectionName) {
  var element = document.getElementById(sectionName);
  element.scrollIntoView();
}

function filterByTag(tagName) {
  var tagContiner = document.getElementById("tags-section")
  var children = tagContiner.children;
  for (var i=0; i<children.length; i++) {
    var tab = children[i]
    if (tab.id == tagName + "-filter") {
      tab.classList.add("active")
    } else {
      tab.classList.remove("active")
    }
  }

  var apps = document.getElementById("apps-section").children
  for (var i=0; i<apps.length; i++) {
    var app = apps[i]
    var tags = app.getAttribute("data-tags")
    if (tags.includes(tagName) || tagName == "all") {
      app.classList.remove("hidden-app")
    } else {
      app.classList.add("hidden-app")
    }
  }
}

function sendEmail() {
  $("#contact-submit-button").prop("disabled", true);
  $.post("http://"+window.location.host+"/send_email",
  {
    email: $("#contact-email").val(),
    name: $("#contact-name").val(),
    subject: $("#contact-subject").val(),
    message: $("#contact-message").val()
  },
  function(data, status){
    $("#contact-submit-button").prop("disabled", false);
    switch (status) {
      case "success":
      $("#contact-form-response").text(data)
      $("#contact-email").val("")
      $("#contact-name").val("")
      $("#contact-subject").val("")
      $("#contact-message").val("")
      break;
      default:
      $("#contact-form-response").text("Something went wrong, please try again.")
      break;
    }
  });
}
