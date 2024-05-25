import { client, getId } from "./utils.ts";

async function listProfiles() {
  const events = await client.queryEvents({
    query: { MoveEventType: `${getId("package")}::profile::ProfileCreated` },
    // limit: 2,
    // order: "ascending",
  });

  let profiles = [];
  for (const event of events.data) {
    // @ts-ignore
    profiles.push(event.parsedJson.profile_id);
  }

  console.log(profiles);
}

(async () => {
  await listProfiles();
})().catch((e) => {
  console.log(e);
});
