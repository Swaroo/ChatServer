import React from 'react'
import { render } from 'react-dom'
import axios from 'axios'; // axios seemed like a cool package to do api calls, alternative is fetch


class Login extends React.Component {
  constructor(props){
    super(props);

    // data that user types in from login form
    this.state = {
      username: '',
      password: ''
    };

  }

  // update username in state when keys are typed into login form
  onNameChange = (event) =>{
    this.setState({username: event.target.value})
  }

   // update password in state when keys are typed into login form
  onPasswordChange = (event) =>{
    this.setState({password: event.target.value})
  }

  // call post to server when user submits login form
  onSubmit = (event) => {
    event.preventDefault(); // prevents page from reloading with username + password visible as url query

    // log that username is visible from our state
    console.log("Login form submitted\n");
    console.log("username: " + this.state.username);
    console.log("password: " + this.state.password);

    // test to just call GET / 
    // not working because of CORS
    axios.get('localhost:3000')
    .then(response => {
      console.log(response.data);
    })
    .catch(error => {
      console.log(error);
    });
	}
	
	render() {
		return (
			<div>
				<form onSubmit={this.onSubmit}>
          <h1>Login</h1>

          <label> <b>Username</b> </label>
          <input type="text" value={this.state.username} onChange={this.onNameChange} required/>
          <br></br>
          <label> <b>Password</b> </label>
          <input type="text" value={this.state.password} onChange={this.onPasswordChange} required/>
          <br></br>
          <button type="submit" className="btn">Login</button>
        </form>
			</div>
		)
	}
}

render(
  <Login />,
	document.getElementById('root')
)