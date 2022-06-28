// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./abstracts/brain/BatchFunctions.sol";
import "./abstracts/brain/SingleFunctions.sol";
import "./abstracts/brain/CrosschainFunctions.sol";
import "./abstracts/brain/PublicViewHelpers.sol";

contract Brain is BatchFunctions, SingleFunctions, CrosschainFunctions, PublicViewHelpers {

    constructor (
        uint newFee, 
        address _allowedSigner, 
        address _connext, 
        address _swapper,
        address _wNATIVE
    ) Swapper(_swapper, _wNATIVE) XCall(_connext) {
        _setFee(newFee);
        _changeAllowedSigner(_allowedSigner);
    }

}