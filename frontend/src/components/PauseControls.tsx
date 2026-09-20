import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { solimanWeb3Contract } from "../config/contract";
import { useTokenData } from "../hooks/useTokenData";

/** Only rendered by the parent when the connected wallet holds PAUSER_ROLE. */
export function PauseControls() {
  const { paused, refetch } = useTokenData();
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  if (isSuccess) refetch();

  function toggle() {
    writeContract({
      ...solimanWeb3Contract,
      functionName: paused ? "unpause" : "pause",
    });
  }

  return (
    <div className="card card-accent">
      <h3>Pause controls (pauser only)</h3>
      <p>
        Transfers, mints and burns are currently{" "}
        <strong>{paused ? "paused" : "active"}</strong>.
      </p>
      <button onClick={toggle} disabled={isPending || isConfirming}>
        {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : paused ? "Unpause" : "Pause"}
      </button>
      {error && <p className="status-error">{error.message}</p>}
    </div>
  );
}
