/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke
const { constants, expectEvent, expectRevert } = require('openzeppelin-test-helpers');
const {expect} = require('chai');
const { ZERO_ADDRESS } = constants;

const BigNumber = require("bignumber.js");

const BookingContract = artifacts.require("BookingContract.sol");

contract("BookingContract", function ([kibiwooOwner, shop1, shop2, customer1, customer2, ...accounts]) {

    beforeEach(async function () {
        this.tokenIdRef = 1;
        this.blockTime = 3600;
        this.bookingContractInstance = await BookingContract.new(this.tokenIdRef, this.blockTime);
    });
    
    describe(
        '#Initial checks regarding initial set-up and general Smart contract configuration', 
        function () {
        
            it('Check tokenIdRef is correct.', async function () {
                let tokenIdRef = await this.bookingContractInstance.getTokenIdRef.call();
                expect(
                    web3.utils.toBN(tokenIdRef),
                    'Token Id reference bad initialized.'
                ).to.be.bignumber.equal(web3.utils.toBN(this.tokenIdRef));
            });

            it('Check block time is correct.', async function () {
                let blockTime = await this.bookingContractInstance.getBlockTime.call();
                expect(
                    web3.utils.toBN(blockTime), 
                    'Block Time bad initialized.'
                ).to.be.bignumber.equal(web3.utils.toBN(this.blockTime));
            });

            it('Check correct value of Maximum Reservation constant', async function () {
                let MAX_TIME = await 
                    this.bookingContractInstance.RESERVATION_DURATION_LIMIT();
                expect(
                    web3.utils.toBN(MAX_TIME),
                    'MAX_TIME constant incorrect value.'
                ).to.be.bignumber.equal(web3.utils.toBN(60*24*60*60));
            });

            it('Check Smart Contract can receive ether.', async function () {
                
                let balance = await web3.eth.getBalance(this.bookingContractInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    'Contract does not have 0 balance.'
                ).to.be.bignumber.equal(web3.utils.toBN(0));

                await this.bookingContractInstance.sendTransaction({
                    from: accounts[0],
                    value: web3.utils.toBN(1e+18)
                });
                
                balance = await web3.eth.getBalance(this.bookingContractInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    'Contract did not receive ether.'
                ).to.be.bignumber.equal(web3.utils.toBN(1e+18));
            });
        }
    );

    describe('#Test CheckAvailability and Book function', function () {
        
        it("Reverts if stopTime is less than startTime.", async function() {
            await expectRevert(
                this.bookingContractInstance.checkAvailability(10000, 5000), 
                'BookingContract: StopTimeBlock must end after startTimeBlock.'
            );
        });

        it("Reverts if total Time exceeds Reservation Maximum Limit time.", async function() {
            let start = 1000;
            let stop = 1000+61*24*3600;
            await expectRevert(
                this.bookingContractInstance.checkAvailability(start, stop), 
                'BookingContract: Reservation duration must not exceed limit'
            );
        });

        context('No revert cases', function () {

            it("Returns true if no reservations already made", async function() {
                let start = 1000;
                let stop = 1000+11*24*3600;
                expect(await this.bookingContractInstance.checkAvailability(start, stop)).to.be.true;
            });

            context('Cases where should return false due to overlap on intended bookings', function() {

                beforeEach('Create an initial booking', async function() {
                    this.start1 = 1000+5*24*3600;
                    this.stop1 = 1000+20*24*3600;
                    this.start2 = 1000+30*24*3600;
                    this.stop2 = 1000+35*24*3600;
                    this.bookingId1 = await 
                        this.bookingContractInstance.book(customer1, this.start1, this.stop1, {from: customer1});
                    this.bookingId2 = await 
                        this.bookingContractInstance.book(customer1, this.start2, this.stop2, {from: customer1});
                });

                // block time range >> reservation 1 and 2
                //  |---------------------|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 1.", async function() {
                    let startTime = 1000+2*24*3600;
                    let stopTime = 1000+36*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                //     // block time range >> reservation 1 but not 2
                //  |----------|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 2.", async function() {
                    let startTime = 1000+2*24*3600;
                    let stopTime = 1000+15*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range >> reservation 2 but not 1
                //              |----------|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 3.", async function() {
                    let startTime = 1000+28*24*3600;
                    let stopTime = 1000+36*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range starts before reservation 1 and ends during 1
                //  |----|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 4.", async function() {
                    let startTime = 1000+2*24*3600;
                    let stopTime = 1000+10*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range starts within reservation 1
                //       |--|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 5.", async function() {
                    let startTime = 1000+7*24*3600;
                    let stopTime = 1000+10*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range starts during reservation 1 and ends before 2
                //       |----|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 6.", async function() {
                    let startTime = 1000+7*24*3600;
                    let stopTime = 1000+18*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range starts after reservation 1 and ends during 2
                //             |---|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 7.", async function() {
                    let startTime = 1000+22*24*3600;
                    let stopTime = 1000+32*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });

                // block time range within reservation 2
                //                  |--|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 8.", async function() {
                    let startTime = 1000+32*24*3600;
                    let stopTime = 1000+34*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });


                // block time range starts during reservation 2
                //                    |---|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 9.", async function() {
                    let startTime = 1000+32*24*3600;
                    let stopTime = 1000+37*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.false;
                });


                // available time range before reservation 1
                // |--|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 10.", async function() {
                    let startTime = 1000+1*24*3600;
                    let stopTime = 1000+3*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.true;
                });



                // available time range between reservation 1 and 2
                //            |--|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 11.", async function() {
                    let startTime = 1000+22*24*3600;
                    let stopTime = 1000+28*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.true;
                });

                // available time range after 2
                //                        |--|
                //     |--1--|    |--2--|
                it("Returns false if already reserved. Case 12.", async function() {
                    let startTime = 1000+37*24*3600;
                    let stopTime = 1000+45*24*3600;
                    let available = await 
                        this.bookingContractInstance.checkAvailability(startTime, stopTime);
                    expect(available).to.be.true;
                });
            });
        });
    });

    describe('#Test Book function', function () {
        
        it("Reverts if stopTime is less than startTime.", async function() {
            await expectRevert(
                this.bookingContractInstance.book(customer1, 10000, 5000), 
                'BookingContract: StopTimeBlock must end after startTimeBlock.'
            );
        });

        it("Reverts if total Time exceeds Reservation Maximum Limit time.", async function() {
            let start = 1000;
            let stop = 1000+61*24*3600;
            await expectRevert(
                this.bookingContractInstance.book(customer1, start, stop), 
                'BookingContract: Reservation duration must not exceed limit'
            );
        });

        context('With correct values', function () {

            beforeEach('Create initial bookings', async function() {
                this.start1 = 1000+5*24*3600;
                this.stop1 = 1000+20*24*3600;
                this.start2 = 1000+30*24*3600;
                this.stop2 = 1000+35*24*3600;
                ({ logs: this.logs } = await 
                    this.bookingContractInstance.book(
                        customer1, 
                        this.start1, 
                        this.stop1, 
                        {from: customer2}
                    )
                );
                this.bookingId2 = await 
                    this.bookingContractInstance.book(
                        customer2, 
                        this.start2, 
                        this.stop2, 
                        {from: customer2}
                    );
            });

            it("Check correct owner of bookings.", async function() {
                let owner1 = await this.bookingContractInstance.ownerOf(0);
                let owner2 = await this.bookingContractInstance.ownerOf(1);
                expect(owner1).to.equal(customer1);
                expect(owner2).to.equal(customer2);
            });

            it("Check correct values for startTimeStamp and stopTimestamp", async function () {
                let start1 = await this.bookingContractInstance.startTimestamps(0);
                let start2 = await this.bookingContractInstance.startTimestamps(1);
                let nonExistentStart = await this.bookingContractInstance.startTimestamps(2);

                expect(web3.utils.toBN(start1)).to.be.bignumber.equal(web3.utils.toBN(this.start1));
                expect(web3.utils.toBN(start2)).to.be.bignumber.equal(web3.utils.toBN(this.start2));
                expect(web3.utils.toBN(nonExistentStart)).to.be.bignumber.equal(web3.utils.toBN(0));

                let stop1 = await this.bookingContractInstance.stopTimestamps(0);
                let stop2 = await this.bookingContractInstance.stopTimestamps(1);
                let nonExistentStop = await this.bookingContractInstance.stopTimestamps(2);

                expect(web3.utils.toBN(stop1)).to.be.bignumber.equal(web3.utils.toBN(this.stop1));
                expect(web3.utils.toBN(stop2)).to.be.bignumber.equal(web3.utils.toBN(this.stop2));
                expect(web3.utils.toBN(nonExistentStop)).to.be.bignumber.equal(web3.utils.toBN(0));
            });

            it('Booking a product emits NewBooking event with correct values.', async function () {
                expectEvent.inLogs(
                    this.logs, 
                    'NewBooking', 
                    {
                        booker: customer1, 
                        bookingId: new web3.utils.BN(0), 
                        startTimeBlock: new web3.utils.toBN(this.start1),
                        stopTimeBlock: new web3.utils.toBN(this.stop1)
                    }
                );
            });

            it("Reverts if trying to book an already booked timeslot", async function () {
                await expectRevert(
                    this.bookingContractInstance.book(customer2, this.start1, this.stop1), 
                    'BookingContract: Time blocks are unavailable.'
                );
                // Action does not have effect over owner of booking
                expect(await this.bookingContractInstance.ownerOf(0)).to.equal(customer1);
            });
        });
    });

  //     describe("cancellation", () => {
  //   before(async () => {
  //     calendar = await Calendar.new();
  //     await calendar.mint();
  //     await calendar.mint();

  //     await calendar.reserve(0, 1000, 2000, { from: renter1 });
  //     await calendar.reserve(0, 3000, 3500, { from: renter1 });
  //     await calendar.reserve(0, 4000, 5000, { from: renter1 });
  //     await calendar.reserve(0, 2500, 2700, { from: renter2 });
  //   });

  //   it("makes cancelled time period available again", async () => {
  //     await calendar.cancel(0, 0, { from: renter1 });

  //     (await calendar.isAvailable(0, 1000, 2000)).should.equal(true);

  //     (await calendar.renterOf(0, 1500)).should.equal(nullAddress);

  //     // can be reserved again
  //     await calendar.reserve(0, 1000, 2000, { from: renter1 });
  //   });

  //   it("reverts if requestor doesn't own the reservation", async () => {
  //     calendar
  //       .cancel(0, 1, {
  //         from: renter2,
  //       })
  //       .should.be.rejectedWith(EVMRevert);
  //   });

  //   it("reverts if the calendar id doesn't match", async () => {
  //     calendar
  //       .cancel(1, 0, { from: renter1 })
  //       .should.be.rejectedWith(EVMRevert);
  //   });

  //   it("reverts if the calendar id doesn't exist", async () => {
  //     calendar
  //       .cancel(2, 0, { from: renter1 })
  //       .should.be.rejectedWith(EVMRevert);
  //   });
  // });
});