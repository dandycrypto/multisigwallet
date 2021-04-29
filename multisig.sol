pragma solidity 0.7.5;
pragma abicoder v2; 

contract MultisigWallet {
    
  address[3] private multisig; 
  address owner;
  uint balance; 
  uint pendingbalance; 

  
    constructor ( address _multisig1, address _multisig2, address _multisig3)  {
        
        owner = msg.sender; 
        require(_multisig1 != _multisig2 && _multisig1 != _multisig3 && _multisig2 != _multisig3, "Cannot use the same address");
        
        multisig=[_multisig1, _multisig2, _multisig3];
        balance = 0; 
        pendingbalance = 0; 
     }
     
       modifier OnlyAuthorized() {
        require(msg.sender == multisig[0] || msg.sender== multisig[1] || msg.sender ==multisig[2]); 
        _;
    }
    
    modifier OnlyOwner() {
        require(msg.sender == owner, "Only contract's owner can change the multisig account"); 
        _;
    }
     
     function changeMultisig (uint _index, address _multisigAdd) public OnlyOwner {
         multisig[_index] = _multisigAdd; 
     }
  
     function getMultisig () public view returns (address, address, address) {
         return (multisig[0], multisig[1],multisig[2]);
     }
  
    struct Transaction { 
        address payable toAdd;
        uint confirmation;
        address initAdd; 
        uint amount; 
        bool paid; 
    }
    
    Transaction[] private transfer;
        

    
    function getBalance() public view returns (uint, uint) { 
    
        return (balance, pendingbalance); 
        
    }
    
    
    function deposit(uint _amount) public payable returns (uint) {
        require(msg.sender.balance > _amount);
        msg.sender.transfer(_amount);
        balance += _amount; 
        return (balance); 
    }
    
    
    function inittransfer(address payable _toAdd, uint _amount) public OnlyAuthorized returns (uint) {
        
        require((balance-pendingbalance) >= _amount);
        require(_toAdd != multisig[0] &&_toAdd != multisig[1] && _toAdd != multisig[2] );
        Transaction  memory initTransf; 
        initTransf.toAdd = _toAdd; 
        initTransf.confirmation += 1; 
        initTransf.initAdd = msg.sender; 
        initTransf.amount = _amount; 
        initTransf.paid = false; 
        
        transfer.push(initTransf);
        pendingbalance  +=_amount;
        return (balance-pendingbalance); 
    }
    
    function checkpending(uint _index) public OnlyAuthorized view returns (address, address, uint, uint, bool) {
        return (transfer[_index].initAdd, transfer[_index].toAdd,transfer[_index].confirmation,transfer[_index].amount, transfer[_index].paid);
    }
    
    
    function confirmtransfer(uint _index) public OnlyAuthorized returns (address, uint){
        
        require(msg.sender != transfer[_index].initAdd , "Cannot be confirmed by initiator");
        require(transfer[_index].paid != true, "transfer was already approved  by another person");
        transfer[_index].confirmation +=1; 
        if (transfer[_index].confirmation >= 2 && transfer[_index].paid == false)
            executetransfer(_index);
            return (transfer[_index].toAdd, transfer[_index].amount);
    }
    
    function executetransfer (uint _index)  private  {
        
        balance -= transfer[_index].amount; 
        transfer[_index].toAdd.transfer(transfer[_index].amount);
        transfer[_index].paid = true; 
        pendingbalance -=transfer[_index].amount;
    }
    
}
