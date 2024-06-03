import './App.css'
import { useState } from 'react'
import DN404ABI from './DN404ABI.json'
import { ethers } from 'ethers'
import Water from './water.mp4'
import Feesh from './assets/feesh.svg'

function App() {
  const [connected, setConnected] = useState(false)
  const [name, setName] = useState('')
  const [balance, setBalance] = useState(0)
  const [nfts, setNfts] = useState([])

  const contractAddress = '0xC5641589A0124586a8daFA3670F7C2A4b8B0cb82'

  const connect = async () => {
    try {
      let provider;
      provider = new ethers.BrowserProvider(window.ethereum)
      const network = await provider.getNetwork();
      const desiredChainId = '0x2105';
      if (network.chainId !== parseInt(desiredChainId)) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: desiredChainId }],
          });
        } catch (switchError) {
          if (switchError.code === 4902) {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [{
                chainId: desiredChainId,
                chainName: 'Base',
                nativeCurrency: {
                  name: 'ETH',
                  symbol: 'ETH',
                  decimals: 18
                },
                rpcUrls: ['https://developer-access-mainnet.base.org'],
                blockExplorerUrls: ['https://basescan.org/'],
              }],
            });
          } else {
            throw switchError;
          }
        }
      }
      provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner()
      const contract = new ethers.Contract(contractAddress, DN404ABI, signer)
      const address = await signer.getAddress()
      const tokenBalance = await contract.balanceOf(address)
      const ensProvider = new ethers.InfuraProvider('mainnet');
      const ens = await ensProvider.lookupAddress(address);
        if (ens) {
          setName(ens)
        } else {
          setName(address.substr(0, 6) + "...")
        }
        await fetchNfts()
        setConnected(true)
        setBalance(ethers.formatEther(tokenBalance))
    } catch (error) {
      console.error(error)
    }
  }

  const fetchNfts = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum)
    const signer = await provider.getSigner()
    const address = await signer.getAddress()
    try {
      const options = {
        method: 'GET',
        headers: { accept: 'application/json', 'x-api-key': '31fdf34560ab4e66a9b5052597c1c06a' }
      }

      const response = await fetch(`https://api.opensea.io/api/v2/chain/base/account/${address}/nfts?collection=feesh404-4`, options)
      const data = await response.json()
      const identifiers = data.nfts.map(nft => nft.identifier)
      const fetchPromises = identifiers.map(identifier =>
        fetch(`https://api.opensea.io/api/v2/chain/base/contract/0x0FFDfc660E5955988d88f3c21E88D97984626AC3/nfts/${identifier}`, options)
          .then(response => response.json())
      )

      const nftDetailsArray = await Promise.all(fetchPromises)
      const nftsData = nftDetailsArray.map(nftDetails => {
        const metadata = JSON.parse(atob(nftDetails.nft.metadata_url.split(",")[1]))
        return {
          token_id: metadata.ID,
          animation_url: metadata.animation_url,
        }
      })

      setNfts(nftsData)
    } catch (error) {
      console.error(error)
    }
  }

  const disconnect = () => {
    setConnected(false)
    setName('')
    setBalance(0)
    setNfts([])
  }

  return (
    <div className='app'>
      <div className='background'>
        <video src={Water} autoPlay loop muted />
      </div>
      <div className='background-overlay'></div>
      <h1>FEESH-404</h1>
      {!connected && <button className='connect-btn' onClick={connect}>Connect</button>}
      {connected && (
        <>
          <nav>
          <div className='logo'>
          <img className='feesh' src={Feesh} alt='Feesh' />
          <p className='balance'>{parseFloat(balance)} Feesh</p>
          </div>
          <button className='disconnect-btn' onClick={disconnect}>{name}</button>
          </nav>
          <div className='nft-grid'>
            {nfts.map((nft, index) => (
              <div key={index} className='nft-item'>
                {nft.animation_url ? (
                  <iframe src={nft.animation_url} title={`Token ID ${nft.token_id}`} frameBorder="0" />
                ) : (
                  <p>error loading...</p>
                )}
              </div>
            ))}
          </div>
          <a className='swap-btn' href='https://app.uniswap.org/explore/tokens/base/0xc5641589a0124586a8dafa3670f7c2a4b8b0cb82' target='_blank' rel="noreferrer"><button>Swap</button></a>
          <a className='opensea-btn' href='https://opensea.io/collection/feesh404-4' target='_blank' rel="noreferrer"><button>Opensea</button></a>
        </>
      )}
    </div>
  )
}

export default App
