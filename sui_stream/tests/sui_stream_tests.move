#[test_only]
module sui_stream::test {
    use sui::test_scenario::{Self, next_tx};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui_stream::profile::{Self as profile, Profile, ProfileOwnerCap};
    use std::string::{Self, String};

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

            profile::tip(&mut profile, coin);

            assert!(profile::balance(&profile) == 10, 1);

            test_scenario::return_shared(profile);
        };  

        // === Test Withdraw Tip ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);

            let tip = profile::withdraw_tip(&mut profile, &profile_cap, test_scenario::ctx(scenario));
            transfer::public_transfer(tip, USER);

            assert!(profile::balance(&profile) == 0, 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Username ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let username = b"jack andi".to_string();

            profile::set_username(&mut profile, &profile_cap, username);

            assert!(profile::username(&profile) == b"jack andi".to_string(), 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Bio ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let bio = b"new bio..".to_string();

            profile::set_bio(&mut profile, &profile_cap, bio);

            assert!(profile::bio(&profile) == b"new bio..".to_string(), 0);

            test_scenario::return_shared(profile);
            test_scenario::return_to_sender(scenario, profile_cap);
        };

        // === Test Set Pfp ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut profile = test_scenario::take_shared<Profile>(scenario);
            let profile_cap = test_scenario::take_from_sender<ProfileOwnerCap>(scenario);
            let pfp = b"new pfp..".to_string();

            profile::set_pfp(&mut profile, &profile_cap, pfp);

            assert!(profile::pfp(&profile) == b"new pfp..".to_string(), 0);

            test_scenario::return_shared(profile);
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