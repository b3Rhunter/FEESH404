// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DN404.sol";
import "./DN404Mirror.sol";
import "./Base64.sol";
import {Ownable} from "./Ownable.sol";
import {LibString} from "./LibString.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";

library Random {
    function randomHue(uint256 seed) internal pure returns (uint256) {
        bytes32 randomHash;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, seed)
            randomHash := keccak256(ptr, 0x20)
        }
        uint256 randomInt;
        assembly {
            randomInt := mod(randomHash, 361)
        }
        return randomInt;
    }

    function randomColor(uint256 seed) internal pure returns (string memory) {
        uint256 hue = randomHue(seed);
        string memory hueStr = LibString.toString(hue);
        return string(abi.encodePacked("hsl(", hueStr, ", 75%, 66%)"));
    }
}


contract FEESH404 is DN404, Ownable {
    string private _name;
    string private _symbol;
    uint32 public totalMinted;

    error InvalidMint();
    error InvalidPrice();
    error TotalSupplyReached();

    constructor() {
        _initializeOwner(msg.sender);
        _name = "FEESH404";
        _symbol = "FEESH";
        uint96 initialTokenSupply = 10000000000000000000000;
        address initialSupplyOwner = msg.sender;
        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function renderSvg(uint256 tokenId) public pure returns (string memory) {
        string memory color1 = Random.randomColor(tokenId);
        string memory color2 = Random.randomColor(tokenId + 42);
        string memory color3 = Random.randomColor(tokenId + 9);
        uint256 chubbiness = 35 + ((55 * Random.randomHue(tokenId)) / 255);

        return string(
            abi.encodePacked(
                '<path d="m46.84799,95.43508l93.93269,47.25625l-93.93269,47.25626l0,-94.51251z" fill="', color2, '"/>',
                '<ellipse ry="',LibString.toString(chubbiness),'" rx="113.06712" cy="142.11132" cx="190.08488" fill="', color1, '"/>',
                '<ellipse stroke="#191919" ry="20.87393" rx="20.87393" cy="107.32143" cx="275.12876" fill="#e5e6ea"/>',
                '<ellipse stroke="#191919" ry="25.22267" rx="25.22267" cy="116.88865" cx="244.68761" fill="#e5e6ea"/>',
                '<ellipse ry="9.56722" rx="9.56722" cy="118.04831" cx="251.06575" fill="#191919"/>',
                '<ellipse ry="7.53781" rx="7.53781" cy="109.64076" cx="281.50691" fill="#191919"/>',
                '<ellipse ry="7.82772" rx="13.91595" cy="156.31719" cx="280.34724" fill="', color3, '"/>'
            )
        );
    }

    function _tokenURI(uint256 tokenId) internal pure override returns (string memory result) {
    
       string memory color2 = Random.randomColor(tokenId + 7);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                renderSvg(tokenId),
                '</svg>'
            )
        );

        string memory styles = string(
            abi.encodePacked(
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
                '</style>'
            )
        );

        string memory html = string(
            abi.encodePacked(
                '<html style="box-sizing: border-box; margin: 0;">',
                '<head>',
                styles,
                '</head>',
                '<body style="width: 100%; height: 100%; margin: 0;">',
                '<div style="position:relative; width: 100%; height: 100%; overflow:hidden;">',
                '<img src="https://github.com/b3Rhunter/dads-thumbnails/raw/main/water.webp" style="position:absolute; object-fit: cover; left: 0; top: 0; z-index: -1; transform: scaleX(-1); width: 100%; height: 100%;" />',
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" style="position:absolute; width: 100%; height: 100%;">',
                renderSvg(tokenId),
                '</svg>',
                '<div style="position:absolute; top: 0; left: 0; background-color:', color2, '; mix-blend-mode: overlay; z-index: 999; margin: 2px;"></div>',
                '<div style="position:absolute; z-index: 3; top: 0; left: 0; color: white; padding: 10px; text-align: left; padding-left: 15px; font-size: 18px;"></div>',
                '<div style="position:absolute; z-index: 3; bottom: 0; left: 0; color: white; padding-inline: 10px; padding-top: 61px; text-align: left; background-color: #0c0e0c; height: 10px; width: 100%;"></div>',
                '<div style="position:absolute; z-index: 3; bottom: 0; left: 0; color: white; padding-inline: 10px; padding-top: 14px; text-align: left; margin-left: 15px; margin-bottom: 8px; font-size: 16px; font-family: monospace">',
                '<p class="typing-effect">FEESH404 ',LibString.toString(tokenId),'...appreciates you!</p>',
                '</div>',
                '</div>',
                '</body>',
                '</html>'
            )
        );
        string memory svgBase64 = Base64.encode(bytes(svg));
        string memory htmlBase64 = Base64.encode(bytes(html));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Feesh ',LibString.toString(tokenId),'", "description": "Super fishy feesh.", "ID": "',LibString.toString(tokenId),'", "image": "data:image/svg+xml;base64,', svgBase64, '", "animation_url": "data:text/html;base64,', htmlBase64, '"}'
                    )
                )
            )
        );
        result = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function retrieveURI(uint256 tokenId) public pure returns (string memory) {
        return _tokenURI(tokenId);
    }
}