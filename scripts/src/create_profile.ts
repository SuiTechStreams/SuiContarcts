import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId } from "./utils.ts";

async function createProfile(username: string, bio: string, pfp: string) {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const tx = new TransactionBlock();
  let [profile] = tx.moveCall({
    arguments: [tx.pure(username), tx.pure(bio), tx.pure(pfp)],
    target: `${getId("package")}::profile::create_profile`,
  });
  tx.transferObjects([profile], currentAccount);
  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  await createProfile("name", "bio", "pfp");
  console.log("done");
})().catch((e) => {
  console.log(e);
});
