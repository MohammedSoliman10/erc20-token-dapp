import { useState } from "react";
import { formatUnits, isAddress, parseUnits } from "viem";
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { solimanWeb3Contract } from "../config/contract";
import { useTokenData } from "../hooks/useTokenData";

export function ApproveForm() {
  const { address } = useAccount();
  const [spender, setSpender] = useState("");
  const [amount, setAmount] = useState("");
  const { decimals, symbol } = useTokenData();

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: currentAllowance, refetch: refetchAllowance } = useReadContract({
    ...solimanWeb3Contract,
    functionName: "allowance",
    args: address && isAddress(spender) ? [address, spender] : undefined,
    query: { enabled: Boolean(address && isAddress(spender)) },
  });

  const validAddress = spender === "" || isAddress(spender);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isAddress(spender) || !amount) return;
    writeContract({
      ...solimanWeb3Contract,
      functionName: "approve",
      args: [spender, parseUnits(amount, decimals ?? 18)],
    });
  }

  if (isSuccess) refetchAllowance();

  return (
    <form className="card" onSubmit={handleSubmit}>
      <h3>Approve</h3>
      <label>
        Spender address
        <input
          value={spender}
          onChange={(e) => setSpender(e.target.value)}
          placeholder="0x..."
          className={!validAddress ? "input-error" : ""}
        />
        {!validAddress && <span className="field-error">Not a valid address</span>}
      </label>
      {isAddress(spender) && currentAllowance !== undefined && (
        <p className="hint">
          Current allowance: {formatUnits(currentAllowance, decimals ?? 18)} {symbol}
        </p>
      )}
      <label>
        Amount
        <input
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.0"
          inputMode="decimal"
        />
      </label>
      <button type="submit" disabled={isPending || isConfirming || !isAddress(spender) || !amount}>
        {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : "Approve"}
      </button>
      {isSuccess && <p className="status-ok">Approval confirmed ✓</p>}
      {error && <p className="status-error">{error.message}</p>}
    </form>
  );
}
