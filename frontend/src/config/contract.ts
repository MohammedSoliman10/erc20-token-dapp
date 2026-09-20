import { solimanWeb3Abi } from "../abi/SolimanWeb3";
import type { Address } from "viem";

// Set this after you deploy (see ../../script/Deploy.s.sol), either by
// editing this file directly or via VITE_CONTRACT_ADDRESS in your .env.
export const CONTRACT_ADDRESS = (import.meta.env.VITE_CONTRACT_ADDRESS ??
  "0x0000000000000000000000000000000000000000") as Address;

export const solimanWeb3Contract = {
  address: CONTRACT_ADDRESS,
  abi: solimanWeb3Abi,
} as const;

// NOTE: we deliberately don't hardcode MINTER_ROLE / PAUSER_ROLE hashes here.
// They're fetched on-chain via the contract's own MINTER_ROLE()/PAUSER_ROLE()
// getters in useTokenData — that's the source of truth and can't drift out
// of sync with the deployed bytecode.
