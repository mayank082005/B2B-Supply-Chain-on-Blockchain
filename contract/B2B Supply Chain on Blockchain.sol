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

    // ✅ New Function 1: Get shipment status as string
    function getShipmentStatus(uint256 _shipmentId) external view returns (string memory) {
        Shipment storage s = shipments[_shipmentId];
        if (s.status == Status.Pending) return "Pending";
        if (s.status == Status.InTransit) return "In Transit";
        if (s.status == Status.Delivered) return "Delivered";
        if (s.status == Status.Cancelled) return "Cancelled";
        return "Unknown";
    }

    // ✅ New Function 2: Get all shipment IDs with a specific status
    function getShipmentsByStatus(Status _status) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= shipmentCount; i++) {
            if (shipments[i].status == _status) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= shipmentCount; i++) {
            if (shipments[i].status == _status) {
                result[index++] = i;
            }
        }
        return result;
    }

    // ✅ New Function 3: Get all shipment IDs involving a user (sender or receiver)
    function getShipmentHistoryByUser(address _user) external view returns (uint256[] memory) {
        uint256 senderCount = shipmentsBySender[_user].length;
        uint256 receiverCount = shipmentsByReceiver[_user].length;
        uint256[] memory result = new uint256[](senderCount + receiverCount);

        for (uint256 i = 0; i < senderCount; i++) {
            result[i] = shipmentsBySender[_user][i];
        }

        for (uint256 i = 0; i < receiverCount; i++) {
            result[senderCount + i] = shipmentsByReceiver[_user][i];
        }

        return result;
    }

    // ✅ New Function 4: Check if a user is registered as supplier or buyer
    function isRegisteredUser(address _user) external view returns (bool isSupplier, bool isBuyer) {
        isSupplier = registeredSuppliers[_user];
        isBuyer = registeredBuyers[_user];
    }

    // ✅ New Function 5: Admin-only delete (use with caution)
    function deleteShipment(uint256 _shipmentId) external onlyOwner {
        require(_shipmentId > 0 && _shipmentId <= shipmentCount, "Invalid shipment ID");
        delete shipments[_shipmentId];
    }

    // ✅ New Function 6: Get all shipment IDs
    function getAllShipments() external view returns (uint256[] memory) {
        uint256[] memory all = new uint256[](shipmentCount);
        for (uint256 i = 0; i < shipmentCount; i++) {
            all[i] = i + 1;
        }
        return all;
    }
}
