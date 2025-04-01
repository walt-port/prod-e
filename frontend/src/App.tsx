import { useCallback, useState } from 'react';
import LoadingTerminal from './components/LoadingTerminal';
import Dashboard from './pages/Dashboard';
// Remove default App.css import if it exists and is unused
// import './App.css';

function App() {
  const [isLoading, setIsLoading] = useState(true);

  const handleLoadingFinished = useCallback(() => {
    setIsLoading(false);
  }, []);

  return <>{isLoading ? <LoadingTerminal onFinished={handleLoadingFinished} /> : <Dashboard />}</>;
}

export default App;
