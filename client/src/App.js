import React, { Component } from 'react'
import logo from './logo.svg';
import './App.css';
//import ReadSum from './ReadSum'
import ReadNumberProducts from './ReadNumberProducts';
import ProductHolder from './Product-holder';
import ProductRegisterForm from './ProductRegisterForm';

class App extends Component {

    state = { loading: true, drizzleState: null };

    componentDidMount() {
        const { drizzle } = this.props;

        // subscribe to changes in the store
        this.unsubscribe = drizzle.store.subscribe(() => {

        // every time the store updates, grab the state from drizzle
        const drizzleState = drizzle.store.getState();

        // check to see if it's ready, if so, update local component state
        if (drizzleState.drizzleStatus.initialized) {
          this.setState({ loading: false, drizzleState });
        }
        });
    }

    compomentWillUnmount() {
        this.unsubscribe();
    }

    render() {
        if (this.state.loading) return "Loading Drizzle...";
        var rows = [];
        for (var i = 0; i < 10; i++) {
            // note: we add a key prop here to allow react to uniquely identify each
            // element in this array. see: https://reactjs.org/docs/lists-and-keys.html
            rows.push(
                <ProductHolder 
                    drizzle={this.props.drizzle}
                    drizzleState={this.state.drizzleState}
                    name={i}
                    key={i} 
                />
            );
        }
        return (
            <div className="App">
                <ReadNumberProducts
                    drizzle={this.props.drizzle}
                    drizzleState={this.state.drizzleState}
                />
                <ProductRegisterForm
                    drizzle={this.props.drizzle}
                    drizzleState={this.state.drizzleState}
                />
                <div className="products-list">
                    {rows}
                </div>
            </div>
        );
    }
}

export default App;
