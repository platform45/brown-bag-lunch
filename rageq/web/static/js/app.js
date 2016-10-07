// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import "phoenix"
import $ from "jquery"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

// import { Socket } from "web/static/js/socket";
import { Socket } from "phoenix"

class Rageq {
  static init(){
    let socket = new Socket('/socket');

    var msg_area = $("#comment-text-area");

    socket.connect();

    let post_id = parseInt($("#post").data("id"));
    let user_id = parseInt($("#user").val());

    var postChannel = socket.channel("post_comments:"+post_id, {})
    postChannel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) });

    $(".js-submit-comment").on("click", function(e){
      var msg = msg_area.val();
      if (msg === "") { return; }
      postChannel.push("created_comment", { body: msg, post_id, user_id })
      msg_area.val("");
    });

    msg_area.off("keypress").on("keypress", e => {
      if (e.keyCode == 13) {
        if (msg_area.val() === "") { return; }
        $(".js-submit-comment").trigger("click")
      }
    });

    postChannel.on("created_comment", (payload) => {
      $(".post-post-comment-box").before(
        createCommentUpdated(payload)
      )
    });

    let createCommentUpdated = (payload) => `
      <div class="post-post--comment">
  <div class="post-post--comment-details row">
    <div class="post-post--comment-details-author col-sm-6">
      ${payload.user}
    </div>
    <div class="post-post--comment-details-date text-right col-sm-6">
      ${payload.inserted_at}
    </div>
  </div>
  <div class="post-post--comment-body">
  ${payload.body}
  </div>
</div>
    `
  }
}

$( () => Rageq.init() );

export default Rageq;
