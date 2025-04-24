// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVerifierManagement.sol";
import "../storage/VerifierStorage.sol";
import "../libraries/AttributeEvents.sol";

/**
 * @title VerifierManagement
 * @dev Mixin for managing the authorized verifier address
 */
abstract contract VerifierManagement is Ownable, VerifierStorage, IVerifierManagement {
    /**
     * @dev Constructor
     * @param initialVerifier The initial verifier address
     */
    constructor(address initialVerifier) {
        _setVerifier(initialVerifier);
    }
    
    /**
     * @dev Gets the current verifier address
     * @return The address of the current verifier
     */
    function getVerifier() public view override returns (address) {
        return _verifier;
    }
    
    /**
     * @dev Sets a new verifier address
     * @param newVerifier The address of the new verifier
     */
    function setVerifier(address newVerifier) public override onlyOwner {
        _setVerifier(newVerifier);
    }
    
    /**
     * @dev Internal function to set the verifier
     * @param newVerifier The address of the new verifier
     */
    function _setVerifier(address newVerifier) internal {
        require(newVerifier != address(0), "VerifierManagement: verifier cannot be zero address");
        
        address oldVerifier = _verifier;
        _verifier = newVerifier;
        
        emit AttributeEvents.VerifierChanged(oldVerifier, newVerifier);
    }
}