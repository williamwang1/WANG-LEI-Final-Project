 module devhub::devcard {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::event;

    const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const MIN_CARD_COST: u64 = 1;

    struct DevCard has key, store {
        id: UID,
        name: String,
        owner: address,
        title: String,
        img_url: Url,
        description: Option<String>,
        years_of_exp: u8,
        technologies: String,
        portfolio: String,
        contact: String,
        open_to_work: bool,
    }

    struct Devhub has key {
        id: UID,
        owner: address,
        counter: u64,
        cards: ObjectTable<u64, DevCard>
    }

    struct CardCreated has copy, drop {
        id: ID,
        name: String,
        owner: address,
        title: String,
        contact: String,
    }

    struct DescriptionUpadted has copy, drop {
        name: String,
        owner: address,
        new_description: String,
    }

    struct PortfolioUpadted has copy, drop {
        name: String,
        owner: address,
        new_portfolio: String,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(
            Devhub {
                id: object::new(ctx),
                owner: tx_context::sender(ctx),
                counter: 0,
                cards: object_table::new(ctx),
            }
        )
    }

    public entry fun create_card (
        name: vector<u8>,
        title: vector<u8>,
        img_url: vector<u8>,
        years_of_exp: u8,
        technologies: vector<u8>,
        portfolio: vector<u8>,
        contact: vector<u8>,
        payment: Coin<SUI>,
        devhub: &mut Devhub,
        ctx: &mut TxContext
    ) {
        // transfer coin to owner
        let value = coin::value(&payment);
        assert!(value == MIN_CARD_COST, INSUFFICIENT_FUNDS);
        transfer::public_transfer(payment, devhub.owner);

        let id = object::new(ctx);

        // object::uid_to_inner(&id)
        event::emit(
            CardCreated {
                id: object::uid_to_inner(&id),
                name: string::utf8(name),
                owner: tx_context::sender(ctx),
                title: string::utf8(title),
                contact: string::utf8(contact)
            }
        );

        //create dev card
        let card = DevCard { 
            id: id,
            name: string::utf8(name),
            owner: tx_context::sender(ctx),
            title: string::utf8(title),
            img_url: url::new_unsafe_from_bytes(img_url),
            description: option::none(),
            years_of_exp,
            technologies: string::utf8(technologies),
            portfolio: string::utf8(portfolio),
            contact: string::utf8(contact),
            open_to_work: true   
        };

        //update dev hub
        devhub.counter = devhub.counter + 1;
        object_table::add(&mut devhub.cards, devhub.counter, card);
        //emit event

    }


    public entry fun update_card_description(devhub: &mut Devhub, new_description: vector<u8>, id: u64, ctx: &mut TxContext) {
    //get card from devhub by interal id 
        let user_card = object_table::borrow_mut(&mut devhub.cards, id);
    // check whether sender is owner
        assert!(tx_context::sender(ctx) == user_card.owner, NOT_THE_OWNER);
    // update description
        let old_value = option::swap_or_fill(&mut user_card.description, string::utf8(new_description));
    // emit event
        event::emit(
            DescriptionUpadted{
                name: user_card.name,
                owner: user_card.owner,
                new_description: string::utf8(new_description)
            }
        );
        // delete old value
        _ = old_value;
    }

    public entry fun update_portfolio(devhub: &mut Devhub, new_portfolio: vector<u8>, id: u64, ctx: &mut TxContext) {
        let card = object_table::borrow_mut(&mut devhub.cards, id);
        assert!(tx_context::sender(ctx) == card.owner, NOT_THE_OWNER);
        card.portfolio = string::utf8(new_portfolio);
        event::emit(
            PortfolioUpadted{
                name: card.name,
                owner: card.owner,
                new_portfolio: string::utf8(new_portfolio)
            }
        )

    }

    public entry fun deactivate_card(devhub: &mut Devhub, id: u64, ctx: &mut TxContext) {
        let user_card = object_table::borrow_mut(&mut devhub.cards, id);
        assert!(tx_context::sender(ctx) == user_card.owner, NOT_THE_OWNER);
        user_card.open_to_work = false;
    }

    public fun get_card_info(devhub: &mut Devhub, id: u64): (
        String, 
        address,
        String,
        Url,
        Option<String>,
        u8,
        String,
        String,
        String,
        bool,
    ) {
        let card = object_table::borrow(&devhub.cards, id);
        (
            card.name,
            card.owner,
            card.title,
            card.img_url,
            card.description,
            card.years_of_exp,
            card.technologies,
            card.portfolio,
            card.contact,
            card.open_to_work
        )


        //      id: UID,
        // name: String,
        // owner: address,
        // title: String,
        // img_url: Url,
        // description: Option<String>,
        // years_of_exp: u8,
        // technologies: String,
        // portfolio: String,
        // contact: String,
        // open_to_work: bool,
    }
 }

 