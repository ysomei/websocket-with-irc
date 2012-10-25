/*                 */
/* web socket test */
/*                 */

var socket = new WebSocket("ws://192.168.1.1:8089/");
var msglog = new Array();
var MAX_SIZE = 30;

socket.onopen = function(event){
  //alert("open websocket!");
};
socket.onmessage = function(event){
  var nowtime = createtime();
  msglog.push(nowtime + " " + event.data);
  if(msglog.length > MAX_SIZE) msglog.shift();

  showtimeline();
};
socket.onerror = function(event){
  alert("error!");
};
socket.onclose = function(event){
  //alert("close websocket. " + event);
};

function sendmsg() {
  var nick = document.getElementById("nickname").value;
  var msg = document.getElementById("sendmsg").value;
  
  if(nick == "") nick = "nana-shi";
	var sendmsg = "(" + nick + ") " + msg;
  socket.send(sendmsg);

  var nowtime = createtime();
  msglog.push(nowtime + " " + sendmsg);
  if(msglog.length > MAX_SIZE) msglog.shift();

  showtimeline();
}

function showtimeline() {
  var msgid = document.getElementById("msg");
  var str = "";
  for(var i = msglog.length; i > 0; i--){
    str += msglog[i - 1] + "<br />";
  }
  msgid.innerHTML = str;
}

function createtime() {
  var now = new Date();
  return ("0" + now.getHours()).slice(-2) + ":" + ("0" + now.getMinutes()).slice(-2) + ":" + ("0" + now.getSeconds()).slice(-2);
}

