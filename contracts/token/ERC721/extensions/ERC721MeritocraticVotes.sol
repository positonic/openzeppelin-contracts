// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "../ERC721.sol";
import {Votes} from "../../../governance/utils/Votes.sol";

/**
 * @dev Extension of ERC-721 to support meritocratic voting and delegation as implemented by {Votes}.
 * Each individual NFT's vote can be influenced by a set of multipliers based on the attributes of the holder or the NFT itself.
 */
abstract contract ERC721MeritocraticVotes is ERC721, Votes {
    struct Multiplier {
        string name;
        uint256 percentage; // 20% = 20 (use basis points: 10000 = 100%)
    }

    mapping(uint256 => Multiplier[]) public tokenMultipliers;

    // Example base voting power per token
    uint256 public baseVotingPower = 0.2 ether; // Represents 0.2 base voting score

    // Attestation station or any other mechanism to validate user-specific attributes (e.g., external contracts)
    address public attestationStation;

    constructor(address _attestationStation) {
        attestationStation = _attestationStation;
    }

    /**
     * @dev Sets a multiplier attribute to the specific tokenId.
     * Example: setMultiplier(tokenId, "isBuilder", 20) increases vote weight by 20%.
     */
    function setMultiplier(uint256 tokenId, string memory name, uint256 percentage) public {
        // Ensure only authorized accounts can set multipliers (optional)
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to set multiplier");
        tokenMultipliers[tokenId].push(Multiplier(name, percentage));
    }

    /**
     * @dev Override to calculate voting units based on multipliers.
     */
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        uint256 totalVotingPower = 0;

        // Loop through all the tokens held by the account
        uint256 balance = balanceOf(account);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i);

            // Base voting power starts at 0.2 for each token
            uint256 tokenVotingPower = baseVotingPower;

            // Apply any multipliers assigned to the token
            Multiplier[] memory multipliers = tokenMultipliers[tokenId];
            for (uint256 j = 0; j < multipliers.length; j++) {
                // Add multiplier to base voting power (percentage is in basis points, so we divide by 100)
                tokenVotingPower += (tokenVotingPower * multipliers[j].percentage) / 100;
            }

            totalVotingPower += tokenVotingPower;
        }

        return totalVotingPower;
    }

    /**
     * @dev See {ERC721-_update}. Adjusts votes when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        uint256 votingUnits = _getVotingUnits(previousOwner);
        _transferVotingUnits(previousOwner, to, votingUnits);

        return previousOwner;
    }

    /**
     * @dev Optionally, you could implement an external attestation mechanism
     * or oracle to adjust multipliers based on external sources (e.g., Ethereum Attestation Station).
     */
    function getExternalMultiplier(address account) public view returns (uint256) {
        // Add logic here to fetch multipliers from external attestation contracts
        // You can query the attestation station for any attributes relevant to account
        return 0; // Placeholder, assume no external multiplier in this example
    }
}
