# Altcoin Generator
Easiest way to create your own cryptocurrency.

## What does this script do?

This script is an experiment to generate new cryptocurrencies (altcoins) based on litecoin.
It will help you creating a git repository with minimal required changes to start your new coin and blockchain.

## What do I have to do?

You need to make sure you have git installed in any Linux distribution or MacOS.
If you are using MacOS, then you also need to install gnu-sed using 'brew install gnu-sed'

The other requirements will be installed automatically in a docker container by the script.

Simply open the script and edit the first variables to match your coin requirements (total supply, coin unit, coin name, tcp ports..)
Then simply run the script like this:

```
bash altcoin_generator.sh clone
bash altcoin_generator.sh fork
```

To see all possible options run the script like this:

```
bash altcoin_generator.sh
```

## What will happen then?

The script will perform a couple of actions:

  * Clone GenesisH0 and mine the genesis blocks of main, test and regtest networks in the container (this might take a lot of time)
  * Clone litecoin
  * Rename files and replace variables in litecoin code (genesis hashes, merkle tree hashes, tcp ports, coin name, supply...)
  * The GENESIS_REWARD_PUBKEY will be used in the UTXO of the genesis block. If you don't change it to your own before mining the genesis block you are agreeing to pay me the genesis block reward in case your coin succeeds (Thanks! :p)
  
## What can I do next?

You can first check if your nodes are running and then ask them to generate some blocks.
Instructions on how to do it will be printed once the script execution is done.

## Is there anything I must be aware of?

Yes.

  * This is a very simple script to help you bootstrap. More changes will be needed to launch a cryptocurrency for real.
  * You have to manually change the pictures in mycoin/share/pixmaps.
  * You will need change the checkpoints in mycoin/src/chainparams.cpp.
  * Consider adding a seed node and add it to src/chainparams.cpp as well.
    * Currently all seeds are getting disabled.
  * The script connects to the regression test network by default. This is a special network that will let you mine new blocks almost instantly (nice for testing). To launch the nodes in the main network, simply leave the CHAIN variable empty.
  
## I think something went wrong!

Then you can clean up the mess with:

```
bash altcoin_generator.sh clean
```
