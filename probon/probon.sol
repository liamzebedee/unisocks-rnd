// this is an AMM with a unisocks-style price curve.
// the exchange sells an NFT. The price of the NFT is a function of the number of NFTs sold.


// In dappnet, I launched the token, and as I realised it was more valuable (by seeing stats), I increased the price.
// the problem wiht the original unisocks design is that it is not sufficient for fundraising
// as the initial creator of the pool needs to deposit a lot of money to get the ball rolling.
// so instead, we allocate 50% of the initial supply to the creator, and 50% to the pool.
// the creator can sell the NFT's at a fixed price, and the pool can sell the NFT's at a variable price.


// it needs to be like a game
// people can commit capital
// the longer they lock it up (conviction), the more they get of the NFT supply
// people can individually exit their commitment, and their lockups are redistributed to the other holders
// it's like a french tauntine contract.
// after the initial period passes, there is now a total capital locked of C.
// the price of the NFT is now P = C / N, where N is the total supply of NFT's.
// ie. if C = 18 ETH, and N = 1000, then P = 0.018 ETH
// the AMM is then set to sell the NFT's at an average of P.
// the AMM is designed such that buyers receive an integer number of NFT's.
// so if they committed 0.5 ETH, and the total capital committed was 5 ETH, and the supply allocated was 100 NFT's, the price of each NFT is 5/100=0.05 ETH. So they would receive 10 NFT's.
// however, if they committed 0.56 ETH, and the total capital committed was 5 ETH, and the supply allocated was 100 NFT's, the price of each NFT is 5/100=0.05 ETH. So they would receive 11 NFT's. And a small refund of 0.01 ETH.

// what's the idea here?
// it allows people to fundraise without knowing what price to raise at.
// 1. a fundraiser creates a pool, setting an initial total supply of NFT's, and minimum commitment
// 2. for the next 24h, anyone can stake capital into the pool, and receive pool shares in return.
//    i. much like a yield farm, early stakers receive more pool shares, because the total capital committed is lower in the early stages
//       there are a couple desired properties for this:
//       - we want to incentivise early stage believers.
//       - we want to level the playing field with whales. So initially, stakers receive an amount of pool shares quadratic in their capital committed.
//         this means that a whale can't just dump a lot of capital into the pool, and receive a lot of pool shares.
//         as time goes on, the total capital committed increases, and the quadratic function becomes linear.
//         so bigger stakers receive more pool shares, but early stakers are still incentivised to commit capital.
//   ii. removing capital will incur a small fee (3%) in order to disincentivise frontrunning. the fee is distributed to the remaining stakers, at the end of the period.
// 3. after the 24h is up, the initial fundraising event has finished. We have discovered the price of the NFT's.
//    the pool shares are convertible to NFT's. 
//    the price of the NFT is the total capital committed / total supply of NFT's.
//    ie. for a pool with 500 NFT's, and 23 ETH committed, the price of each NFT is 23/500 = 0.046 ETH.
// 4. 50% of the NFT's are allocated to the pool, and 50% are allocated to the investors.
//    the pool sells NFT's according to a bonding curve, set at the price discovered in step 3 (x 10% to makeup the time value of their capital).

// thinking around step (4) is still in progress.
// the idea is that the pool can be used to sell the NFT's at a variable price.
// the price of the NFT is according to the uniswap price curve.
// the pool is set to sell the NFT's at an average price of P.
// 50% of the capital raised is used to create a liquid market
// the other 50% goes to the creator of the pool.
// this has a couple effects:
// - the creator has fundraised at a price that was fairly discovered by the market + they haven't had to front up the capital to get the ball rolling
// - this is good - they've raised capital
// - for the buyers of the NFT, they've also had the opportunity to buy early, and get a discount
// - if they become dissatisfied with the price, they sell their NFT's to the pool
// - if they hold their NFT's, they receive trading fees from the pool
// - lastly, the creator also receives trading fees from the pool. But this is via a DAO, so they can't just withdraw it all. It can be voted on fairly by governance.
// 
// the other part is governance:
// Curve mechanism. Instead of fees to creator, fees go 50% to holders, 50% to a DAO, and there is governance which can change this.
// so for example, early funders receive fees from specuators trading on the pool.
// the DAO can then use these fees to fund projects, or buy back NFT's.


// what is the name of this protocol?
// it's a fundraising protocol, with a bonding curve.
// it's a fundraising protocol, with a bonding curve, and a DAO.
// it's a fundraising protocol, with a bonding curve, and a DAO, and a governance token.
// it's a fundraising protocol, with a bonding curve, and a DAO, and a governance token, and a yield farm.
// it's a fundraising protocol, with a bonding curve, and a DAO, and a governance token, and a yield farm, and a french tauntine contract.
// it's a fundraising protocol, with a bonding curve, and a DAO, and a governance token, and a yield farm, and a french tauntine contract, and a unisocks price curve.
// fundraising protocol with bonding curve, DAO, governance token, yield farm, french tauntine contract, unisocks price curve.
// funproboncdaogtyfcupc
// probon

contract probon {
    // External contracts.
    // 
    // UniswapV2Factory
    // UniswapV2Router02
    IUniswapV2Factory public UniswapV2Factory;
    IUniswapV2Router02 public UniswapV2Router02;

    // the time period for the fundraising event
    uint256[2] public fundraising_period; // start, end

    // the creator of the pool
    address public creator;

    // the token that is being sold
    IERC721 public token;

    // the total supply of NFT's
    uint256 public totalSupply;

    // the minimum commitment
    uint256 public minCommitment;

    // the total capital committed
    uint256 public totalCapital;

    // the total pool shares
    uint256 public totalPoolShares;

    // the pool shares of each staker
    mapping(address => uint256) public poolShares;

    // the capital committed by each staker
    mapping(address => uint256) public capital;

    // the NFT's allocated to each staker
    mapping(address => uint256) public nfts;

    // the NFT's allocated to the pool
    uint256 public poolNfts;

    IFarmingPod public farmingPod;

    // Whether setupLiquidity has been called.
    bool public liquiditySetup;
    

    // Create a pool.
    function createPool(
        IERC721 _token,
        uint256 _totalSupply,
        uint256 _minCommitment,
        uint256 _fundraisingPeriod
    ) public {
        // set the creator
        creator = msg.sender;

        // set the token
        token = _token;

        // set the total supply
        totalSupply = _totalSupply;

        // set the minimum commitment
        minCommitment = _minCommitment;

        // set the fundraising period
        fundraising_period[0] = block.timestamp;
        fundraising_period[1] = block.timestamp + _fundraisingPeriod;
    }

    // Stake capital into the pool.
    function stakeCapital(uint256 amount) public payable {
        // check that the fundraising period is active
        require(block.timestamp >= fundraising_period[0], "fundraising period not active");
        require(block.timestamp <= fundraising_period[1], "fundraising period has ended");

        // check that the minimum commitment has been met
        require(amount >= minCommitment, "minimum commitment not met");

        // start farming pool shares for this user.
        farmingPod.startFarming(amount, this.fundraising_period[1]);

        // // update the total pool shares
        // totalPoolShares += _poolShares;

        // // update the pool shares of the staker
        // poolShares[msg.sender] += _poolShares;

        // // update the capital committed by the staker
        // capital[msg.sender] += msg.value;

        // // update the total capital committed
        // totalCapital += msg.value;
    }

    // After the fundraising period has ended, this function is called once to transfer
    // 50% of the capital to the creator, and then setup the liquidity in the AMM with the other 50%.
    function setupLiquidity() public {
        // check that the fundraising period has ended
        require(block.timestamp > fundraising_period[1], "fundraising period has not ended");

        // check that liquidity has not already been setup
        require(!liquiditySetup, "liquidity has already been setup");

        // check that the creator is calling this function
        // require(msg.sender == creator, "only the creator can call this function");

        // transfer 50% of the capital to the creator
        payable(creator).transfer(totalCapital / 2);

        // setup the liquidity in the AMM
        // Simply deposit the NFT's into Uniswap v2.
        // TODO.
    }

    // Get the pool shares for a staker.
    function getPoolShares(address staker) public view returns (uint256) {
        uint256 amount = this.farmingPod.farmed(staker);
        // Quadratic funding formula.
        // For any given project, take the square root of each contributor's contribution, add these values together, and take the square of the result.
        // This is the total amount of funding that the project will receive.
        // Converted to python pseudocode:
        // sqrt(sum([sqrt(x) for x in contributions])) ** 2
        // Converted to Latex:
        // \sqrt{\sum_{i=1}^{n} \sqrt{x_i}}^2
        
        // In LaTeX: 
        // return sqrt(amount) + (amount - sqrt(amount)) * (block.timestamp - this.fundraising_period[0]) / (this.fundraising_period[1] - this.fundraising_period[0]);

    }

    // Convert your pool shares into NFT's, after the fundraising period has ended.
    function convertPoolSharesToNfts() public {
        // check that the fundraising period has ended
        require(block.timestamp > fundraising_period[1], "fundraising period has not ended");

        // get the pool shares of the staker
        uint256 _poolShares = this.getPoolShares(msg.sender);

        // get the NFT's allocated to the pool
        uint256 _poolNfts = this.poolNfts;

        // calculate the NFT's allocated to the staker
        uint256 _nfts = _poolShares * _poolNfts / totalPoolShares;

        // update the NFT's allocated to the pool
        poolNfts -= _nfts;

        // update the NFT's allocated to the staker
        nfts[msg.sender] += _nfts;
    }



    // 
    // Internal functions.
    // 

    function calculatePoolShares(uint256 _capital) internal view returns (uint256) {
        // calculate the pool shares
        uint256 _poolShares = _capital * _capital / totalCapital;

        // return the pool shares
        return _poolShares;
    }

    // 
    // Helper functions.
    // 

    function isFundraising() public view returns (bool) {
        return block.timestamp >= fundraising_period[0] && block.timestamp <= fundraising_period[1];
    }

    function isFundraisingOver() public view returns (bool) {
        return block.timestamp > fundraising_period[1];
    }

    function isFundraisingStarted() public view returns (bool) {
        return block.timestamp >= fundraising_period[0];
    }


    
}