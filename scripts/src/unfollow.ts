import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId, getProfile } from "./utils.ts";

async function unfollow(
  profileId: string,
  profileCapId: string,
  profileIdUnFollow: string
) {
  const tx = new TransactionBlock();

  tx.moveCall({
    arguments: [
      tx.object(profileId),
      tx.object(profileCapId),
      tx.pure(profileIdUnFollow),
    ],
    target: `${getId("package")}::profile::unfollow`,
  });

  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const { profileCapId, profileId } = await getProfile(currentAccount);

  const profileIdUnFollow =
    "0x157db3ca1a51ceaf9169f62eadf2158b4adc70fa28114945923601c598fdb7fe";

  await unfollow(profileId, profileCapId, profileIdUnFollow);

  console.log("done");
})().catch((e) => {
  console.log(e);
});
