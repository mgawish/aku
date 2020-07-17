$(document).ready(function() {
  document.getElementsByClassName("ql-editor")[0].innerHTML = document.getElementById("content").value
});

var quill = new Quill('.editorContainer', {
  modules: {
    toolbar: [
      [{ header: [1, 2, false] }],
      ['bold', 'italic', 'underline'],
      ['image', 'code-block']
    ]
  },
  placeholder: 'Compose an epic...',
  theme: 'snow'
});

function quillGetHTML(inputDelta) {
    var tempCont = document.createElement("div");
    (new Quill(tempCont)).setContents(inputDelta);
    return tempCont.getElementsByClassName("editorContainer")[0].innerHTML;
}

quill.on('text-change', function(delta, oldDelta, source) {
  var content = document.getElementsByClassName("ql-editor")[0].innerHTML
  document.getElementById("content").value = content
});
