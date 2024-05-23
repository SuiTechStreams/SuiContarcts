module sui_stream::video {

    use std::string::String;
    use sui::clock::Clock;
    use sui::linked_table::{Self, LinkedTable};
    use sui::event;

    use sui_stream::profile::{Profile, ProfileOwnerCap};

    // === Errors ===

    const EAlreadyLiked: u64 = 0;
    const ENotLiked: u64 = 1;
    const ECommentNotFound: u64 = 2;

    // === Structs ===

    public struct Video has key, store {
        id: UID,
        stats: ID,
        url: String,
        length: u64,
        timestamp_ms: u64,
        created_by: address,
    }

    public struct VideoStats has key {
        id: UID,
        for_video: ID,
        views: u64,
        // profile id to timestamp
        likes: LinkedTable<ID, u64>,
        comment_id: u64,
        // comment_id to comment
        comments: LinkedTable<u64, Comment>,
        comments_by_profile: LinkedTable<ID, vector<u64>>,
    }

    public struct Comment has store, drop {
        by: ID,
        text: String,
        timestamp_ms: u64,
    }

    // === Events ===

    public struct VideoLiked has copy, drop {
        profile_id: ID,
        video_id: ID,
    }

    public struct VideoUnliked has copy, drop {
        profile_id: ID,
        video_id: ID,
    }

    public struct VideoCommented has copy, drop {
        profile_id: ID,
        video_id: ID,
        comment_id: u64,
    }

    public struct VideoCommentDeleted has copy, drop {
        profile_id: ID,
        video_id: ID,
        comment_id: u64,
    }


    // === Public-Mutative Functions ===

    public fun create_video(url: String, length: u64, clock: &Clock, ctx: &mut TxContext): Video {
        let video_id = object::new(ctx);

        let video_stats: VideoStats = VideoStats {
            id: object::new(ctx),
            for_video: video_id.to_inner(),
            views: 0,
            likes: linked_table::new(ctx),
            comment_id: 0,
            comments: linked_table::new(ctx),
            comments_by_profile: linked_table::new(ctx),
        };


        let video = Video {
            id: video_id,
            stats: video_stats.id.to_inner(),
            url,
            length,
            timestamp_ms: clock.timestamp_ms(),
            created_by: ctx.sender(),
        };

        transfer::share_object(video_stats);

        video
    }

    public fun like(profile: &Profile, profile_cap: &ProfileOwnerCap, video_stats: &mut VideoStats, clock: &Clock) {
        profile.assert_has_access(profile_cap);

        assert!(!video_stats.likes.contains(object::id(profile)), EAlreadyLiked);

        let timestamp = clock.timestamp_ms();
        video_stats.likes.push_back(object::id(profile), timestamp);

        event::emit(VideoLiked { profile_id: object::id(profile), video_id: video_stats.for_video });
    }

    public fun unlike(profile: &Profile, profile_cap: &ProfileOwnerCap, video_stats: &mut VideoStats) {
        profile.assert_has_access(profile_cap);

        assert!(video_stats.likes.contains(object::id(profile)), ENotLiked);
        video_stats.likes.remove(object::id(profile));

        event::emit(VideoUnliked { profile_id: object::id(profile), video_id: video_stats.for_video });
    }

    public fun comment(profile: &Profile, profile_cap: &ProfileOwnerCap, video_stats: &mut VideoStats, text: String, clock: &Clock) {
        profile.assert_has_access(profile_cap);

        video_stats.comments.push_back(
            video_stats.comment_id,
            Comment { by: object::id(profile), text, timestamp_ms: clock.timestamp_ms() }
        );

        let profile_id = object::id(profile);

        if (!video_stats.comments_by_profile.contains(profile_id)) {
            video_stats.comments_by_profile.push_back(profile_id, vector::empty());
        };

        let mut comments = video_stats.comments_by_profile[profile_id];
        comments.push_back(video_stats.comment_id);

        event::emit(VideoCommented { profile_id, video_id: video_stats.for_video, comment_id: video_stats.comment_id });

        video_stats.comment_id = video_stats.comment_id + 1;
    }

    public fun delete_comment(profile: &Profile, profile_cap: &ProfileOwnerCap, comment_id: u64, video_stats: &mut VideoStats) {
        profile.assert_has_access(profile_cap);

        assert!(video_stats.comments.contains(comment_id), ECommentNotFound);

        video_stats.comments.remove(comment_id);

        let profile_id = object::id(profile);

        let mut comments = video_stats.comments_by_profile[profile_id];
        let (found, index) = comments.index_of(&comment_id);
        assert!(found, ECommentNotFound);
        comments.remove(index);

        event::emit(VideoCommentDeleted { profile_id, video_id: video_stats.for_video, comment_id });
    }


} 