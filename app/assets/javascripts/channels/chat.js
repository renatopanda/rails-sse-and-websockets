App.chat = App.cable.subscriptions.create("ChatChannel", {
  connected: function() {
    // Called when the subscription is ready for use on the server
    console.log("WebSocket connected.");
  },

  disconnected: function() {
    // Called when the subscription has been terminated by the server
  },

  received: function(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received data: " + data['message']);
    // this function is being replaced in the view as part of the simplest class example
  },

  send_msg: function(data) {
    payload = {}
    payload['message'] = data;
    this.perform('send_msg', payload);
  }
});
