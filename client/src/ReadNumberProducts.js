    import 'bootstrap/dist/css/bootstrap.min.css';
import React from "react";

class ReadNumberProducts extends React.Component {
    
    state = { numProducts: null };

    componentDidMount() {
        const { drizzle } = this.props;

        const contract = drizzle.contracts.Kibiwoo;

        const numProducts = contract.methods["getProductsCount"].cacheCall();

        this.setState({ numProducts });

        //console.log(drizzle);
        //console.log(this.props.drizzleState)
    }

    render() {

        // get the contract state from drizzleState
        const KibiwooStore = this.props.drizzleState.contracts.Kibiwoo;

        // uing the saved dataKey get the variable we are interested in
        const numProducts = KibiwooStore.getProductsCount[this.state.numProducts];

        return (

            <div className="numProducts">
                <p> Total number of products: {numProducts && numProducts.value}  </p>
            </div>
        );
    }
}

export default ReadNumberProducts;