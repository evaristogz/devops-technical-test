import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [health, setHealth] = useState('checking...');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Health check
        await axios.get('/health');
        setHealth('healthy');
        
        // Fetch products  
        const response = await axios.get('/api/products');
        setProducts(response.data);
      } catch (error) {
        setHealth('unhealthy');
        console.error('Error:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const addToCart = (product) => {
    setCart([...cart, product]);
  };

  if (loading) {
    return <div style={{textAlign: 'center', padding: '50px'}}>Loading...</div>;
  }

  return (
    <div style={{minHeight: '100vh'}}>
      <header style={{
        background: '#2c3e50', 
        color: 'white', 
        padding: '20px',
        marginBottom: '20px'
      }}>
        <h1 style={{margin: 0}}>🛒 DevOps E-commerce Test</h1>
        <div style={{marginTop: '10px', fontSize: '14px'}}>
          Status: <span style={{
            color: health === 'healthy' ? '#2ecc71' : '#e74c3c'
          }}>{health}</span> | Cart: {cart.length} items
        </div>
      </header>
      
      <main style={{padding: '0 20px', maxWidth: '1200px', margin: '0 auto'}}>
        <h2>Products</h2>
        {products.length === 0 ? (
          <p>No products available or backend not connected.</p>
        ) : (
          <div style={{
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', 
            gap: '20px',
            marginBottom: '40px'
          }}>
            {products.map(product => (
              <div key={product.id} style={{
                background: 'white',
                border: '1px solid #ddd',
                borderRadius: '8px',
                padding: '20px',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
              }}>
                <h3 style={{margin: '0 0 10px 0', color: '#2c3e50'}}>{product.name}</h3>
                <p style={{color: '#7f8c8d', margin: '0 0 15px 0'}}>{product.category}</p>
                <p style={{fontSize: '18px', fontWeight: 'bold', color: '#27ae60', margin: '0 0 15px 0'}}>
                  ${product.price}
                </p>
                <button 
                  onClick={() => addToCart(product)}
                  style={{
                    background: '#3498db',
                    color: 'white',
                    border: 'none',
                    padding: '10px 20px',
                    borderRadius: '5px',
                    cursor: 'pointer',
                    width: '100%'
                  }}
                  onMouseOver={(e) => e.target.style.background = '#2980b9'}
                  onMouseOut={(e) => e.target.style.background = '#3498db'}
                >
                  Add to Cart
                </button>
              </div>
            ))}
          </div>
        )}
        
        {cart.length > 0 && (
          <div style={{
            background: 'white',
            border: '2px solid #3498db',
            borderRadius: '8px',
            padding: '20px',
            marginBottom: '40px'
          }}>
            <h3 style={{color: '#2c3e50', margin: '0 0 15px 0'}}>🛒 Shopping Cart</h3>
            {cart.map((item, index) => (
              <div key={index} style={{
                padding: '10px 0',
                borderBottom: index < cart.length - 1 ? '1px solid #eee' : 'none',
                display: 'flex',
                justifyContent: 'space-between'
              }}>
                <span>{item.name}</span>
                <span style={{fontWeight: 'bold'}}>${item.price}</span>
              </div>
            ))}
            <div style={{
              marginTop: '15px',
              paddingTop: '15px',
              borderTop: '2px solid #3498db',
              fontSize: '18px',
              fontWeight: 'bold',
              textAlign: 'right'
            }}>
              Total: ${cart.reduce((sum, item) => sum + parseFloat(item.price), 0).toFixed(2)}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
