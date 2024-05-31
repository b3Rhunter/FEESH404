// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DN404.sol";
import "./DN404Mirror.sol";
import {Ownable} from "./Ownable.sol";
import {LibString} from "./LibString.sol";
import {DynamicBufferLib} from "./DynamicBufferLib.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract FEESH404 is DN404, Ownable {
    string private _name;
    string private _symbol;
    string private _baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply,
        address initialSupplyOwner
    ) {
        _initializeOwner(msg.sender);

        _name = name_;
        _symbol = symbol_;

        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _tokenURI(uint256 tokenId) internal pure override returns (string memory result) {
        string memory color1 = _randomColor(tokenId);
        string memory color2 = _randomColor(tokenId + 1);
        string memory color3 = _randomColor(tokenId + 2);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style>',
                '@keyframes typing {',
                    'from { width: 0; }',
                    '62.5% { width: 100%; }',
                    'to { width: 100%; }',
                '}',
                '@keyframes cursorBlink {',
                    '50% { border-right-color: transparent; }',
                '}',
                '.typing-effect {',
                    'overflow: hidden;',
                    'border-right: 2px solid white;',
                    'white-space: nowrap;',
                    'animation: typing 8s steps(40, end) infinite, cursorBlink 1s step-end infinite;',
                '}',
                '</style>',
                '<foreignObject width="100%" height="100%">',
                '<div xmlns="http://www.w3.org/1999/xhtml" style="font-size:14px;">',
                '<img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExc2lnbDUyeDA2YjUyd2ZlNzhubTFrbDM3N2g4ejVjaXJ4d2s1ZHNvNSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/KKpvdoG5Ew48xh9YUK/giphy.gif" width="100%" height="100%" style="position:absolute; object-fit: cover; left: 0; top: 0; z-index: 1; border-radius: 20px; border: 1px solid white; transform: scaleX(-1);" />',
                '<div style="position: absolute; top: 0; left: 0; width: 347px; height: 347px; background-color:', color3, '; mix-blend-mode: overlay; z-index: 999; border-radius: 20px; margin: 2px;"></div>',
                '<div style="position:absolute; z-index: 3; top: 0; left: 0; color: white; padding: 10px; text-align: left; padding-left: 15px; font-size: 18px;">',
                '</div>',
                '<div style="position:absolute; z-index: 3; bottom: 0; left: 0; color: white; padding-inline: 10px; padding-top: 61px; text-align: left; background-color: #0c0e0c; height: 73px; width: 347px; border-radius: 0px 0px 20px 20px; margin-left: 2px; margin-bottom: 2px;"></div>',
                '<div style="position:absolute; z-index: 3; bottom: 0; left: 0; color: white; padding-inline: 10px; padding-top: 14px; text-align: left; margin-left: 15px; margin-bottom: 8px; font-size: 16px; font-family: monospace">',
                '<p class="typing-effect">FEESH404...Thank you</p>',
                '</div>',
                '</div>',
                '</foreignObject>',
                '<ellipse ry="66.10078" rx="113.06712" cy="142.11132" cx="190.08488" fill="', color1, '"/>',
                '<ellipse stroke="#191919" ry="20.87393" rx="20.87393" cy="107.32143" cx="275.12876" fill="#e5e6ea"/>',
                '<ellipse stroke="#191919" ry="25.22267" rx="25.22267" cy="116.88865" cx="244.68761" fill="#e5e6ea"/>',
                '<ellipse ry="9.56722" rx="9.56722" cy="118.04831" cx="251.06575" fill="#191919"/>',
                '<path d="m46.84799,95.43508l93.93269,47.25625l-93.93269,47.25626l0,-94.51251z" fill="', color2, '"/>',
                '<ellipse ry="7.53781" rx="7.53781" cy="109.64076" cx="281.50691" fill="#191919"/>',
                '<ellipse ry="7.82772" rx="13.91595" cy="156.31719" cx="280.34724" fill="', color3, '"/>',
                '</svg>'
            )
        );

        string memory svgBase64 = Base64.encode(bytes(svg));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Test", "description": "Testing", "ID": ',LibString.toString(tokenId),', "image": "data:image/svg+xml;base64,', svgBase64, '"}'
                    )
                )
            )
        );
        result = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _randomColor(uint256 seed) internal pure returns (string memory) {
        uint256 hue = _randomHue(seed);
        return string(abi.encodePacked("hsl(", LibString.toString(hue), ", 50%, 50%)"));
    }

    function _randomHue(uint256 seed) internal pure returns (uint256) {
        bytes32 randomHash = keccak256(abi.encodePacked(seed));
        uint256 randomInt = uint256(randomHash) % 361;
        return randomInt;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    function retrieveURI(uint256 tokenId) public pure returns (string memory) {
        return _tokenURI(tokenId);
    }
}
