import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import CryptoPiggoPotion from ${FLOW_CRYPTO_PIGGO_ADDRESS}

transaction(recipient: Address, nftIDs: [UInt64]) {
  prepare(signer: AuthAccount) {
    let collectionRef = signer
      .borrow<&CryptoPiggoPotion.Collection>(from: CryptoPiggoPotion.CollectionStoragePath)
      ?? panic("Could not borrow a reference to the owner's collection")

    let depositRef = getAccount(recipient)
      .getCapability(CryptoPiggoPotion.CollectionPublicPath)!
      .borrow<&{NonFungibleToken.CollectionPublic}>()!

    for nftID in nftIDs {
      collectionRef.transfer(id: nftID, recipient: depositRef)
    }
  }
}