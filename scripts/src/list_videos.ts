import { client, getId } from "./utils.ts";

async function listVideos() {
  const events = await client.queryEvents({
    query: { MoveEventType: `${getId("package")}::video::VideoCreated` },
    // limit: 2,
    // order: "ascending",
  });

  let videos = [];
  for (const event of events.data) {
    // @ts-ignore
    videos.push(event.parsedJson.video_id);
  }

  console.log(videos);
}

(async () => {
  await listVideos();
})().catch((e) => {
  console.log(e);
});
