// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Mortgage {
    address payable public homeownerAddress;
    address payable public mortgageHolder;
    uint256 public loanAmount;
    uint256 public monthlyPayment;
    uint256 public remainingBalance;
    bool public loanApproved;
    uint256 public totalMortgages;
    uint256 public requiredMonthlyIncome; // Required monthly income for loan approval

    event LoanRequested(uint256 loanAmount, uint256 monthlyPayment, address indexed homeowner);
    event LoanApproved(uint256 loanAmount, uint256 monthlyPayment);
    event LoanDeclined(uint256 loanAmount, address indexed homeowner);
    event PaymentReceived(uint256 amount);
    event LateFeeApplied(uint256 lateFee);

    constructor(uint256 _requiredMonthlyIncome) {
        mortgageHolder = payable(msg.sender);
        requiredMonthlyIncome = _requiredMonthlyIncome;
    }

    modifier onlyMortgageHolder() {
        require(msg.sender == mortgageHolder, "Only the mortgage holder can call this function");
        _;
    }

    function getHomeowner() public view returns (address payable) {
        return homeownerAddress;
    }

    function submitLoan(uint256 _loanAmount, uint256 _monthlyPayment, address payable _homeowner, uint256 _interestRate) external onlyMortgageHolder {
        require(getMonthlyIncome(_homeowner) >= requiredMonthlyIncome, "Insufficient monthly income for loan approval");

        // Calculate total loan amount with interest
        loanAmount = _loanAmount + (_loanAmount * _interestRate / 100);

        monthlyPayment = _monthlyPayment;
        homeownerAddress = _homeowner;
        remainingBalance = loanAmount;
        loanApproved = true; // Loan automatically approved if monthly income requirement is met
        totalMortgages++; // Increment total mortgages when a new loan is submitted
        emit LoanRequested(loanAmount, monthlyPayment, homeownerAddress);
        emit LoanApproved(loanAmount, monthlyPayment);
    }

    function declineLoan() external onlyMortgageHolder {
        require(!loanApproved, "Loan is already approved");
        loanApproved = false;
        emit LoanDeclined(loanAmount, homeownerAddress);
    }

    function makePayment() external payable onlyMortgageHolder {
        require(loanApproved, "Loan not approved");
        require(remainingBalance > 0, "Loan fully paid off");
        require(msg.value == monthlyPayment, "Incorrect payment amount");

        if (msg.value >= remainingBalance) {
            remainingBalance = 0;
            loanApproved = false;
        } else {
            remainingBalance -= msg.value;
        }

        // Check for late payment and apply late fee
        if (block.timestamp > (block.timestamp + 30 days)) {
            uint256 lateFee = monthlyPayment / 10; // 10% late fee
            payable(msg.sender).transfer(lateFee);
            emit LateFeeApplied(lateFee);
        }

        emit PaymentReceived(msg.value);
    }

    function withdrawRemainingBalance() external onlyMortgageHolder {
        require(!loanApproved, "Loan not fully paid off yet");
        mortgageHolder.transfer(address(this).balance);
    }

    // Function to retrieve the total number of mortgages
    function getTotalMortgages() external view returns (uint256) {
        return totalMortgages;
    }

    // Function to calculate monthly income (example implementation)
    function getMonthlyIncome(address _account) public view returns (uint256) {
        // Example implementation: You can replace this with your own logic to calculate monthly income
        // Here, we'll return a random value for demonstration purposes
        return uint256(keccak256(abi.encodePacked(block.timestamp, _account))) % 10000; // Random value up to 10000
    }
}