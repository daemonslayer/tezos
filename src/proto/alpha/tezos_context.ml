(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2017.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

type t = Raw_context.t
type context = t

module type BASIC_DATA = sig
  type t
  include Compare.S with type t := t
  val encoding: t Data_encoding.t
  val pp: Format.formatter -> t -> unit
end

module Tez = Tez_repr
module Period = Period_repr

module Timestamp = struct
  include Time_repr
  let current = Raw_context.current_timestamp
end

include Operation_repr
module Operation = struct
  type t = operation
  include Operation_repr
end
module Block_header = Block_header_repr
module Vote = struct
  include Vote_repr
  include Vote_storage
end
module Raw_level = Raw_level_repr
module Cycle = Cycle_repr
module Script_int = Script_int_repr
module Script_timestamp = struct
  include Script_timestamp_repr
  let now ctxt =
    Raw_context.current_timestamp ctxt
    |> Timestamp.to_seconds
    |> of_int64
end
module Script = struct
  include Michelson_v1_primitives
  include Script_repr
end
type public_key = Ed25519.Public_key.t
type public_key_hash = Ed25519.Public_key_hash.t
type secret_key = Ed25519.Secret_key.t
type signature = Ed25519.Signature.t

include Tezos_hash

module Constants = struct
  include Constants_repr
  let cycle_length c =
    let constants = Raw_context.constants c in
    constants.cycle_length
  let voting_period_length c =
    let constants = Raw_context.constants c in
    constants.voting_period_length
  let time_before_reward c =
    let constants = Raw_context.constants c in
    constants.time_before_reward
  let slot_durations c =
    let constants = Raw_context.constants c in
    constants.slot_durations
  let first_free_baking_slot c =
    let constants = Raw_context.constants c in
    constants.first_free_baking_slot
  let max_signing_slot c =
    let constants = Raw_context.constants c in
    constants.max_signing_slot
  let instructions_per_transaction c =
    let constants = Raw_context.constants c in
    constants.instructions_per_transaction
  let proof_of_work_threshold c =
    let constants = Raw_context.constants c in
    constants.proof_of_work_threshold
  let dictator_pubkey c =
    let constants = Raw_context.constants c in
    constants.dictator_pubkey
  let max_number_of_operations c =
    let constants = Raw_context.constants c in
    constants.max_number_of_operations
  let max_operation_data_length c =
    let constants = Raw_context.constants c in
    constants.max_operation_data_length
end

module Delegates_pubkey = Public_key_storage

module Voting_period = Voting_period_repr

module Level = struct
  include Level_repr
  include Level_storage
end
module Contract = struct
  include Contract_repr
  include Contract_storage
end
module Roll = struct
  include Roll_repr
  include Roll_storage
end
module Nonce = Nonce_storage
module Seed = struct
  include Seed_repr
  include Seed_storage
end
module Bootstrap = Bootstrap_storage
module Reward = Reward_storage

module Fitness = struct

  include Fitness_repr
  include Fitness
  type fitness = t
  include Fitness_storage

end

let init = Init_storage.may_initialize

let finalize ?commit_message:message c =
  let fitness = Fitness.from_int64 (Fitness.current c) in
  let context = Raw_context.recover c in
  let constants = Raw_context.constants c in
  { Updater.context ; fitness ; message ; max_operations_ttl = 60 ;
    max_operation_data_length = constants.max_operation_data_length ;
    max_number_of_operations = constants.max_number_of_operations ;
  }

let configure_sandbox = Raw_context.configure_sandbox

let activate = Raw_context.activate
let fork_test_network = Raw_context.fork_test_network

let faucet_count = Raw_context.faucet_count
let incr_faucet_count = Raw_context.incr_faucet_count
