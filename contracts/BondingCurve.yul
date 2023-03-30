object "BondingCurve" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Storage layout:
            //   0: totalSupply
            //   1: reserveBalance
            //   2: priceConstant (k)

            function increase_total_supply(value: uint256) {
                sstore(0, add(sload(0), value))
            }

            function increase_reserve_balance(value: uint256) {
                sstore(1, add(sload(1), value))
            }

            function set_price_constant(k: uint256) {
                sstore(2, k)
            }

            function price_to_mint(tokens: uint256) -> cost: uint256 {
                let k := sload(2)
                cost := mul(tokens, k)
            }

            function price_to_withdraw(tokens: uint256) -> refund: uint256 {
                let k := sload(2)
                refund := div(tokens, k)
            }

            switch calldataload(0)
            // set_price_constant(uint256)
            case 0x17d7da8e {
                let k := calldataload(4)
                set_price_constant(k)
            }
            // mint(uint256)
            case 0x40c10f19 {
                let tokens := calldataload(4)
                let cost := price_to_mint(tokens)
                if callvalue() < cost { revert(0, 0) }
                increase_reserve_balance(cost)
                increase_total_supply(tokens)
                if sub(callvalue(), cost) > 0 {
                    let success := call(gas(), caller(), 0, sub(callvalue(), cost), 0, 0, 0)
                    if iszero(success) { revert(0, 0) }
                }
            }
            // withdraw(uint256)
            case 0x2e1a7d4d {
                let tokens := calldataload(4)
                let refund := price_to_withdraw(tokens)
                increase_reserve_balance(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                increase_total_supply(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                let success := call(gas(), caller(), 0, refund, 0, 0, 0)
                if iszero(success) { revert(0, 0) }
            }
            default {
                revert(0, 0)
            }
        }
    }
}
