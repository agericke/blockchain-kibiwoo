pragma solidity ^0.5.0;

import "./kibiwoohelperproducts.sol";
// Change this import for importing openzeppelin erc721's implementation.
import "./ERC721.sol";

/// @title A contract that implements ERC721 implementation adapted to Kibiwoo's Products as the NFTs
/// @author Álvaro Gericke
contract KibiwooOwnership is KibiwooHelperProducts, ERC721{

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

    // Mapping to keep track of approvals for each product.
    mapping(uint => address)  productApprovals;

    /// @notice Count all the products a Store has.
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner Address of the store for whom wuery the balance
    /// @return The number of prdocts owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        return storeProductCount[_owner];

    }

    /// @notice Find the owner of a specific product
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT. (In our case a product)
    /// @return The address of the owner of the NFT. In our case s the address of the store that owns that product.
    function ownerOf(uint256 _tokenId) external view returns (address) {
           return productToStore[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // TODO: Use Safemath libarary form openzeppelin
        storeProductCount[_to] += 1;
        storeProductCount[_from] -= 1;
        productToStore[_tokenId] = _to;
        emit Transfer(_from,_to,_tokenId);
    }

    /// @notice Transfer ownership of  product. -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require (msg.sender == productToStore[_tokenId] || productApprovals[_tokenId] == msg.sender);
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