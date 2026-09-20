# SolimanWeb3 Token — Frontend

React + wagmi + viem + RainbowKit dApp for the `SolimanWeb3` ERC-20 contract.

## Features

- Connect wallet (RainbowKit — MetaMask, WalletConnect, etc.)
- Read name, symbol, total supply, cap, and your balance
- Transfer tokens
- Approve a spender / view current allowance
- Mint — only shown if your connected wallet holds `MINTER_ROLE`
- Pause/unpause — only shown if your connected wallet holds `PAUSER_ROLE`
- Auto-refreshes on `Transfer`/`Approval` events, no manual reload needed

## Setup

```bash
cd frontend
npm install
cp .env.example .env
```

Fill in `.env`:

- `VITE_WALLETCONNECT_PROJECT_ID` — free at https://cloud.walletconnect.com (only needed for the WalletConnect option in the wallet modal; MetaMask/injected wallets work without it)
- `VITE_CONTRACT_ADDRESS` — the deployed `SolimanWeb3` address (see `../script/Deploy.s.sol`)

```bash
npm run dev
```

## Networks

Configured for Sepolia and a local Hardhat/Anvil node (chain id 31337) in
`src/config/wagmi.ts`. Add mainnet or other chains there if you deploy
elsewhere.

## Notes

- The ABI in `src/abi/SolimanWeb3.ts` is extracted directly from the compiled
  contract (`forge inspect SolimanWeb3 abi --json`). Re-run that if you change
  `src/SolimanWeb3.sol`.
- Role checks (`isMinter`/`isPauser`) are read live from the contract's own
  `MINTER_ROLE()`/`PAUSER_ROLE()`/`hasRole()` — there's no hardcoded role hash
  anywhere in the frontend, so it can't drift out of sync with the contract.
- The UI role checks are a convenience only; the contract enforces access
  control on-chain regardless of what the frontend shows.
