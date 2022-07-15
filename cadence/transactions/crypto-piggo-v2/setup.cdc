import NonFungibleToken from ${FLOW.FLOW_NFT_ADDRESS}
import MetadataViews from ${FLOW_NFT_ADDRESS}
import CryptoPiggoV2 from ${FLOW_CRYPTO_PIGGO_ADDRESS}

transaction {
  prepare(signer: AuthAccount) {
    if signer.borrow<&CryptoPiggoV2.Collection>(from: CryptoPiggoV2.CollectionStoragePath) == nil {
      let collection <-CryptoPiggoV2.createEmptyCollection()
      signer.save(<-collection, to: CryptoPiggoV2.CollectionStoragePath)
      signer.link<&{
        NonFungibleToken.CollectionPublic, 
        MetadataViews.ResolverCollection
      }>(
        CryptoPiggoV2.CollectionPublicPath,
        target: CryptoPiggoV2.CollectionStoragePath
      )
    }
  }
}