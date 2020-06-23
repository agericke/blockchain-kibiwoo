pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/drafts/Counters.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol';
import 'solidity-treemap/contracts/TreeMap.sol';

/// @author Álvaro Gericke
/// @title A contract for managing products  bookings.
contract BookingContract is ERC721Enumerable {

    // TODO: Use Safemath library from openzeppelin
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using TreeMap for TreeMap.Map;

    // Constant that representss the Maximum duration allowed. 
    // This is implemented for security reasons
    uint256 constant public RESERVATION_DURATION_LIMIT = 60 days;
    /// tokenId this contract refers to in the Products Management contract.
    uint256 private _tokenIdReference;
    /// Constant that represents the amount of time each block represents.
    uint256 private _blockTime;
    // TreeMap that stores all reservations.
    TreeMap.Map public timeBlocksMap;
    /// Mapping from reservationId to startTimeStamp
    mapping(uint256 => uint256) public startTimestamps;
    /// Mapping from reservationId to endTimeStamp
    mapping(uint256 => uint256) public stopTimestamps;
    /// Variable to store the id for the next token
    uint256 nextTokenId;

    event NewBooking(
        address indexed booker, 
        uint256 indexed bookingId, 
        uint256 startTimeBlock, 
        uint256 stopTimeBlock
    );
    event CancelBooking(
        address indexed booker,
        uint256 indexed bookingId
    );

    constructor (uint256 tokenIdRef, uint256 min_rent_time) public {
        _tokenIdReference = tokenIdRef;
        _blockTime = min_rent_time;
    }

    ///@notice special function for allowing the Samrt contract receive ether in case any of the 
    ///         existing functions is called
    function() external payable {

    }

    /// @notice Reserve the period between time `_start` to time `_stop`
    /// @dev A successful booking must ensure each time slot in the range _start to _stop
    ///  is not previously booked.
    /// @param _booker The Ethereum address of the person that wants to book.
    /// @param _start startTimeBlock.
    /// @param _stop stopTimeBlock
    /// @return The token Id associated to this reservation.
    function book(address _booker, uint256 _start, uint256 _stop)
    public
    returns(uint256)
    {
        // First ensure all timeblocks between `_start`and `_stop` are available. 
        if (!checkAvailability(_start, _stop)) {
            revert("BookingContract: Time blocks are unavailable.");
        }

        // Obtain the Id that will be associated to this booking.
        uint256 tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        // Create the token of the reservation.
        _mint(_booker, tokenId);

        // Store start timeblock and stop timeblock for this booking tokenId.
        startTimestamps[tokenId] = _start;
        stopTimestamps[tokenId] = _stop;

        timeBlocksMap.put(_start, tokenId);

        emit NewBooking(_booker, tokenId, _start, _stop);

        return tokenId;
    }

    /// @notice Cancel an existing booking. Only the owner can do it.
    /// @param _bookingId Booking Identifier inside this contract.
    /// @param origin equals to the msg.sender value of the origin transaction.
    function cancelBooking(address origin, uint256 _bookingId)
    public
    {
        require(_exists(_bookingId), "BookingContract: Booking does not exist");

        uint256 startTime = startTimestamps[_bookingId];

        _burn(origin, _bookingId);

        delete startTimestamps[_bookingId];
        delete stopTimestamps[_bookingId];
        timeBlocksMap.remove(startTime);

        emit CancelBooking(origin, _bookingId);
    }

    /// @notice Gets the tokenId it refers to in the product management contract.
    /// @return uint256 representing product's Id this token refers to.
    function getTokenIdRef() public view returns(uint256) {
        return _tokenIdReference;
    }

    /// @notice Gets the number of seconds each block of time represents.
    /// @return uint256 that represents the amount of time in seconds of each block time.
    function getBlockTime() public view returns(uint256) {
        return _blockTime;
    }

    /// @notice Get the reservationId for a specific startTime
    /// @param _startTimeBlock The start timeblock save as a key in the TreeMap
    /// @return uint256 representating the reservationId associated to that startTime.
    function getReservationIdFromStartTimeBlock(uint256 _startTimeBlock) 
    public 
    view 
    returns(uint256) 
    {
        bool found;
        uint256 reservationId;

        (found, reservationId) = timeBlocksMap.get(_startTimeBlock);

        if (!found) {
            revert("BookingContract: No Reservation Id for that startTimeBlock.");
        }

        return reservationId;
    }

    /// @notice Check if timeslots between startTimeBlock and stopTimeBlock are available.
    /// @param _startTimeBlock The start time block for the reservation.
    /// @param _stopTimeBlock The end time block for the reservation.
    /// @return bool indicating if the token Id is available or not.
    function checkAvailability(uint256 _startTimeBlock, uint256 _stopTimeBlock) 
    public 
    view 
    returns(bool) 
    {
        
        require(_stopTimeBlock > _startTimeBlock, "BookingContract: StopTimeBlock must end after startTimeBlock.");
        require((_stopTimeBlock - _startTimeBlock) <= uint256(RESERVATION_DURATION_LIMIT), "BookingContract: Reservation duration must not exceed limit");

        bool found;
        uint256 reservationId;
        uint256 startTime;

        // find closest event that started after _start
        (found, startTime, reservationId) = timeBlocksMap.ceilingEntry(_startTimeBlock);
        if (found && _stopTimeBlock > startTime) {
          return false;
        }

        // find closest event that started before _start
        (found, startTime, reservationId) = timeBlocksMap.floorEntry(_startTimeBlock);
        if (found) {
            if (stopTimestamps[reservationId] > _startTimeBlock) {
                return false;
            }
        }
       return true;
    }
}