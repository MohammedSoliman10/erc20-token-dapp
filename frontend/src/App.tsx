import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";
import { TokenInfo } from "./components/TokenInfo";
import { TransferForm } from "./components/TransferForm";
import { ApproveForm } from "./components/ApproveForm";
import { MintForm } from "./components/MintForm";
import { PauseControls } from "./components/PauseControls";
import { useTokenData } from "./hooks/useTokenData";
import { CONTRACT_ADDRESS } from "./config/contract";
import "./App.css";

function App() {
  const { isConnected } = useAccount();
  const { isMinter, isPauser } = useTokenData();

  const contractNotConfigured =
    CONTRACT_ADDRESS === "0x0000000000000000000000000000000000000000";

  return (
    <div className="app">
      <header className="app-header">
        <h1>SolimanWeb3 Token</h1>
        <ConnectButton />
      </header>

      {contractNotConfigured && (
        <div className="card card-warn">
          No contract address configured. Set{" "}
          <code>VITE_CONTRACT_ADDRESS</code> in your <code>.env</code> after
          deploying (see <code>script/Deploy.s.sol</code>).
        </div>
      )}

      <TokenInfo />

      {isConnected ? (
        <div className="grid">
          <TransferForm />
          <ApproveForm />
          {isMinter && <MintForm />}
          {isPauser && <PauseControls />}
        </div>
      ) : (
        <p className="hint">Connect a wallet to transfer, approve, or mint.</p>
      )}
    </div>
  );
}

export default App;
