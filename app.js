import React, { useEffect, useState } from "react";
import Web3 from "web3";
import B2BSupplyChainABI from "./B2BSupplyChainABI.json"; // Your ABI file

const CONTRACT_ADDRESS = 0x10e119dedaD58d59A671BA1920160135CcF8EA3a

function App() {
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState("");
  const [shipments, setShipments] = useState([]);

  useEffect(() => {
    async function loadBlockchain() {
      if (window.ethereum) {
        const web3Instance = new Web3(window.ethereum);
        await window.ethereum.enable();
        const accounts = await web3Instance.eth.getAccounts();
        const networkId = await web3Instance.eth.net.getId();

        const contractInstance = new web3Instance.eth.Contract(
          B2BSupplyChainABI,
          CONTRACT_ADDRESS
        );

        setWeb3(web3Instance);
        setContract(contractInstance);
        setAccount(accounts[0]);
      } else {
        alert("Please install MetaMask to use this DApp!");
      }
    }

    loadBlockchain();
  }, []);

  const getAllShipments = async () => {
    const ids = await contract.methods.getAllShipments().call();
    const details = await Promise.all(
      ids.map((id) => contract.methods.getShipment(id).call())
    );
    setShipments(details);
  };

  const createShipment = async (receiver, productDetails) => {
    await contract.methods
      .createShipment(receiver, productDetails)
      .send({ from: account });
    alert("Shipment created!");
  };

  return (
    <div>
      <h1>B2B Supply Chain Dashboard</h1>
      <button onClick={getAllShipments}>Load All Shipments</button>
      <ul>
        {shipments.map((s, idx) => (
          <li key={idx}>
            From: {s.sender} To: {s.receiver} - Product: {s.productDetails} - Status: {s.status}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
