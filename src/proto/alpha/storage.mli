(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2017.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

(** Tezos Protocol Implementation - Typed storage

    This module hides the hierarchical (key x value) database under
    pre-allocated typed accessors for all persistent entities of the
    tezos context.

    This interface enforces no invariant on the contents of the
    database. Its goal is to centralize all accessors in order to have
    a complete view over the database contents and avoid key
    collisions. *)

open Storage_sigs

module Roll : sig

  (** Storage from this submodule must only be accessed through the
      module `Roll`. *)

  module Owner : Indexed_data_storage
    with type key = Roll_repr.t
     and type value = Contract_repr.t
     and type t := Raw_context.t

  val clear: Raw_context.t -> Raw_context.t Lwt.t

  (** The next roll to be allocated. *)
  module Next : Single_data_storage
    with type value = Roll_repr.t
     and type t := Raw_context.t

  (** Rolls linked lists represent both account owned and free rolls.
      All rolls belongs either to the limbo list or to an owned list. *)

  (** Head of the linked list of rolls in limbo *)
  module Limbo : Single_data_storage
    with type value = Roll_repr.t
     and type t := Raw_context.t

  (** Rolls associated to contracts, a linked list per contract *)
  module Contract_roll_list : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Roll_repr.t
     and type t := Raw_context.t

  (** Use this to iter on a linked list of rolls *)
  module Successor : Indexed_data_storage
    with type key = Roll_repr.t
     and type value = Roll_repr.t
     and type t := Raw_context.t

  (** The tez of a contract that are not assigned to rolls *)
  module Contract_change : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Tez_repr.t
     and type t := Raw_context.t

  (** Frozen rolls per cycle *)

  module Last_for_cycle : Indexed_data_storage
    with type key = Cycle_repr.t
     and type value = Roll_repr.t
     and type t := Raw_context.t

  module Owner_for_cycle : Indexed_data_storage
    with type key = Roll_repr.t
     and type value = Ed25519.Public_key_hash.t
     and type t = Raw_context.t * Cycle_repr.t

end

module Contract : sig

  (** Storage from this submodule must only be accessed through the
      module `Contract`. *)

  module Global_counter : sig
    val get : Raw_context.t -> int32 tzresult Lwt.t
    val set : Raw_context.t -> int32 -> Raw_context.t tzresult Lwt.t
    val init : Raw_context.t -> int32 -> Raw_context.t tzresult Lwt.t
  end

  (** The domain of alive contracts *)
  val fold :
    Raw_context.t ->
    init:'a -> f:(Contract_repr.t -> 'a -> 'a Lwt.t) -> 'a Lwt.t
  val list : Raw_context.t -> Contract_repr.t list Lwt.t

  (** All the tez possesed by a contract, including rolls and change *)
  module Balance : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Tez_repr.t
     and type t := Raw_context.t

  (** The manager of a contract *)
  module Manager : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Manager_repr.t
     and type t := Raw_context.t

  (** The delegate of a contract, if any. *)
  module Delegate : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Ed25519.Public_key_hash.t
     and type t := Raw_context.t

  module Spendable : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = bool
     and type t := Raw_context.t

  module Delegatable : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = bool
     and type t := Raw_context.t

  module Counter : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = int32
     and type t := Raw_context.t

  module Code : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Script_repr.expr
     and type t := Raw_context.t

  module Storage : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Script_repr.expr
     and type t := Raw_context.t

  module Code_fees : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Tez_repr.t
     and type t := Raw_context.t

  module Storage_fees : Indexed_data_storage
    with type key = Contract_repr.t
     and type value = Tez_repr.t
     and type t := Raw_context.t

end

(** Votes *)

module Vote : sig

  module Current_period_kind : Single_data_storage
    with type value = Voting_period_repr.kind
     and type t := Raw_context.t

  module Current_quorum : Single_data_storage
    with type value = int32 (* in centile of percentage *)
     and type t := Raw_context.t

  module Current_proposal : Single_data_storage
    with type value = Protocol_hash.t
     and type t := Raw_context.t

  module Listings_size : Single_data_storage
    with type value = int32 (* total number of rolls in the listing. *)
     and type t := Raw_context.t

  module Listings : Indexed_data_storage
    with type key = Ed25519.Public_key_hash.t
     and type value = int32 (* number of rolls for the key. *)
     and type t := Raw_context.t

  module Proposals : Data_set_storage
    with type elt = Protocol_hash.t * Ed25519.Public_key_hash.t
     and type t := Raw_context.t

  module Ballots : Indexed_data_storage
    with type key = Ed25519.Public_key_hash.t
     and type value = Vote_repr.ballot
     and type t := Raw_context.t

end


(** Keys *)

module Public_key : Indexed_data_storage
  with type key = Ed25519.Public_key_hash.t
   and type value = Ed25519.Public_key.t
   and type t := Raw_context.t

(** Seed *)

module Seed : sig

  (** Storage from this submodule must only be accessed through the
      module `Seed`. *)

  type nonce_status =
    | Unrevealed of {
        nonce_hash: Tezos_hash.Nonce_hash.t ;
        delegate_to_reward: Ed25519.Public_key_hash.t ;
        reward_amount: Tez_repr.t ;
      }
    | Revealed of Seed_repr.nonce

  module Nonce : Non_iterable_indexed_data_storage
    with type key := Level_repr.t
     and type value := nonce_status
     and type t := Raw_context.t

  module For_cycle : sig
    val init : Raw_context.t -> Cycle_repr.t -> Seed_repr.seed -> Raw_context.t tzresult Lwt.t
    val get : Raw_context.t -> Cycle_repr.t -> Seed_repr.seed tzresult Lwt.t
    val delete : Raw_context.t -> Cycle_repr.t -> Raw_context.t tzresult Lwt.t
  end

end

(** Rewards *)

module Rewards : sig

  module Next : Single_data_storage
    with type value = Cycle_repr.t
     and type t := Raw_context.t

  module Date : Indexed_data_storage
    with type key = Cycle_repr.t
     and type value = Time.t
     and type t := Raw_context.t

  module Amount : Indexed_data_storage
    with type key = Ed25519.Public_key_hash.t
     and type value = Tez_repr.t
     and type t = Raw_context.t * Cycle_repr.t

end
