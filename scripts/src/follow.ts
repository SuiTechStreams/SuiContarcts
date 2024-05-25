import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId, getProfile } from "./utils.ts";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";

async function withdrawTip(
  profileId: string,
  profileCapId: string,
  profileIdFollow: string
) {
  const tx = new TransactionBlock();

  tx.moveCall({
    arguments: [
      tx.object(profileId),
      tx.object(profileCapId),
      tx.pure(profileIdFollow),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
    target: `${getId("package")}::profile::follow`,
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

  const profileIdFollow =
    "0x157db3ca1a51ceaf9169f62eadf2158b4adc70fa28114945923601c598fdb7fe";

  await withdrawTip(profileId, profileCapId, profileIdFollow);

  console.log("done");
})().catch((e) => {
  console.log(e);
});
