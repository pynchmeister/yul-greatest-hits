object "MultiSignatureWallet" {
    code {
        codecopy(0, 311, codesize())
        sstore(address(), mload(0))
        for { let i := 96 }
        lt(i, add(96, mul(32, mload(64))))
        { i := add(i, 32) }
        { sstore(mload(i), mload(i)) }
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }
    object "Runtime" {
        code {
            if calldatasize()
            {
                calldatacopy(1060, 0, calldatasize())
                let dataLength := mload(1192)
                mstore(1000, 0x4a0a6d86122c7bd7083e83912c312adabf207e986f1ac10a35dfeb610d28d0b6)
                mstore(1032, sload(add(address(), 1)))
                mstore(1128, keccak256(1224, dataLength))
                mstore8(0, 0x19)
                mstore8(1, 0x01)
                mstore(2, 0xb0609d81c5f719d8a516ae2f25079b20fb63da3e07590e23fbf0028e6745e5f2)
                mstore(34, keccak256(1000, 160))
                let EIP712Hash := keccak256(0, 66)
                let previousAddress := 0
                for { let i := 0 } lt(i, sload(address())) { i := add(i, 1) }
                {
                    let memPosition := add(add(1064, mload(1160)), mul(i, 96))
                    mstore(memPosition, EIP712Hash)
                    let result := call(3000, 1, 0, memPosition, 128, 300, 32)
                    if iszero(gt(sload(mload(300)), previousAddress)) { revert(0, 0) }
                    previousAddress := mload(300)
                }
                sstore(add(address(), 1), add(1, mload(1032)))
                if iszero(delegatecall(mload(1096), mload(1064), 1224, dataLength, 0, 0)) { revert(0, 0) }
            }
        }
    }
}
