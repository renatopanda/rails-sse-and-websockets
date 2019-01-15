# Server-Sent Events and WebSockets in Rails 5.2

A very small example about SSE (ping) and WebSockets (chat) used in the Software Engineering classes (MEI-IoT).


## Step-by-step instructions
The following steps can be used to replicate this example step-by-step. Use Git BASH if you are using Windows.  


### Start a new Rails project inside a Vagrant VM
Create the project folder and Vagrantfile. If you want you can skip all the Vagrant part and use your host directly but you will need to have ruby (+bundler and rails), node, redis (used to create the websockets pub/sub).
```bash
mkdir rails-sse-and-websockets
cd rails-sse-and-websockets
vagrant init
```


Edit the Vagrantfile and add (replace config.vm.box = "base"):
```ruby
  config.vm.box = "jadesystems/rails-5-2"

  config.vm.provider "virtualbox" do |v|
    v.linked_clone = true
    v.memory = "1024"
    v.cpus = 1
  end
```


Start the VM / initial provisioning
```bash
vagrant up
```


SSH into the VM and go to the shared folder (between host and guest)
```bash
vagrant ssh
cd /vagrant
```


Finally, create the rails project. I'm skipping coffee script in this example and will use only JS.
```bash
rails new . --skip-coffee
```



### Server-Sent Events Example


#### Example 1 - Simple Ticker
Create a new controller `Home` and an action `ticker`
```bash
rails g controller Home ticker
```


Include `ActionController::Live` in the HomeController class to be able to use SSE.
```ruby
class HomeController < ApplicationController
  include ActionController::Live
```


Add some logic to the ticker action. This will write a message with the current time to the stream each 2 seconds (5 times).
```ruby
def ticker
  5.times do
    response.stream.write "Hi!: #{Time.now} <br>"
    sleep 2
  end
  response.stream.close
end
```


You should have a route to the new action. If not, just add it to your routes.rb file:
```ruby
  get 'home/ticker'
```


Finally, launch the server (`rails s`) and test it at (http://localhost:3000/home/ticker)


#### Example 2 - A better example
Add a new `live` action to the same controller with the following content. It will properly set the response headers and send a ping every 2 seconds but this time (notice the id and event fields).
```ruby
def live
  response.headers['Content-Type'] = 'text/event-stream'
  sse = SSE.new(response.stream, retry: 300, event: "event-name")
  loop do
    sse.write({time: Time.now}, id: 10, event: "other-event", retry: 500)
    sleep 2
  end
rescue ClientDisconnected
  logger.info 'Client disconnects causes IOError on write'
ensure
  sse.close
end
```


Add also a route to `/home/live` in the routes.rb file:
```ruby
get 'home/live'
```


Now test it using your browser console. For example, using the view created in example 1 (http://localhost:3000/home/ticker), open the browser console (<kbd>ctrl</kbd> + <kbd>shift</kbd> + <kbd>i</kbd> in chrome/firefox).

1. Start the connection by typing the following command in the console:
```javascript
var evtSource = new EventSource('/home/live');
```

2. Do something with it, for example add a listener for "other-event" (remember it?) and print its content to the console. With this the output should appear in the console log.
```javascript
evtSource.addEventListener("other-event", function(e) {
  console.log(e.data);
}, false);
```

3. Finally, just close it by typing:
```javascript
evtSource.close(); 
```


#### Example 3 - a proper example
Instead of just using the console.log, lets use the output in a new view to modify the dom of the page by writing the new messages to an `<li>` element.


Start by creating an empty action `home#sse`, used just to render a view. Don't forget to add the associated route `get 'home/sse'.
```ruby
def sse
end
```


Next, create the associated view file `views/home/sse.html.erb` with the following content. It contains a single button to close the connection and an empty `<ul>`element. The JS is similar to example 2, but this time instead of console.log it adds the data to a new `<li>`.
```html
<h1>MEI-IoT / ES - Server-sent Events Demo</h1>

<button>Close the connection</button>

  <ul>
  </ul>

<script>
  var button = document.querySelector('button');
  var evtSource = new EventSource('/home/live');
  console.log(evtSource.withCredentials);
  console.log(evtSource.readyState);
  console.log(evtSource.url);
  var eventList = document.querySelector('ul');

  evtSource.onopen = function() {
    console.log("Connection to server opened.");
  };

  evtSource.addEventListener("other-event", function(e) {
    var newElement = document.createElement("li");
  
    var obj = JSON.parse(e.data);
    newElement.innerHTML = "ping at " + obj.time;
    eventList.appendChild(newElement);
  }, false);

  evtSource.onerror = function() {
    console.log("EventSource failed.");
  };

  button.onclick = function() {
    console.log('Connection closed');
    evtSource.close();
  }
</script>
```

Go ahead, restart the server (rails s) and try it at (http://localhost:3000/home/sse).


### WebSockets
SSE provides unidirectional communication only (server -> client). WebSockets on the other hand give us real-time bidirectional communication. In this example we will build a very simple chat using WebSockets. To better understand it please read the course material about the subject and how WebSockets are implemented in RoR.


## Creating an index to organize all our examples.

Start by creating an index view (`views/home/index.html.erb`) with the following code:
```html
<h1>MEI-IoT - Server-sent Events and WebSockets Examples</h1>

<p>Example 1: <a href="/home/ticker">/home/ticker</a></p>
<p>Example 2 (SSE): Open a browser console (ctrl+shift+i) e run each line at a time, analyzing the output:
  <pre>
    <code class="language-js">
      //start the connection
      var evtSource = new EventSource('home/live');

      //what should we do with the event?
      evtSource.addEventListener("other-event", function(e) {
        console.log(e.data);
      }, false);

    //close the socket
    evtSource.close();
  </code>
</pre>
</p>

<p>Example 3 (SSE): <a href="/home/sse">/home/sse</a></p>
<p>Example 4 (WebSockets): <a href="/home/chat">/home/chat</a></p>
```


Also add `root home#index` to the routes.rb file. You should now be able to see it at (http://localhost:3000/).


#### Example 4 - Chat using WebSockets


Add jQuery and Bootstrap to the app. This is not mandatory but we will just do it to make it easier to select html elements and a bit prettier.
There are several ways of doing so such as
1. Add the files (js and css) to assets/* and include them as needed (kinda old school).
2. Use gems such as `jquery` that to the work for you.
3. Use yarn (yarn init && yarn add...) and include the files.
4. Add them from some free CDN

Since this is just a simple demo we will use the last option. So go to (https://code.jquery.com/) and (https://www.bootstrapcdn.com/) and include the needed files in our application layout `views/layout/application.html.erb`.

In our case, the head block will look like this:
```html
<head>
  <title>MEI-IoT/ES - SSE and WebSockets Example</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
  <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">

  <script
  src="https://code.jquery.com/jquery-3.3.1.min.js"
  integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
  crossorigin="anonymous"></script>
  <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>

  <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
</head>
```


Next add a new route to `route.rb`:
```ruby
get 'home/chat'
```


Create our chat interface under `views/home/chat.html.erb`:
```html
<div class="container">
  <h1>MEI-IoT / ES - Chat using WebSockets</h1>
  <span id="chat"></span>
  <hr>
  Message:
  <br>
  <textarea id="msg" class="form-control" style="min-width: 100%"></textarea>
  <hr>
  <button id="send" type="button" class="btn btn-primary">Send Message</button>
</div>

<script>
  $(document).ready(function(){

    $("#send").click(function(){
      msg = $("#msg").val();
      alert(msg);
    })
  })
</script>
```


Test it at (http://localhost:3000/home/chat). You should get your messages in the JS alert.


Now mount the ActionCable server route, by adding to our `routes.rb`:
```ruby
mount ActionCable.server => "/cable"
```


Create a new channel for our chat messages with an action send_msg. This action will be called (RPC) by the clients using JS. You can check the content of created files (`chat_channel.rb` and `chat.js`) - the course slides contain more details about their content (e.g., the `subscribed` action, the `send_msg` and so on).
```bash
rails g channel Chat send_msg
```


Edit the `chat_channel` to set the topic/channel to which the clients will subscribe. Also change the `send_msg` action accordingly:
```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "es_chat"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def send_msg(data)
    ActionCable.server.broadcast "es_chat", message:data['message']
  end
end
```


Edit also the chat.js JS file, which contains the could that will be executed by the client in the browser (`assets/javascripts/channels/chat.js`). Add a debug message on connect, when data is received and also set the logic of our `send_msg` function. The later will call the `perform(action, payload)` function, which executes the `action` in the server sending the `payload` as params.
```javascript
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
  },

  send_msg: function(data) {
    payload = {}
      payload['message'] = data;
      this.perform('send_msg', payload);
  }
});
```


At this point, if you reload the page and see the console you should see that the websocket is connected (you may need to restart the server).


Thus, the final step is just to edit our view to send and received the messages. Open `chat.html.erb` and change the `alert(msg);` to something more meaningful, such as:

```html
<script>
  $(document).ready(function(){

    //when button is pressed, send the message using the websocket
    $("#send").click(function(){
      msg = $("#msg").val();
      App.chat.send_msg(msg); //the App.chat comes from the chat.js (first line)
    })

    // When we receive data from the websocket, just add to the chat
    App.chat.received = function(data) {
      $("#chat").append(data['message'] + "<br>");
    }
    
  })
</script>
```


That is it. Don't forget to halt the vm and destroy it in the end:
```bash
exit
vagrant halt
vagrant destroy
```
