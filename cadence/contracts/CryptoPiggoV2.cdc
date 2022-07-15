/**
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

pub contract CryptoPiggoV2: NonFungibleToken {
  pub var totalSupply: UInt64

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, name: String, description: String, file: MetadataViews.IPFSFile, metadata: {String:String})
  pub event Burned(id: UInt64, address: Address?)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64
    pub let name: String
    pub let description: String
    pub let file: MetadataViews.IPFSFile
    access(self) let royalties: [MetadataViews.Royalty]
    access(self) let metadata: {String:String}

    init(
      name: String,
      description: String,
      file: MetadataViews.IPFSFile,
      royalties: [MetadataViews.Royalty],
      metadata: {String:String}
    ) {
      self.id = CryptoPiggoV2.totalSupply
      self.name = name
      self.description = description
      self.file = file
      self.royalties = royalties
      self.metadata = metadata

      emit Minted(
        id: self.id,
        name: self.name,
        description: self.description,
        file: self.file,
        metadata: self.metadata
      )

      CryptoPiggoV2.totalSupply = CryptoPiggoV2.totalSupply + 1
    }
  
    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Editions>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Traits>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: "Crypto Piggo V2 NFT ".concat(self.id.toString()),
            description: "",
            thumbnail: MetadataViews.HTTPFile(
              url: "https://ipfs.tenzingai.com/ipfs/".concat(self.file.cid)
            )
          )

        case Type<MetadataViews.Editions>():
          // There is no max number of NFTs that can be minted from this contract
          // so the max edition field value is set to nil
          return MetadataViews.Editions([
            MetadataViews.Edition(
              name: "Meta Panda NFT Edition", 
              number: self.id, 
              max: nil
            )
          ])

        case Type<MetadataViews.Serial>():
          return MetadataViews.Serial(self.id)

        case Type<MetadataViews.Royalties>():
          return MetadataViews.Royalties(self.royalties)

        case Type<MetadataViews.ExternalURL>():
          return MetadataViews.ExternalURL("https://s3.us-west-2.amazonaws.com/crypto-piggo.nft/".concat(self.id.toString()).concat(".png"))

        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: CryptoPiggoV2.CollectionStoragePath,
            publicPath: CryptoPiggoV2.CollectionPublicPath,
            providerPath: /private/CryptoPiggoV2Collection,
            publicCollection: Type<&CryptoPiggoV2.Collection>(),
            publicLinkedType: Type<&CryptoPiggoV2.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&CryptoPiggoV2.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                return <-CryptoPiggoV2.createEmptyCollection()
            })
          )

        case Type<MetadataViews.NFTCollectionDisplay>():
          // TODO:
          let media = MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: ""),
            mediaType: "image/png"
          )
          return MetadataViews.NFTCollectionDisplay(
            name: "The Crypto Piggo V2 NFT Collection",
            description: "",
            externalURL: MetadataViews.ExternalURL("https://www.rareworx.com/"),
            squareImage: media,
            bannerImage: media,
            socials: {}
          )

        case Type<MetadataViews.Traits>():
          return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
      }
      return nil
    }

    destroy() {
      emit Burned(id: self.id, address: self.owner?.address)
    }
  }

  pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    // dictionary of NFT conforming tokens
    // NFT is a resource type with an `UInt64` ID field
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    // withdraw removes an NFT from the collection and moves it to the caller
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    // deposit takes a NFT and adds it to the collections dictionary
    // and adds the ID to the id array
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @CryptoPiggoV2.NFT

      let id: UInt64 = token.id

      // add the new token to the dictionary which removes the old one
      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    // transfer takes an NFT ID and a reference to a recipient's collection
    // and transfers the NFT corresponding to that ID to the recipient
    pub fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}) {
      post {
        self.ownedNFTs[id] == nil: "The specified NFT was not transferred"
        recipient.borrowNFT(id: id) != nil: "Recipient did not receive the intended NFT"
      }

      let nft <- self.withdraw(withdrawID: id)
      
      recipient.deposit(token: <- nft)
    }

    // burn destroys an NFT
    pub fun burn(id: UInt64) {
      post {
        self.ownedNFTs[id] == nil: "The specified NFT was not burned"
      }

      // This will emit a burn event
      destroy <- self.withdraw(withdrawID: id)
    }

    // getIDs returns an array of the IDs that are in the collection
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    // borrowNFT gets a reference to an NFT in the collection
    // so that the caller can read its metadata and call its methods
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      if self.ownedNFTs[id] != nil {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }
      panic("NFT not found in collection.")
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      if self.ownedNFTs[id] != nil {
        let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
        if nft != nil {
          return nft! as! &CryptoPiggoV2.NFT
        }
      }
      panic("NFT not found in collection.")
    }

    destroy() {
        destroy self.ownedNFTs
    }
  }

  // public function that anyone can call to create a new empty collection
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  // Resource that an admin or something similar would own to be
  // able to mint new NFTs
  //
  pub resource NFTMinter {
    // transformMetadata ensures that the NFT metadata follows a particular
    // schema. At the moment, it is much more convenient to use functions
    // rather than structs to enforce a metadata schema because functions 
    // are much more flexible, easier to maintain, and safer to update.
    access(self) fun transformMetadata(_ metadata: {String:String}): {String:String} {
      pre {
        metadata.containsKey("background")
        && metadata.containsKey("body")
        && metadata.containsKey("outfit")
        && metadata.containsKey("head")
        && metadata.containsKey("face")
        && metadata.containsKey("name")
        && metadata.containsKey("rarity")
        && metadata.containsKey("unique")
        : "Metadata does not conform to schema"
      }
      return {
        "background": metadata["background"]!,
        "body": metadata["body"]!,
        "outfit": metadata["outfit"]!,
        "head": metadata["head"]!,
        "face": metadata["face"]!,
        "name": metadata["name"]!,
        "rarity": metadata["rarity"]!,
        "unique": metadata["unique"]!
      }
    }

    // mintNFT mints a new NFT with a new ID
    // and deposit it in the recipients collection using their collection reference
    pub fun mintNFT(
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      file: MetadataViews.IPFSFile,
      royalties: [MetadataViews.Royalty],
      metadata: {String:String},
    ) {
      // create a new NFT
      let newNFT <- create NFT(
        name: name,
        description: description,
        file: file,
        royalties: royalties,
        metadata: self.transformMetadata(metadata)
      )

      // deposit it in the recipient's account using their reference
      recipient.deposit(token: <-newNFT)
    }
  }

  init() {
    // Initialize the total supply
    self.totalSupply = 0

    // Set the named paths
    self.CollectionStoragePath = /storage/CryptoPiggoV2Collection
    self.CollectionPublicPath = /public/CryptoPiggoV2Collection
    self.MinterStoragePath = /storage/CryptoPiggoV2Minter

    // Create a Collection resource and save it to storage
    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    // create a public capability for the collection
    self.account.link<&CryptoPiggoV2.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath, 
      target: self.CollectionStoragePath
    )

    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)

    emit ContractInitialized()
  }
}
 