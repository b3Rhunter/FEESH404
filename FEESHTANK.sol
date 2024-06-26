pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './Base64.sol';
import './HexStrings.sol';
import {LibString} from "./LibString.sol";


abstract contract FEESH404 {
  function renderSvg(uint256 tokenId) external virtual view returns (string memory);
  function transferFrom(address from, address to, uint256 id) external virtual;
}

contract FEESHTANKTEST is ERC721Enumerable, IERC721Receiver {

  using Counters for Counters.Counter;
  using HexStrings for uint160;

  Counters.Counter private _tokenIds;

  FEESH404 feesh;
  mapping(uint256 => uint256[]) feeshById;

  constructor(address _feesh) ERC721("Feesh Tank TEST", "FEESHTANKTEST") {
    feesh = FEESH404(_feesh);
  }

  function mintItem() public returns (uint256) {
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      return id;
  }

  function returnAllLoogies(uint256 _id) external {
    require(msg.sender == ownerOf(_id), "only tank owner can return the loogies");
    for (uint256 i = 0; i < feeshById[_id].length; i++) {
      feesh.transferFrom(address(this), ownerOf(_id), feeshById[_id][i]);
    }

    delete feeshById[_id];
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      string memory name = string(abi.encodePacked('Feesh Tank #',LibString.toString(id)));
      string memory description = string(abi.encodePacked('Feesh Tank for those silly feesh...'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '", "description":"',
                    description,
                    '", "external_url":"https://feesh404.xyz',
                    LibString.toString(id),
                    '", "owner":"',
                    (uint160(ownerOf(id))).toHexString(20),
                    '", "image": "',
                    'data:image/svg+xml;base64,',
                    image,
                    '"}'
                )
            )
        )
      ));
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="350" height="350" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
       '<rect x="0" y="0" width="350" height="350" stroke="black" fill="#8FB9EB" stroke-width="5"/>',
       '<g transform="translate(-60 -62)">',
       renderFeesh(id),
       '</g>'
    ));

    return render;
  }

  function renderFeesh(uint256 _id) internal view returns (string memory) {
    string memory feeshSVG = "";

    for (uint8 i = 0; i < feeshById[_id].length; i++) {
      uint16 blocksTraveled = uint16((block.number-blockAdded[feeshById[_id][i]])%256);
      int8 speedX = int8(uint8(feeshById[_id][0]));
      int8 speedY = int8(uint8(feeshById[_id][1]));
      uint8 newX;
      uint8 newY;

      newX = newPos(
        speedX,
        blocksTraveled,
        x[feeshById[_id][i]]);

      newY = newPos(
        speedY,
        blocksTraveled,
        y[feeshById[_id][i]]);

      feeshSVG = string(abi.encodePacked(
        feeshSVG,
        '<g>',
        '<animateTransform attributeName="transform" dur="1500s" fill="freeze" type="translate" additive="sum" ',
        'values="', LibString.toString(newX), ' ', LibString.toString(newY) , ';'));

      for (uint8 j = 0; j < 100; j++) {
        newX = newPos(speedX, 1, newX);
        newY = newPos(speedY, 1, newY);

        feeshSVG = string(abi.encodePacked(
          feeshSVG,
          LibString.toString(newX), ' ', LibString.toString(newY), ';'));
      }

      feeshSVG = string(abi.encodePacked(
        feeshSVG,
        '"/>',
        '<animateTransform attributeName="transform" type="scale" additive="sum" values="0.3 0.3"/>',
        feesh.renderSvg(feeshById[_id][i]),
        '</g>'));
    }

    return feeshSVG;
  }

  function newPos(int8 speed, uint16 blocksTraveled, uint8 initPos) internal pure returns (uint8) {
      uint16 traveled;
      uint16 start;

      if (speed >= 0) {
        traveled = uint16((blocksTraveled * uint8(speed)) % 256);
        start = (initPos + traveled) % 256;
        return uint8(start);
      } else {
        traveled = uint16((blocksTraveled * uint8(-speed)) % 256);
        start = (255 - traveled + initPos)%256;
        return uint8(start);
      }
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length >= 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
  }

  mapping(uint256 => uint8) x;
  mapping(uint256 => uint8) y;

  mapping(uint256 => uint256) blockAdded;

  // to receive ERC721 tokens
  function onERC721Received(
      address operator,
      address from,
      uint256 feeshTokenId,
      bytes calldata tankIdData) external override returns (bytes4) {

      uint256 tankId = toUint256(tankIdData);
      require(ownerOf(tankId) == from, "you can only add feesh to a tank you own.");
      require(feeshById[tankId].length < 256, "tank has reached the max limit of 255 feesh.");

      feeshById[tankId].push(feeshTokenId);

      bytes32 randish = keccak256(abi.encodePacked( blockhash(block.number-1), from, address(this), feeshTokenId, tankIdData  ));
      x[feeshTokenId] = uint8(randish[0]);
      y[feeshTokenId] = uint8(randish[1]);
      blockAdded[feeshTokenId] = block.number;

      return this.onERC721Received.selector;
    }
}
