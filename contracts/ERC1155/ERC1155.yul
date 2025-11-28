// SPDX-License-Identifier: MIT
// Minimal ERC-1155-style multi-token in pure Yul.
// WARNING: Experimental / not audited / not spec-complete.
// No receiver acceptance checks; for learning & experiments only.

object "ERC1155Yul" {
    // Deployment code: set owner, install runtime
    code {
        // Store deployer as owner at storage slot 2
        sstore(2, caller())

        // Copy runtime code into memory and return it
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }

    // Runtime object
    object "Runtime" {
        code {
            // ─────────────────────────────────────────────────────────────
            // Storage layout
            // slot 0: mapping(uint256 => mapping(address => uint256)) balances
            // slot 1: mapping(address => mapping(address => bool))   operatorApprovals
            // slot 2: address owner
            // ─────────────────────────────────────────────────────────────

            // Utility: revert with no data
            function _revertEmpty() {
                revert(0, 0)
            }

            // Utility: load balances[id][account]
            function _balanceOf(account, id) -> bal {
                // inner = keccak256(abi.encode(id, balances.slot=0))
                mstore(0x00, id)
                mstore(0x20, 0)
                let inner := keccak256(0x00, 0x40)

                // slot = keccak256(abi.encode(account, inner))
                mstore(0x00, account)
                mstore(0x20, inner)
                let slot := keccak256(0x00, 0x40)

                bal := sload(slot)
            }

            // Utility: set balances[id][account] = newBal
            function _setBalance(account, id, newBal) {
                mstore(0x00, id)
                mstore(0x20, 0)
                let inner := keccak256(0x00, 0x40)

                mstore(0x00, account)
                mstore(0x20, inner)
                let slot := keccak256(0x00, 0x40)

                sstore(slot, newBal)
            }

            // Utility: get operator approval: operatorApprovals[owner][operator]
            function _isApproved(owner, operator) -> ok {
                mstore(0x00, owner)
                mstore(0x20, 1)          // operatorApprovals.slot = 1
                let inner := keccak256(0x00, 0x40)

                mstore(0x00, operator)
                mstore(0x20, inner)
                let slot := keccak256(0x00, 0x40)

                ok := sload(slot)
            }

            // Utility: set operator approval
            function _setApproved(owner, operator, approved) {
                mstore(0x00, owner)
                mstore(0x20, 1)
                let inner := keccak256(0x00, 0x40)

                mstore(0x00, operator)
                mstore(0x20, inner)
                let slot := keccak256(0x00, 0x40)

                sstore(slot, approved)
            }

            // Core transfer for one id
            function _transferSingle(from, to, id, amount) {
                // load from balance
                let fromBal := _balanceOf(from, id)
                if lt(fromBal, amount) {
                    // revert on underflow
                    _revertEmpty()
                }

                // write from balance
                let newFrom := sub(fromBal, amount)
                _setBalance(from, id, newFrom)

                // load to balance
                let toBal := _balanceOf(to, id)
                let newTo := add(toBal, amount)
                _setBalance(to, id, newTo)
            }

            // Owner-only modifier: require caller == owner (slot 2)
            function _onlyOwner() {
                if iszero(eq(caller(), sload(2))) {
                    _revertEmpty()
                }
            }

            // ─────────────────────────────────────────────────────────────
            // Function dispatch
            // ─────────────────────────────────────────────────────────────

            // If no calldata, just revert
            if iszero(calldatasize()) { _revertEmpty() }

            // Load function selector (first 4 bytes of calldata)
            let sig := shr(224, calldataload(0))

            // ERC-1155 selectors (standard)
            // balanceOf(address,uint256)                         -> 0x00fdd58e
            // balanceOfBatch(address[],uint256[])                -> 0x4e1273f4
            // setApprovalForAll(address,bool)                    -> 0xa22cb465
            // isApprovedForAll(address,address)                  -> 0xe985e9c5
            // safeTransferFrom(address,address,uint256,uint256,bytes)         -> 0xf242432a
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)-> 0x2eb2c2d6
            // mint(address,uint256,uint256) (custom helper)      -> 0x40c10f19 (same selector as ERC20 mint, different semantics)
            // batchMint(address,uint256[],uint256[]) (custom)    -> 0xc3d0f6f1  (chosen arbitrary)

            switch sig
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                // account at calldata[4:36], id at [36:68]
                if lt(calldatasize(), 68) { _revertEmpty() }

                let account := shr(96, calldataload(4))
                let id := calldataload(36)

                let bal := _balanceOf(account, id)

                mstore(0x00, bal)
                return(0x00, 0x20)
            }

            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                // calldata layout (standard ABI):
                // 0x04: offset to accounts array (A)
                // 0x24: offset to ids array (B)
                if lt(calldatasize(), 0x44) { _revertEmpty() }

                let offsAccounts := calldataload(0x04)
                let offsIds := calldataload(0x24)

                // Pointers to array headers
                let ptrAccounts := add(0x04, offsAccounts)
                let ptrIds := add(0x04, offsIds)

                // len at arrPtr
                if or(lt(calldatasize(), add(ptrAccounts, 0x20)), lt(calldatasize(), add(ptrIds, 0x20))) {
                    _revertEmpty()
                }

                let len := calldataload(ptrAccounts)
                if iszero(eq(len, calldataload(ptrIds))) {
                    _revertEmpty()
                }

                // Output array in memory
                // [0x00..0x1f] length
                // [0x20..]     elements
                mstore(0x00, len)
                let outPtr := 0x20

                // accounts elements start at ptrAccounts + 0x20
                // ids elements start at ptrIds + 0x20
                let accBase := add(ptrAccounts, 0x20)
                let idsBase := add(ptrIds, 0x20)

                for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                    // account is address in lower 20 bytes of 32 bytes
                    let acc := shr(96, calldataload(add(accBase, mul(i, 0x20))))
                    let id := calldataload(add(idsBase, mul(i, 0x20)))

                    let bal := _balanceOf(acc, id)
                    mstore(add(outPtr, mul(i, 0x20)), bal)
                }

                return(0x00, add(0x20, mul(len, 0x20)))
            }

            // setApprovalForAll(address operator, bool approved)
            case 0xa22cb465 {
                if lt(calldatasize(), 0x44) { _revertEmpty() }

                let owner := caller()
                let operator := shr(96, calldataload(0x04))
                let approved := iszero(iszero(calldataload(0x24))) // normalize to 0 or 1

                // disallow self-approve
                if eq(owner, operator) { _revertEmpty() }

                _setApproved(owner, operator, approved)

                // No return data (bool in standard but can be omitted; here we just return nothing)
                mstore(0x00, 1)
                return(0x00, 0x20)
            }

            // isApprovedForAll(address account, address operator)
            case 0xe985e9c5 {
                if lt(calldatasize(), 0x44) { _revertEmpty() }

                let account := shr(96, calldataload(0x04))
                let operator := shr(96, calldataload(0x24))

                let ok := _isApproved(account, operator)
                // ok is 0 or 1
                mstore(0x00, ok)
                return(0x00, 0x20)
            }

            // safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
            case 0xf242432a {
                // calldata:
                // 0x04: from
                // 0x24: to
                // 0x44: id
                // 0x64: amount
                // 0x84: offset to data
                if lt(calldatasize(), 0x84) { _revertEmpty() }

                let from := shr(96, calldataload(0x04))
                let to := shr(96, calldataload(0x24))
                let id := calldataload(0x44)
                let amount := calldataload(0x64)

                // auth: caller is from or approved
                let sender := caller()
                if iszero(or(eq(sender, from), _isApproved(from, sender))) {
                    _revertEmpty()
                }

                // disallow zero to
                if iszero(to) { _revertEmpty() }

                _transferSingle(from, to, id, amount)

                // No events emitted here (pure Yul version, minimal)
                // Return nothing
                return(0, 0)
            }

            // safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data)
            case 0x2eb2c2d6 {
                // 0x04: from
                // 0x24: to
                // 0x44: offset ids
                // 0x64: offset amounts
                if lt(calldatasize(), 0x64) { _revertEmpty() }

                let from := shr(96, calldataload(0x04))
                let to := shr(96, calldataload(0x24))
                let offsIds := calldataload(0x44)
                let offsAmounts := calldataload(0x64)

                if iszero(to) { _revertEmpty() }

                let sender := caller()
                if iszero(or(eq(sender, from), _isApproved(from, sender))) {
                    _revertEmpty()
                }

                let idsPtr := add(0x04, offsIds)
                let amtsPtr := add(0x04, offsAmounts)

                if or(lt(calldatasize(), add(idsPtr, 0x20)), lt(calldatasize(), add(amtsPtr, 0x20))) {
                    _revertEmpty()
                }

                let len := calldataload(idsPtr)
                if iszero(eq(len, calldataload(amtsPtr))) {
                    _revertEmpty()
                }

                let idsBase := add(idsPtr, 0x20)
                let amtsBase := add(amtsPtr, 0x20)

                for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                    let id := calldataload(add(idsBase, mul(i, 0x20)))
                    let amount := calldataload(add(amtsBase, mul(i, 0x20)))

                    _transferSingle(from, to, id, amount)
                }

                return(0, 0)
            }

            // mint(address to, uint256 id, uint256 amount) -- owner only
            case 0x40c10f19 {
                if lt(calldatasize(), 0x64) { _revertEmpty() }
                _onlyOwner()

                let to := shr(96, calldataload(0x04))
                let id := calldataload(0x24)
                let amount := calldataload(0x44)

                if iszero(to) { _revertEmpty() }

                let bal := _balanceOf(to, id)
                let newBal := add(bal, amount)
                _setBalance(to, id, newBal)

                return(0, 0)
            }

            // batchMint(address to, uint256[] ids, uint256[] amounts) -- owner only
            case 0xc3d0f6f1 {
                if lt(calldatasize(), 0x64) { _revertEmpty() }
                _onlyOwner()

                let to := shr(96, calldataload(0x04))
                if iszero(to) { _revertEmpty() }

                let offsIds := calldataload(0x24)
                let offsAmts := calldataload(0x44)

                let idsPtr := add(0x04, offsIds)
                let amtsPtr := add(0x04, offsAmts)

                if or(lt(calldatasize(), add(idsPtr, 0x20)), lt(calldatasize(), add(amtsPtr, 0x20))) {
                    _revertEmpty()
                }

                let len := calldataload(idsPtr)
                if iszero(eq(len, calldatasize(), calldataload(amtsPtr))) {
                    // slight cheat: we only check equal lengths;
                    // but to keep code short, we won't fully re-validate all offsets here
                }

                if iszero(eq(len, calldataload(amtsPtr))) {
                    _revertEmpty()
                }

                let idsBase := add(idsPtr, 0x20)
                let amtsBase := add(amtsPtr, 0x20)

                for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                    let id := calldataload(add(idsBase, mul(i, 0x20)))
                    let amount := calldataload(add(amtsBase, mul(i, 0x20)))

                    let bal := _balanceOf(to, id)
                    let newBal := add(bal, amount)
                    _setBalance(to, id, newBal)
                }

                return(0, 0)
            }

            // Fallback: revert
            default {
                _revertEmpty()
            }
        }
    }
}
