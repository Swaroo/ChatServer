import React from 'react'
import { render } from 'react-dom'
import axios from 'axios'; // axios seemed like a cool package to do api calls, alternative is fetch

function date_format(timestamp) {
  var date = new Date(timestamp * 1000);
  return (
      date.toLocaleDateString("en-US") +
      " " +
      date.toLocaleTimeString("en-US")
  );
}

class Board extends React.Component {
  constructor(props){
    super(props);
    
    // data that user types in from login form
    this.state = {
      board_data: 'This is default data on board',
      messages: ["Messages"],
      users: ["Online"],
      columns: "this is a column",
      token: ''
    };

    
  }
  // update username in state when keys are typed into login form
  onMessageChange = (event) =>{
    console.log("a");
    this.setState({out_message: event.target.value})
    if (event.target.value === 'Enter'){
      console.log("You typed enter!\n");
    }
  }

  onKeyDown = (ele) =>{
    if (ele.keyCode === 13){
      var cur_message = this.state.out_message;
      console.log("enter pressed!");
      console.log("sending this message to server: " + cur_message);
      console.log("with this token: " + this.state.token);

      this.setState({out_message: ''});

      axios.post( "http://localhost:3000/message", null, { 
      params: {
        message: cur_message
      }, 
      headers: { 
        "Access-Control-Allow-Origin": "*", 
        Authorization: `Bearer ${this.state.token}`
      } 
    }).then((response) => {
      console.log(response);

    }, (error) => {
      console.log(error);
      if (error.response.status === 403){
        console.log("403: Token not valid");
      }

    });

    }
  }

  onTextChange = (event) =>{
    // DUMMY
    this.setState({out_message: event.target.value})
  }

  

  componentWillMount() {
    var old_state = this.props.location.state;
    if (old_state === void(0)){
      console.log("old_state is undefined");
      this.props.history.push({pathname: '/', state: {}})
      return
    }
    else{
      console.log("old state: ");
      console.log(old_state);
      console.log("old token: " + old_state.token);
    }
    

    this.setState({token: old_state.token});
    var eventSource = new EventSource("http://localhost:3000/stream/"+old_state.token);


    let my = this;

    eventSource.onerror   = function(event) {
      console.log("Connection error", event);
      eventSource.close();
    }

    eventSource.addEventListener(
      "Part",
        (event) => {
            console.log("Part");
            var msg = JSON.parse(event.data);
            console.log(msg);
            var parted_user = msg["user"]
            console.log(parted_user);
            
            my.setState({users: my.state.users.filter(function(user) { 
              return user !== parted_user
            })});

            var post = date_format(msg["created"]) + " : " + msg["user"] + " got bored and left the chat." 
            my.setState({
              messages: [...my.state.messages, post]
            })
           

            console.log("my users:");
            console.log(my.state.users);
        },
        false
    );

    eventSource.addEventListener(
      "Users",
        (event) => {
            console.log("Users");
            var msg = JSON.parse(event.data);
            var onlineUsers = msg["users"]
            console.log(onlineUsers);
            
            my.setState({
              users: ["Online"]
            });
            var i = 0;
            for (; i < onlineUsers.length; i++){
              my.setState({
                users: [...my.state.users, onlineUsers[i]]
              });
            }
        },
        false
    );

    eventSource.addEventListener(
      "Join",
        (event) => {
            console.log("Join");
            console.log(event.data);
            var msg = JSON.parse(event.data);
            //var board_data = document.getElementById('board').value;
            var post = date_format(msg["created"]) + " : Make some noise for " + msg["user"] + "." 
            my.setState({
              messages: [...my.state.messages, post]
            })

            if (my.state.users.includes(msg["user"]) === false){
              my.setState({
                users: [...my.state.users, msg["user"]]
              })
            }
            
        },
        false
    );

    eventSource.addEventListener(
      "HeartBeat",
        (event) => {
            console.log(event.data);
        },
        false
    );

    eventSource.addEventListener(
      "Disconnect",
        (event) => {
          console.log("Stream disconnected", event) 
          eventSource.close();
          my.props.history.push({pathname: '/', state: {}})
        },
        false
    );
    
    eventSource.addEventListener(
      "Message",
        (event) => {
            console.log("Message");
            console.log(event.data);
            var msg = JSON.parse(event.data);
            //var board_data = document.getElementById('board').value;
            var post = date_format(msg["created"]) + " : " + msg["user"] + " SAYS -> " +msg["message"];
            my.setState({
              messages: [...my.state.messages, post]
            })
        },
        false
    );   
    
    eventSource.addEventListener(
      "ServerStatus",
        (event) => {
            console.log("Message");
            console.log(event.data);
            var msg = JSON.parse(event.data);
            //var board_data = document.getElementById('board').value;
            var post = date_format(msg["created"]) + " STATUS: " + msg["status"] + ". Do you know even see my messages, huh?";
            my.setState({
              messages: [...my.state.messages, post]
            })
        },
        false
    ); 
  }

  //<ReactTable data={this.state.board_data} columns={this.state.columns} />
	
	render() {
		return (
		
        <section style={{display:'flex', flexDirection:'column', height:'90vh', overflow: 'hidden'}}>
          <h1 align="center" style={{color:'green'}}> CS 291 Class</h1>
          <div style={{display: 'flex', flex: '1', margin: '0.5em 0.5em 0 0.5em', minHeight: '0'}} >
            <MessageList style={{ height:'100%',  width:'10em', overflow:'scroll', margin: '0 0.5em 0.5em 0.5em', minHeight: '2em'}}
                messages={this.state.messages} />
          
            <MessageList style={{  height:'100%',  width:'20%', overflow:'scroll', marginBottom: '0.5em'}}
                messages={this.state.users} />

          </div>

          <input style={{margin:'80vh 0vh', height: '20vh', width:'100%'}} type="text" value={this.state.out_message} onChange={this.onMessageChange} onKeyDown={this.onKeyDown} required/>
        </section>
    )
  }
}

class MessageList extends React.Component {
  render() {
      return (
          <ul >
              {this.props.messages.map((message) => {
                  return (
                    <ul>
                      <div>{message}</div>
                    </ul>
                  )
              })}
          </ul>
      )
  }
}

//<input style={{height: '30px', width:'100%'}} type="text" value={this.state.message} onChange={this.onMessageChange} required/>
export default Board