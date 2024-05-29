import { TransactionBlock } from "@mysten/sui.js/transactions";
import { client, keypair, getId, getProfile } from "./utils.ts";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";

async function likeVideo(videoStatsId: string, profileCapId: string) {
  const tx = new TransactionBlock();

  tx.moveCall({
    arguments: [
      tx.object(videoStatsId),
      tx.object(profileCapId),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
    target: `${getId("package")}::video::like`,
  });

  const result = await client.signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: tx,
  });
  console.log("result: ", JSON.stringify(result, null, 2));
}

(async () => {
  const currentAccount = keypair.getPublicKey().toSuiAddress();

  const { profileCapId } = await getProfile(currentAccount);

  // get a Video object and than from video.stats there will be id for VideoStats
  const videStatsId =
    "0xc586dbbd022cee34d9eae417c9146115aa095d8d888de76ca41edf02fe8dfd74";

  await likeVideo(videStatsId, profileCapId);

  console.log("done");
})().catch((e) => {
  console.log(e);
});
