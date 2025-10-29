import { Button, Card, Checkbox, Flex, Link, Text } from "@radix-ui/themes";
import { MdEmail } from "react-icons/md";
import { FaKey, FaFacebookF, FaGoogle } from "react-icons/fa";

import Input from "./Input";
import { useState } from "react";

const GoogleLoginBtn = () => {
  return (
    <div className="cursor-pointer bg-white shadow-lg shadow-gray-200/60 flex items-center justify-center gap-5 w-full p-5 rounded-xl hover:scale-105 ease-in transition-transform">
      {/* login with google */}
     <FaGoogle  size={28}/>

      <p>Login with Google</p>
    </div>
  );
};
const FacebookLoginBtn = () => {
  return (
    <div className="cursor-pointer bg-white shadow-lg shadow-gray-200/60 flex items-center justify-center gap-5 w-full p-5 rounded-xl hover:scale-105 ease-in transition-transform">
      {/* login with google */}
     <FaFacebookF size={32} color="#2856ff" className="ring-2 rounded-full p-1"  />

      <p>Login with Facebook</p>
    </div>
  );
};
function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  return (
    <div className="p-10 w-full h-dvh grid items-center">
      <header className="flex items-center justify-center flex-col gap-2">
        <p className="text-4xl poppins-medium">Welcome to</p>
        <h1
          className="poppins-black text-center text-pmv text-5xl"
          style={{
            lineHeight: "135.5%",
          }}
        >
          Dromos
        </h1>
      </header>

      <main className="flex flex-col gap-5">
        <FacebookLoginBtn />
        <GoogleLoginBtn />

        {/* hr line */}
        <div className="flex justify-center gap-2 items-center w-full">
          <span className="w-2/3 h-px border border-[#bfbfbf]"></span>
          <span>OR</span>
          <span className="w-2/3 h-px border border-[#bfbfbf]"></span>
        </div>

        <Input
          icon={<MdEmail size={30} />}
          title="Email"
          type="email"
          id="email"
          name="email"
          autoComplete="email"
          placeholder={"example@du.ac.bd"}
          required
          value={email}
          handleChange={(e) => setEmail(e.target.value)}
        />

        <Input
          icon={<FaKey size={30} />}
          title="Password"
          type="password"
          id="password"
          name="password"
          autoComplete="new-password"
          required
          value={password}
          handleChange={(e) => setPassword(e.target.value)}
        />

        
         
          <Text as="label" size="2">
            <Flex gap="2">
              <Checkbox />
              Remember me
            </Flex>
          </Text>
    

        <button className="bg-pmv text-white poppins-semibold text-base p-3.5 rounded-lg hover:bg-scv ease-in transition-colors w-full cursor-pointer">
          Login
        </button>

        <Text as="p" size="3">
          <Link href="#" size="3">
            Forgot Password?
          </Link>
        </Text>
        <Text as="p" size="3">
          Don&rsquo;t have an account?{" "}
          <Link href="#" size="3">
            Register Now!
          </Link>
        </Text>
      </main>
    </div>
  );
}

export default Login;
