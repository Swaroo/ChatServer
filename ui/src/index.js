import React from 'react'
import ReactDOM from 'react-dom'
import './index.css'
import { Route, Link, BrowserRouter as Router, Switch } from 'react-router-dom'

import App from './App'
import Login from './login'
import Board from './board'
import Notfound from './notfound'

const routing = (
  <Router>
    <div>
      <Switch>
        <Route exact path="/" component={Login} />
        <Route exact path="/board" component={Board} />
        <Route component={Notfound} />
      </Switch>
    </div>
  </Router>
)


ReactDOM.render(routing, document.getElementById('root'))