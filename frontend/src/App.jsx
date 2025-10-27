import { Theme } from "@radix-ui/themes";
import Home from "./pages/Home";
import Signin from "./pages/account/Signin";

function App() {
  return (
    <Theme
      accentColor="iris"
      panelBackground="translucent"
      grayColor="gray"
      appearance="light"
    >
      <div className="p-10 poppins-regular">
        <p className="poppins-light">light</p>
        <p className="poppins-regular">normal</p>
        <p className="poppins-medium">medium</p>
        <p className="poppins-bold">bold</p>
      </div>
      <div className="flex justify-start gap-2 overflow-x-auto p-3 poppins-regular">
        <Home />
        <Signin />
      </div>
    </Theme>
  );
}

export default App;
