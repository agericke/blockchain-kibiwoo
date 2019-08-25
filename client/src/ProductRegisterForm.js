import React from "react";

class ProductRegisterForm extends React.Component {
    
    state = {stackId: null};

    handleKeyDown = e => {

        if (e.keyCode === 13) {
            this.setValue(e.targetValue);
        }
    };

    setValue = value => {
        const {drizzle, drizzleState} = this.props;
        const contract = drizzle.contracts.Kibiwoo;

        const stackId = contract.methods["createNewProduct"].cacheSend(value, {
            from: drizzleState.accounts[0]
        });

        this.setState({ stackId });
    };

    getTxStatus = () => {

        // get the transaction states from the drizzle state
        const { transactions, transactionStack } = this.props.drizzleState;

        // get the transaction hash using our saved `stackId`
        const txHash = transactionStack[this.state.stackId];

        // if transaction hash does not exist, don't display anything
        if (!txHash) return null;

        // otherwise, return the transaction status
        return `Transaction status: ${transactions[txHash] && transactions[txHash].status}`;
    };

    render() {
        return (
            <div>
                <input type="text" onKeyDown={this.handleKeyDown} />
                <div>{this.getTxStatus()}</div>
            </div>
        );
    };
}
export default ProductRegisterForm;