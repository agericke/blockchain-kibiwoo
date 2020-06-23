import 'bootstrap/dist/css/bootstrap.min.css';
import React from "react";

class ProductHolder extends React.Component {
  
    componentDidMount() {
        const { drizzle, drizzleState } = this.props;
    }

    render() {

        return (
            <div id="productTemplate">
                <div className="col-sm-6 col-md-4 col-lg-3">
                    <div className="card panel-product">
                        <div className="card-header">
                            <h3 className="card-title">Scrappy-{this.props.name}</h3>
                        </div>
                        <img 
                            className="card-img-top" 
                            alt="140x140" 
                            data-src="holder.js/140x140" 
                            style={{width: '100%'}} 
                            src="https://animalso.com/wp-content/uploads/2017/01/Golden-Retriever_6.jpg" 
                            data-holder-rendered="true"
                        />
                        <div className="card-body">
                            <br/><br/>
                            <strong>Name</strong>: <span className="product-name">PRODUCT NAME</span><br/>
                            <strong>Category</strong>: <span className="product-category">CAT.</span><br/>
                            <strong>SKU</strong>: <span className="product-sku">SKU</span><br/><br/>
                            <strong>Booked</strong>: <span className="product-booked">False</span><br/><br/>
                            <button className="btn btn-default btn-book" type="button" data-id="0">Book</button>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
}

export default ProductHolder;