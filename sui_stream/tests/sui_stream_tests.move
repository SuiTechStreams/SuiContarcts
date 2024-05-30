#[test_only]
module sui_stream::test {
    use sui::test_scenario;
    use sui::sui::SUI;
    use sui::coin;
    use sui::clock;
    use sui_stream::profile::{Self as profile, Profile, ProfileOwnerCap};
    use sui_stream::video::{Self as video, VideoStats};

    // === Users ===
    const USER: address = @0xab;

    #[test]
    fun test_sui_stream() {

        let mut scenario_val = test_scenario::begin(USER);
        let scenario = &mut scenario_val;

        // === Test Create Profile ===
        test_scenario::next_tx(scenario, USER);
        {
            let username = b"john doe".to_string();
            let bio = b"some bio".to_string();
            let pfp = b"some pfp".to_string();

            let profile = profile::create_profile(username, bio, pfp, test_scenario::ctx(scenario));
            transfer::public_transfer(profile, USER);
        };

        // === Test Tipping ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let coin = coin::mint_for_testing<SUI>(10, test_scenario::ctx(scenario));

            profile.tip(coin);

            assert!(profile.balance() == 10, 1);

            test_scenario::return_shared(profile);
        };  

        // === Test Withdraw Tip ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);

            let tip = profile.withdraw_tip(&profile_cap, test_scenario::ctx(scenario));
            transfer::public_transfer(tip, USER);

            assert!(profile.balance() == 0, 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Username ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let username = b"jack andi".to_string();

            profile.set_username(&profile_cap, username);

            assert!(profile.username() == b"jack andi".to_string(), 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Bio ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let bio = b"new bio..".to_string();

            profile.set_bio(&profile_cap, bio);

            assert!(profile.bio() == b"new bio..".to_string(), 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Pfp ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let pfp = b"new pfp..".to_string();

            profile.set_pfp(&profile_cap, pfp);

            assert!(profile.pfp() == b"new pfp..".to_string(), 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Create Video ===
        test_scenario::next_tx(scenario, USER);
        {
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let url = b"http://www.example.com/index.html".to_string();
            let length = 5;
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));

            let video = video::create_video(&profile_cap, url, length, &clock, test_scenario::ctx(scenario));
            transfer::public_transfer(video, USER);
            clock::destroy_for_testing(clock);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Like ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut video_stats = test_scenario::take_shared<VideoStats>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));

            video::like(&mut video_stats, &profile_cap, &clock);

            assert!(video::likes_length(&video_stats) == 1, 0);

            test_scenario::return_shared(video_stats);
            test_scenario::return_to_sender(scenario, profile_cap);
            clock::destroy_for_testing(clock);
        };

        // === Test UnLike ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut video_stats = test_scenario::take_shared<VideoStats>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);

            video::unlike(&mut video_stats, &profile_cap);

            assert!(video::likes_length(&video_stats) == 0, 0);

            test_scenario::return_shared(video_stats);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Comment ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut video_stats = test_scenario::take_shared<VideoStats>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            let text = b"nice video".to_string();

            video::comment(&mut video_stats, &profile_cap, text, &clock);

            assert!(video::comments_length(&video_stats) == 1, 0);
            assert!(video_stats.comment_id() == 1, 0);

            test_scenario::return_shared(video_stats);
            test_scenario::return_to_sender(scenario, profile_cap);
            clock::destroy_for_testing(clock);
        };

        // === Test Delete Comment ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut video_stats = test_scenario::take_shared<VideoStats>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let comment_id = video_stats.comment_id() - 1;

            video::delete_comment(&mut video_stats, &profile_cap, comment_id);
            
            assert!(video::comments_length(&video_stats) == 0, 0);

            test_scenario::return_shared(video_stats);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Delete Profile ===
        test_scenario::next_tx(scenario, USER);
        {
            let profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);

            profile::delete_profile(profile, profile_cap);

            assert!(!test_scenario::has_most_recent_for_sender<Profile>(scenario), 0)
        };

        test_scenario::end(scenario_val);

    }

}