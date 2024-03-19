# CaffeineHeadBlockchainCoffee

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

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
1. Anvil

#start a new terminal window in the same directory 
2. source .env

3. $ forge script script/deployCaffeineHeadBlockchainCoffee.s.sol --rpc-url $ANVIL_RPC_URL --private-key $PRIVATE_KEY_ANVIL --broadcast
```
