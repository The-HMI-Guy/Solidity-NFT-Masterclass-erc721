import CollectionConfigInterface from '../lib/CollectionConfigInterface';
import * as Networks from '../lib/Networks';
import * as Marketplaces from '../lib/Marketplaces';
import whitelistAddresses from './whitelist.json';

const CollectionConfig: CollectionConfigInterface = {
  testnet: Networks.ethereumTestnet,
  mainnet: Networks.ethereumMainnet,
  // The contract name can be updated using the following command:
  // yarn rename-contract NEW_CONTRACT_NAME
  // Please DO NOT change it manually!
  contractName: 'DragonEye',
  tokenName: 'Dragon Eye',
  tokenSymbol: 'DE',
  hiddenMetadataUri: 'ipfs://QmcmJ1g8kNsiRRKUznLkjcigFk4sw7YZMy8dQ7W9axNNGN/hidden.json',
  maxSupply: 10,
  whitelistSale: {
    price: 0.001,
    maxMintAmountPerTx: 2,
  },
  preSale: {
    price: 0.07,
    maxMintAmountPerTx: 2,
  },
  publicSale: {
    price: 0.09,
    maxMintAmountPerTx: 5,
  },
  contractAddress: "0xf670cE43b87BFe067fAd2Fd50CE125bAc8F44c7C",
  marketplaceIdentifier: 'my-nft-token',
  marketplaceConfig: Marketplaces.openSea,
  whitelistAddresses,
};

export default CollectionConfig;
