use array::ArrayTrait;
use traits::Into;
use traits::TryInto;

trait Serde<T> {
    fn serialize(ref serialized: Array::<felt>, input: T);
    fn deserialize(ref serialized: Array::<felt>) -> Option::<T>;
}

impl FeltSerde of Serde::<felt> {
    fn serialize(ref serialized: Array::<felt>, input: felt) {
        serialized.append(input);
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<felt> {
        serialized.pop_front()
    }
}

impl BoolSerde of Serde::<bool> {
    fn serialize(ref serialized: Array::<felt>, input: bool) {
        Serde::<felt>::serialize(ref serialized, if input {
            1
        } else {
            0
        });
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<bool> {
        Option::Some(Serde::<felt>::deserialize(ref serialized)? != 0)
    }
}

impl U8Serde of Serde::<u8> {
    fn serialize(ref serialized: Array::<felt>, input: u8) {
        Serde::<felt>::serialize(ref serialized, input.into());
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<u8> {
        Option::Some((Serde::<felt>::deserialize(ref serialized)?.try_into())?)
    }
}

impl U32Serde of Serde::<u32> {
    fn serialize(ref serialized: Array::<felt>, input: u32) {
        Serde::<felt>::serialize(ref serialized, input.into());
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<u32> {
        Option::Some((Serde::<felt>::deserialize(ref serialized)?.try_into())?)
    }
}

impl U64Serde of Serde::<u64> {
    fn serialize(ref serialized: Array::<felt>, input: u64) {
        Serde::<felt>::serialize(ref serialized, input.into());
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<u64> {
        Option::Some((Serde::<felt>::deserialize(ref serialized)?.try_into())?)
    }
}

impl U128Serde of Serde::<u128> {
    fn serialize(ref serialized: Array::<felt>, input: u128) {
        Serde::<felt>::serialize(ref serialized, input.into());
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<u128> {
        Option::Some((Serde::<felt>::deserialize(ref serialized)?.try_into())?)
    }
}

impl U256Serde of Serde::<u256> {
    fn serialize(ref serialized: Array::<felt>, input: u256) {
        Serde::<u128>::serialize(ref serialized, input.low);
        Serde::<u128>::serialize(ref serialized, input.high);
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<u256> {
        Option::Some(
            u256 {
                low: Serde::<u128>::deserialize(ref serialized)?,
                high: Serde::<u128>::deserialize(ref serialized)?,
            }
        )
    }
}

impl ArrayFeltSerde of Serde::<Array::<felt>> {
    fn serialize(ref serialized: Array::<felt>, mut input: Array::<felt>) {
        Serde::<usize>::serialize(ref serialized, input.len());
        serialize_array_felt_helper(ref serialized, ref input);
    }
    fn deserialize(ref serialized: Array::<felt>) -> Option::<Array::<felt>> {
        let length = Serde::<felt>::deserialize(ref serialized)?;
        let mut arr = ArrayTrait::new();
        deserialize_array_felt_helper(ref serialized, arr, length)
    }
}

fn serialize_array_felt_helper(ref serialized: Array::<felt>, ref input: Array::<felt>) {
    // TODO(orizi): Replace with simple call once inlining is supported.
    match try_fetch_gas() {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('Out of gas');
            panic(data);
        },
    }
    match input.pop_front() {
        Option::Some(value) => {
            Serde::<felt>::serialize(ref serialized, value);
            serialize_array_felt_helper(ref serialized, ref input);
        },
        Option::None(_) => {},
    }
}

fn deserialize_array_felt_helper(
    ref serialized: Array::<felt>, mut curr_output: Array::<felt>, remaining: felt
) -> Option::<Array::<felt>> {
    // TODO(orizi): Replace with simple call once inlining is supported.
    match try_fetch_gas() {
        Option::Some(_) => {},
        Option::None(_) => {
            let mut data = ArrayTrait::new();
            data.append('Out of gas');
            panic(data);
        },
    }
    if remaining == 0 {
        return Option::<Array::<felt>>::Some(curr_output);
    }
    curr_output.append(Serde::<felt>::deserialize(ref serialized)?);
    deserialize_array_felt_helper(ref serialized, curr_output, remaining - 1)
}
