function send(object, to) {
  return $.ajax({
    url: to,
    global: false,
    type: "POST",
    data: (object),
    dataType: "text",
    async:false,
    success: function(){
      console.log("Contacted server (" + to +")  with " + JSON.stringify(object) + "!");
    }
  }).responseText;
}

function setup(board) {
  for(i = 0; i < board.length; i++) {
    if(board[i] == 1 || board[i] == -1) {
      $("#cell" + i).children().attr("src", "../images/" + board[i] + ".png");
      $("#cell" + i).children().fadeIn();
    }
  }
  $("div#board").show();
}