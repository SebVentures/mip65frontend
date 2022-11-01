# MIP65 Frontend

## Summary

This project aim to allow any third party to track the evolution of MakerDAO MIP65 collateral. It is composed by a solidity smart contract and a Python data scrapper.

A [Dune dashbord](https://dune.com/SebVentures/makerdao-mip65) present the collateral evolution based on an [on-chain smart contract](https://polygonscan.com/address/0xc79c0b5f0a9fe841704d89befb0cd5c2b3e6a8f7) filled "manually" by a scrapper.

## Operations

A .env file need to be created at the root director based on `.env-default` then the Python srapper can be called by:

```
scrapy crawl etfspider
```

