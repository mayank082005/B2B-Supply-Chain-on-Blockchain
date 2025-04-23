// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract B2BSupplyChain {
    address public owner;

    struct Shipment {
        address sender;
        address receiver;
        string productDetails;
        uint256 timestamp;
        bool delivered;
    }

    uint256 public shipmentCount;
    mapping(uint256 => Shipment) public shipments;

    event ShipmentCreated(uint256 shipmentId, address sender, address receiver, string productDetails);
    event ShipmentDelivered(uint256 shipmentId);

    constructor() {
        owner = msg.sender;
    }

    function createShipment(address _receiver, string memory _productDetails) external {
        shipmentCount++;
        shipments[shipmentCount] = Shipment(msg.sender, _receiver, _productDetails, block.timestamp, false);
        emit ShipmentCreated(shipmentCount, msg.sender, _receiver, _productDetails);
    }

    function confirmDelivery(uint256 _shipmentId) external {
        Shipment storage s = shipments[_shipmentId];
        require(msg.sender == s.receiver, "Only the receiver can confirm delivery");
        require(!s.delivered, "Already delivered");

        s.delivered = true;
        emit ShipmentDelivered(_shipmentId);
    }

    function getShipment(uint256 _shipmentId) external view returns (Shipment memory) {
        return shipments[_shipmentId];
    }
}
