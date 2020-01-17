pragma solidity 0.6.1;
pragma experimental ABIEncoderV2;

import "./Libraries/BytesUtil.sol";
import "./Libraries/AddressUtils.sol";
import "./Libraries/SigUtil.sol";
import "./Libraries/SafeMath.sol";
import "./Interfaces/ERC1271.sol";
import "./Interfaces/ERC1271Constants.sol";
import "./Interfaces/ERC1654.sol";
import "./Interfaces/ERC1654Constants.sol";
import "./Interfaces/ERC20.sol";

contract GenericMetaTxProcessor is ERC1271Constants, ERC1654Constants {

    // ////////////// LIBRARIES /////////////////
    using SafeMath for uint256;
    using AddressUtils for address;
    // //////////////////////////////////////////


    // /////////////// CONSTANTS ////////////////
    enum SignatureType { DIRECT, EIP1654, EIP1271 }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,address verifyingContract)"
    );
    bytes32 DOMAIN_SEPARATOR;

    bytes32 constant ERC20METATRANSACTION_TYPEHASH = keccak256(
        "ERC20MetaTransaction(address from,address to,address tokenContract,uint256 amount,bytes data,uint256 batchId,uint256 batchNonce,uint256 expiry,uint256 txGas,uint256 baseGas,uint256 tokenGasPrice,address relayer)"
    );
    // //////////////////////////////////////////

    // //////////////// EVENTS //////////////////
    event MetaTx(
        address indexed from,
        uint256 indexed batchId,
        uint256 indexed batchNonce,
        bool success,
        bytes returnData
    ); // TODO specify event as part of ERC-1776 ?
    // //////////////////////////////////////////

    // //////////////// STATE ///////////////////
    mapping(address => mapping(uint256 => uint256)) batches;
    bool lock = false;
    // //////////////////////////////////////////

    constructor() public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("Generic Meta Transaction"),
                keccak256("1"),
                address(this)
            )
        );
    }

    struct Call {
        address from;
        address to;
        bytes data;
        bytes signature;
        SignatureType signatureType;
    }

    struct CallParams {
        address tokenContract;
        uint256 amount;
        uint256 batchId;
        uint256 batchNonce;
        uint256 expiry;
        uint256 txGas;
        uint256 baseGas;
        uint256 tokenGasPrice;
        address relayer;
    }

    function executeMetaTransaction(
        Call memory callData,
        CallParams memory callParams,
        address tokenReceiver
    ) public returns (bool success, bytes memory returnData) {
        require(!lock, "IN_PROGRESS");
        lock = true;
        _ensureParametersValidity(callData, callParams);
        _ensureCorrectSigner(callData, callParams);
        (success, returnData) = _performERC20MetaTx(callData, callParams, tokenReceiver);
        lock = false;
    }

    // ////////////////////////////// INTERNALS /////////////////////////

    function _ensureParametersValidity(
        Call memory callData,
        CallParams memory callParams
    ) internal view {
        require(
            callParams.relayer == address(0) || callParams.relayer == msg.sender,
            "wrong relayer"
        );
        require(block.timestamp < callParams.expiry, "expired");
        require(batches[callData.from][callParams.batchId] + 1 == callParams.batchNonce, "batchNonce out of order");
    }

    function _encodeMessage(
        Call memory callData,
        CallParams memory callParams
    ) internal view returns (bytes memory) {
        return abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(messageBytes(callData, callParams))
        );
    }

    function messageBytes(
        Call memory callData,
        CallParams memory callParams
    ) internal pure returns(bytes memory) {
        return abi.encode(
            ERC20METATRANSACTION_TYPEHASH,
            callData.from,
            callData.to,
            callParams.tokenContract,
            callParams.amount,
            keccak256(callData.data),
            callParams.batchId,
            callParams.batchNonce,
            callParams.expiry,
            callParams.txGas,
            callParams.baseGas,
            callParams.tokenGasPrice,
            callParams.relayer
        );
    }

    function _ensureCorrectSigner(
        Call memory callData,
        CallParams memory callParams
    ) internal view {
        bytes memory dataToHash = _encodeMessage(callData, callParams);
        if (callData.signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(callData.from).isValidSignature(dataToHash, callData.signature) == ERC1271_MAGICVALUE,
                "invalid 1271 signature"
            );
        } else if(callData.signatureType == SignatureType.EIP1654){
            require(
                ERC1654(callData.from).isValidSignature(keccak256(dataToHash), callData.signature) == ERC1654_MAGICVALUE,
                "invalid 1654 signature"
            );
        } else {
            address signer = SigUtil.recover(keccak256(dataToHash), callData.signature);
            require(signer == callData.from, "signer != from");
        }
    }

    function _charge(
        address from,
        ERC20 tokenContract,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 initialGas,
        uint256 baseGasCharge,
        address tokenReceiver
    ) internal {
        uint256 gasCharge = initialGas - gasleft();
        if(gasCharge > gasLimit) {
            gasCharge = gasLimit;
        }
        gasCharge += baseGasCharge;
        uint256 tokensToCharge = gasCharge * tokenGasPrice;
        require(tokensToCharge / gasCharge == tokenGasPrice, "overflow");
        tokenContract.transferFrom(from, tokenReceiver, tokensToCharge);
    }

    function _executeWithSpecificGas(
        address to,
        uint256 gasLimit,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        (success, returnData) = to.call.gas(gasLimit)(data);
        assert(gasleft() > gasLimit / 63); // not enough gas provided, assert to throw all gas // TODO use EIP-1930
    }

    function _transferAndChargeForGas(
        address from,
        address to,
        ERC20 tokenContract,
        uint256 amount,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver
    ) internal returns (bool) {
        uint256 initialGas = gasleft();
        tokenContract.transferFrom(from, to, amount);
        if (tokenGasPrice > 0) {
            _charge(from, tokenContract, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
        return true;
    }

    function _executeWithSpecificGasAndChargeForIt(
        address from,
        address to,
        ERC20 tokenContract,
        uint256 gasLimit,
        uint256 tokenGasPrice,
        uint256 baseGasCharge,
        address tokenReceiver,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        uint256 initialGas = gasleft();
        (success, returnData) = _executeWithSpecificGas(to, gasLimit, data);
        if (tokenGasPrice > 0) {
            _charge(from, tokenContract, gasLimit, tokenGasPrice, initialGas, baseGasCharge, tokenReceiver);
        }
    }

    function _performERC20MetaTx(
        Call memory callData,
        CallParams memory callParams,
        address tokenReceiver
    ) internal returns (bool success, bytes memory returnData) {
        batches[callData.from][callParams.batchId] = callParams.batchNonce;

        ERC20 tokenContract = ERC20(callParams.tokenContract);

        if (callData.data.length == 0) {
            if(callParams.tokenGasPrice > 0) {
                _transferAndChargeForGas(
                    callData.from,
                    callData.to,
                    tokenContract,
                    callParams.amount,
                    callParams.txGas,
                    callParams.tokenGasPrice,
                    callParams.baseGas,
                    tokenReceiver
                );
            } else {
                require(tokenContract.transferFrom(callData.from, callData.to, callParams.amount), "ERC20_TRANSFER_FAILED");
            }
            success = true;
        } else {
            require(
                BytesUtil.doFirstParamEqualsAddress(callData.data, callData.from),
                "first param != from"
            );
            uint256 previousBalance;
            if(callParams.amount > 0) {
                previousBalance = tokenContract.balanceOf(address(this));
                require(tokenContract.transferFrom(callData.from, address(this), callParams.amount), "ERC20_ALLOCATION_FAILED");
                tokenContract.approve(callData.to, callParams.amount);
            }
            if(callParams.tokenGasPrice > 0) {
                (success, returnData) = _executeWithSpecificGasAndChargeForIt(
                    callData.from,
                    callData.to,
                    tokenContract,
                    callParams.txGas,
                    callParams.tokenGasPrice,
                    callParams.baseGas,
                    tokenReceiver,
                    callData.data
                );
            } else {
                (success, returnData) = _executeWithSpecificGas(callData.to, callParams.txGas, callData.data);
            }
            if(callParams.amount > 0) {
                uint256 newBalance = tokenContract.balanceOf(address(this));
                if (newBalance > previousBalance) {
                    require(tokenContract.transfer(callData.from, newBalance - previousBalance), "ERC20_REFUND_FAILED");
                }
            }
        }

        emit MetaTx(callData.from, callParams.batchId, callParams.batchNonce, success, returnData);
    }

    function meta_nonce(address from, uint256 batchId) external view returns(uint256) {
        return batches[from][batchId];
    }
}
