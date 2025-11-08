import { useNavigate } from "react-router-dom";
import Landing from "../components/landing";
import { useEffect } from "react";

function Home() {
  const router = useNavigate();
  useEffect(() => {
    setTimeout(() => {
      router("/signin");
    }, 5000);
  }, []);
  return (
    <div className="max-w-md min-w-sm w-full border-2 rounded-2xl mx-auto">
      <Landing />
    </div>
  );
}

export default Home;
