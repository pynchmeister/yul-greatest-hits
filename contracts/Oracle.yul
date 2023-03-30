object "Oracle" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Storage layout:
            // Mapping of key-value pairs:
            //   keccak256(key) => value

            function set_value(key: uint256, value: uint256) {
                sstore(keccak256(key, 32), value)
            }

            function get_value(key: uint256) -> value: uint256 {
                value := sload(keccak256(key, 32))
            }

            switch calldataload(0)
            // set_value(uint256, uint256)
            case 0x7a2a1e52 {
                let key := calldataload(4)
                let value := calldataload(36)
                set_value(key, value)
            }
            // get_value(uint256)
            case 0x20965255 {
                let key := calldataload(4)
                let value := get_value(key)
                mstore(0, value)
                return(0, 32)
            }
            default {
                revert(0, 0)
            }
        }
    }
}
