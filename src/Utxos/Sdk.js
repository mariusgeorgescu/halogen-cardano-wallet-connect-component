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
  // @utxos/sdk overrides signTx to default `returnFullTx=true`, breaking CIP-30
  // semantics (which expect a witness set, not a full signed tx). Force false so
  // the popup returns a witness set. Extra args are ignored by standard CIP-30 wallets.
  const originalSignTx = api.signTx.bind(api);
  api.signTx = (tx, partialSign) => originalSignTx(tx, partialSign, false);
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
