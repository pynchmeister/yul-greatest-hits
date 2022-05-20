object "ERC721Y" {
    code {
        // owner ~ creator                                  slot:0
        sstore(0, caller())
        // collection name                                  slot:1
        sstore(1, "myName")
        // collection symbol                                slot:2
        sstore(2, "mySymbol")
        // token counter ~ tokenId                          slot:3
        sstore(3, 1)
        // Mapping from account to operator approvals       slot:4
        // (address => mapping(address => bool))

        // Mapping tokenId to approved address              slot:5

        // Mapping from owner address to balance            slot:6

        // array of owner addresses (index ~ tokenId)       slot:7...5008
        sstore(7, 5000)

        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return (0, datasize("runtime"))
    }

    object "runtime" {
        code {
            switch selector()
                case 0x26092b83 /* publicMint() */ {
                    safeMint(caller())
                    checkValue()
                    checkIfCallerIsContract()
                }
                case 0xde6892c8 /* publicMint(bytes data) */ {
                    safeMint2(caller(), decodeAsBytes(0))
                    checkValue()
                    checkIfCallerIsContract()
                }
                case 0x70a08231 /* balanceOf(address owner) */ {
                    return256(balanceOf(decodeAsAddress(0)))
                }
                case 0x6352211e /* ownerOf(uint256 tokenId) */ {
                    return256(ownerOf(decodeAsUint(0)))
                }
                case 0x42842e0e /* safeTransferFrom(address from, address to, uint256 tokenId) */ {
                    _safeTransfer(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), "")
                }
                case 0xb88d4fde /* safeTransferFrom(address from, address to, uint256 tokenId, bytes data) */ {
                    _safeTransfer(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsBytes(3))
                }
                case 0x23b872dd /* transferFrom(address from, address to, uint256 tokenId) */ {
                    _transfer(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
                }
                case 0x095ea7b3 /* approve(address to, uint256 tokenId) */ {
                    approve(decodeAsAddress(0), decodeAsUint(1))
                }
                case 0xa22cb465 /* setApprovalForAll(address operator, bool _approved) */ {
                    setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
                }
                case 0x081812fc /* getApproved(uint256 tokenId) */ {
                    return256(getApproved(decodeAsUint(0)))
                }
                case 0xe985e9c5 /* isApprovedForAll(address owner, address operator) */ {
                    return256(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))  
                }
                case 0xd082e381 /* tokenCounter() */ {
                    return256(read_tokenCounter())
                }
                case 0x06fdde03 /* name() */ {
                    return256(read_name())
                }
                case 0x95d89b41 /* symbol() */ {
                    return256(read_symbol())
                }
                case 0x8da5cb5b /* owner() */ {
                    return256(read_owner())
                }
                default {
                    revert256("invalid function selector")
                }


            /* ---------- calldata decoding ----------- */

            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
            

            function decodeAsAddress(_offset) -> _v {
                _v := decodeAsUint(_offset)
                if iszero(iszero(and(_v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert256("argument not address")
                }
            }


            function decodeAsUint(_offset) -> _v {
                let _pos := add(4, mul(_offset, 0x20))
                if lt(calldatasize(), add(_pos, 0x20)) {
                    revert256("argument out of bounds")
                }
                _v := calldataload(_pos)
            }


            function decodeAsBytes(_offset) -> _memPos {
                let _pos := add(4, mul(_offset, 0x20))
                let _size := sub(calldataload(_pos), 0x20)
                _memPos := 0x80
                calldatacopy(_memPos, add(_pos, 0x20), add(_pos, _size))
                // in this contract we dont need to allocate the free memory pointer at 0x40
                // since we never leave the mem scratch space except for this functioon
            }


            /* ---------- calldata encoding ---------- */

            function return256(_v) {
                mstore(0, _v)
                return (0, 0x20)
            }


            function revert256(_v) {
                mstore(0, _v)
                revert (0, 0x20)
            }


            /* -------- events ---------- */

            function emitTransfer(_from, _to, _tokenId) {
                //Transfer(address from,address to,uint256 tokenId)
                log4(0x0, 0x0, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, _from, _to, _tokenId)
            }


            function emitApproval(_owner, _to, _tokenId){
                //Approval(address owner,address to,uint256 tokenId)
                log4(0x0, 0x0,0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, _owner, _to, _tokenId)
            }


            function emitApprovalForAll(_owner, _operator, _approved){
                //ApprovalForAll(address owner, address operator, data[bool approved])
                mstore(0x0, _approved)
                log3(0x0, 0x20,0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31, _owner, _operator)
            }

    
            /* -------- storage access ---------- */

            function read_owner() -> _o {
                _o := sload(0)
            }


            function read_name() -> _n {
                _n := sload(1)
            }


            function read_symbol() -> _s {
                _s := sload(2)
            }


            function increase_tokenCounter() {
                sstore(3, add(read_tokenCounter(), 0x01))
            }


            function read_tokenCounter() -> _t {
                _t := sload(3)
            }


            function write_mapping(_slot, _key, _value) {
                mstore(0x0, _key)
                mstore(0x20, _slot)
                sstore(keccak256(0x0, 0x40), _value)
            }


            function read_mapping(_slot, _key) -> _value {
                mstore(0x0, _key)
                mstore(0x20, _slot)
                _value := sload(keccak256(0x0, 0x40))
            }


            function read_ownerAddressToOperatorApprovals(_operator, _owner) -> _approved {
                mstore(0x0, _operator)
                mstore(0x20, 5)

                mstore(0x20, keccak256(0x0, 0x40))
                mstore(0x0, _owner)

                _approved := sload(keccak256(0x0, 0x40))
            }


            function write_ownerAddressToOperatorApprovals(_owner, _operator, _approved) {
                mstore(0x0, _operator)
                mstore(0x20, 5)

                mstore(0x20, keccak256(0x0, 0x40))
                mstore(0x0, _owner)

                sstore(keccak256(0x0, 0x40), _approved)
            }


            function read_tokenIdToApprovedAddress(_tokenId) -> _approvedAddress {
                _approvedAddress := read_mapping(5, _tokenId)
            }


            function write_tokenIdToApprovedAddress(_tokenId, _owner) {
                write_mapping(5, _tokenId, _owner)
            }


            function read_ownerAddressToBalance(_owner) -> _balance {
                _balance := read_mapping(6, _owner)
            }


            function write_ownerAddressToBalance(_owner, _balance) {
                write_mapping(6, _owner, _balance)
            }


            function read_ownerships(_tokenId) -> _owner {
                _owner := sload(add(8, _tokenId)) // slot 7 contains the length
            }


            function write_ownerships(_tokenId, _owner) {
                sstore(add(8, _tokenId), _owner)
            }


            /* -------- utils ---------- */

            function checkValue(){
                if lt(callvalue(), 500000000000000000) {
                    revert256("value below price")
                }
            }


            function checkIfCallerIsContract(){
                if iszero(eq(caller(), origin())) {
                    revert256("caller is contract")
                }
            }


            /* -------- erc721 logic ---------- */

            /**
             * @dev Returns the number of tokens in ``owner``'s account.
             */
            function balanceOf(_owner) -> _balance {
                _balance := read_ownerAddressToBalance(_owner)
                if eq(_owner, 0) {
                    revert256("zero address given")
                }
            }


            /**
             * @dev Returns the owner of the `tokenId` token.
             */
            function ownerOf(_tokenId) -> _owner {
                _owner := read_ownerships(_tokenId)
                if eq(_owner, 0) {
                    revert256("token not minted yet")
                }
            }


            /**
             * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
             * are aware of the ERC721 protocol to prevent tokens from being forever locked.
             */
            function _safeTransfer(_from, _to, _tokenId, _data) {
                _transfer(_from, _to, _tokenId)
                let _isReceiver := _checkOnERC721Received(_from, _to, _tokenId, _data)
                if iszero(_isReceiver) {
                    revert256("no valid receiver")
                }
            }

            
            /**
             * @dev Transfers `tokenId` from `from` to `to`.
             *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
             */
            function _transfer(_from, _to, _tokenId) {
                if iszero(_isApprovedOrOwner(caller(), _tokenId)){
                    revert(0, 0)
                }
                let _owner := ownerOf(_tokenId)
                _approve(0, _tokenId)
                write_ownerAddressToBalance(_from, sub(read_ownerAddressToBalance(_from), 0x01))
                write_ownerAddressToBalance(_to, add(read_ownerAddressToBalance(_to), 0x01))
                write_ownerships(_tokenId, _to)
                emitTransfer(_from, _to, _tokenId)
                if or(eq(_owner, 0), eq(_to, 0)) {
                    revert(0, 0)
                }
            }


            /**
            * @dev Gives permission to `to` to transfer `tokenId` token to another account.
            * The approval is cleared when the token is transferred.
            * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
            */
            function approve(_to, _tokenId) {
                let _owner := ownerOf(_tokenId)
                let _isApprovedForAll := read_ownerAddressToOperatorApprovals(_owner, caller())
                _approve(_to, _tokenId)

                if iszero(or(eq(_owner, caller()), _isApprovedForAll)) {
                    revert256("caller not authorized")
                }
                if eq(_to, _owner) {
                    revert256("cant approve owner")
                }
            }


            /**
            * @dev Approve `to` to operate on `tokenId`
            * Emits a {Approval} event.
            */
            function _approve(_to, _tokenId) {
                let _owner := ownerOf(_tokenId)

                write_tokenIdToApprovedAddress(_tokenId, _to)

                emitApproval(_owner, _to, _tokenId)
            }


            /**
            * @dev Approve or remove `operator` as an operator for the caller.
            * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
            */
            function setApprovalForAll(_operator, _approved) {
                let _owner := caller()
                write_ownerAddressToOperatorApprovals(_owner, _operator, _approved) 
                emitApprovalForAll(_owner, _operator, _approved)
                if eq(_owner, _operator) {
                    revert256("cant approve owner")
                }
            }


            /**
            * @dev Returns the account approved for `tokenId` token.
            */
            function getApproved(_tokenId) -> _operator {
                _operator := read_tokenIdToApprovedAddress(_tokenId)
                if eq(read_ownerships(_tokenId), 0) {
                    revert256("no approvement found")
                }
            }


            /**
            * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
            */
            function isApprovedForAll(_owner, _operator) -> _approvedForAll {
                _approvedForAll := read_ownerAddressToOperatorApprovals(_operator, _owner) 
            }


            /**
            * @dev Safely mints `tokenId` and transfers it to `to`.
            */
            function safeMint(_to) {
                safeMint2(_to, "")
            }


            /**
            * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
            * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
            */
            function safeMint2(_to, _data) {
                let _tokenId := read_tokenCounter()
                increase_tokenCounter()
                let _isReceiver := _checkOnERC721Received(0x0, _to, _tokenId, _data)
                _mint(_to, _tokenId)
                if iszero(_isReceiver) {
                    revert256("zero address given")
                }
                if eq(read_tokenCounter(), 5001) {
                    revert256("max amount of tokens minted")
                }
            }

            /**
            * @dev Mints `tokenId` and transfers it to `to`.
            */
            function _mint(_to, _tokenId) {
                write_ownerAddressToBalance(_to, add(read_ownerAddressToBalance(_to), 0x01))
                write_ownerships(_tokenId, _to)
                emitTransfer(0, _to, _tokenId)
                if eq(_to, 0x0) {
                    revert256("zero address given")
                }
            }


            /**
            * @dev Returns whether `spender` is allowed to manage `tokenId`.
            */
            function _isApprovedOrOwner(_spender, _tokenId) -> _approvedOrOwner {
                let _owner := ownerOf(_tokenId)
                let _isOwner := eq(_owner, _spender)
                let _isApprovedForAll := isApprovedForAll(_owner, _spender)
                let _isApproved := eq(getApproved(_tokenId), _spender)
                if iszero(read_ownerships(_tokenId)) {
                    revert256("token not minted yet")
                }
                _approvedOrOwner := or(or(_isOwner, _isApprovedForAll), _isApproved)
            }


            /* -------- erc165 logic ---------- */

            function supportsInterface(_interfaceId) -> _supportsInterface {
                _supportsInterface := or(eq(_interfaceId, 0x01ffc9a7 ), eq(_interfaceId, 0x80ac58cd ))
            }


            /* -------- erc721Receiver check ---------- */

            function _checkOnERC721Received(_from, _to, _tokenId, _data) -> _isERC721Receiver {
                _isERC721Receiver := 0x01
                if gt(extcodesize(_to), 0x0) {
                    let freeMem := mload(0x40)
                    _isERC721Receiver := call(gas(), _to, callvalue(), add(_data, 0x20), mload(_data), 0x0, 0x0)
                }
            }
        }
    }
}
