# PaymentTimelockedVault

A secure vault that locks ETH until a future timestamp.  
Only the assigned **beneficiary** can withdraw, and only **after the unlock time**.  
Uses **Pull Payment pattern**, making it safer and more gas-efficient compared to push-based transfers.

---

## 🎯 Key Features

| Feature | Description |
|---------|-------------|
| Timelock | Funds cannot be withdrawn before unlock time |
| Pull Payment Pattern | Beneficiary must manually withdraw, preventing failed transfers or attacks |
| Deposit Flexibility | Anyone can deposit ETH on behalf of the beneficiary |
| Immutable Variables | Saves gas, improves security |
| Custom Errors | Cheaper than require strings |

---

## 🔐 Contract Flow

1️⃣ Contract deployed with:
- Beneficiary address  
- Unlock timestamp  

2️⃣ Anyone can send ETH using `deposit()`

3️⃣ After time passes, beneficiary calls `withdraw()`

---

## 🧠 Why Pull Payment?
| Push Payment ❌ | Pull Payment ✔ |
|----------------|----------------|
| Contract sends funds automatically | Receiver actively withdraws |
| High reentrancy risk | Safer withdrawal control |
| Failed transfers possible | Guaranteed withdrawal execution |
| More gas | More secure & gas-efficient |

---

## 📜 Functions

| Function | Type | Description |
|----------|------|-------------|
| deposit() | Payable | Lock ETH inside vault |
| withdraw() | External | Beneficiary withdraws unlocked ETH |
| timeLeft() | View | Seconds remaining until unlock |
| contractBalance() | View | Current ETH stored |

---

## 🧪 Possible Use Cases
- DAOs vesting funds for contributors  
- Lottery prize lockups  
- Timelocked donation vaults  
- Employee token/payment vesting  

---

## 🚀 Future Improvements
- Add ERC20 support  
- Multiple beneficiaries  
- Scheduled release streams (like Sablier-style vesting)  
- Automatic partial withdrawal support  

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

---

🛠 Day 8 of my 30-Day Solidity Challenge