import { Theme } from "@radix-ui/themes";
import Home from "./pages/Home";
import "./App.css";
function App({ children }) {
  return (
    <Theme
      accentColor="iris"
      panelBackground="translucent"
      grayColor="gray"
      appearance="light"
    >
      <div className="poppins-regular">{children ? children : <Home />}</div>
    </Theme>
  );
}

export default App;
