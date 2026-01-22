import { StrictMode } from 'react';
import * as ReactDOM from 'react-dom/client';
import App from './app/app';
import './index.css';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement,
);

root.render(
  <StrictMode>
    {/* QUITAR BrowserRouter de aquí - ya está en App.tsx */}
    <App />
  </StrictMode>,
);
