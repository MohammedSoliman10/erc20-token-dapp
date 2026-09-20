import { useState } from "react";
import { isAddress, parseUnits } from "viem";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { solimanWeb3Contract } from "../config/contract";
import { useTokenData } from "../hooks/useTokenData";

/**
 * Only rendered by the parent when the connected wallet holds MINTER_ROLE —
 * see App.tsx. The contract itself also enforces this on-chain, so this is
 * purely a UI convenience, not the security boundary.
 */
export function MintForm() {
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("");
  const { decimals } = useTokenData();

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const validAddress = to === "" || isAddress(to);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isAddress(to) || !amount) return;
    writeContract({
      ...solimanWeb3Contract,
      functionName: "mint",
      args: [to, parseUnits(amount, decimals ?? 18)],
    });
  }

  return (
    <form className="card card-accent" onSubmit={handleSubmit}>
      <h3>Mint (minter only)</h3>
      <label>
        Recipient address
        <input
          value={to}
          onChange={(e) => setTo(e.target.value)}
          placeholder="0x..."
          className={!validAddress ? "input-error" : ""}
        />
        {!validAddress && <span className="field-error">Not a valid address</span>}
      </label>
      <label>
        Amount
        <input
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="0.0"
          inputMode="decimal"
        />
      </label>
      <button type="submit" disabled={isPending || isConfirming || !isAddress(to) || !amount}>
        {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : "Mint"}
      </button>
      {isSuccess && <p className="status-ok">Mint confirmed ✓</p>}
      {error && <p className="status-error">{error.message}</p>}
    </form>
  );
}
