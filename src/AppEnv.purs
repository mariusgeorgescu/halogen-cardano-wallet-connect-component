module AppEnv where

-- | Network configuration
type BlockchainProviderConfig
  = { cardanoNetwork :: String
    }

-----------------
-- Env Type
-----------------
-- | The application environment
type Env
  = { blockchainProviderConfig :: BlockchainProviderConfig }

defaultEnv :: Env
defaultEnv = { blockchainProviderConfig: { cardanoNetwork: "Preview" } }
