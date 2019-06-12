pragma solidity ^0.5.0;

import "./KibiwooHelperProducts.sol";
// Change this import for importing openzeppelin erc721's implementation.
import 'openzeppelin-solidity/contracts/token/ERC721/IERC721.sol';
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/drafts/Counters.sol";
import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

/// @title A contract that implements ERC721 implementation adapted to Kibiwoo's 
///  Products as the NFTs.
/// @author Álvaro Gericke
contract KibiwooOwnership is KibiwooHelperProducts, ERC165, IERC721{
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _productApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /// @dev This emits when ownership of any Kibiwoo Product changes by any mechanism.
    ///  This event emits when Kibiwoo Products are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of Kibiwoo Products
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that Kibiwoo Prduct (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an Kibiwoo Product is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that Kibiwoo Product (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Gets the number of products a Registered Store has.
    /// @dev Kibiwoo Products assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner Address of the store for whom query the balance.
    /// @return uint256 The number of products owned by `owner`, possibly zero.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address.");
        return storeProductCount[owner].current();
    }

    /// @notice Find the owner (store) of a specific product.
    /// @dev Kibiwoo Products assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT. (In our case a product)-
    /// @return The address of the owner of the NFT. Address of the store that owns that product.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = productToStore[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token.");
        return owner;
    }

    /// @notice Change or reaffirm the approved address for a Kibiwoo product.
    /// @dev Approves another address to transfer the given Kibiwoo product ID.
    /// The zero address indicates there is no approved address.
    /// There can only be one approved address per product at a given time.
    /// Throws unless `msg.sender` is the current Kibiwoo product owner, or an authorized
    ///  operator of the current owner (store).
    /// Can only be called by the token owner (store) or an approved operator.
    /// @param approved address to be approved for the given token ID.
    /// @param tokenId uint256 ID of the token to be approved.
    function approve(address approved, uint256 tokenId) public payable {
        address owner = ownerOf(tokenId);
        require(approved != owner, "ERC721: approval to current owner.");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all."
        );
        _productApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @notice Gets the approved address for a Kibiwoo product ID, or zero if no address set.
    /// @dev Throws if `tokenId` is not a valid Kibiwoo Product. (does not exist).
    /// @param tokenId uint256 ID of the product to query the approval of.
    /// @return address The approved address for this product, or the zero address if there is none.
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token.");
        return _productApprovals[tokenId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s products. * An operator is allowed to transfer all 
    ///  products of the sender on their behalf.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators.
    /// @param approved True if the operator is approved, false to revoke approval.
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller.");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Tells whether an operator is approved by a given owner (store).
    /// @param owner owner address which you want to query the approval of.
    /// @param operator operator address which you want to query the approval of.
    /// @return True if `operator` is an approved operator for `owner`, false otherwise.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers the ownership of a given product ID to another address. 
    ///  -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `to` IS CAPABLE OF 
    ///  RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST.
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. Requires the msg.sender to be the owner, 
    ///  approved, or operator.
    /// @param from The current owner of the Kibiwoo Product.
    /// @param to The new owner.
    /// @param tokenId The Kibiwoo Product ID to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public payable {
        require(
            _isApprovedOrOwner(msg.sender, tokenId), 
            "ERC721: transfer caller is not owner nor approved."
        );
        _transferFrom(from, to, tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this Kibiwoo Product. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid Kibiwoo Product. When transfer is complete,
    ///  this function checks if `to` is a smart contract (code size > 0). If
    ///  so, it calls `onERC721Received` on `to` and throws if the return value
    ///  is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param from The current owner of the Kibiwoo Product.
    /// @param to The new owner.
    /// @param tokenId The Kibiwoo Product to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Safely transfers the ownership of a given token ID to another address
    /// @dev If the target address is a contract, it must implement `onERC721Received`,
    ///  which is called upon a safe transfer, and return the magic value
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    ///  the transfer is reverted.
    ///  Requires the msg.sender to be the owner, approved, or operator.
    /// @param from current owner of the token
    /// @param to address to receive the ownership of the given token ID
    /// @param tokenId uint256 ID of the token to be transferred
    /// @param _data bytes data to send along with a safe transfer check
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) 
        public
        payable 
    {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data), 
            "ERC721: transfer to non ERC721Receiver implementer."
        );
    }

    /// @dev Returns whether the specified Kibiwoo Product exists.
    /// @param tokenId uint256 ID of the product to query the existence of.
    /// @return bool whether the product exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = productToStore[tokenId];
        return owner != address(0);
    }

    /// @dev Returns whether the given spender can transfer a given Kibiwoo Product ID.
    /// @param _spender address of the spender to query.
    /// @param tokenId uint256 ID of the product to be transferred.
    /// @return bool whether the msg.sender is approved for the given product ID,
    ///  is an operator of the owner, or is the owner of the token.
    function _isApprovedOrOwner(address _spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token.");
        address owner = ownerOf(tokenId);
        return (
            _spender == owner || 
            getApproved(tokenId) == _spender || 
            isApprovedForAll(owner, _spender)
        );
    }

    /// @dev Internal function to mint a new product Id.
    ///  Reverts if the given token ID already exists.
    /// @param to The address that will own the minted product Id.
    /// @param tokenId uint256 ID of the product to be minted.
    // TODO: Connect with registerProduct function.
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address.");
        require(!_exists(tokenId), "ERC721: token already minted.");
        productToStore[tokenId] = to;
        storeProductCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }

    /// @dev Internal function to burn a specific product.
    ///  Reverts if the product does not exist.
    ///  Deprecated, use _burn(uint256) instead.
    /// @param owner owner of the token to burn.
    /// @param tokenId uint256 ID of the token being burned.
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of product that is not own.");
        _clearApproval(tokenId);
        storeProductCount[owner].decrement();
        productToStore[tokenId] = address(0);
        emit Transfer(owner, address(0), tokenId);
    }

    /// @dev Internal function to burn a specific token.
    ///  Reverts if the token does not exist.
    /// @param tokenId uint256 ID of the token being burned.
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /// @dev Internal function to transfer ownership of a given product ID to another address.
    ///  As opposed to transferFrom, this imposes no restrictions on msg.sender.
    /// @param from current owner of the token.
    /// @param to address to receive the ownership of the given product ID.
    /// @param tokenId uint256 ID of the product to be transferred.
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of product that is not own.");
        require(to != address(0), "ERC721: transfer to the zero address.");
        
        _clearApproval(tokenId);
        
        storeProductCount[from].decrement();
        storeProductCount[to].increment();
        
        productToStore[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to invoke `onERC721Received` on a target address.
    ///  The call is not executed if the target address is not a contract.
    ///
    ///  This function is deprecated.
    /// @param from address representing the previous owner of the given product ID.
    /// @param to target address that will receive the products.
    /// @param tokenId uint256 ID of the product to be transferred.
    /// @param _data bytes optional data to send along with the call.
    /// @return bool whether the call correctly returned the expected magic value.
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Private function to clear current approval of a given product ID.
    /// @param tokenId uint256 ID of the product to be transferred.
    function _clearApproval(uint256 tokenId) private {
        if (_productApprovals[tokenId] != address(0)) {
            _productApprovals[tokenId] = address(0);
        }
    }
}