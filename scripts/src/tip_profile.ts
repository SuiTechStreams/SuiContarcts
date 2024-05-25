import { TransactionBlock } from "@mysten/sui.js/transactions";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import { client, keypair, getId } from "./utils.ts";

async function tip(profileId: string, amountInSui: number) {
  const tx = new TransactionBlock();

  let [coin] = tx.splitCoins(tx.gas, [amountInSui * Number(MIST_PER_SUI)]);

  tx.moveCall({
    arguments: [tx.object(profileId), coin],
    target: `${getId("package")}::profile::tip`,
  });

  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  const profileId =
    "0x3e13696db5948db4d904dca0a4f739159bfe7a342f9128d2574f90900059c1b6";

  await tip(profileId, 0.1);
  console.log("done");
})().catch((e) => {
  console.log(e);
});
