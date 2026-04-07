// | FFI bindings for @utxos/sdk.
// | Uses dynamic import() so the SDK is only loaded when UTXOS flow triggers.

export const _utxosEnable = projectId => networkId => () =>
  import("@utxos/sdk").then(({ Web3Wallet }) =>
    Web3Wallet.enable({ projectId, networkId, keepWindowOpen: true })
  );

export const _getCardanoApi = wallet => wallet.cardano;

export const _utxosOnramp = wallet => opts => () =>
  Promise.resolve(wallet.onramp(opts));
