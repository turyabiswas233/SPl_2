import { createRoot } from "react-dom/client";
import "./index.css";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import App from "./App.jsx";
import SigninPage from "./pages/account/Signin.jsx";
import Home from "./pages/Home.jsx";
import "@radix-ui/themes/styles.css";

const routerConfig = [
  {
    path: "/",
    element: <Home />,
  },
  {
    path: "/signin",
    element: <SigninPage />,
  },
];

const NotFound = () => {
  return (
    <div className="flex flex-col items-center justify-center h-screen">
      <h1 className="text-6xl font-bold mb-4">404</h1>
      <p className="text-2xl">Page Not Found</p>
    </div>
  );
};
createRoot(document.getElementById("root")).render(
  <App>
    <BrowserRouter>
      <Routes>
        {routerConfig.map((route) => (
          <Route key={route.path} path={route.path} element={route.element} />
        ))}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  </App>
);
