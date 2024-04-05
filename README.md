# CaffeineHeadBlockchainCoffee

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test 
```
<!-- Use --via-ir if test throws stack too deep error -->
### Test a specific function
```shell
$ forge test --match-test <name_of_test>

#Example
forge test --match-test test_storeProduct
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

### Deploy to Anvil
```shell
#initialize anvil
1. $ Anvil

#start a new terminal window in the same directory 
Set up .env with ANVIL_RPC_URL, PRIVATE_KEY_ANVIL and DEFAULT_ANVIL_KEY

2. $ source .env

3. $ forge script script/deployCaffeineHeadBlockchainCoffee.s.sol --rpc-url $ANVIL_RPC_URL --private-key $PRIVATE_KEY_ANVIL --broadcast --via-ir

2. SEPOLIA TestNet
Set up .env with PRIVATE_KEY and SEPOLIA_RPC_URL.

1. $ source .env

2. forge script script/deployCaffeineHeadBlockchainCoffee.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --via-ir
```
