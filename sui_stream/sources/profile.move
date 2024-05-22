
module sui_stream::profile {
    use std::string::String;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
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
        followers: vector<ID>, // change to some dynamic structure (LinkedTable?)
        follows:vector<ID>, // change to some dynamic structure (LinkedTable?)
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

    public struct Followed has copy, drop {
        by: ID,
        to: ID,
    }

    public struct Unfollowed has copy, drop {
        by: ID,
        from: ID,
    }


    // === Public-Mutative Functions ===

    public fun create_profile(username: String, bio: String, pfp: String, ctx: &mut TxContext): ProfileOwnerCap {
        let owner_id = object::new(ctx);
        let profile = Profile{
            id: object::new(ctx),
            username,
            bio,
            pfp,
            followers: vector::empty(),
            follows: vector::empty(),
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
        self.balance.join(amount.into_balance());
    }


    // === Owner Functions ===

    public fun follow(self: &mut Profile, cap: &ProfileOwnerCap, follow_to: &mut Profile) {
        assert!(self.has_access(cap), ENotOwner);

        assert!(!self.follows.contains(&follow_to.id.to_inner()), EAlreadyFollowing);

        self.follows.push_back(follow_to.id.to_inner());
        follow_to.followers.push_back(self.id.to_inner());

        event::emit(Followed { by: self.id.to_inner(), to: follow_to.id.to_inner() });
    }

    public fun unfollow(self: &mut Profile, cap: &ProfileOwnerCap, unfollow_from: &mut Profile) {
        assert!(self.has_access(cap), ENotOwner);

        let (contains, index) = self.follows.index_of(&unfollow_from.id.to_inner());
        assert!(contains, ENotFollowing);
        self.follows.swap_remove(index);

        let (contains, index) = self.follows.index_of(&unfollow_from.id.to_inner());
        assert!(contains, ENotFollowing);
        unfollow_from.followers.swap_remove(index);

        event::emit(Unfollowed { by: self.id.to_inner(), from: unfollow_from.id.to_inner() });
    }

    public fun withdraw_tip(self: &mut Profile, cap: &ProfileOwnerCap, ctx: &mut TxContext): Coin<SUI> {
        assert!(self.has_access(cap), ENotOwner);

        assert!(self.balance.value() != 0, EBalanceZero);

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

    public fun set_pfpl(self: &mut Profile, cap: &ProfileOwnerCap, pfp: String) {
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
            followers: _,
            follows: _,
            balance,
            owner_cap: _,
        } = self;

        balance.destroy_zero();
        id.delete();

        let ProfileOwnerCap {id, profile_id: _} = cap;
        id.delete();
    }


    // === Private Functions ===

    fun has_access(self: &Profile, cap: &ProfileOwnerCap): bool {
        object::id(self) == cap.profile_id
    }

}
