/*
Jackpot is a contract that allows players to play a game of 777.
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./random.sol";

contract Jackpot is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  mapping(address => uint256) private _tOwned;

  uint256 private _round = 0;
  mapping(uint256 => mapping(address => uint256)) private _jackpotAllocation;

  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) public _isExcludedFromFee;

  address payable public Wallet_Marketing =
    payable(0xF3BeAaD8F3CFDCE8b0f2a0f0F677a58058CCd877);
  address payable public constant Wallet_Burn =
    payable(0x000000000000000000000000000000000000dEaD);
  address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  //0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c mainnent bnb
  //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd testnet
  uint256 private constant MAX = ~uint256(0);
  uint8 private constant _decimals = 18;
  uint256 private _tTotal = 777777777 * 10**_decimals;
  string private constant _name = "Jackpot";
  string private constant _symbol = "777";

  uint256 public _priceVar = 20;
  uint256 public _ticketPrice = 1 / _priceVar;

  uint8 private txCount = 0;
  uint8 private swapTrigger = 3;

  // This is the max fee that the contract will accept, it is hard-coded to protect buyers
  uint256 public maxPossibleSellFee = 15;

  uint256 public _Tax_On_Buy = 11;
  uint256 public _Tax_On_Sell = 11;

  uint256 public Percent_Marketing = 18;
  uint256 public Percent_Jackpot = 64;
  uint256 public Percent_Burn = 0;
  uint256 public Percent_AutoLP = 18;

  uint256 public _maxWalletToken = _tTotal.mul(5).div(100);
  uint256 private _previousMaxWalletToken = _maxWalletToken;

  uint256 public _maxTxAmount = _tTotal.mul(5).div(100);
  uint256 private _previousMaxTxAmount = _maxTxAmount;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  bool public inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  event SwapAndLiquifyEnabledUpdated(bool true_or_false);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  event isbuy(bool isit);
  event buyfee(uint256 buyFEE);
  event txcount(uint256 ttxcount);
  event ttransferAmount(uint256 tTransferAmount);
  event howmuchfee(uint256 fee);
  event isswap(bool truefalse);
  event inswapAndLiquify(bool trufals);
  event frm(address frmo);
  event tto(address ttto);
  event swapandLiquifyEnabled(bool trufls);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() {
    address deployer = msg.sender;

    _owner = deployer;
    emit OwnershipTransferred(address(0), _owner);

    _tOwned[owner()] = _tTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    );
    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Testnet

    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[Wallet_Marketing] = true;
    _isExcludedFromFee[Wallet_Burn] = true;

    emit Transfer(address(0), owner(), _tTotal);
  }

  function changeBS(uint256 bamount, uint256 samount) public onlyOwner {
    require((samount) <= maxPossibleSellFee, "Sell fee is too high!");

    _Tax_On_Buy = bamount;
    _Tax_On_Sell = samount;
  }

  function changeMW(uint256 amount) public onlyOwner {
    _maxWalletToken = amount;
  }

  function changeMWPerc(uint256 amount) public onlyOwner {
    _maxWalletToken = (_tTotal * amount) / 1000;
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _tOwned[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address theOwner, address theSpender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[theOwner][theSpender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  receive() external payable {}

  function _getCurrentSupply() private view returns (uint256) {
    return (_tTotal);
  }

  function balanceOfBNB() public view returns (uint256) {
    return address(this).balance;
  }

  function _approve(
    address theOwner,
    address theSpender,
    uint256 amount
  ) private {
    require(
      theOwner != address(0) && theSpender != address(0),
      "ERR: zero address"
    );
    _allowances[theOwner][theSpender] = amount;
    emit Approval(theOwner, theSpender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    if (
      to != owner() &&
      to != Wallet_Burn &&
      to != Wallet_Marketing &&
      to != address(this) &&
      to != uniswapV2Pair &&
      from != owner()
    ) {
      uint256 heldTokens = balanceOf(to);
      require((heldTokens + amount) <= _maxWalletToken, "Over wallet limit.");
    }

    if (from != owner())
      require(amount <= _maxTxAmount, "Over transaction limit.");

    require(from != address(0) && to != address(0), "ERR: Using 0 address!");
    require(amount > 0, "Token value must be higher than zero.");

    // emit inswapAndLiquify (inSwapAndLiquify);
    // emit frm (from);
    // emit tto (to);
    // emit swapandLiquifyEnabled (swapAndLiquifyEnabled);

    if (
      txCount >= swapTrigger &&
      !inSwapAndLiquify &&
      from != uniswapV2Pair &&
      swapAndLiquifyEnabled &&
      from != Wallet_Marketing &&
      to != Wallet_Marketing
    ) {
      //  emit isswap (true);

      uint256 contractTokenBalance = balanceOf(address(this));
      if (contractTokenBalance > _maxTxAmount) {
        contractTokenBalance = _maxTxAmount;
      }
      txCount = 0;
      swapAndLiquify(contractTokenBalance);
    }

    bool takeFee = true;
    bool isBuy;
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    } else {
      if (from == uniswapV2Pair) {
        isBuy = true;
      }

      txCount++;
      //    emit txcount (txCount);
    }

    _tokenTransfer(from, to, amount, takeFee, isBuy);
  }

  function sendToWallet(address payable wallet, uint256 amount) private {
    wallet.transfer(amount);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    uint256 tokens_to_Burn = (contractTokenBalance * Percent_Burn) / 100;
    _tTotal = _tTotal - tokens_to_Burn;
    _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn] + tokens_to_Burn;
    _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_Burn;

    uint256 tokens_to_M = (contractTokenBalance * Percent_Marketing) / 100;
    uint256 tokens_to_D = (contractTokenBalance * Percent_Jackpot) / 100;
    uint256 tokens_to_LP_Half = (contractTokenBalance * Percent_AutoLP) / 200;

    uint256 balanceBeforeSwap = address(this).balance;
    swapTokensForBNB(tokens_to_LP_Half + tokens_to_M + tokens_to_D);
    uint256 BNB_Total = address(this).balance - balanceBeforeSwap;

    uint256 split_M = (Percent_Marketing * 100) /
      (Percent_AutoLP + Percent_Marketing + Percent_Jackpot);
    uint256 BNB_M = (BNB_Total * split_M) / 100;

    uint256 split_D = (Percent_Jackpot * 100) /
      (Percent_AutoLP + Percent_Marketing + Percent_Jackpot);
    uint256 BNB_D = (BNB_Total * split_D) / 100;

    addLiquidity(tokens_to_LP_Half, (BNB_Total - BNB_M - BNB_D));
    emit SwapAndLiquify(
      tokens_to_LP_Half,
      (BNB_Total - BNB_M - BNB_D),
      tokens_to_LP_Half
    );

    sendToWallet(Wallet_Marketing, BNB_M);

    BNB_Total = address(this).balance;
  }

  function swapTokensForBNB(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: BNBAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      owner(),
      block.timestamp
    );
  }

  function remove_Random_Tokens(
    address random_Token_Address,
    uint256 percent_of_Tokens
  ) public returns (bool _sent) {
    require(
      random_Token_Address != address(this),
      "Can not remove native token"
    );
    uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
    uint256 removeRandom = (totalRandom * percent_of_Tokens) / 100;
    _sent = IERC20(random_Token_Address).transfer(
      Wallet_Marketing,
      removeRandom
    );
  }
event isfee (bool isFee);
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 tAmount,
    bool takeFee,
    bool isBuy
  ) private {
    //   emit isbuy(isBuy);
    emit isfee(takeFee);
    if (!takeFee) {
      _tOwned[sender] = _tOwned[sender] - tAmount;
      _tOwned[recipient] = _tOwned[recipient] + tAmount;
      emit Transfer(sender, recipient, tAmount);

      if (recipient == Wallet_Burn) _tTotal = _tTotal - tAmount;
    } else if (isBuy) {
      uint256 tokenBNBprice = getAmountOutMin(address(this), WBNB, tAmount);
      bnbAmount[recipient] = bnbAmount[recipient] + tokenBNBprice;
      uint256 ticketAmount = bnbAmount[recipient] / ticketPrice;

      //  if(tickets[recipient] )
      if (ticketAmount > 0) {
        if (hodlBonus[recipient] == 0) {
          hodlBonus[recipient] = block.timestamp;
          if (hodlBonusDaily[recipient] == 0) {
            hodlBonusDaily[recipient] = block.timestamp;
          }
        }
        if (lotteriesDaily[currentLotteryIdDaily].isActive == true){
        buyLotteryTickets(ticketAmount, recipient);
        if (ticketsDaily[recipient] == 0) {
          buyLotteryTicketsDaily(1, recipient);
        }
        bnbAmount[recipient] =
          bnbAmount[recipient] -
          (ticketAmount * ticketPrice);
          }
      }

      //     emit howmuchfee(tAmount);
      uint256 buyFEE = (tAmount * _Tax_On_Buy) / 100;
      //     emit buyfee(buyFEE);

      uint256 tTransferAmount = tAmount - buyFEE;
      //       emit ttransferAmount(tTransferAmount);

      _tOwned[sender] = _tOwned[sender] - tAmount;
      _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
      _tOwned[address(this)] = _tOwned[address(this)] + buyFEE;

      emit Transfer(sender, recipient, tTransferAmount);

      if (recipient == Wallet_Burn) _tTotal = _tTotal - tTransferAmount;
    } else {
      uint256 tokenBNBprice = getAmountOutMin(address(this), WBNB, tAmount);
      bnbAmountSell[sender] = bnbAmountSell[sender] + tokenBNBprice;

      uint256 ticketAmount = bnbAmountSell[sender] / ticketPrice;
       if (lotteriesDaily[currentLotteryIdDaily].isActive == true){
      if (ticketAmount > 0) {
        if (ticketAmount > tickets[sender]) {
          sellLotteryTickets(tickets[sender], sender);
        } else {
          sellLotteryTickets(ticketAmount, sender);
        }
        if (ticketsDaily[sender] == 1) {
          sellLotteryTicketsDaily(1, sender);
        }
        bnbAmountSell[sender] =
          bnbAmountSell[sender] -
          (ticketAmount * ticketPrice);
      }}
      hodlBonus[sender] = 0;
      hodlBonusDaily[sender] = 0;

      uint256 sellFEE = (tAmount * _Tax_On_Sell) / 100;
      uint256 tTransferAmount = tAmount - sellFEE;

      _tOwned[sender] = _tOwned[sender] - tAmount;
      _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
      _tOwned[address(this)] = _tOwned[address(this)] + sellFEE;
      emit Transfer(sender, recipient, tTransferAmount);

      if (recipient == Wallet_Burn) _tTotal = _tTotal - tTransferAmount;
    }
  }

  /*
Calculate 1 token price via router getAmountsOut method
*/
  function getAmountOutMin(
    address _tokenIn,
    address _tokenOut,
    uint256 _amount
  ) public view returns (uint256) {
    address[] memory path;
    path = new address[](2);
    path[0] = _tokenIn;
    path[1] = _tokenOut;
    uint256[] memory amountOutMins = uniswapV2Router.getAmountsOut(
      _amount,
      path
    );
    return amountOutMins[path.length - 1];
  }

  struct LotteryStruct {
    uint256 lotteryId;
    uint256 startTime;
    uint256 endTime;
    bool isActive;
    bool isCompleted; // winner was found; winnings were deposited.
    bool isCreated; // is created
  }
  struct TicketDistributionStruct {
    address playerAddress;
    uint256 startIndex; // inclusive
    uint256 endIndex; // inclusive
  }
  struct WinningTicketStruct {
    uint256 currentLotteryId;
    uint256 winningTicketIndex;
    address addr; // TASK: rename to "winningAddress"?
  }

  uint256 public constant NUMBER_OF_HOURS_HOURLY = 1; // 1 day by default; configurable
  uint256 public constant NUMBER_OF_HOURS_DAILY = 24; // 1 day by default; configurable

  bool public inLotteryDraw; //used so people can't buy while drawing lottery

  // max # loops allowed for binary search; to prevent some bugs causing infinite loops in binary search
  uint256 public maxLoops = 10;
  uint256 private loopCount = 0; // for binary search

  uint256 public ticketPrice = (1 * (10**16)); // 0.05 BNB

  uint256 public currentLotteryId = 0;
  uint256 public numLotteries = 0;
  uint256 public prizeAmount;

  WinningTicketStruct public winningTicket;

  TicketDistributionStruct[] public ticketDistribution;

  address[] public listOfPlayers; // Don't rely on this for current participants list

  uint256 public numActivePlayers;
  uint256 public numTotalTickets;

  // Daily

  mapping(uint256 => uint256) public prizes; // key is lotteryId
  mapping(uint256 => WinningTicketStruct) public winningTickets; // key is lotteryId
  mapping(address => bool) public players; // key is player address
  mapping(address => uint256) public tickets; // key is player address
  mapping(uint256 => LotteryStruct) public lotteries; // key is lotteryId
  mapping(uint256 => mapping(address => uint256)) public pendingWithdrawals; // pending withdrawals for each winner, key is lotteryId, then player address

  mapping(address => uint256) public hodlBonus;

  mapping(address => uint256) public bnbAmount;
  mapping(address => uint256) public bnbAmountSell;

  // Events
  event LogNewLottery(address creator, uint256 startTime, uint256 endTime); // emit when lottery created
  event LogTicketsBought(address player, uint256 numTickets); // emit when user purchases tix
  event LogTicketsSold(address player, uint256 numTickets); // emit when user sells tix

  // emit when lottery drawing happens; winner found
  event LogWinnerFound(
    uint256 lotteryId,
    uint256 winningTicketIndex,
    address winningAddress
  );
  // emit when lottery winnings deposited in pending withdrawals
  event LotteryWinningsDeposited(
    uint256 lotteryId,
    address winningAddress,
    uint256 amountDeposited
  );
  // emit when funds withdrawn by winner
  event LogWinnerFundsWithdrawn(
    address winnerAddress,
    uint256 withdrawalAmount
  );
  // emit when owner has changed max player param
  event LogMaxPlayersAllowedUpdated(uint256 maxPlayersAllowed);

  // Errors
  error Lottery__ActiveLotteryExists();
  error Lottery__NotCompleted();
  error Lottery__InadequateFunds();
  error Lottery__InvalidWinningIndex();
  error Lottery__InvalidWithdrawalAmount();
  error Lottery__WithdrawalFailed();

  /* check that new lottery is a valid implementation
    previous lottery must be inactive for new lottery to be saved
    for when new lottery will be saved
    */
  modifier isNewLotteryValid() {
    // active lottery
    LotteryStruct memory lottery = lotteries[currentLotteryId];
    if (lottery.isActive == true) {
      revert Lottery__ActiveLotteryExists();
    }
    _;
  }

  /*
    Checks if there is a lottery draw ongoing so people can't buy tickets
    */
  modifier lockBuy() {
    inLotteryDraw = true;
    _;
    inLotteryDraw = false;
  }

  /* check that period is completed, and lottery drawing can begin
    either:
    1.  period manually ended, ie lottery is inactive. Then drawing can begin immediately.
    2. lottery period has ended organically, and lottery is still active at that point
    */
  modifier isLotteryCompleted() {
    if (
      !((lotteries[currentLotteryId].isActive == true &&
        lotteries[currentLotteryId].endTime < block.timestamp) ||
        lotteries[currentLotteryId].isActive == false)
    ) {
      revert Lottery__NotCompleted();
    }
    _;
  }

  /*
    A function for owner to force update lottery status isActive to false
    public because it needs to be called internally when a Lottery is cancelled
    */
  function setLotteryInactive() public onlyOwner {
    lotteries[currentLotteryId].isActive = false;
  }

  /*
    A function for owner to force update lottery to be cancelled
    funds should be returned to players too
    */
  function cancelLottery() external onlyOwner {
    setLotteryInactive();
    _resetLottery();
    // TASK: implement refund funds to users
  }

  /*
    A function to initialize a lottery
    probably should also be onlyOwner
    uint256 startTime_: start of period, unixtime
    uint256 numHours: in hours, how long period will last
    */
  function initLottery(uint256 startTime_, uint256 numHours_)
    public
    onlyOwner
    isNewLotteryValid
  {
    // basically default value
    // if set to 0, default to explicit default number of days
    if (numHours_ == 0) {
      numHours_ = NUMBER_OF_HOURS_HOURLY;
    }
    uint256 endTime = startTime_ + (numHours_ * 1 hours);
    lotteries[currentLotteryId] = LotteryStruct({
      lotteryId: currentLotteryId,
      startTime: startTime_,
      endTime: endTime,
      isActive: true,
      isCompleted: false,
      isCreated: true
    });
    numLotteries = numLotteries + 1;
    emit LogNewLottery(msg.sender, startTime_, endTime);
  }

  /*
    a function for players to lottery tix
    */
  function buyLotteryTickets(uint256 numberOfTickets, address player) private {
    uint256 _numTickets = numberOfTickets;
    require(_numTickets >= 1);
    // if player is "new" for current lottery, update the player lists

    uint256 _numActivePlayers = numActivePlayers;

    if (players[player] == false) {
      if (listOfPlayers.length > _numActivePlayers) {
        listOfPlayers[_numActivePlayers] = player;
      } else {
        listOfPlayers.push(player); // otherwise append to array
      }
      players[player] = true;
      numActivePlayers = _numActivePlayers + 1;
    }
    tickets[player] = tickets[player] + _numTickets; // account for if user has already tix previously for this current lottery
    numTotalTickets = numTotalTickets + _numTickets; // update the total # of tickets
    emit LogTicketsBought(player, _numTickets);
  }

  /*
    a function for players to lottery tix
    */
  function sellLotteryTickets(uint256 numberOfTickets, address player) private {
    uint256 _numTickets = numberOfTickets;
    require(_numTickets >= 1);
    require(tickets[player] >= _numTickets); // double check that user has enough tix to sell
    // if player is "new" for current lottery, update the player lists

    //  uint _numActivePlayers = numActivePlayers;

    tickets[player] = tickets[player] - _numTickets; // account for if user has already tix previously for this current lottery
    numTotalTickets = numTotalTickets - _numTickets; // update the total # of tickets sell
    emit LogTicketsSold(player, _numTickets);
  }

  /*
    a function for owner to trigger lottery drawing
    */

  event winningticket(uint256 winner1);

  function triggerLotteryDrawing() public onlyOwner isLotteryCompleted {
    // console.log("triggerLotteryDrawing");
    prizes[currentLotteryId] = prizeAmount; // keep track of prize amts for each of the previous lotteries

    _playerTicketDistribution(); // create the distribution to get ticket indexes for each user
    // can't be done a prior bc of potential multiple tix per user
    uint256 winningTicketIndex = _performRandomizedDrawing();
    // uint256 winningTicketIndex2 = _performRandomizedDrawing();
    //     uint256 winningTicketIndex3 = _performRandomizedDrawing();

    // initialize what we can first
    winningTicket.currentLotteryId = currentLotteryId;
    winningTicket.winningTicketIndex = winningTicketIndex;
    // winningTicket2.currentLotteryId = currentLotteryId;
    // winningTicket2.winningTicketIndex = winningTicketIndex2;
    // winningTicket3.currentLotteryId = currentLotteryId;
    // winningTicket3.winningTicketIndex = winningTicketIndex3;
    emit winningticket(winningTicketIndex);
    findWinningAddress(winningTicketIndex); // via binary search
    // TODO: send BNB to winner, emit an event

    emit LogWinnerFound(
      currentLotteryId,
      winningTicket.winningTicketIndex,
      winningTicket.addr
    );

    hodlBonus[winningTicket.addr] = 0;
  }

  /*
    getter function for ticketDistribution bc its a struct
    */
  function getTicketDistribution(uint256 playerIndex_)
    public
    view
    returns (
      address playerAddress,
      uint256 startIndex, // inclusive
      uint256 endIndex // inclusive
    )
  {
    return (
      ticketDistribution[playerIndex_].playerAddress,
      ticketDistribution[playerIndex_].startIndex,
      ticketDistribution[playerIndex_].endIndex
    );
  }

  /*
    function to handle creating the ticket distribution
    if 1) player1 buys 10 tix, then 2) player2 buys 5 tix, and then 3) player1 buys 5 more
    player1's ticket indices will be 0-14; player2's from 15-19
    this is why ticketDistribution cannot be determined until period is closed
    */
  function _playerTicketDistribution() private {
    uint256 _ticketDistributionLength = ticketDistribution.length; // so state var doesn't need to be invoked each iteration of loop

    uint256 _ticketIndex = 0; // counter within loop
    for (uint256 i = _ticketIndex; i < numActivePlayers; i++) {
      address _playerAddress = listOfPlayers[i];
      uint256 _numTickets = tickets[_playerAddress] +
        _calculateHodlBonus(_playerAddress);

      TicketDistributionStruct memory newDistribution = TicketDistributionStruct({
        playerAddress: _playerAddress,
        startIndex: _ticketIndex,
        endIndex: _ticketIndex + _numTickets - 1 // sub 1 to account for array indices starting from 0
      });
      if (_ticketDistributionLength > i) {
        ticketDistribution[i] = newDistribution;
      } else {
        ticketDistribution.push(newDistribution);
      }

      tickets[_playerAddress] = 0; // reset player's tickets to 0 after they've been counted
      _ticketIndex = _ticketIndex + _numTickets;
    }
  }

  /*
    function to generate random winning ticket index. Still need to find corresponding user afterwards.
    */

  function _performRandomizedDrawing() private view returns (uint256) {
    // console.log("_performRandomizedDrawing");
    /* TASK: implement random drawing from 0 to numTotalTickets-1
    use chainlink https://docs.chain.link/docs/get-a-random-number/ to get random values
    */
    return Random.naiveRandInt(0, numTotalTickets - 1);
  }

  /*
    function to find winning player address corresponding to winning ticket index
    calls binary search
    uint256 winningTicketIndex_: ticket index selected as winner.
    Search for this within the ticket distribution to find corresponding Player
    */
  function findWinningAddress(uint256 winningTicketIndex1_) public {
    // console.log("findWinningAddress");
    uint256 _numActivePlayers = numActivePlayers;
    if (_numActivePlayers == 1) {
      winningTicket.addr = ticketDistribution[0].playerAddress;
    } else {
      // do binary search on ticketDistribution array to find winner
      uint256 _winningPlayerIndex = _bSearch(
        0,
        _numActivePlayers - 1,
        winningTicketIndex1_
      );
      if (_winningPlayerIndex >= _numActivePlayers) {
        revert Lottery__InvalidWinningIndex();
      }
      winningTicket.addr = ticketDistribution[_winningPlayerIndex]
        .playerAddress;
    }
  }

  /*
    function implementing binary search on ticket distribution var
    uint256 leftIndex_ initially 0
    uint256 rightIndex_ initially max ind, ie array.length - 1
    uint256 ticketIndexToFind_ to search for
    */

  function _bSearch(
    uint256 leftIndex_,
    uint256 rightIndex_,
    uint256 ticketIndexToFind_
  ) private returns (uint256) {
    uint256 _searchIndex = (rightIndex_ - leftIndex_) / (2) + (leftIndex_);
    uint256 _loopCount = loopCount;
    // counter
    loopCount = _loopCount + 1;
    if (_loopCount + 1 > maxLoops) {
      // emergency stop in case infinite loop due to unforeseen bug
      return numActivePlayers;
    }

    if (
      ticketDistribution[_searchIndex].startIndex <= ticketIndexToFind_ &&
      ticketDistribution[_searchIndex].endIndex >= ticketIndexToFind_
    ) {
      return _searchIndex;
    } else if (
      ticketDistribution[_searchIndex].startIndex > ticketIndexToFind_
    ) {
      // go to left subarray
      rightIndex_ = _searchIndex - (leftIndex_);

      return _bSearch(leftIndex_, rightIndex_, ticketIndexToFind_);
    } else if (ticketDistribution[_searchIndex].endIndex < ticketIndexToFind_) {
      // go to right subarray
      leftIndex_ = _searchIndex + (leftIndex_) + 1;
      return _bSearch(leftIndex_, rightIndex_, ticketIndexToFind_);
    }

    // if nothing found (bug), return an impossible player index
    // this index is outside expected bound, bc indexes run from 0 to numActivePlayers-1
    return numActivePlayers;
  }

  /*
    function to reset lottery by setting state vars to defaults
    */

  function _resetLottery() public {
    // console.log("_resetLottery");

    numTotalTickets = 0;
    numActivePlayers = 0;
    lotteries[currentLotteryId].isActive = false;
    lotteries[currentLotteryId].isCompleted = true;
    winningTicket = WinningTicketStruct({
      currentLotteryId: 0,
      winningTicketIndex: 0,
      addr: address(0)
    });

    // increment id counter
    currentLotteryId = currentLotteryId + (1);
  }

  /*
    function calculate hodl bonus tickets (one per hour)
    */

  function _calculateHodlBonus(address player) public view returns (uint256) {
    uint256 _hodlBonus = 0;
    // uint256 bonusStart =  hodlBonus[player]
    if (hodlBonus[player] > 0) {
      _hodlBonus = (block.timestamp - hodlBonus[player]) / 3600;
    }

    return _hodlBonus;
  }

  struct LotteryStructDaily {
    uint256 lotteryId;
    uint256 startTime;
    uint256 endTime;
    bool isActive;
    bool isCompleted; // winner was found; winnings were deposited.
    bool isCreated; // is created
  }
  struct TicketDistributionStructDaily {
    address playerAddress;
    uint256 startIndex; // inclusive
    uint256 endIndex; // inclusive
  }
  struct WinningTicketStructDaily {
    uint256 currentLotteryId;
    uint256 winningTicketIndex;
    address addr; // TASK: rename to "winningAddress"?
  }

  bool public inLotteryDrawDaily; //used so people can't buy while drawing lottery

  // max # loops allowed for binary search; to prevent some bugs causing infinite loops in binary search
  uint256 public maxLoopsDaily = 10;
  uint256 private loopCountDaily = 0; // for binary search

  uint256 public currentLotteryIdDaily = 0;
  uint256 public numLotteriesDaily = 0;
  uint256 public prizeAmountDaily;

  WinningTicketStructDaily public winningTicketDaily;

  TicketDistributionStructDaily[] public ticketDistributionDaily;

  address[] public listOfPlayersDaily; // Don't rely on this for current participants list

  uint256 public numActivePlayersDaily;
  uint256 public numTotalTicketsDaily;

  // Daily

  mapping(uint256 => uint256) public prizesDaily; // key is lotteryId
  mapping(uint256 => WinningTicketStructDaily) public winningTicketsDaily; // key is lotteryId
  mapping(address => bool) public playersDaily; // key is player address
  mapping(address => uint256) public ticketsDaily; // key is player address
  mapping(uint256 => LotteryStructDaily) public lotteriesDaily; // key is lotteryId
  mapping(uint256 => mapping(address => uint256))
    public pendingWithdrawalsDaily; // pending withdrawals for each winner, key is lotteryId, then player address

  mapping(address => uint256) public hodlBonusDaily;

  // Events
  event LogNewLotteryDaily(address creator, uint256 startTime, uint256 endTime); // emit when lottery created
  event LogTicketsBoughtDaily(address player, uint256 numTickets); // emit when user purchases tix
  event LogTicketsSoldDaily(address player, uint256 numTickets); // emit when user sells tix

  // emit when lottery drawing happens; winner found
  event LogWinnerFoundDaily(
    uint256 lotteryId,
    uint256 winningTicketIndex,
    address winningAddress
  );

  // emit when owner has changed max player param
  event LogMaxPlayersAllowedUpdatedDaily(uint256 maxPlayersAllowed);

  // Errors
  error Lottery__ActiveLotteryExistsDaily();
  error Lottery__NotCompletedDaily();
  error Lottery__InadequateFundsDaily();
  error Lottery__InvalidWinningIndexDaily();
  error Lottery__InvalidWithdrawalAmountDaily();
  error Lottery__WithdrawalFailedDaily();

  /* check that new lottery is a valid implementation
    previous lottery must be inactive for new lottery to be saved
    for when new lottery will be saved
    */
  modifier isNewLotteryValidDaily() {
    // active lottery
    LotteryStructDaily memory lotteryDaily = lotteriesDaily[
      currentLotteryIdDaily
    ];
    if (lotteryDaily.isActive == true) {
      revert Lottery__ActiveLotteryExistsDaily();
    }
    _;
  }

  /* check that round period is completed, and lottery drawing can begin
    either:
    1.  period manually ended, ie lottery is inactive. Then drawing can begin immediately.
    2. lottery  period has ended organically, and lottery is still active at that point
    */
  modifier isLotteryCompletedDaily() {
    if (
      !((lotteriesDaily[currentLotteryIdDaily].isActive == true &&
        lotteriesDaily[currentLotteryIdDaily].endTime < block.timestamp) ||
        lotteriesDaily[currentLotteryIdDaily].isActive == false)
    ) {
      revert Lottery__NotCompletedDaily();
    }
    _;
  }

  /*
    A function for owner to force update lottery status isActive to false
    public because it needs to be called internally when a Lottery is cancelled
    */
  function setLotteryInactiveDaily() public {
    lotteriesDaily[currentLotteryIdDaily].isActive = false;
  }

  /*
    A function for owner to force update lottery to be cancelled
    funds should be returned to players too
    */
  function cancelLotteryDaily() external {
    setLotteryInactiveDaily();
    _resetLotteryDaily();
  }

  /*
    A function to initialize a lottery
    probably should also be onlyOwner
    uint256 startTime_: start of period, unixtime
    uint256 numHours: in hours, how long period will last
    */
  function initLotteryDaily(uint256 startTime_, uint256 numHours_)
    public
    isNewLotteryValidDaily
  {
    // basically default value
    // if set to 0, default to explicit default number of days
    if (numHours_ == 0) {
      numHours_ = NUMBER_OF_HOURS_DAILY;
    }
    uint256 endTime = startTime_ + (numHours_ * 1 hours);
    lotteriesDaily[currentLotteryIdDaily] = LotteryStructDaily({
      lotteryId: currentLotteryIdDaily,
      startTime: startTime_,
      endTime: endTime,
      isActive: true,
      isCompleted: false,
      isCreated: true
    });
    numLotteriesDaily = numLotteriesDaily + 1;
    emit LogNewLotteryDaily(msg.sender, startTime_, endTime);
  }

  /*
    a function for players to lottery tix
    */
  function buyLotteryTicketsDaily(uint256 numberOfTickets, address player)
    private
  {
    uint256 _numTickets = numberOfTickets;
    require(_numTickets >= 1);
    // if player is "new" for current lottery, update the player lists

    uint256 _numActivePlayers = numActivePlayersDaily;

    if (playersDaily[player] == false) {
      if (listOfPlayersDaily.length > _numActivePlayers) {
        listOfPlayersDaily[_numActivePlayers] = player;
      } else {
        listOfPlayersDaily.push(player); // otherwise append to array
      }
      playersDaily[player] = true;
      numActivePlayersDaily = _numActivePlayers + 1;
    }
    ticketsDaily[player] = ticketsDaily[player] + _numTickets; // account for if user has already tix previously for this current lottery
    numTotalTicketsDaily = numTotalTicketsDaily + _numTickets; // update the total # of tickets
    emit LogTicketsBoughtDaily(player, _numTickets);
  }

  /*
    a function for players to sell lottery tix
    */
  function sellLotteryTicketsDaily(uint256 numberOfTickets, address player)
    private
  {
    uint256 _numTickets = numberOfTickets;
    require(_numTickets >= 1);
    require(ticketsDaily[player] >= _numTickets); // double check that user has enough tix
    // if player is "new" for current lottery, update the player lists

    //  uint _numActivePlayers = numActivePlayers;

    ticketsDaily[player] = ticketsDaily[player] - _numTickets; // account for if user has already tix previously for this current lottery
    numTotalTicketsDaily = numTotalTicketsDaily - _numTickets; // update the total # of tickets
    emit LogTicketsSoldDaily(player, _numTickets);
  }

  /*
    a function for owner to trigger lottery drawing
    */

  function triggerLotteryDrawingDaily() public isLotteryCompletedDaily {
    // console.log("triggerLotteryDrawing");
    prizesDaily[currentLotteryIdDaily] = prizeAmountDaily; // keep track of prize amts for each of the previous lotteries

    _playerTicketDistributionDaily(); // create the distribution to get ticket indexes for each user
    // can't be done a prior bc of potential multiple tix per user
    uint256 winningTicketIndexDaily = _performRandomizedDrawingDaily();

    // initialize what we can first
    winningTicketDaily.currentLotteryId = currentLotteryIdDaily;
    winningTicketDaily.winningTicketIndex = winningTicketIndexDaily;

    findWinningAddressDaily(winningTicketIndexDaily); // via binary search
    // TODO: send BNB to winner, emit an event

    emit LogWinnerFoundDaily(
      currentLotteryIdDaily,
      winningTicketDaily.winningTicketIndex,
      winningTicketDaily.addr
    );

    hodlBonusDaily[winningTicketDaily.addr] = 0;
  }

  /*
    getter function for ticketDistribution bc its a struct
    */
  function getTicketDistributionDaily(uint256 playerIndex_)
    public
    view
    returns (
      address playerAddress,
      uint256 startIndex, // inclusive
      uint256 endIndex // inclusive
    )
  {
    return (
      ticketDistributionDaily[playerIndex_].playerAddress,
      ticketDistributionDaily[playerIndex_].startIndex,
      ticketDistributionDaily[playerIndex_].endIndex
    );
  }

  /*
    function to handle creating the ticket distribution
    if 1) player1 buys 10 tix, then 2) player2 buys 5 tix, and then 3) player1 buys 5 more
    player1's ticket indices will be 0-14; player2's from 15-19
    this is why ticketDistribution cannot be determined until period is closed
    */
  function _playerTicketDistributionDaily() private {
    uint256 _ticketDistributionLength = ticketDistributionDaily.length; // so state var doesn't need to be invoked each iteration of loop

    uint256 _ticketIndex = 0; // counter within loop
    for (uint256 i = _ticketIndex; i < numActivePlayersDaily; i++) {
      address _playerAddress = listOfPlayersDaily[i];
      uint256 _numTickets = ticketsDaily[_playerAddress] +
        _calculateHodlBonusDaily(_playerAddress);

      TicketDistributionStructDaily memory newDistributionDaily = TicketDistributionStructDaily({
        playerAddress: _playerAddress,
        startIndex: _ticketIndex,
        endIndex: _ticketIndex + _numTickets - 1 // sub 1 to account for array indices starting from 0
      });
      if (_ticketDistributionLength > i) {
        ticketDistributionDaily[i] = newDistributionDaily;
      } else {
        ticketDistributionDaily.push(newDistributionDaily);
      }

      ticketsDaily[_playerAddress] = 0; // reset player's tickets to 0 after they've been counted
      _ticketIndex = _ticketIndex + _numTickets;
    }
  }

  /*
    function to generate random winning ticket index. Still need to find corresponding user afterwards.
    */

  function _performRandomizedDrawingDaily() private view returns (uint256) {
    // console.log("_performRandomizedDrawing");
    /* TASK: implement random drawing from 0 to numTotalTickets-1
    use chainlink https://docs.chain.link/docs/get-a-random-number/ to get random values
    */
    return Random.naiveRandInt(0, numTotalTicketsDaily - 1);
  }

  /*
    function to find winning player address corresponding to winning ticket index
    calls binary search
    uint256 winningTicketIndex_: ticket index selected as winner.
    Search for this within the ticket distribution to find corresponding Player
    */
  function findWinningAddressDaily(uint256 winningTicketIndex1_) public {
    // console.log("findWinningAddress");
    uint256 _numActivePlayers = numActivePlayersDaily;
    if (_numActivePlayers == 1) {
      winningTicketDaily.addr = ticketDistributionDaily[0].playerAddress;
    } else {
      // do binary search on ticketDistribution array to find winner
      uint256 _winningPlayerIndex = _bSearchDaily(
        0,
        _numActivePlayers - 1,
        winningTicketIndex1_
      );
      if (_winningPlayerIndex >= _numActivePlayers) {
        revert Lottery__InvalidWinningIndexDaily();
      }
      winningTicketDaily.addr = ticketDistributionDaily[_winningPlayerIndex]
        .playerAddress;
    }
  }

  /*
    function implementing binary search on ticket distribution var
    uint256 leftIndex_ initially 0
    uint256 rightIndex_ initially max ind, ie array.length - 1
    uint256 ticketIndexToFind_ to search for
    */

  function _bSearchDaily(
    uint256 leftIndex_,
    uint256 rightIndex_,
    uint256 ticketIndexToFind_
  ) private returns (uint256) {
    uint256 _searchIndex = (rightIndex_ - leftIndex_) / (2) + (leftIndex_);
    uint256 _loopCount = loopCountDaily;
    // counter
    loopCountDaily = _loopCount + 1;
    if (_loopCount + 1 > maxLoopsDaily) {
      // emergency stop in case infinite loop due to unforeseen bug
      return numActivePlayersDaily;
    }

    if (
      ticketDistributionDaily[_searchIndex].startIndex <= ticketIndexToFind_ &&
      ticketDistributionDaily[_searchIndex].endIndex >= ticketIndexToFind_
    ) {
      return _searchIndex;
    } else if (
      ticketDistributionDaily[_searchIndex].startIndex > ticketIndexToFind_
    ) {
      // go to left subarray
      rightIndex_ = _searchIndex - (leftIndex_);

      return _bSearchDaily(leftIndex_, rightIndex_, ticketIndexToFind_);
    } else if (
      ticketDistributionDaily[_searchIndex].endIndex < ticketIndexToFind_
    ) {
      // go to right subarray
      leftIndex_ = _searchIndex + (leftIndex_) + 1;
      return _bSearchDaily(leftIndex_, rightIndex_, ticketIndexToFind_);
    }

    // if nothing found (bug), return an impossible player index
    // this index is outside expected bound, bc indexes run from 0 to numActivePlayers-1
    return numActivePlayersDaily;
  }

  /*
    function to reset lottery by setting state vars to defaults
    */

  function _resetLotteryDaily() public {
    // console.log("_resetLottery");

    numTotalTicketsDaily = 0;
    numActivePlayersDaily = 0;
    lotteriesDaily[currentLotteryIdDaily].isActive = false;
    lotteriesDaily[currentLotteryIdDaily].isCompleted = true;
    winningTicketDaily = WinningTicketStructDaily({
      currentLotteryId: 0,
      winningTicketIndex: 0,
      addr: address(0)
    });

    // increment id counter
    currentLotteryIdDaily = currentLotteryIdDaily + (1);
  }

  /*
    function calculate hodl bonus tickets (one per hour)
    */

  function _calculateHodlBonusDaily(address player)
    public
    view
    returns (uint256)
  {
    uint256 _hodlBonus = 0;
    // uint256 bonusStart =  hodlBonus[player]
    if (hodlBonusDaily[player] > 0) {
      _hodlBonus = (block.timestamp - hodlBonusDaily[player]) / 86400;
    }

    return _hodlBonus;
  }
}
