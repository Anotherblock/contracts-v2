// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Superfluid Contracts */
import {SuperToken, ISuperfluid} from '@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol';

/* Openzeppelin Contract */
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract ABSuperToken is SuperToken {
    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    constructor(address _host) SuperToken(ISuperfluid(_host)) {}

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint amount of tokens to the receiver
     *  Only Anotherblock Vault contract can perform this operation
     *
     * @param _receiver receiver address
     * @param _amount amount of tokens to be minted
     */
    function mint(address _receiver, uint256 _amount) external {
        this.selfMint(_receiver, _amount, '');
    }

    /**
     * @notice
     *  Mint amount of tokens to the receiver
     *  Only Anotherblock Vault contract can perform this operation
     *
     * @param _from address to be burnt from
     * @param _amount amount of tokens to be burnt
     */
    function burn(address _from, uint256 _amount) external {
        this.selfBurn(_from, _amount, '');
    }
}
