pragma solidity ^0.5.0;

contract Kibiwoo {

    event NewProduct(uint id, string name, string indexed _sport, address indexed _owner);

    struct Product {
        uint id;
        string name;
        string sport;
        address owner;
    }

    Product[] public products;

    address[20] public _owners;
    // struct User {
    // 	address user_address;
    // 	string email;
    // 	string name;
    // }

    // User[] private _owners;

    function _registerProduct(uint _id, string memory _name, string memory _sport) public returns (uint) {
        products.push(Product(_id, _name, _sport, msg.sender));
        _owners[_id] = msg.sender;
        // emit NewProduct(_id, _name, _sport, msg.sender);

        return _id;
    }

    // function _createUser(address _user_address, string _email, string _name) private {
    // 	users.push(User(_user_address, _email, _name))
    // }

    function getOwners() public view returns (address[20] memory) {
        return _owners;
    }

}