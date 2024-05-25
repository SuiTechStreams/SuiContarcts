import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId, getProfile } from "./utils.ts";

async function withdrawTip(
  profileId: string,
  profileCapId: string,
  currentAccount: string
) {
  const tx = new TransactionBlock();

  let [coin] = tx.moveCall({
    arguments: [tx.object(profileId), tx.object(profileCapId)],
    target: `${getId("package")}::profile::withdraw_tip`,
  });

  tx.transferObjects([coin], currentAccount);

  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const { profileCapId, profileId } = await getProfile(currentAccount);

  await withdrawTip(profileId, profileCapId, currentAccount);

  console.log("done");
})().catch((e) => {
  console.log(e);
});
