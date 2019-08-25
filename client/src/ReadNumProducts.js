import React from "react";

class ReadNumProducts extends React.Component {
  
    componentDidMount() {
        const { drizzle, drizzleState } = this.props;
        console.log(drizzle);
        console.log(drizzleState);
    }

    render() {
        return <div>ReadNumProducts Component</div>;
    }
}

export default ReadNumProducts;