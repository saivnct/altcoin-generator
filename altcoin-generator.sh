#!/bin/bash -e
# This script is an experiment to clone litecoin into a 
# brand new coin + blockchain.
# The script will perform the following steps:
# 1) mine the genesis blocks of main, test and regtest networks in the container (this may take a lot of time)
# 2) clone litecoin
# 3) replace variables (keys, merkle tree hashes, timestamps..)
# 4) build new coin
# 
# By default the script uses the regtest network, which can mine blocks
# instantly. If you wish to switch to the main network, simply change the 
# CHAIN variable below

# change the following variables to match your new coin
COIN_NAME="SaiCoin"
COIN_UNIT="SVC"
COIN_PUB_KEY="02f4da04b8300816ef0aba9b81e7994391f95ad262296e3451f820a2c705426c2c3bd7509e04330a9d55382d26b705853f4c3a9fbdb4ad99959bc8b7db02a4be4d"
COIN_REWARD=5000
COIN_HALVING_INTERVAL=788400
COIN_BLOCK_INTERVAL="2 \* 60"
COIN_TARGET_TIME_SPAN="2 \* 24 \* 60 \* 60; // 2 days"

MAIN_TIMESTAMP=1627306705
MAIN_NONCE=0

TEST_TIMESTAMP=1627306713
TEST_NONCE=0

REGTEST_TIMESTAMP=1627306713
REGTEST_NONCE=0

PHRASE="08/08/2021 G88 studio, Welcome to new currency"
# 42 million coins at total (litecoin total supply is 84000000)
TOTAL_SUPPLY=10000000000
# this is the amount of coins to get as a reward of mining the block of height 1. if not set this will default to 50
# PREMINED_AMOUNT=10000000

MAINNET_SEED_ADDR=192.168.31.163
TESTNET_SEED_ADDR=192.168.31.163

MAINNET_PORT="6333"
TESTNET_PORT="16335"
REGTEST_PORT="16444"

MAINNET_RPC_PORT="6332"
TESTNET_RPC_PORT="16332"
REGTEST_RPC_PORT="16443"

MAINNET_MSGSTART_0="0xa2"
MAINNET_MSGSTART_1="0xe8"
MAINNET_MSGSTART_2="0x88"
MAINNET_MSGSTART_3="0xd2"

TESTNET_MSGSTART_0="0xc7"
TESTNET_MSGSTART_1="0xc8"
TESTNET_MSGSTART_2="0x8a"
TESTNET_MSGSTART_3="0xab"

# First letter of the wallet address. Check https://en.bitcoin.it/wiki/Base58Check_encoding
# 43 -> 0x2B
MAINNET_PUBKEY_CHAR="43"
# number of blocks to wait to be able to spend coinbase UTXO's
COINBASE_MATURITY=100
# leave CHAIN empty for main network, -regtest for regression network and -testnet for test network
CHAIN="-regtest"


# dont change the following variables unless you know what you are doing
LITECOIN_BRANCH=0.18
LITECOIN_REPOS=https://github.com/litecoin-project/litecoin.git

LITECOIN_PUB_KEY=040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9
LITECOIN_HALVING_INTERVAL=840000
LITECOIN_BLOCK_INTERVAL="2.5 \* 60"
LITECOIN_POW_TARGET_TIME_SPAN="3.5 \* 24 \* 60 \* 60; // 3.5 days"
LITECOIN_MERKLE_HASH=97ddfbbae6be97fd6cdf3e7ca13232a3afff2353e29badfab7f73011edd4ced9
LITECOIN_MAIN_GENESIS_HASH=12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2
LITECOIN_TEST_GENESIS_HASH=4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0
LITECOIN_REGTEST_GENESIS_HASH=530827f38f93b43ed12af0b3ad25a288dc02ed74d6d7857862df51fc56c416f9
COIN_NAME_LOWER=$(echo $COIN_NAME | tr '[:upper:]' '[:lower:]')
COIN_NAME_UPPER=$(echo $COIN_NAME | tr '[:lower:]' '[:upper:]')
COIN_UNIT_LOWER=$(echo $COIN_UNIT | tr '[:upper:]' '[:lower:]')
DIRNAME=$(dirname $0)
OSVERSION="$(uname -s)"

generate_genesis_block()
{
    __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

     if [ ! -f ${COIN_NAME}-main.txt ]; then
        echo "Mining genesis block of MAIN NET... this procedure can take many hours of cpu work.."
        ${__dir}/generate-genesis -algo scrypt -bits 1e0ffff0 -coins ${COIN_REWARD}00000000 -nonce $MAIN_NONCE -timestamp $MAIN_TIMESTAMP -pubkey $COIN_PUB_KEY -psz "$PHRASE" > ${COIN_NAME}-main.txt
    else
        echo "Genesis block MAIN NET already mined.."
    fi

    if [ ! -f ${COIN_NAME}-test.txt ]; then
        echo "Mining genesis block of TEST NET... this procedure can take many hours of cpu work.."
        ${__dir}/generate-genesis -algo scrypt -bits 1e0ffff0 -coins ${COIN_REWARD}00000000 -nonce $TEST_NONCE -timestamp $TEST_TIMESTAMP -pubkey $COIN_PUB_KEY -psz "$PHRASE" > ${COIN_NAME}-test.txt
    else
        echo "Genesis block TEST NET already mined.."
    fi

    if [ ! -f ${COIN_NAME}-regtest.txt ]; then
        echo "Mining genesis block of REG NET... this procedure can take many hours of cpu work.."
        ${__dir}/generate-genesis -algo scrypt -bits 207fffff -coins ${COIN_REWARD}00000000 -nonce $REGTEST_NONCE -timestamp $REGTEST_TIMESTAMP -pubkey $COIN_PUB_KEY -psz "$PHRASE" > ${COIN_NAME}-regtest.txt
    else
        echo "Genesis block REGTEST NET already mined.."
    fi


    MERKLE_HASH=$(cat ${COIN_NAME}-main.txt | grep "^Mkl Hash:" | $SED 's/^Mkl Hash:	0x//')

    MAIN_TIMESTAMP=$(cat ${COIN_NAME}-main.txt | grep "^Timestamp:" | $SED 's/^Timestamp:	//')
    TEST_TIMESTAMP=$(cat ${COIN_NAME}-test.txt | grep "^Timestamp:" | $SED 's/^Timestamp:	//')
    REGTEST_TIMESTAMP=$(cat ${COIN_NAME}-regtest.txt | grep "^Timestamp:" | $SED 's/^Timestamp:	//')   

    MAIN_NONCE=$(cat ${COIN_NAME}-main.txt | grep "^Nonce:" | $SED 's/^Nonce:	//')
    TEST_NONCE=$(cat ${COIN_NAME}-test.txt | grep "^Nonce:" | $SED 's/^Nonce:	//')
    REGTEST_NONCE=$(cat ${COIN_NAME}-regtest.txt | grep "^Nonce:" | $SED 's/^Nonce:	//')

    MAIN_GENESIS_HASH=$(cat ${COIN_NAME}-main.txt | grep "^Blk Hash:" | $SED 's/^Blk Hash:	0x//')
    TEST_GENESIS_HASH=$(cat ${COIN_NAME}-test.txt | grep "^Blk Hash:" | $SED 's/^Blk Hash:	0x//')
    REGTEST_GENESIS_HASH=$(cat ${COIN_NAME}-regtest.txt | grep "^Blk Hash:" | $SED 's/^Blk Hash:	0x//')
    
    echo MERKLE_HASH: $MERKLE_HASH
    echo ---------------------------------
    echo MAIN_TIMESTAMP: $MAIN_TIMESTAMP
    echo MAIN_NONCE: $MAIN_NONCE
    echo MAIN_GENESIS_HASH: $MAIN_GENESIS_HASH
    
    echo ---------------------------------
    echo TEST_TIMESTAMP: $TEST_TIMESTAMP
    echo TEST_NONCE: $TEST_NONCE
    echo TEST_GENESIS_HASH: $TEST_GENESIS_HASH

    echo ---------------------------------
    echo REGTEST_TIMESTAMP: $REGTEST_TIMESTAMP
    echo REGTEST_NONCE: $REGTEST_NONCE
    echo REGTEST_GENESIS_HASH: $REGTEST_GENESIS_HASH
}

newcoin_clone_replace_brand()
{
    if [ -d $COIN_NAME_LOWER ]; then
        echo "Warning: $COIN_NAME_LOWER already existing. Not replacing any values"
        return 0
    fi
    if [ ! -d "litecoin-master" ]; then
        # clone litecoin and keep local cache
        git clone -b $LITECOIN_BRANCH $LITECOIN_REPOS litecoin-master
    else
        echo "Updating master branch"
        pushd litecoin-master
        git pull
        popd
    fi

    git clone -b $LITECOIN_BRANCH litecoin-master $COIN_NAME_LOWER

    pushd $COIN_NAME_LOWER

    # first rename all directories
    for i in $(find . -type d | grep -v "^./.git" | grep litecoin); do 
        git mv $i $(echo $i| $SED "s/litecoin/$COIN_NAME_LOWER/")
    done

    # then rename all files
    for i in $(find . -type f | grep -v "^./.git" | grep litecoin); do
        git mv $i $(echo $i| $SED "s/litecoin/$COIN_NAME_LOWER/")
    done

    for i in $(find . -not -path "./.git/*" -type f); do
        $SED -i "s/Litecoin/$COIN_NAME/g" $i
        $SED -i "s/litecoin/$COIN_NAME_LOWER/g" $i
        $SED -i "s/LITECOIN/$COIN_NAME_UPPER/g" $i
        $SED -i "s/LTC/$COIN_UNIT/g" $i
    done

    popd
}

newcoin_replace_vars()
{
    pushd $COIN_NAME_LOWER

    $SED -i "s/84000000/$TOTAL_SUPPLY/" src/amount.h

    $SED -i "s/static const CAmount COIN = 100000000;/static const CAmount COIN = 100000000;\nstatic const CAmount INITIAL_BLOCK_REWARD = $COIN_REWARD;/" src/amount.h
    if [ -n "$PREMINED_AMOUNT" ]; then
        
        $SED -i "s/static const CAmount COIN = 100000000;/static const CAmount COIN = 100000000;\nstatic const CAmount INITIAL_COIN_PREMINE = $PREMINED_AMOUNT;/" src/amount.h

        $SED -i "s/CAmount nSubsidy = 50 \* COIN;/if \(nHeight == 1\) return INITIAL_COIN_PREMINE \* COIN;\n    CAmount nSubsidy = INITIAL_BLOCK_REWARD \* COIN;/" src/validation.cpp
    else
        $SED -i "s/CAmount nSubsidy = 50 \* COIN;/CAmount nSubsidy = INITIAL_BLOCK_REWARD \* COIN;/" src/validation.cpp
    fi

    

    $SED -i "s/lites/m$COIN_UNIT/g" src/qt/bitcoinunits.cpp
    $SED -i "s/photons/u$COIN_UNIT/g" src/qt/bitcoinunits.cpp
    $SED -i "s/litoshi/a$COIN_UNIT/g" src/qt/bitcoinunits.cpp

    $SED -i "s/Lite/Milli-$COIN_NAME/g" src/qt/bitcoinunits.cpp
    $SED -i "s/Photon/Micro-$COIN_NAME/g" src/qt/bitcoinunits.cpp
    $SED -i "s/Litoshi/Atom-$COIN_NAME/g" src/qt/bitcoinunits.cpp

    $SED -i "s;NY Times 05/Oct/2011 Steve Jobs, Apple’s Visionary, Dies at 56;$PHRASE;" src/chainparams.cpp
    $SED -i "s/$LITECOIN_PUB_KEY/$COIN_PUB_KEY/" src/chainparams.cpp

    $SED -i "s/$LITECOIN_HALVING_INTERVAL/$COIN_HALVING_INTERVAL/" src/chainparams.cpp
    $SED -i "s/$LITECOIN_BLOCK_INTERVAL/$COIN_BLOCK_INTERVAL/" src/chainparams.cpp
    $SED -i "s,$LITECOIN_POW_TARGET_TIME_SPAN,$COIN_TARGET_TIME_SPAN,g" src/chainparams.cpp

    $SED -i "s/$LITECOIN_MERKLE_HASH/$MERKLE_HASH/" src/qt/test/rpcnestedtests.cpp
    $SED -i "s/$LITECOIN_MERKLE_HASH/$MERKLE_HASH/" src/chainparams.cpp
    
    $SED -i "s/50 \* COIN/INITIAL_BLOCK_REWARD \* COIN/" src/chainparams.cpp

    $SED -i "s/= 0xfb;/= $MAINNET_MSGSTART_0;/" src/chainparams.cpp
    $SED -i "s/= 0xc0;/= $MAINNET_MSGSTART_1;/" src/chainparams.cpp
    $SED -i "s/= 0xb6;/= $MAINNET_MSGSTART_2;/" src/chainparams.cpp
    $SED -i "s/= 0xdb;/= $MAINNET_MSGSTART_3;/" src/chainparams.cpp
    $SED -i "s/= 9333;/= $MAINNET_PORT;/" src/chainparams.cpp
    $SED -i "s/1,48/1,$MAINNET_PUBKEY_CHAR/" src/chainparams.cpp

    $SED -i "s/1317972665/$MAIN_TIMESTAMP/" src/chainparams.cpp
    $SED -i "0,/2084524493/s//$MAIN_NONCE/" src/chainparams.cpp
    $SED -i "0,/$LITECOIN_MAIN_GENESIS_HASH/s//$MAIN_GENESIS_HASH/" src/chainparams.cpp
    $SED -i "s/1565379143/$MAIN_TIMESTAMP/" src/chainparams.cpp
    $SED -i "s/36299075/0/" src/chainparams.cpp
    

    $SED -i "s/= 0xfd;/= $TESTNET_MSGSTART_0;/" src/chainparams.cpp
    $SED -i "s/= 0xd2;/= $TESTNET_MSGSTART_1;/" src/chainparams.cpp
    $SED -i "s/= 0xc8;/= $TESTNET_MSGSTART_2;/" src/chainparams.cpp
    $SED -i "s/= 0xf1;/= $TESTNET_MSGSTART_3;/" src/chainparams.cpp
    $SED -i "s/= 19335;/= $TESTNET_PORT;/" src/chainparams.cpp
    $SED -i "s/1486949366/$TEST_TIMESTAMP/" src/chainparams.cpp
    $SED -i "0,/293345/s//$TEST_NONCE/" src/chainparams.cpp
    $SED -i "0,/$LITECOIN_TEST_GENESIS_HASH/s//$TEST_GENESIS_HASH/" src/chainparams.cpp
    $SED -i "s/1565582448/$TEST_TIMESTAMP/" src/chainparams.cpp
    $SED -i "s/2848910/0/" src/chainparams.cpp


    $SED -i "s/= 19444;/= $REGTEST_PORT;/" src/chainparams.cpp
    $SED -i "s/1296688602, 0/$REGTEST_TIMESTAMP, $REGTEST_NONCE/" src/chainparams.cpp
    $SED -i "0,/$LITECOIN_REGTEST_GENESIS_HASH/s//$REGTEST_GENESIS_HASH/" src/chainparams.cpp
    
    
    ################
    # change bip activation heights
    # bip 16
    $SED -i "s,= 218579; // 87afb798a3ad9378fcd56123c81fb31cfd9a8df4719b9774d71730c16315a092 - October 1\\, 2012,= 0;,g" src/chainparams.cpp
    # bip 34
    $SED -i "s,= 710000;,= 0;,g" src/chainparams.cpp
    $SED -i "s,fa09d204a83a768ed5a7c8d441fa62f2043abf420cff1226c7b4329aeb9d51cf,$MAIN_GENESIS_HASH,g" src/chainparams.cpp
    # bip 65
    $SED -i "s,= 918684; // bab3041e8977e0dc3eeff63fe707b92bde1dd449d8efafb248c27c8264cc311a,= 0;,g" src/chainparams.cpp
    # bip 66
    $SED -i "s,= 811879; // 7aceee012833fa8952f8835d8b1b3ae233cd6ab08fdb27a771d2bd7bdc491894,= 0;,g" src/chainparams.cpp

    # TEST-NET bip 16,34,65,66
    $SED -i "s,= 76; // 8075c771ed8b495ffd943980a95f702ab34fce3c8c54e379548bda33cc8c0573,= 0;,g" src/chainparams.cpp
    $SED -i "s,= 76;,= 0;,g" src/chainparams.cpp
    $SED -i "s,8075c771ed8b495ffd943980a95f702ab34fce3c8c54e379548bda33cc8c0573,$TEST_GENESIS_HASH,g" src/chainparams.cpp
    ################

    # testdummy
    # $SED -i "s/1199145601/Consensus::BIP9Deployment::ALWAYS_ACTIVE/g" src/chainparams.cpp
    # $SED -i "s/1230767999/Consensus::BIP9Deployment::NO_TIMEOUT/g" src/chainparams.cpp

    # csv, segwit
    $SED -i "s,= 1485561600; // January 28\\, 2017,= Consensus::BIP9Deployment::ALWAYS_ACTIVE;,g" src/chainparams.cpp
    $SED -i "s,= 1483228800; // January 1\\, 2017,= Consensus::BIP9Deployment::ALWAYS_ACTIVE;,g" src/chainparams.cpp

    # timeout of segwit is the same as csv
    $SED -i "s,= 1517356801; // January 31st\\, 2018,= Consensus::BIP9Deployment::NO_TIMEOUT;,g" src/chainparams.cpp
    
    # defaultAssumeValid
    $SED -i "s/0xb34a457c601ef8ce3294116e3296078797be7ded1b0d12515395db9ab5e93ab8/0x$MAIN_GENESIS_HASH/" src/chainparams.cpp
    $SED -i "s/0xf19dfbdc0e6c399ef45d315d89fc3e972dd8da74503252bacaf664f64d86e6f6/0x$TEST_GENESIS_HASH/" src/chainparams.cpp

    # reset minimum chain work to 0
    $SED -i "s/0x0000000000000000000000000000000000000000000002ee655bf00bf13b4cca/0x00/" src/chainparams.cpp
    $SED -i "s/0x0000000000000000000000000000000000000000000000000035ed7ece35dc93/0x00/" src/chainparams.cpp


    $SED -i "s,vSeeds.emplace_back,//vSeeds.emplace_back,g" src/chainparams.cpp
    if [ -n "$MAINNET_SEED_ADDR" ]; then
        $SED -i "s,//vSeeds.emplace_back(\"dnsseed.thrasher.io\"),vSeeds.emplace_back(\"$MAINNET_SEED_ADDR\"),g" src/chainparams.cpp
    fi

    if [ -n "$TESTNET_SEED_ADDR" ]; then
        $SED -i "s,//vSeeds.emplace_back(\"dnsseed-testnet.thrasher.io\"),vSeeds.emplace_back(\"$MAINNET_SEED_ADDR\"),g" src/chainparams.cpp
    fi

    

    ################
    #checkpoints MAIN NET
    $SED -i "s,{  1500, {  0,g" src/chainparams.cpp
    $SED -i "s/0x841a2965955dd288cfa707a755d05a54e45f8bd476835ec9af4402a2b59a2967/0x$MAIN_GENESIS_HASH/" src/chainparams.cpp
    $SED -i "s,{  4032, //{  4032,g" src/chainparams.cpp
    $SED -i "s,{  8064, //{  8064,g" src/chainparams.cpp
    $SED -i "s,{ 16128, //{ 16128,g" src/chainparams.cpp
    $SED -i "s,{ 23420, //{ 23420,g" src/chainparams.cpp
    $SED -i "s,{ 50000, //{ 50000,g" src/chainparams.cpp
    $SED -i "s,{ 80000, //{ 80000,g" src/chainparams.cpp
    $SED -i "s,{120000, //{120000,g" src/chainparams.cpp
    $SED -i "s,{161500, //{161500,g" src/chainparams.cpp
    $SED -i "s,{179620, //{179620,g" src/chainparams.cpp
    $SED -i "s,{240000, //{240000,g" src/chainparams.cpp
    $SED -i "s,{383640, //{383640,g" src/chainparams.cpp
    $SED -i "s,{409004, //{409004,g" src/chainparams.cpp
    $SED -i "s,{456000, //{456000,g" src/chainparams.cpp
    $SED -i "s,{638902, //{638902,g" src/chainparams.cpp
    $SED -i "s,{721000, //{721000,g" src/chainparams.cpp
    #checkpoints TEST NET
    $SED -i "s,{2056, {0,g" src/chainparams.cpp
    $SED -i "s/17748a31ba97afdc9a4f86837a39d287e3e7c7290a08a1d816c5969c78a83289/$TEST_GENESIS_HASH/" src/chainparams.cpp   
    #checkpoints REGTEST NET
    $SED -i "s/530827f38f93b43ed12af0b3ad25a288dc02ed74d6d7857862df51fc56c416f9/$REGTEST_GENESIS_HASH/" src/chainparams.cpp    


    $SED -i "s/ltc/$COIN_UNIT_LOWER/g" src/chainparams.cpp

    $SED -i "s/COINBASE_MATURITY = 100/COINBASE_MATURITY = $COINBASE_MATURITY/" src/consensus/consensus.h

    #RPC PORT
    $SED -i "s/, 9332/, $MAINNET_RPC_PORT/" src/chainparamsbase.cpp 
    $SED -i "s/, 19332/, $TESTNET_RPC_PORT/" src/chainparamsbase.cpp
    $SED -i "s/, 19443/, $REGTEST_RPC_PORT/" src/chainparamsbase.cpp  

    popd
}

if [ $DIRNAME =  "." ]; then
    DIRNAME=$PWD
fi

cd $DIRNAME

# sanity check

case $OSVERSION in
    Linux*)
        SED=sed
    ;;
    Darwin*)
        SED=$(which gsed 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "please install gnu-sed with 'brew install gnu-sed'"
            exit 1
        fi
        SED=gsed
    ;;
    *)
        echo "This script only works on Linux and MacOS"
        exit 1
    ;;
esac

if ! which git &>/dev/null; then
    echo Please install git first
    exit 1
fi


case $1 in
    clean)
        rm -rf $COIN_NAME_LOWER
        if [ "$2" != "keep_genesis_block" ]; then
            rm -f ${COIN_NAME}-*.txt
        fi
        exit 1
    ;;
    clone)
        newcoin_clone_replace_brand
        exit 1
    ;;
    fork)
        generate_genesis_block        
        newcoin_replace_vars
        exit 1
    ;;
    *)

        cat <<EOF
Usage: $0 (fork|clone|clean)
 - clone: clone and setup brand
 - fork: bootstrap environment, build and run your new coin
 - clean: WARNING: this will delete source code, genesis block information and nodes data directory. (to start from scratch)
EOF
    ;;
esac