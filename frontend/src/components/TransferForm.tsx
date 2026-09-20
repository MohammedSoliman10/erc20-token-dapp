import { useState } from "react";
import { isAddress, parseUnits } from "viem";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { solimanWeb3Contract } from "../config/contract";
import { useTokenData } from "../hooks/useTokenData";

export function TransferForm() {
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
      functionName: "transfer",
      args: [to, parseUnits(amount, decimals ?? 18)],
    });
  }

  return (
    <form className="card" onSubmit={handleSubmit}>
      <h3>Transfer</h3>
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
        {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : "Transfer"}
      </button>
      {isSuccess && <p className="status-ok">Transfer confirmed ✓</p>}
      {error && <p className="status-error">{error.message}</p>}
    </form>
  );
}
