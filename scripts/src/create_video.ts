import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId, getProfile } from "./utils.ts";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";

async function createVideo(profileCapId: string, url: string, length: number) {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const tx = new TransactionBlock();

  let video = tx.moveCall({
    arguments: [
      tx.object(profileCapId),
      tx.pure(url),
      tx.pure(length),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
    target: `${getId("package")}::video::create_video`,
  });

  tx.transferObjects([video], currentAccount);

  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const { profileCapId } = await getProfile(currentAccount);

  const url = "some_url";
  const length = 100;

  await createVideo(profileCapId, url, length);

  console.log("done");
})().catch((e) => {
  console.log(e);
});
