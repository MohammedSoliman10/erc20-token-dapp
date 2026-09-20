import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, hardhat } from "wagmi/chains";

// WalletConnect project ID — free at https://cloud.walletconnect.com
// Required for the WalletConnect connector in RainbowKit's modal to work.
const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID as string | undefined;

if (!projectId) {
  // eslint-disable-next-line no-console
  console.warn(
    "VITE_WALLETCONNECT_PROJECT_ID is not set. WalletConnect will not work; " +
      "browser wallets like MetaMask injected directly will still work fine.",
  );
}

export const wagmiConfig = getDefaultConfig({
  appName: "SolimanWeb3 Token",
  projectId: projectId ?? "MISSING_PROJECT_ID",
  chains: [sepolia, hardhat],
  ssr: false,
});
