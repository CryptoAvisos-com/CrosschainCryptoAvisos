// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./abstracts/brain/BatchFunctions.sol";
import "./abstracts/brain/SingleFunctions.sol";
import "./abstracts/brain/CrosschainFunctions.sol";
import "./abstracts/brain/PublicViewHelpers.sol";

contract Brain is BatchFunctions, SingleFunctions, CrosschainFunctions, PublicViewHelpers {

    constructor(uint newFee, address _allowedSigner){
        _setFee(newFee);
        _changeAllowedSigner(_allowedSigner);
    }

}