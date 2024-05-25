module sui_stream::video {

    use std::string::String;
    use sui::clock::Clock;
    use sui::table::{Self, Table};
    use sui::event;

    use sui_stream::profile::{Self, ProfileOwnerCap};

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
        created_by: ID,
    }

    public struct VideoStats has key {
        id: UID,
        for_video: ID,
        views: u64,
        // profile id to timestamp
        likes: Table<ID, u64>,
        comment_id: u64,
        // comment_id to comment
        comments: Table<u64, Comment>,
        // profile id to vector of comment ids
        comments_by_profile: Table<ID, vector<u64>>,
    }

    public struct Comment has store, drop {
        by: ID,
        text: String,
        timestamp_ms: u64,
    }

    // === Events ===

    public struct VideoCreated has copy, drop {
        profile_id: ID,
        video_id: ID,
    }

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

    public fun create_video(profile_cap: &ProfileOwnerCap, url: String, length: u64, clock: &Clock, ctx: &mut TxContext): Video {
        let video_id = object::new(ctx);
        event::emit(VideoCreated { profile_id: profile::profile_id(profile_cap), video_id: video_id.to_inner() });

        let video_stats: VideoStats = VideoStats {
            id: object::new(ctx),
            for_video: video_id.to_inner(),
            views: 0,
            likes: table::new(ctx),
            comment_id: 0,
            comments: table::new(ctx),
            comments_by_profile: table::new(ctx),
        };


        let video = Video {
            id: video_id,
            stats: video_stats.id.to_inner(),
            url,
            length,
            timestamp_ms: clock.timestamp_ms(),
            created_by: profile::profile_id(profile_cap),
        };

        transfer::share_object(video_stats);

        video
    }

    public fun like(video_stats: &mut VideoStats, profile_cap: &ProfileOwnerCap, clock: &Clock) {
        let profile_id = profile::profile_id(profile_cap);

        assert!(!video_stats.likes.contains(profile_id), EAlreadyLiked);

        let timestamp = clock.timestamp_ms();
        video_stats.likes.add(profile_id, timestamp);

        event::emit(VideoLiked { profile_id, video_id: video_stats.for_video });
    }

    public fun unlike(video_stats: &mut VideoStats, profile_cap: &ProfileOwnerCap) {
        let profile_id = profile::profile_id(profile_cap);

        assert!(video_stats.likes.contains(profile_id), ENotLiked);
        video_stats.likes.remove(profile_id);

        event::emit(VideoUnliked { profile_id, video_id: video_stats.for_video });
    }

    public fun comment(video_stats: &mut VideoStats, profile_cap: &ProfileOwnerCap, text: String, clock: &Clock) {
        let profile_id = profile::profile_id(profile_cap);

        video_stats.comments.add(
            video_stats.comment_id,
            Comment { by: profile_id, text, timestamp_ms: clock.timestamp_ms() }
        );

        if (!video_stats.comments_by_profile.contains(profile_id)) {
            video_stats.comments_by_profile.add(profile_id, vector::empty());
        };

        let mut comments = video_stats.comments_by_profile[profile_id];
        comments.push_back(video_stats.comment_id);

        event::emit(VideoCommented { profile_id, video_id: video_stats.for_video, comment_id: video_stats.comment_id });

        video_stats.comment_id = video_stats.comment_id + 1;
    }

    public fun delete_comment(video_stats: &mut VideoStats, profile_cap: &ProfileOwnerCap, comment_id: u64) {
        let profile_id = profile::profile_id(profile_cap);

        assert!(video_stats.comments.contains(comment_id), ECommentNotFound);

        video_stats.comments.remove(comment_id);

        let mut comments = video_stats.comments_by_profile[profile_id];
        let (found, index) = comments.index_of(&comment_id);
        assert!(found, ECommentNotFound);
        comments.remove(index);

        event::emit(VideoCommentDeleted { profile_id, video_id: video_stats.for_video, comment_id });
    }


} 