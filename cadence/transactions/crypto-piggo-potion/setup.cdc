import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import MetadataViews from ${FLOW_NFT_ADDRESS}
import CryptoPiggoPotion from ${FLOW_CRYPTO_PIGGO_ADDRESS}

transaction {
  prepare(signer: AuthAccount) {
    if signer.borrow<&CryptoPiggoPotion.Collection>(from: CryptoPiggoPotion.CollectionStoragePath) == nil {
      let collection <-CryptoPiggoPotion.createEmptyCollection()
      signer.save(<-collection, to: CryptoPiggoPotion.CollectionStoragePath)
      signer.link<&{
        NonFungibleToken.CollectionPublic, 
        MetadataViews.ResolverCollection
      }>(
        CryptoPiggoPotion.CollectionPublicPath,
        target: CryptoPiggoPotion.CollectionStoragePath
      )
    }
  }
}