pragma solidity ^0.5.0;

import "./KibiwooHelperProducts.sol";
// Change this import for importing openzeppelin erc721's implementation.
import 'openzeppelin-solidity/contracts/token/IERC721.sol';

/// @title A contract that implements ERC721 implementation adapted to Kibiwoo's 
///  Products as the NFTs.
/// @author Álvaro Gericke
contract KibiwooOwnership is KibiwooHelperProducts, ERC721{

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

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Gets the number of products a Store has.
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner Address of the store for whom query the balance.
    /// @return uint256 The number of products owned by `_owner`, possibly zero
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return storeProductCount[_owner].current();
    }

    /// @notice Find the owner of a specific product.
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT. (In our case a product)-
    /// @return The address of the owner of the NFT. Address of the store that owns that product.
    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = productToStore[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @notice Change or reaffirm the approved address for an NFT.
    /// @dev Approves another address to transfer the given token ID.
    /// The zero address indicates there is no approved address.
    /// There can only be one approved address per token at a given time.
    /// Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// Can only be called by the token owner or an approved operator.
    /// @param to address to be approved for the given token ID.
    /// @param tokenId uint256 ID of the token to be approved.
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _productApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @notice Gets the approved address for a token ID, or zero if no address set.
    /// @dev Throws if `_tokenId` is not a valid NFT (does not exist).
    /// @param tokenId uint256 ID of the token to query the approval of.
    /// @return address The approved address for this product, or the zero address if there is none.
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _productApprovals[tokenId];
    }


    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets. * An operator is allowed to transfer all 
    ///  tokens of the sender on their behalf.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param to Address to add to the set of authorized operators.
    /// @param approved True if the operator is approved, false to revoke approval.
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /// @notice Tells whether an operator is approved by a given owner.
    /// @param owner owner address which you want to query the approval of.
    /// @param operator operator address which you want to query the approval of.
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // TODO: Use Safemath libarary form openzeppelin
        storeProductCount[_to] += 1;
        storeProductCount[_from] -= 1;
        productToStore[_tokenId] = _to;
        emit Transfer(_from,_to,_tokenId);
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId), 
            "ERC721: transfer caller is not owner nor approved"
        );

        _transferFrom(from, to, tokenId);
    }
    /// @notice Transfers the ownership of a given product ID to another address. 
    ///  -- THE CALLER IS RESPONSIBLE TO CONFIRM THAT `to` IS CAPABLE OF 
    ///  RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST.
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. Requires the msg.sender to be the owner, 
    ///  approved, or operator.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require (
            msg.sender == productToStore[_tokenId] || 
            productApprovals[_tokenId] == msg.sender
        );
        _transfer(_from, _to, _tokenId);
    }
    

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable onlyOwnerOf(_tokenId) {
        productApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

}