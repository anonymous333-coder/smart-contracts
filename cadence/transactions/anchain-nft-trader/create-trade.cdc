import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import CryptoPiggoV2 from ${FLOW_CRYPTO_PIGGO_ADDRESS}
import CryptoPiggoPotion from ${FLOW_CRYPTO_PIGGO_ADDRESS}
import AnchainNFTTrader from ${FLOW_ANCHAIN_NFT_TRADER_ADDRESS}

pub fun hasTrade(trader: &AnchainNFTTrader.Trader, nftID: UInt64): Bool {
  for id in trader.getTradeIDs() {
    let details = trader.borrowTrade(tradeResourceID: id)!.getDetails()
    if details.nftID == nftID && details.nftType == Type<@CryptoPiggoV2.NFT>() {
      return true
    }
  }
  return false
}

transaction(nftID: UInt64, requestedNftID: UInt64?) {
  let nftProvider: Capability<&CryptoPiggoV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
  let nftReceiver: Capability<&CryptoPiggoPotion.Collection{NonFungibleToken.Receiver}>
  let trader: &AnchainNFTTrader.Trader

  prepare(acct: AuthAccount) {
    self.trader = acct.borrow<&AnchainNFTTrader.Trader>(from: AnchainNFTTrader.TraderStoragePath)
      ?? panic("Could not find trader in account storage")

    if hasTrade(trader: self.trader, nftID: nftID) {
      panic("NFT is already listed")
    }
  
    let collection = acct.borrow<&CryptoPiggoV2.Collection>(from: CryptoPiggoV2.CollectionStoragePath)
      ?? panic("Could not find CryptoPiggoV2 collection in trader account")
      
    if !collection.getIDs().contains(nftID) {
      panic("Could not find NFT in account")
    }
    
    // We need a provider capability, but one is not provided by default so we create one if needed.
    let nftCollectionProviderPrivatePath = /private/nftCollectionProviderForAnchainNFTTrader

    if !acct.getCapability<&CryptoPiggoV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftCollectionProviderPrivatePath)!.check() {
      acct.link<&CryptoPiggoV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftCollectionProviderPrivatePath, target: CryptoPiggoV2.CollectionStoragePath)
    }

    self.nftProvider = acct.getCapability<&CryptoPiggoV2.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftCollectionProviderPrivatePath)!
    assert(self.nftProvider.borrow() != nil, message: "Missing or mis-typed CryptoPiggoV2.Collection provider")
    
    // We need a receiver capability, but one is not provided by default so we create one if needed.
    let nftCollectionReceiverPrivatePath = /private/nftCollectionReceiverForAnchainNFTTrader

    if !acct.getCapability<&CryptoPiggoPotion.Collection{NonFungibleToken.Receiver}>(nftCollectionReceiverPrivatePath)!.check() {
      acct.link<&CryptoPiggoPotion.Collection{NonFungibleToken.Receiver}>(nftCollectionReceiverPrivatePath, target: CryptoPiggoPotion.CollectionStoragePath)
    }

    self.nftReceiver = acct.getCapability<&CryptoPiggoPotion.Collection{NonFungibleToken.Receiver}>(nftCollectionReceiverPrivatePath)!
    assert(self.nftReceiver.borrow() != nil, message: "Missing or mis-typed user CryptoPiggoPotion receiver")
  }

  execute {
    self.trader.createTrade(
      nftProviderCapability: self.nftProvider,
      nftType: Type<@CryptoPiggoV2.NFT>(),
      nftID: nftID,
      nftReceiverCapability: self.nftReceiver,
      requestedNftType: Type<@CryptoPiggoPotion.NFT>(),
      requestedNftID: requestedNftID,
    )
  }
}