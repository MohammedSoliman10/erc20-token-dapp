import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { useTokenData } from "../hooks/useTokenData";

export function TokenInfo() {
  const { isConnected } = useAccount();
  const { isLoading, name, symbol, decimals, totalSupply, cap, balance, paused } =
    useTokenData();

  if (isLoading) {
    return <div className="card">Loading token data…</div>;
  }

  const dec = decimals ?? 18;

  return (
    <div className="card">
      <h2>
        {name ?? "—"} ({symbol ?? "—"})
      </h2>
      {paused && <p className="badge badge-warn">⏸ Transfers paused</p>}
      <dl className="stat-grid">
        <dt>Total supply</dt>
        <dd>{totalSupply !== undefined ? formatUnits(totalSupply, dec) : "—"}</dd>

        <dt>Cap</dt>
        <dd>{cap !== undefined ? formatUnits(cap, dec) : "—"}</dd>

        <dt>Your balance</dt>
        <dd>{isConnected && balance !== undefined ? formatUnits(balance, dec) : "—"}</dd>
      </dl>
    </div>
  );
}
