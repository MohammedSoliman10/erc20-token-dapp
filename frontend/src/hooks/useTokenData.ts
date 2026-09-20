import { useAccount, useReadContracts, useWatchContractEvent } from "wagmi";
import { useQueryClient } from "@tanstack/react-query";
import { solimanWeb3Contract } from "../config/contract";

/**
 * Reads all the on-chain token state the UI needs in one batched call,
 * and refetches automatically whenever a Transfer/Approval event touches
 * the connected account.
 */
export function useTokenData() {
  const { address } = useAccount();
  const queryClient = useQueryClient();

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: [
      { ...solimanWeb3Contract, functionName: "name" },
      { ...solimanWeb3Contract, functionName: "symbol" },
      { ...solimanWeb3Contract, functionName: "decimals" },
      { ...solimanWeb3Contract, functionName: "totalSupply" },
      { ...solimanWeb3Contract, functionName: "cap" },
      { ...solimanWeb3Contract, functionName: "paused" },
      { ...solimanWeb3Contract, functionName: "MINTER_ROLE" },
      { ...solimanWeb3Contract, functionName: "PAUSER_ROLE" },
      {
        ...solimanWeb3Contract,
        functionName: "balanceOf",
        args: address ? [address] : undefined,
      },
    ],
    query: { enabled: true },
  });

  const [
    name,
    symbol,
    decimals,
    totalSupply,
    cap,
    paused,
    minterRole,
    pauserRole,
    balance,
  ] = data ?? [];

  // Separate reads that depend on knowing MINTER_ROLE/PAUSER_ROLE first,
  // and on the connected address.
  const roleChecks = useReadContracts({
    contracts:
      address && minterRole?.result && pauserRole?.result
        ? [
            {
              ...solimanWeb3Contract,
              functionName: "hasRole",
              args: [minterRole.result, address],
            },
            {
              ...solimanWeb3Contract,
              functionName: "hasRole",
              args: [pauserRole.result, address],
            },
          ]
        : [],
    query: { enabled: Boolean(address && minterRole?.result && pauserRole?.result) },
  });

  const [isMinter, isPauser] = roleChecks.data ?? [];

  // Refetch balances/supply whenever a Transfer involving us happens.
  useWatchContractEvent({
    ...solimanWeb3Contract,
    eventName: "Transfer",
    onLogs() {
      refetch();
      queryClient.invalidateQueries();
    },
  });

  useWatchContractEvent({
    ...solimanWeb3Contract,
    eventName: "Approval",
    onLogs() {
      refetch();
      queryClient.invalidateQueries();
    },
  });

  return {
    isLoading,
    error,
    refetch,
    name: name?.result,
    symbol: symbol?.result,
    decimals: decimals?.result,
    totalSupply: totalSupply?.result,
    cap: cap?.result,
    paused: paused?.result,
    balance: balance?.result,
    isMinter: Boolean(isMinter?.result),
    isPauser: Boolean(isPauser?.result),
  };
}
