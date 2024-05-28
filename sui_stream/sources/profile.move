
module sui_stream::profile {
    use std::string::String;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::table::{Self, Table};
    use sui::event;


    // === Errors ===

    const ENotOwner: u64 = 0;
    const EBalanceZero: u64 = 1;
    const EBalanceNotZero: u64 = 2;
    const EAlreadyFollowing: u64 = 3;
    const ENotFollowing: u64 = 4;


    // === Structs ===

    public struct Profile has key {
        id: UID,
        username: String,
        bio: String,
        pfp: String,
        // profile id to timestamp
        followers: Table<ID, u64>,
        follows: Table<ID, u64>,
        balance: Balance<SUI>,
        owner_cap: ID,
    }

    public struct ProfileOwnerCap has key, store{
        id: UID,
        profile_id: ID,
    }

    // === Events ===

    public struct ProfileCreated has copy, drop {
        profile_id: ID,
    }

    public struct ProfileDeleted has copy, drop {
        profile_id: ID,
    }

    public struct Followed has copy, drop {
        by: ID,
        to: ID,
    }

    public struct Unfollowed has copy, drop {
        by: ID,
        from: ID,
    }

    public struct Tipped has copy, drop {
        profile_id: ID,
        amount: u64,
    }

    public struct WithdrawTip has copy, drop {
        profile_id: ID,
        amount: u64,
    }


    // === Public-Mutative Functions ===

    public fun create_profile(username: String, bio: String, pfp: String, ctx: &mut TxContext): ProfileOwnerCap {
        let owner_id = object::new(ctx);
        let profile = Profile{
            id: object::new(ctx),
            username,
            bio,
            pfp,
            followers: table::new(ctx),
            follows: table::new(ctx),
            balance: balance::zero(),
            owner_cap: owner_id.to_inner(),
        };

        let profile_owner_cap = ProfileOwnerCap{
            id: owner_id,
            profile_id: profile.id.to_inner(),
        };

        event::emit(ProfileCreated { profile_id: profile.id.to_inner() });

        transfer::share_object(profile);
        profile_owner_cap
    }

    public fun tip(self: &mut Profile, amount: Coin<SUI>) {
        assert!(amount.value() != 0, EBalanceZero);
        event::emit(Tipped { profile_id: self.id.to_inner(), amount: amount.value() });
        self.balance.join(amount.into_balance());
    }

    // === Public-View Functions ===

    public fun isFollowing(self: &Profile, profile_id: ID): bool {
        self.follows.contains(profile_id)
    }

    public fun isFollower(self: &Profile, profile_id: ID): bool {
        self.followers.contains(profile_id)
    }

    public fun balance(self: &Profile): u64 {
        balance::value(&self.balance)
    }

    public fun username(self: &Profile): String {
        self.username
    }

    public fun bio(self: &Profile): String {
        self.bio
    }

    public fun pfp(self: &Profile): String {
        self.pfp
    }

    // === Owner Functions ===

    public fun follow(self: &mut Profile, cap: &ProfileOwnerCap, follow_to: &mut Profile, clock: &Clock) {
        assert!(self.has_access(cap), ENotOwner);
        assert!(!self.follows.contains(follow_to.id.to_inner()), EAlreadyFollowing);

        let timestamp = clock.timestamp_ms();

        self.follows.add(follow_to.id.to_inner(), timestamp);
        follow_to.followers.add(self.id.to_inner(), timestamp);

        event::emit(Followed { by: self.id.to_inner(), to: follow_to.id.to_inner() });
    }

    public fun unfollow(self: &mut Profile, cap: &ProfileOwnerCap, unfollow_from: &mut Profile) {
        assert!(self.has_access(cap), ENotOwner);

        assert!(self.follows.contains(unfollow_from.id.to_inner()), ENotFollowing);
        self.follows.remove(unfollow_from.id.to_inner());

        assert!(unfollow_from.followers.contains(self.id.to_inner()), ENotFollowing);
        unfollow_from.followers.remove(self.id.to_inner());

        event::emit(Unfollowed { by: self.id.to_inner(), from: unfollow_from.id.to_inner() });
    }

    public fun withdraw_tip(self: &mut Profile, cap: &ProfileOwnerCap, ctx: &mut TxContext): Coin<SUI> {
        assert!(self.has_access(cap), ENotOwner);
        assert!(self.balance.value() != 0, EBalanceZero);

        event::emit(WithdrawTip { profile_id: self.id.to_inner(), amount: self.balance.value() });

        coin::from_balance(self.balance.withdraw_all(), ctx)

    }

    public fun set_username(self: &mut Profile, cap: &ProfileOwnerCap, username: String) {
        assert!(self.has_access(cap), ENotOwner);
        self.username = username;
    }

    public fun set_bio(self: &mut Profile, cap: &ProfileOwnerCap, bio: String) {
        assert!(self.has_access(cap), ENotOwner);
        self.bio = bio;
    }

    public fun set_pfp(self: &mut Profile, cap: &ProfileOwnerCap, pfp: String) {
        assert!(self.has_access(cap), ENotOwner);
        self.pfp= pfp;
    }

    public fun delete_profile(self: Profile, cap: ProfileOwnerCap) {
        assert!(self.has_access(&cap), ENotOwner);
        assert!(self.balance.value() == 0, EBalanceNotZero);

        let Profile {
            id,
            username: _,
            bio: _,
            pfp: _,
            followers,
            follows,
            balance,
            owner_cap: _,
        } = self;

        event::emit(ProfileDeleted { profile_id: id.to_inner() });

        followers.drop();
        follows.drop();
        balance.destroy_zero();
        id.delete();

        let ProfileOwnerCap {id, profile_id: _} = cap;
        id.delete();
    }


    // === Public-Package Functions ===

    public(package) fun profile_id(cap: &ProfileOwnerCap): ID {
        cap.profile_id
    }

    // === Private Functions ===

    fun has_access(self: &Profile, cap: &ProfileOwnerCap): bool {
        object::id(self) == cap.profile_id
    }

}
