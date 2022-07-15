import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import CryptoPiggoV2 from ${FLOW_CRYPTO_PIGGO_ADDRESS}
import CryptoPiggoPotion from ${FLOW_CRYPTO_PIGGO_ADDRESS}
import AnchainNFTTrader from ${FLOW_ANCHAIN_NFT_TRADER_ADDRESS}

transaction(address: Address, tradeResourceID: UInt64) {
  let nftCollection: &CryptoPiggoV2.Collection{NonFungibleToken.Receiver}
  let trader: &AnchainNFTTrader.Trader{AnchainNFTTrader.TraderPublic}
  let trade: &AnchainNFTTrader.Trade{AnchainNFTTrader.TradePublic}
  let nft: @NonFungibleToken.NFT

  prepare(signer: AuthAccount) {
    self.trader = getAccount(address)
      .getCapability<&AnchainNFTTrader.Trader{AnchainNFTTrader.TraderPublic}>(
        AnchainNFTTrader.TraderPublicPath
      )!
      .borrow()
      ?? panic("Could not borrow Trader from provided address")

    self.trade = self.trader.borrowTrade(tradeResourceID: tradeResourceID) 
      ?? panic("Could not find trade")

    let signerCollection = signer.borrow<&CryptoPiggoPotion.Collection>(from: CryptoPiggoPotion.CollectionStoragePath)
      ?? panic("Cannot borrow CryptoPiggoPotion collection from account storage")

    let nftID = self.trade.getDetails().requestedNftID
    if nftID != nil {
      self.nft <- signerCollection.withdraw(withdrawID: nftID!)
    } else {
      let ids = signerCollection.getIDs()
      self.nft <- signerCollection.withdraw(withdrawID: ids.removeFirst())
    }    

    self.nftCollection = signer.borrow<&CryptoPiggoV2.Collection{NonFungibleToken.Receiver}>(
      from: CryptoPiggoV2.CollectionStoragePath
    ) ?? panic("Cannot borrow NFT collection receiver from account")
  }

  execute {
    let item <- self.trade.execute(payment: <-self.nft)
    self.nftCollection.deposit(token: <-item)
    self.trader.cleanup(tradeResourceID: self.trade.uuid)
  }    
}