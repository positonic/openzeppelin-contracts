// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/extensions/ERC1155Votes.sol)

pragma solidity ^0.8.20;

import {ERC1155} from "../ERC1155.sol";
import {Votes} from "../../../governance/utils/Votes.sol";

/**
 * @dev Extension of ERC-1155 to support voting and delegation as implemented by {Votes}, where each individual NFT counts
 * as 1 vote unit.
 *
 * Tokens do not count as votes until they are delegated, because votes must be tracked which incurs an additional cost
 * on every transfer. Token holders can either delegate to a trusted representative who will decide how to make use of
 * the votes in governance decisions, or they can delegate to themselves to be their own representative.
 */
abstract contract ERC1155Votes is ERC1155, Votes {
    /**
     * @dev See {ERC1155-_update}. Adjusts votes when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual override {
        super._update(from, to, ids, values);
        
        // Loop through each transferred token ID and adjust votes accordingly.
        for (uint256 i = 0; i < ids.length; i++) {
            _transferVotingUnits(from, to, values[i]);
        }
    }

    /**
     * @dev Returns the balance of `account`.
     *
     * WARNING: Overriding this function will likely result in incorrect vote tracking.
     */
     function _getVotingUnits(address account, uint256[] memory ids) internal view virtual returns (uint256) {
        uint256 totalVotes = 0;
        
        // Sum the balance of each token ID for the given account
        for (uint256 i = 0; i < ids.length; i++) {
            totalVotes += balanceOf(account, ids[i]);
        }
        
        return totalVotes;
    }

    
}
