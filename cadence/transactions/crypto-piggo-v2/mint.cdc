import NonFungibleToken from ${FLOW_NFT_ADDRESS}
import MetadataViews from ${FLOW_NFT_ADDRESS}
import CryptoPiggoV2 from ${FLOW_CRYPTO_PIGGO_ADDRESS}

transaction(recipient: Address, metadata: [{String:String}]) {
  let minter: &CryptoPiggoV2.NFTMinter

  prepare(signer: AuthAccount) {
    self.minter = signer.borrow<&CryptoPiggoV2.NFTMinter>(from: CryptoPiggoV2.MinterStoragePath)
      ?? panic("Could not borrow a reference to the NFT minter")
  }

  execute {
    let receiver = getAccount(recipient)
      .getCapability(CryptoPiggoV2.CollectionPublicPath)!
      .borrow<&{NonFungibleToken.CollectionPublic}>()
      ?? panic("Could not get receiver reference to the NFT Collection")

    for m in metadata {
      self.minter.mintNFT(
        recipient: receiver,
        name: m["name"] ?? panic("name is required"),
        description: m["description"] ?? "",
        file: MetadataViews.IPFSFile(
          cid: m["cid"] ?? panic("cid is required"),
          path: nil
        ),
        royalties: [],
        metadata: m
      )
    }
  }
}