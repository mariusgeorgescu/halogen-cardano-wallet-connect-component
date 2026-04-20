// | FFI bindings for @utxos/sdk.
// | Uses dynamic import() so the SDK is only loaded when UTXOS flow triggers.

export const _utxosEnable = projectId => networkId => fetcher => submitter => () =>
  import("@utxos/sdk").then(({ Web3Wallet }) =>
    Web3Wallet.enable({
      projectId,
      networkId,
      keepWindowOpen: true,
      fetcher,
      submitter,
    })
  ).then(wallet => {
    // Workaround: @utxos/sdk@0.2.0 initCardanoWallet() accepts fetcher but
    // never passes it to MeshCardanoHeadlessWallet.fromCredentialSources().
    if (fetcher && wallet.cardano && !wallet.cardano.fetcher) {
      wallet.cardano.fetcher = fetcher;
    }
    if (submitter && wallet.cardano && !wallet.cardano.submitter) {
      wallet.cardano.submitter = submitter;
    }
    return wallet;
  });

export const _getCardanoApi = wallet => {
  const api = wallet.cardano;
  // UTXOS popup only supports its documented single-arg signTx pattern
  // (https://docs.utxos.dev/wallet/usage/cardano) — `partialSign=true` fails
  // inside the popup with "reconstruct wallet" errors. CIP-30 callers expect a
  // witness set, so we call signTx per the UTXOS docs (returns a full signed
  // tx) and parse it with CSL to extract the witness set.
  const originalSignTx = api.signTx.bind(api);
  api.signTx = async (tx, _partialSign) => {
    const fullSignedTxHex = await originalSignTx(tx);
    const csl = await import("@emurgo/cardano-serialization-lib-browser");
    const decoded = csl.Transaction.from_hex(fullSignedTxHex);
    try {
      return decoded.witness_set().to_hex();
    } finally {
      decoded.free();
    }
  };
  return api;
};

export const _utxosOnramp = wallet => opts => () =>
  Promise.resolve(wallet.onramp(opts));

export const _getUtxosUserAvatarUrl = wallet => {
  const user = wallet.getUser();
  return (user && user.avatarUrl) ? user.avatarUrl : null;
};

export const _getUtxosUserName = wallet => {
  const user = wallet.getUser();
  return (user && user.username) ? user.username : null;
};
