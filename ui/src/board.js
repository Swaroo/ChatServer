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
      out_message: '',
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

  componentDidMount() {
    var old_state = this.props.location.state;
    console.log("old state: ");
    console.log(old_state);
    console.log("old token: " + old_state.token);

    this.setState({token: old_state.token});
    var eventSource = new EventSource("http://localhost:3000/stream/"+old_state.token);

    eventSource.addEventListener(
      "message",
        function(event) {
          debugger;
            console.log(event.data);
            var msg = JSON.parse(event.data);
            var board_data = document.getElementById('board').value;
            document.getElementById('board').value = board_data + "\n" + msg["msg"] + " at " 
            + date_format(msg["post_time"]) + " by "+ msg["name"];
        },
        false
    );



    
  }

  //<ReactTable data={this.state.board_data} columns={this.state.columns} />
	
	render() {
		return (
			<div>
        <h1 align="center" style={{color:'green'}}> CS 291 Class</h1>
        <span>
        <textarea id = "board" style={{height:'850px',  width:'70%', overflow:'scroll'}} value="Hello!" onChange={this.onTextChange}></textarea>
        

				<div style={{float:'right', height: '850px', width:'28%'}}>
          <table>
            <thead style={{fontWeight:'bold'}}>
              <tr>
                <th>Online</th>
              </tr>
            </thead>
            <tbody style={{fontWeight:'light'}}>
              <tr>
                <th>Jill</th>
              </tr>
              <tr>
                <th>Eve</th>
              </tr>
            </tbody>
            
          </table>
        </div>

        </span>

        <input style={{height: '30px', width:'100%'}} type="text" value={this.state.out_message} onChange={this.onMessageChange} onKeyDown={this.onKeyDown} required/>

      </div>
    )
  }
}
//<input style={{height: '30px', width:'100%'}} type="text" value={this.state.message} onChange={this.onMessageChange} required/>
export default Board