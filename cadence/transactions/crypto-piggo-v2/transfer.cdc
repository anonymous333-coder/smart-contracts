import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import CryptoPiggoV2 from ${FLOW_CRYPTO_PIGGO_ADDRESS}

transaction(recipient: Address, nftIDs: [UInt64]) {
  prepare(signer: AuthAccount) {
    let collectionRef = signer
      .borrow<&CryptoPiggoV2.Collection>(from: CryptoPiggoV2.CollectionStoragePath)
      ?? panic("Could not borrow a reference to the owner's collection")

    let depositRef = getAccount(recipient)
      .getCapability(CryptoPiggoV2.CollectionPublicPath)!
      .borrow<&{NonFungibleToken.CollectionPublic}>()!

    for nftID in nftIDs {
      collectionRef.transfer(id: nftID, recipient: depositRef)
    }
  }
}