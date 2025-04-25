// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract B2BSupplyChain {
    address public owner;

    enum Status { Pending, InTransit, Delivered, Cancelled }

    struct Shipment {
        address sender;
        address receiver;
        string productDetails;
        uint256 timestamp;
        uint256 deliveryTimestamp;
        Status status;
    }

    uint256 public shipmentCount;
    mapping(uint256 => Shipment) public shipments;
    mapping(address => uint256[]) public shipmentsBySender;
    mapping(address => uint256[]) public shipmentsByReceiver;

    mapping(address => bool) public registeredSuppliers;
    mapping(address => bool) public registeredBuyers;

    event ShipmentCreated(uint256 shipmentId, address sender, address receiver, string productDetails);
    event ShipmentDelivered(uint256 shipmentId);
    event ShipmentCancelled(uint256 shipmentId);
    event ShipmentUpdated(uint256 shipmentId, string newProductDetails);
    event SupplierRegistered(address supplier);
    event BuyerRegistered(address buyer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyRegisteredSupplier() {
        require(registeredSuppliers[msg.sender], "Not a registered supplier");
        _;
    }

    modifier onlyRegisteredBuyer() {
        require(registeredBuyers[msg.sender], "Not a registered buyer");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerSupplier(address _supplier) external onlyOwner {
        registeredSuppliers[_supplier] = true;
        emit SupplierRegistered(_supplier);
    }

    function registerBuyer(address _buyer) external onlyOwner {
        registeredBuyers[_buyer] = true;
        emit BuyerRegistered(_buyer);
    }

    function createShipment(address _receiver, string memory _productDetails)
        external
        onlyRegisteredSupplier
    {
        require(registeredBuyers[_receiver], "Receiver must be a registered buyer");
        require(_receiver != address(0), "Invalid receiver");
        require(bytes(_productDetails).length > 0, "Product details required");

        shipmentCount++;
        shipments[shipmentCount] = Shipment(
            msg.sender,
            _receiver,
            _productDetails,
            block.timestamp,
            0,
            Status.InTransit
        );

        shipmentsBySender[msg.sender].push(shipmentCount);
        shipmentsByReceiver[_receiver].push(shipmentCount);

        emit ShipmentCreated(shipmentCount, msg.sender, _receiver, _productDetails);
    }

    function confirmDelivery(uint256 _shipmentId) external onlyRegisteredBuyer {
        Shipment storage s = shipments[_shipmentId];
        require(msg.sender == s.receiver, "Only the receiver can confirm delivery");
        require(s.status == Status.InTransit, "Shipment not in transit");

        s.status = Status.Delivered;
        s.deliveryTimestamp = block.timestamp;
        emit ShipmentDelivered(_shipmentId);
    }

    function cancelShipment(uint256 _shipmentId) external {
        Shipment storage s = shipments[_shipmentId];
        require(msg.sender == s.sender, "Only sender can cancel");
        require(s.status == Status.InTransit, "Shipment not in a cancellable state");

        s.status = Status.Cancelled;
        emit ShipmentCancelled(_shipmentId);
    }

    function updateProductDetails(uint256 _shipmentId, string memory _newDetails) external {
        Shipment storage s = shipments[_shipmentId];
        require(msg.sender == s.sender, "Only sender can update");
        require(s.status == Status.InTransit, "Can only update in-transit shipments");

        s.productDetails = _newDetails;
        emit ShipmentUpdated(_shipmentId, _newDetails);
    }

    function getShipment(uint256 _shipmentId) external view returns (Shipment memory) {
        return shipments[_shipmentId];
    }

    function getShipmentsBySender(address _sender) external view returns (uint256[] memory) {
        return shipmentsBySender[_sender];
    }

    function getShipmentsByReceiver(address _receiver) external view returns (uint256[] memory) {
        return shipmentsByReceiver[_receiver];
    }
}
