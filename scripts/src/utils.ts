import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import dotenv from "dotenv";
import * as fs from "fs";

export interface IObjectInfo {
  type: string | undefined;
  id: string | undefined;
}

dotenv.config();

export const keypair = Ed25519Keypair.fromSecretKey(
  Uint8Array.from(Buffer.from(process.env.KEY!, "base64")).slice(1)
);

export const client = new SuiClient({ url: getFullnodeUrl("devnet") });

export const getId = (type: string): string | undefined => {
  try {
    const rawData = fs.readFileSync("./created.json", "utf8");
    const parsedData: IObjectInfo[] = JSON.parse(rawData);
    const typeToId = new Map(parsedData.map((item) => [item.type, item.id]));
    return typeToId.get(type);
  } catch (error) {
    console.error("Error reading the created file:", error);
  }
};

export async function getProfile(accountAddress: string) {
  const packageId = getId("package");

  const { data, hasNextPage, nextCursor } = await client.getOwnedObjects({
    owner: accountAddress,
    filter: {
      StructType: `${packageId}::profile::ProfileOwnerCap`,
    },
    options: {
      showContent: true,
      showType: true,
    },
  });

  // console.log(JSON.stringify(data[0], null, 2));

  return {
    // @ts-ignore
    profileCapId: data[0].data.objectId,
    // @ts-ignore
    profileId: data[0].data?.content.fields.profile_id,
  };
}
