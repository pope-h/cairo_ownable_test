//TEST 
use snforge_std::{declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events, SpyOn, EventSpy, EventAssertions};
use ownable::IOwnableTraitDispatcher;
use ownable::IOwnableTraitDispatcherTrait;
use ownable::OwnableContract;
use starknet::ContractAddress;
use core::traits::TryInto;

fn deploy_contract (name : ByteArray) -> ContractAddress {
    let admin_address : ContractAddress = 'admin'.try_into().unwrap();
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@array![admin_address.into()]).unwrap();
    contract_address
}

#[test]
fn test_initial_data () {
    let admin_address : ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};

    let initial_data = dispatcher.get_data();
    let initial_owner = dispatcher.owner();

    assert(initial_owner == admin_address, 'incorrect admin');
    assert(initial_data == 1, 'incorrect data');
}

#[test]
fn test_set_data_works () {
    let admin_address : ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};

    cheat_caller_address(contract_address, admin_address, CheatSpan::Indefinite);
    dispatcher.set_data(6);
    let new_data = dispatcher.get_data();
    assert(new_data == 6, 'data set failed');
}

#[test]
#[should_panic(expected : ('Caller is not the owner', ))]
fn test_fake_admin_set_data_fails() {
    let fake_admin_address : ContractAddress = 'fake_admin'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};
    cheat_caller_address(contract_address, fake_admin_address, CheatSpan::Indefinite);
    dispatcher.set_data(6);
    let data_check = dispatcher.get_data();
    assert(data_check == 1, 'data set failed');
}

#[test]
fn test_transfer_ownership_works () {
    let admin_address : ContractAddress = 'admin'.try_into().unwrap();
    let new_owner_address : ContractAddress = 'new_owner'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};

    cheat_caller_address(contract_address, admin_address, CheatSpan::Indefinite);
    dispatcher.transfer_ownership(new_owner_address);
    let new_owner = dispatcher.owner();
    assert(new_owner == new_owner_address, 'ownership transfer failed');
}

#[test]
#[should_panic(expected : ('Caller is not the owner', ))]
fn test_transfer_ownership_by_fake_admin_works() {
    let fake_admin_address : ContractAddress = 'fake_admin'.try_into().unwrap();
    let new_owner_address : ContractAddress = 'new_owner'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};
    cheat_caller_address(contract_address, fake_admin_address, CheatSpan::Indefinite);
    dispatcher.transfer_ownership(new_owner_address);
    let new_owner = dispatcher.owner();
    assert(new_owner == new_owner_address, 'ownership transfer failed');
}

#[test]
fn test_event_emitted () {
    let admin_address : ContractAddress = 'admin'.try_into().unwrap();
    let new_owner_address : ContractAddress = 'new_owner'.try_into().unwrap();
    let contract_address = deploy_contract("OwnableContract");
    let dispatcher = IOwnableTraitDispatcher {contract_address};

    let mut spy = spy_events(SpyOn::One(contract_address));

    cheat_caller_address(contract_address, admin_address, CheatSpan::Indefinite);
    dispatcher.transfer_ownership(new_owner_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    OwnableContract::Event::OwnershipTransfer(
                        OwnableContract::OwnershipTransfer {prev_owner: admin_address, new_owner: new_owner_address}
                    )
                )
            ]
        );
}