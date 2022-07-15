import AnchainNFTTrader from ${FLOW_ANCHAIN_NFT_TRADER_ADDRESS}

transaction {
  prepare(signer: AuthAccount) {
    if signer.borrow<&AnchainNFTTrader.Trader>(from: AnchainNFTTrader.TraderStoragePath) == nil {
      let trader <- AnchainNFTTrader.createTrader() as! @AnchainNFTTrader.Trader        
      signer.save(<-trader, to: AnchainNFTTrader.TraderStoragePath)  
      signer.link<&AnchainNFTTrader.Trader{AnchainNFTTrader.TraderPublic}>(AnchainNFTTrader.TraderPublicPath, target: AnchainNFTTrader.TraderStoragePath)
    }
  }
}